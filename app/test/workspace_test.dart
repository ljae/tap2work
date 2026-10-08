import 'support/store_setup_fixture.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap2work/data/workspace_selection_repository.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/components.dart';
import 'operations_test.dart' show sample, response;
import 'work_controller_test.dart' show MemoryStore;

const stores = [
  {'id': 'a', 'name': '이름이 아주 긴 강남 첫 번째 매장', 'role': 'owner'},
  {'id': 'b', 'name': '홍대점', 'role': 'crew'},
];
Json snapshot(String id) => {
  ...sample(id == 'b' ? 'crew' : 'owner'),
  'actor': {'id': 'user', 'role': id == 'b' ? 'crew' : 'owner'},
  'workspaceId': id,
  'workspaces': stores,
  'storeSetupCatalog': setupCatalogFixture(),
  'store': {'name': id == 'b' ? '홍대점' : stores.first['name']},
  'syncWindow': 1,
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('last selected store is isolated by account', () async {
    SharedPreferences.setMockInitialValues({});
    const one = WorkspaceSelectionRepository('one');
    const two = WorkspaceSelectionRepository('two');
    await one.save('a');
    await two.save('b');
    expect(await one.read(), 'a');
    expect(await two.read(), 'b');
  });
  test(
    'switch scopes cache and writes, clears schedule window and rejects late reads',
    () async {
      final requests = <http.Request>[];
      Completer<http.Response>? late;
      final ops = OperationsController(
        accessToken: () async => 'token',
        client: MockClient((r) async {
          requests.add(r);
          if (r.method == 'POST') {
            return response(
              snapshot(jsonDecode(r.body)['workspaceId'] as String),
            );
          }
          if (late != null && r.url.queryParameters['workspace'] == 'a') {
            return late.future;
          }
          return response(snapshot(r.url.queryParameters['workspace'] ?? 'a'));
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      ops.showScheduleRange('2026-10-05', '2026-10-11');
      await Future<void>.delayed(Duration.zero);
      late = Completer<http.Response>();
      final pending = ops.refresh(force: true);
      await Future<void>.delayed(Duration.zero);
      await ops.selectWorkspace('b');
      final b = requests.last.url.queryParameters;
      expect(b['workspace'], 'b');
      expect(b['revision'], isNull);
      expect(b['scheduleFrom'], isNull);
      expect(ops.actor['role'], 'crew');
      late.complete(response(snapshot('a')));
      await pending;
      expect(ops.workspaceId, 'b');
      expect(ops.data!['workspaceId'], 'b');
      late = null;
      await ops.selectWorkspace('a');
      expect(requests.last.url.queryParameters['revision'], isNull);
      expect(ops.data!['workspaceId'], 'a');
      await ops.selectWorkspace('b');
      await ops.act('example', {});
      expect(jsonDecode(requests.last.body)['workspaceId'], 'b');
    },
  );
  test(
    'revoked store clears its snapshot and retains authorized choices',
    () async {
      var revoked = false;
      final ops = OperationsController(
        accessToken: () async => 'token',
        client: MockClient(
          (r) async => revoked
              ? response({
                  'error': '매장 권한 없음',
                  'workspaces': [stores.last],
                }, 403)
              : response(snapshot('a')),
        ),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      revoked = true;
      await ops.refresh();
      expect(ops.data, isNull);
      expect(ops.workspaces.single['id'], 'b');
    },
  );
  for (final width in [320.0, 800.0]) {
    testWidgets(
      'store selector is before account, switches role and adds a named store at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final writes = <Json>[];
        final ops = OperationsController(
          accessToken: () async => 'token',
          client: MockClient((r) async {
            if (r.method == 'POST') {
              final body = jsonDecode(r.body) as Json;
              writes.add(body);
              return response({
                ...snapshot('c'),
                'store': {'name': body['name']},
              });
            }
            return response(
              snapshot(r.url.queryParameters['workspace'] ?? 'a'),
            );
          }),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        await tester.pumpWidget(
          Tap2workApp(
            controller: WorkController(MemoryStore()),
            operations: ops,
          ),
        );
        await tester.pumpAndSettle();
        final menu = find.byKey(const ValueKey('header-workspace-menu'));
        expect(
          tester.getRect(menu).right,
          lessThan(tester.getRect(find.byType(HeaderAccountButton)).left),
        );
        expect(tester.getSize(menu).height, 48);
        expect(tester.takeException(), isNull);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('홍대점').last);
        await tester.pumpAndSettle();
        expect(ops.workspaceId, 'b');
        expect(ops.isOwner, isFalse);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('+ 새 매장 추가'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, '다음'));
        await tester.pumpAndSettle();
        expect(writes, isEmpty);
        await tester.enterText(
          find.byKey(const ValueKey('new-workspace-name')),
          '새로운 지점',
        );
        await tester.tap(find.widgetWithText(FilledButton, '다음'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilterChip, '치킨'));
        for (var i = 0; i < 11; i++) {
          await tester.tap(find.widgetWithText(FilledButton, '다음'));
          await tester.pumpAndSettle();
        }
        expect(writes, isEmpty);
        await tester.tap(find.widgetWithText(FilledButton, '매장 등록'));
        await tester.pumpAndSettle();
        expect(writes.single['name'], '새로운 지점');
        expect(writes.single['mode'], 'blank');
        expect(writes.single['requestId'], matches(RegExp(r'^[a-f0-9-]{36}$')));
        expect(ops.workspaceId, 'c');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
