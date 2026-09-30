import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/tap_settings_screen.dart';
import 'package:tap2work/ui/work_assignment_field.dart';
import 'settings_screens_test.dart' show settingsFixture;
import 'checklist_test.dart' show fixture;
import 'tap_workspace_test.dart' show mountBoard;
import 'operations_test.dart' show response;

void main() {
  testWidgets(
    'band entry edits canonical TAP assignment and preserves Task inheritance',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = settingsFixture();
      data['workplace'] = {
        'parts': [
          {'id': 'kitchen', 'name': '주방'},
        ],
        'days': {
          '1': [
            {'id': 'open', 'name': '오픈', 'start': '09:00', 'end': '14:00'},
          ],
        },
      };
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body) as Json;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TapSettingsScreen(
                      ops: ops,
                      initialTemplateId: 'tap-1',
                      initialTimeBandId: 'open',
                    ),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(find.text('시간대·파트 자동 배정'), findsOneWidget);
      expect(find.textContaining('오픈 09:00–14:00'), findsOneWidget);
      await tester.tap(find.byType(CloseButton).first);
      await tester.pumpAndSettle();
      expect(find.text('변경을 버릴까요?'), findsOneWidget);
      await tester.tap(find.text('계속 수정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('설정 저장'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'save_tap_settings');
      expect(sent?['settings']['assignment']['timeBandIds'], ['open']);
      expect(sent?['settings']['assignment']['partId'], 'kitchen');
      expect(sent?['steps'][0]['settings']['assignment'], isNull);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('actual crew badges and mine filter at $width', (tester) async {
      final data = fixture(actor: 'crew');
      data['tasks'][0]['assignmentView'] = {
        'mode': 'scheduled',
        'timeBandName': '오픈',
        'isMine': false,
        'unassigned': false,
        'assignees': [
          {
            'id': 'cover',
            'nickname': '길이가 긴 대타 크루 이름',
            'start': '13:00',
            'end': '18:00',
          },
        ],
      };
      data['tasks'][1]['assignmentView'] = {
        'mode': 'scheduled',
        'timeBandName': '마감',
        'isMine': true,
        'unassigned': true,
        'assignees': [],
      };
      final ops = OperationsController(
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops, width: width, textScale: 1.5);
      expect(find.textContaining('길이가 긴 대타 크루 이름'), findsOneWidget);
      expect(find.textContaining('담당 미배정'), findsOneWidget);
      await tester.tap(find.text('내 담당만'));
      await tester.pumpAndSettle();
      expect(find.textContaining('길이가 긴 대타 크루 이름'), findsNothing);
      expect(find.text('육수 올리기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'assignment selector supports explicit anyone and inherited Task',
    (tester) async {
      final ops = OperationsController(
        client: MockClient((_) async => response(settingsFixture())),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      Json? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkAssignmentField(
              ops: ops,
              value: null,
              inherit: true,
              onChanged: (v) => selected = v,
            ),
          ),
        ),
      );
      await tester.tap(find.text('TAP 따름'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('누구나 · 오늘 근무 크루').last);
      await tester.pumpAndSettle();
      expect(selected?['mode'], 'anyone');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'part filters use scheduled assignment instead of old all-part scope',
    (tester) async {
      final data = fixture();
      data['workplace'] = {
        'parts': [
          {'id': 'kitchen', 'name': '주방'},
          {'id': 'hall', 'name': '홀'},
        ],
      };
      data['tasks'] = [data['tasks'][0]];
      data['tasks'][0]['assignmentView'] = {
        'mode': 'scheduled',
        'partId': 'kitchen',
        'timeBandName': '오픈',
        'isMine': true,
        'unassigned': false,
        'assignees': [
          {'id': 'a', 'nickname': '배정 크루'},
        ],
      };
      final ops = OperationsController(
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops);
      expect(find.text('전처리 준비'), findsOneWidget);
      await tester.tap(find.text('홀').first);
      await tester.pumpAndSettle();
      expect(find.text('전처리 준비'), findsNothing);
      await tester.tap(find.text('주방').first);
      await tester.pumpAndSettle();
      expect(find.text('전처리 준비'), findsOneWidget);
    },
  );
}
