import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/domain/edit_conflict.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/edit_conflict_dialog.dart';
import 'manual_media_editor_test.dart' show MediaEditorRepository;

void main() {
  testWidgets(
    'conflict comparison shows translated places and masks private references and data URLs',
    (t) async {
      final ops = OperationsController(repository: MediaEditorRepository());
      addTearDown(ops.dispose);
      ops.data = {
        'zones': [
          {'id': 'internal-zone-id', 'name': '세척대'},
        ],
        'manualContentTranslations': {
          'places': {
            'internal-zone-id': {
              'vi': {
                'name': {'sourceText': '세척대', 'text': 'Bồn rửa'},
              },
            },
          },
        },
      };
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: appSupportedLocales,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEditConflictDialog(context, const [
                  EditFieldConflict(
                    'wash',
                    null,
                    'internal-zone-id',
                    'deleted-zone-id',
                  ),
                  EditFieldConflict(
                    'photo',
                    'tap2work-media:secret-old',
                    'tap2work-media:secret-new',
                    'data:image/jpeg;base64,SECRET',
                  ),
                  EditFieldConflict('kind', 'storage', 'equipment', 'table'),
                ], ops: ops),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      final text = t
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .join('\n');
      expect(text, contains('Bồn rửa'));
      expect(text, contains(AppStrings('vi').text('conflict.placeMissing')));
      expect(text, contains(AppStrings('vi').text('conflict.photoChanged')));
      expect(text, isNot(contains('internal-zone-id')));
      expect(text, isNot(contains('deleted-zone-id')));
      expect(text, isNot(contains('tap2work-media:')));
      expect(text, isNot(contains('base64')));
      expect(text, isNot(contains('SECRET')));
      expect(text, contains(AppStrings('vi').text('place.kindEquipment')));
      expect(t.takeException(), isNull);
    },
  );
}
