import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image/image.dart' as img;
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/place_guide.dart';
import 'package:tap2work/ui/translated_content.dart';
import 'manual_media_editor_test.dart'
    show
        MediaEditorRepository,
        mediaReference,
        mediaWorkspace,
        mediaOtherWorkspace;

class RetryPhotoRepository extends MediaEditorRepository {
  int loads = 0;
  Completer<Uint8List>? gate;
  @override
  Future<Uint8List> loadManualPhoto({
    required String actorId,
    required String workspaceId,
    required String reference,
  }) async {
    loads++;
    if (gate != null) return gate!.future;
    if (loads == 1) throw StateError('offline');
    return Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));
  }
}

void main() {
  testWidgets(
    'private photo retries and rejects late bytes after workspace change',
    (t) async {
      final repo = RetryPhotoRepository();
      final ops = OperationsController(
        repository: repo,
        accessToken: () async => 'fixture',
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: placePhoto(mediaReference, ops: ops)),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('다시 시도'), findsOneWidget);
      await t.tap(find.text('다시 시도'));
      await t.pumpAndSettle();
      expect(repo.loads, 2);
      expect(find.byType(Image), findsOneWidget);
      repo.gate = Completer<Uint8List>();
      ops.data = {...ops.data!, 'workspaceId': mediaOtherWorkspace};
      ops.notifyListeners();
      await t.pumpAndSettle();
      ops.data = {...ops.data!, 'workspaceId': mediaWorkspace};
      ops.notifyListeners();
      await t.pump();
      ops.data = {...ops.data!, 'workspaceId': mediaOtherWorkspace};
      ops.notifyListeners();
      await t.pump();
      repo.gate!.complete(
        Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2))),
      );
      await t.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
    },
  );
  for (final locale in appSupportedLocales) {
    testWidgets(
      'place original toggle with 320px large text ${locale.toLanguageTag()}',
      (t) async {
        t.view.physicalSize = const Size(320, 1000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final ops = OperationsController(
          repository: MediaEditorRepository(),
          accessToken: () async => 'fixture',
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        final language = locale.toLanguageTag();
        ops.data = {
          ...ops.data!,
          'manualContentTranslations': {
            'places': {
              'sink': {
                language: {
                  'name': {'sourceText': '세척대', 'text': 'Translated sink'},
                  'description': {
                    'sourceText': '원문 안내',
                    'text': 'Translated guide',
                  },
                },
              },
            },
          },
        };
        await t.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: appSupportedLocales,
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: TranslatedContent(
                    ops: ops,
                    kind: 'place',
                    entityId: 'sink',
                    source: const {
                      'id': 'sink',
                      'name': '세척대',
                      'description': '원문 안내',
                    },
                    loadDictionary: (_) async => {},
                    builder: (_, row) =>
                        Text('${row['name']} · ${row['description']}'),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        if (language != 'ko') {
          expect(
            find.text('Translated sink · Translated guide'),
            findsOneWidget,
          );
          await t.tap(find.text(AppStrings(language).text('manual.original')));
          await t.pumpAndSettle();
        }
        expect(find.text('세척대 · 원문 안내'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
