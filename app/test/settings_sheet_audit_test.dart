import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/components.dart';
import 'package:tap2work/ui/prepared_item_editor.dart';
import 'package:tap2work/ui/prepared_inventory.dart';
import 'package:tap2work/ui/workplace_screens.dart';
import 'package:tap2work/ui/store_profile_screen.dart';
import 'package:tap2work/ui/payroll_settings_screen.dart';
import 'package:tap2work/ui/tap_settings_screen.dart';
import 'package:tap2work/ui/checklist_editor.dart';
import 'package:tap2work/ui/crew_pattern_screen.dart';
import 'package:tap2work/ui/staff_workspace.dart';
import 'package:tap2work/ui/catalog_editor.dart';
import 'package:tap2work/ui/labor_panel.dart';
import 'manual_workspace_test.dart' show directoryData;
import 'operations_test.dart' show response;
import 'work_controller_test.dart' show MemoryStore;

Json sheetData() {
  final data = directoryData();
  data['dashboard'] = {
    'reports': [
      {
        'menus': [
          {'id': 'menu', 'name': '이름이 긴 메뉴의 준비품 사용량'},
        ],
      },
    ],
  };
  data['catalogMenus'] = [
    {'id': 'menu', 'name': '메뉴', 'price': 10000, 'category': '식사'},
  ];
  data['tappers'] = [
    {
      'id': 'crew',
      'nickname': '테스트 크루',
      'active': true,
      'rank': 'crew',
      'role': 'crew',
    },
  ];
  return data;
}

const preparedSample = <String, dynamic>{
  'id': 'prepared',
  'name': '길이가 긴 준비품 이름 설정',
  'unit': '인분',
  'onHand': 3,
  'minimum': 2,
  'target': 10,
  'batchQuantity': 10,
  'folderId': 'general',
  'zone': 'storage',
  'menuUses': [],
};
Map<String, Widget> sheetCases(OperationsController ops) => {
  for (final section in [
    'hours',
    'parts',
    'permissions',
    'person',
    'invite',
    'verification',
    'certificate',
    'settlement',
    'order-system',
  ])
    section: WorkplaceSettings(
      ops: ops,
      section: section,
      person: const {'id': 'crew', 'nickname': '테스트 크루'},
    ),
  'prepared-add': PreparedItemEditor(ops: ops),
  'prepared-edit': PreparedItemEditor(ops: ops, item: preparedSample),
  'prepared-count': PreparedItemEditor(
    ops: ops,
    item: preparedSample,
    countOnly: true,
  ),
  'profile': StoreProfileScreen(ops: ops),
  'payroll': PayrollSettingsScreen(ops: ops),
  'tap': TapSettingsScreen(ops: ops, initialTemplateId: 'a'),
  'task': TapSettingsScreen(
    ops: ops,
    initialTemplateId: 'a',
    initialStepId: 's1',
  ),
  'manual': ManualTaskEditor(ops: ops, templateId: 'a', sourceStepId: 's1'),
  'patterns': CrewPatternScreen(ops: ops, day: DateTime(2026, 9, 28)),
  'hiring': HiringDraftEditor(ops: ops),
  'catalog': CatalogEditor(ops: ops),
  'labor-review': LaborReviewEditor(
    ops: ops,
    person: const {'id': 'crew', 'nickname': '테스트 크루'},
    week: '2026-09-28',
  ),
  'actions': AppSheetPanel(
    title: const Text('설정 동작 정렬'),
    content: const Text('입력 내용'),
    actions: [
      TextButton(onPressed: () {}, child: const Text('취소')),
      FilledButton(onPressed: () {}, child: const Text('변경 저장')),
    ],
  ),
};

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'all settings sheet families fit $width with large text and keyboard',
      (tester) async {
        tester.view.physicalSize = Size(width, 840);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final ops = OperationsController(
          client: MockClient((_) async => response(sheetData())),
        );
        await ops.refresh();
        addTearDown(ops.dispose);
        final work = WorkController(MemoryStore());
        addTearDown(work.dispose);
        for (final entry in sheetCases(ops).entries) {
          tester.view.resetViewInsets();
          await tester.pumpWidget(
            Tap2workApp(
              key: ValueKey(entry.key),
              controller: work,
              homeOverride: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () =>
                        showAppSheet(context, builder: (_) => entry.value),
                    child: const Text('설정 열기'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('설정 열기'));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} initial',
          );
          if (entry.key == 'profile') {
            for (final label in ['POS', '배달', '크루', '운영', '기본']) {
              final tab = find.text(label).first;
              await tester.ensureVisible(tab);
              await tester.tap(tab);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: 'profile $label');
            }
          }
          if (entry.key == 'actions') {
            expect(
              tester.getTopLeft(find.text('입력 내용')).dy,
              lessThan(tester.getBottomLeft(find.text('설정 동작 정렬')).dy + 80),
            );
            final a = find.widgetWithText(TextButton, '취소');
            final b = find.widgetWithText(FilledButton, '변경 저장');
            expect(tester.getSize(a), tester.getSize(b));
          }
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} keyboard',
          );
          final scroll = find.byType(Scrollable);
          if (scroll.evaluate().isNotEmpty) {
            await tester.drag(scroll.first, const Offset(0, -1200));
            await tester.pumpAndSettle();
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} lower controls',
          );
          final footer = find.byType(AppSheetFooter);
          if (footer.evaluate().isNotEmpty) {
            expect(
              tester.getRect(footer.last).bottom,
              lessThanOrEqualTo(560),
              reason: entry.key,
            );
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        }
      },
    );
  }
  testWidgets(
    'prepared save failure preserves draft, opening revision and keyboard footer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 840);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            sent = jsonDecode(r.body) as Json;
            return response({'error': '다른 동료가 수정했어요.'}, 409);
          }
          return response(sheetData());
        }),
      );
      await ops.refresh();
      addTearDown(ops.dispose);
      await tester.pumpWidget(MaterialApp(home: PreparedItemEditor(ops: ops)));
      await tester.enterText(find.byKey(const ValueKey('prepared-name')), '육수');
      ops.data!['revision'] = 99;
      await tester.tap(find.text('준비품 저장'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'save_prepared_item');
      expect(sent?['revision'], 2);
      expect(find.text('다른 동료가 수정했어요.'), findsOneWidget);
      expect(find.widgetWithText(TextField, '육수'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'prepared entry uses a sheet, preserves omitted menu links and closes only after save',
    (tester) async {
      final data = sheetData();
      data['preparedItems'] = [
        {
          ...preparedSample,
          'menuUses': [
            {'menuId': 'hidden-menu', 'quantity': 2},
          ],
        },
      ];
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body) as Json;
          return response(data);
        }),
      );
      await ops.refresh();
      addTearDown(ops.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PreparedInventory(ops: ops)),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('prepared-inventory-details')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('기준·메뉴 수정'));
      await tester.tap(find.text('기준·메뉴 수정'));
      await tester.pumpAndSettle();
      expect(find.byType(PreparedItemEditor), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('prepared-name')),
        '새 준비품',
      );
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.text('계속 편집'), findsOneWidget);
      await tester.tap(find.text('계속 편집'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('준비품 저장'));
      await tester.pumpAndSettle();
      expect(sent?['menuUses'], [
        {'menuId': 'hidden-menu', 'quantity': 2},
      ]);
      expect(sent?['name'], '새 준비품');
      expect(find.byType(PreparedItemEditor), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
