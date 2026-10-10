import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/crew_invitation_screen.dart';

http.Response reply(Json data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
void main() {
  testWidgets(
    'authenticated recipient sees existing crew details and must explicitly accept before membership changes',
    (tester) async {
      final calls = <Json>[];
      var accepted = false, finished = false;
      final ops = OperationsController(
        accessToken: () async => 'test-session',
        client: MockClient((r) async {
          if (r.method == 'GET') {
            return reply(
              accepted
                  ? {
                      'workspaceId': 'joined-store',
                      'revision': 2,
                      'actor': {'id': 'signed-in-user', 'role': 'crew'},
                      'tappers': [
                        {'id': 'existing-crew', 'actorId': 'signed-in-user'},
                      ],
                    }
                  : {'needsWorkspace': true},
            );
          }
          expect(r.url.queryParameters['invite'], 'crew');
          expect(r.headers['Authorization'], 'Bearer test-session');
          final input = jsonDecode(r.body) as Json;
          calls.add(input);
          if (input['action'] == 'preview') {
            return reply({
              'workspaceName': '초대 매장',
              'crewName': '등록된 크루',
              'role': 'crew',
              'expiresAt': '2026-10-17T12:00:00Z',
            });
          }
          expect(input['action'], 'accept');
          expect(input['confirm'], true);
          accepted = true;
          return reply({'accepted': true, 'workspaceId': 'joined-store'});
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: CrewInvitationScreen(
            ops: ops,
            initialCode: 'ABCD' * 6,
            onFinished: () => finished = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      await tester.tap(find.text('초대 확인'));
      await tester.pumpAndSettle();
      expect(find.text('초대 매장'), findsOneWidget);
      expect(find.text('연결할 크루: 등록된 크루'), findsOneWidget);
      expect(accepted, isFalse);
      await tester.ensureVisible(find.text('내 정보가 맞아요 · 연결 수락'));
      await tester.tap(find.text('내 정보가 맞아요 · 연결 수락'));
      await tester.pumpAndSettle();
      expect(accepted, isTrue);
      expect(finished, isTrue);
      expect(ops.workspaceId, 'joined-store');
      expect(ops.rows('tappers').single['id'], 'existing-crew');
      expect(calls.length, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'manager invitation selects an existing crew and only returns a code for explicit copying',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final calls = <Json>[];
      final data = {
        'workspaceId': 'test-store',
        'revision': 4,
        'actor': {'id': 'manager', 'role': 'manager'},
        'canManageCrewInvites': true,
        'tappers': [
          {'id': 'target', 'nickname': '가상 크루', 'rank': 'crew', 'active': true},
        ],
      };
      final ops = OperationsController(
        accessToken: () async => 'session',
        client: MockClient((r) async {
          if (r.method == 'GET') return reply(data);
          final input = jsonDecode(r.body) as Json;
          calls.add(input);
          if (input['action'] == 'list') return reply({'invitations': []});
          expect(input['action'], 'create');
          expect(input['tapperId'], 'target');
          expect(input['revision'], 4);
          return reply({
            'tapperId': 'target',
            'code': 'ABCD-ABCD-ABCD-ABCD-ABCD-ABCD',
            'link': 'https://tap2.work/?invite=${'ABCD' * 6}',
            'expiresAt': '2026-10-17T12:00:00Z',
          });
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        MaterialApp(home: CrewInvitationScreen(ops: ops, management: true)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('가상 크루').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('7일 초대 만들기'));
      await tester.pumpAndSettle();
      expect(find.text('초대 링크 복사'), findsOneWidget);
      expect(find.text('코드 복사'), findsOneWidget);
      expect(calls.where((c) => c['action'] == 'create').length, 1);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'late invitation response cannot switch a different account or workspace',
    () async {
      late OperationsController ops;
      ops = OperationsController(
        accessToken: () async => 'session',
        client: MockClient((r) async {
          ops.workspaceId = 'switched';
          return reply({'accepted': true, 'workspaceId': 'invited'});
        }),
      );
      addTearDown(ops.dispose);
      await expectLater(
        ops.crewInvitation('accept', {'code': 'ABCD' * 6, 'confirm': true}),
        throwsStateError,
      );
      expect(ops.workspaceId, 'switched');
    },
  );
}
