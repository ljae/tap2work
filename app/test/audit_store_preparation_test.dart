import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/domain/store_preparation.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/workplace_screens.dart';
import 'package:tap2work/ui/crew_invitation_screen.dart';
import 'operations_test.dart' show sample, response;

Json preparationFixture() => {
  'day': '2026-10-10',
  'workplace': {
    'parts': [
      {'id': 'kitchen', 'name': '주방'},
    ],
    'days': {
      '6': [
        {'id': 'open', 'start': '10:00', 'end': '11:00'},
      ],
    },
  },
  'tappers': [
    {'id': 'owner', 'rank': 'owner', 'active': true},
    {'id': 'crew', 'rank': 'crew', 'active': true},
    {'id': 'inactive', 'rank': 'crew', 'active': false},
  ],
  'taskTemplates': [
    {'id': 'manual'},
  ],
  'tasks': [
    {'id': 'today'},
  ],
  'rosterTemplates': [
    for (var i = 0; i < 3; i++)
      {
        'id': 'seat-$i',
        'weekday': 6,
        'partId': 'kitchen',
        'name': '주방',
        'start': '10:00',
        'end': '11:00',
      },
  ],
  'staffShifts': [
    {
      'id': 'shift',
      'date': '2026-10-10',
      'partId': 'kitchen',
      'tapperId': 'crew',
      'start': '10:00',
      'end': '11:00',
      'status': 'planned',
    },
    {
      'id': 'inactive-shift',
      'date': '2026-10-10',
      'partId': 'kitchen',
      'tapperId': 'inactive',
      'start': '10:00',
      'end': '11:00',
      'status': 'planned',
    },
    {
      'id': 'past-shift',
      'date': '2026-10-03',
      'partId': 'kitchen',
      'tapperId': 'crew',
      'start': '10:00',
      'end': '11:00',
      'status': 'planned',
    },
  ],
  'menus': [
    {'id': 'starter', 'price': 0, 'setupNeedsReview': true},
    {'id': 'free', 'price': 0, 'setupNeedsReview': false},
    {'id': 'archived', 'price': 0, 'archivedAt': '2026-10-01'},
  ],
  'items': [
    {'id': 'unknown', 'inventoryStatus': 'quantity_unknown'},
    {'id': 'policy', 'inventoryStatus': 'policy_unknown'},
    {'id': 'low', 'inventoryStatus': 'low'},
    {'id': 'legacy', 'quantity': 0, 'minimum': 5},
  ],
};

void main() {
  testWidgets(
    'cloud invite entry uses authenticated invitation screen, demo remains separate',
    (tester) async {
      final ops = OperationsController(
        accessToken: () async => 'synthetic-test-token',
        client: MockClient((_) async => response({'invitations': <Json>[]})),
      )..data = sample();
      ops.workspaceId = 'audit-workspace';
      addTearDown(ops.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: WorkplaceSettings(ops: ops, section: 'invite'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CrewInvitationScreen), findsOneWidget);
      expect(find.textContaining('체험용 초대 코드예요'), findsNothing);
      expect(tester.takeException(), isNull);
      final demo = OperationsController()..data = sample();
      addTearDown(demo.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: WorkplaceSettings(
            key: const ValueKey('demo'),
            ops: demo,
            section: 'invite',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CrewInvitationScreen), findsNothing);
      expect(find.textContaining('체험용 초대 코드예요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'only manager exposes explicitly opt-in crew invitation permission',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = sample();
      data['workplace'] = {
        ...?data['workplace'],
        'restrictions': <String, dynamic>{},
      };
      Json? posted;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            posted = jsonDecode(r.body) as Json;
            data['revision'] = (data['revision'] as int) + 1;
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkplaceSettings(ops: ops, section: 'permissions'),
        ),
      );
      await tester.pumpAndSettle();
      final row = find.ancestor(
        of: find.text('크루 초대·계정 연결'),
        matching: find.byType(SettingRow),
      );
      final control = find.descendant(of: row, matching: find.byType(Switch));
      expect(tester.widget<Switch>(control).value, isFalse);
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(posted!['action'], 'save_workplace_permissions');
      expect(posted!['role'], 'manager');
      expect(posted!['permissions']['crew'], isTrue);
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, '크루'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '크루'));
      await tester.pumpAndSettle();
      expect(find.text('크루 초대·계정 연결'), findsNothing);
      expect(find.byType(Switch), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'readiness uses required headcount minutes and valid dated active assignments',
    () {
      final status = StorePreparationStatus(preparationFixture());
      expect(status.hasAssignments, isTrue);
      expect(status.neededMinutes, 180);
      expect(status.coveredMinutes, 60);
      expect(
        status.menusToReview,
        1,
        reason: 'explicitly saved free menu is not unconfigured',
      );
      expect(
        status.inventoryToReview,
        2,
        reason: 'known low stock is not an unreviewed setup',
      );
    },
  );

  test(
    'closed days and historical assignments do not claim current setup coverage',
    () {
      final data = preparationFixture();
      data['workplace']['days'] = {'6': <Json>[]};
      data['rosterTemplates'] = <Json>[];
      data['staffShifts'] = [data['staffShifts'].last];
      final status = StorePreparationStatus(data);
      expect(status.hasHours, isFalse);
      expect(status.hasAssignments, isFalse);
      expect(status.neededMinutes, 0);
      expect(status.coveredMinutes, 0);
    },
  );

  testWidgets(
    'basic 4/4 still shows three actionable operational gaps without gating',
    (tester) async {
      final ops = OperationsController()..data = preparationFixture();
      addTearDown(ops.dispose);
      var schedule = 0, menus = 0, inventory = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StorePreparation(
                ops: ops,
                onHours: () {},
                onPeople: () {},
                onTasks: () {},
                onSchedule: () => schedule++,
                onMenus: () => menus++,
                onInventory: () => inventory++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('기본 설정 4/4'), findsOneWidget);
      expect(find.text('이어서 준비할 항목'), findsOneWidget);
      expect(find.textContaining('180'), findsOneWidget);
      expect(find.textContaining('가격 확인이 필요한 메뉴 1개'), findsOneWidget);
      expect(find.textContaining('수량·발주 기준 확인이 필요한 재료 2개'), findsOneWidget);
      await tester.tap(find.textContaining('180'));
      await tester.ensureVisible(find.textContaining('가격 확인이 필요한 메뉴 1개'));
      await tester.tap(find.textContaining('가격 확인이 필요한 메뉴 1개'));
      await tester.ensureVisible(find.textContaining('수량·발주 기준 확인이 필요한 재료 2개'));
      await tester.tap(find.textContaining('수량·발주 기준 확인이 필요한 재료 2개'));
      expect([schedule, menus, inventory], [1, 1, 1]);
      expect(tester.takeException(), isNull);
    },
  );
}
