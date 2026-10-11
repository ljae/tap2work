import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/owner_workflow_screen.dart';
import 'manual_workspace_test.dart' show directoryData;
import 'manual_market_test.dart' show mount;
import 'operations_test.dart' show response;

Json data() => {
  ...directoryData(),
  'actor': {'id': 'owner', 'role': 'owner', 'name': '사장님'},
  'ownerWorkflow': {
    'version': 1,
    'date': '2026-10-12',
    'closed': false,
    'assumption': '홀·주방이 있는 작은 식당의 기본 제안',
    'candidates': [
      {
        'id': 'phone',
        'title': '전화 응대',
        'usage': 'reference',
        'steps': [
          {
            'id': 'one',
            'title': '매장명으로 인사',
            'manual': '요청을 듣고 날짜·시간·인원을 되읽어요.',
            'tip': '모르면 확인 후 안내해요.',
          },
        ],
      },
    ],
    'pending': [],
    'plans': [
      {
        'templateId': 'a',
        'title': '홀 오픈',
        'slot': '오픈',
        'stepCount': 3,
        'assignment': {'assignees': []},
      },
    ],
  },
};
void main() {
  testWidgets(
    'owner reviews before batch registration and sees saved effects',
    (tester) async {
      final writes = <Json>[];
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') writes.add(jsonDecode(r.body) as Json);
          return response(data());
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, OwnerWorkflowScreen(ops: ops));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, '확인 후 0개 우리 매장에 등록'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('전화 응대'));
      await tester.pumpAndSettle();
      expect(find.text('요청을 듣고 날짜·시간·인원을 되읽어요.'), findsOneWidget);
      await tester.tap(find.text('내용을 검토했어요 · 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인 후 1개 우리 매장에 등록'));
      await tester.pumpAndSettle();
      expect(writes.single['reviewed'], true);
      expect(writes.single['starterIds'], ['phone']);
      expect(find.text('설정은 여기에 반영돼요'), findsOneWidget);
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'tomorrow preview is read-only and shows unassigned work at $width',
      (tester) async {
        var writes = 0;
        final ops = OperationsController(
          client: MockClient((r) async {
            if (r.method == 'POST') writes++;
            return response(data());
          }),
        );
        addTearDown(ops.dispose);
        await mount(
          tester,
          ops,
          OwnerWorkflowScreen(ops: ops),
          width: width,
          scale: 1.5,
        );
        await tester.tap(find.text('3 내일 준비'));
        await tester.pumpAndSettle();
        expect(find.text('담당 크루 확인이 필요해요'), findsOneWidget);
        expect(find.text('담당·반복 일정 변경'), findsOneWidget);
        expect(writes, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
