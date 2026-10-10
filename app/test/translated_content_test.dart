import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/domain/content_translation_repository.dart';
import 'package:tap2work/domain/operations_repository.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/translated_content.dart';

class TranslationFake
    implements OperationsRepository, ContentTranslationRepository {
  Completer<Json>? _response;
  Completer<Json> get response => _response ??= Completer<Json>();
  int writes = 0, reads = 0;
  @override
  Future<Json> translateContent({
    required String actorId,
    required String workspaceId,
    required String targetLocale,
    required String kind,
    String? id,
  }) {
    reads++;
    return response.future;
  }

  @override
  Future<OperationsResult> read({
    required String actorId,
    String? demoToken,
    String? scheduleFrom,
    String? scheduleTo,
    String? workspaceId,
    bool useCache = true,
  }) async => const OperationsResult(200, {});
  @override
  Future<OperationsResult> write({
    required String actorId,
    String? demoToken,
    required Json values,
  }) async {
    writes++;
    return const OperationsResult(200, {});
  }

  @override
  void close() {}
}

void main() {
  late TranslationFake repo;
  late OperationsController ops;
  setUp(() {
    repo = TranslationFake();
    ops = OperationsController(
      repository: repo,
      readOnly: false,
      accessToken: () async => 'test',
    );
    ops.data = {
      'workspaceId': 'store-a',
      'revision': 1,
      'translationRuntimeEnabled': true,
      'actor': {'id': 'owner', 'role': 'owner'},
    };
  });
  tearDown(() => ops.dispose());
  Widget frame(Json source) => MaterialApp(
    locale: const Locale('en'),
    supportedLocales: appSupportedLocales,
    localizationsDelegates: const [AppStrings.delegate],
    home: Scaffold(
      body: TranslatedContent(
        ops: ops,
        kind: 'welcome',
        loadDictionary: (_) async => {},
        source: source,
        builder: (_, row) => Text('${row['body']}'),
      ),
    ),
  );
  testWidgets(
    'automatically displays translation; original toggle never writes progress',
    (tester) async {
      await tester.pumpWidget(frame({'title': '환영', 'body': '함께 시작'}));
      expect(find.text('함께 시작'), findsOneWidget);
      expect(repo.reads, 1);
      repo.response.complete({
        'status': 'translated',
        'original': {'title': '환영', 'body': '함께 시작'},
        'translated': {'title': 'Welcome', 'body': 'Start together'},
      });
      await tester.pumpAndSettle();
      expect(
        find.text('Start together'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data)
            .join(' | '),
      );
      await tester.tap(find.text(AppStrings('en').text('manual.original')));
      await tester.pumpAndSettle();
      expect(find.text('함께 시작'), findsOneWidget);
      expect(repo.writes, 0);
    },
  );
  testWidgets('response from another store cannot replace source', (
    tester,
  ) async {
    await tester.pumpWidget(frame({'title': '환영', 'body': '함께 시작'}));
    ops.data = {'workspaceId': 'store-b', 'revision': 1};
    repo.response.complete({
      'status': 'translated',
      'original': {'title': '환영', 'body': '함께 시작'},
      'translated': {'title': 'Welcome', 'body': 'Wrong store'},
    });
    await tester.pumpAndSettle();
    expect(find.text('Wrong store'), findsNothing);
    expect(find.text('함께 시작'), findsOneWidget);
  });
  testWidgets('concurrently edited source rejects stale translation', (
    tester,
  ) async {
    await tester.pumpWidget(frame({'title': '환영', 'body': '새로운 안내'}));
    repo.response.complete({
      'status': 'translated',
      'original': {'title': '환영', 'body': '이전 안내'},
      'translated': {'title': 'Welcome', 'body': 'Stale content'},
    });
    await tester.pumpAndSettle();
    expect(find.text('Stale content'), findsNothing);
    expect(find.text('새로운 안내'), findsOneWidget);
  });
  testWidgets(
    'prepared and registered fields show without paid calls; only edited field needs translation',
    (tester) async {
      ops.data!['translationRuntimeEnabled'] = false;
      ops.data!['manualContentTranslations'] = {
        'welcome': {
          'en': {
            'body': {'sourceText': '함께 시작', 'text': 'Start together'},
          },
        },
      };
      Widget prepared(Json source) => MaterialApp(
        locale: const Locale('en'),
        supportedLocales: appSupportedLocales,
        localizationsDelegates: const [AppStrings.delegate],
        home: Scaffold(
          body: TranslatedContent(
            ops: ops,
            kind: 'welcome',
            source: source,
            loadDictionary: (_) async => {'환영': 'Welcome'},
            builder: (_, row) => Text('${row['title']} | ${row['body']}'),
          ),
        ),
      );
      await tester.pumpWidget(prepared({'title': '환영', 'body': '함께 시작'}));
      await tester.pumpAndSettle();
      expect(find.text('Welcome | Start together'), findsOneWidget);
      expect(repo.reads, 0);
      await tester.pumpWidget(prepared({'title': '환영', 'body': '새로운 안내'}));
      await tester.pumpAndSettle();
      expect(find.text('Welcome | 새로운 안내'), findsOneWidget);
      expect(
        find.text(AppStrings('en').text('translation.needed')),
        findsOneWidget,
      );
      expect(repo.reads, 0);
      expect(repo.writes, 0);
    },
  );
}
