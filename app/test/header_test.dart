import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/components.dart';
import 'operations_test.dart' show sample, response;
import 'work_controller_test.dart' show MemoryStore;

void phone(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void expectOneCompactAction(WidgetTester tester) {
  final header = find.byType(BrandHeader);
  expect(header, findsOneWidget);
  expect(
    find.descendant(of: header, matching: find.byType(HeaderAccountButton)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: header, matching: find.byType(PopupMenuButton<String>)),
    findsOneWidget,
  );
  expect(
    tester.getRect(find.byType(BrandLogo)).right,
    lessThan(tester.getRect(find.byType(HeaderAccountButton)).left),
  );
  expect(tester.getSize(find.byType(AppBar)).height, 72);
  expect(tester.takeException(), isNull);
}

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'preview header combines login and clearly labeled demo roles at $width',
      (tester) async {
        phone(tester, width);
        final ops = OperationsController(
          readOnly: true,
          client: MockClient(
            (request) async => response(
              sample(request.url.path.endsWith('crew.json') ? 'crew' : 'owner'),
            ),
          ),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        var accountOpens = 0;
        await tester.pumpWidget(
          Tap2workApp(
            controller: WorkController(MemoryStore()),
            operations: ops,
            onAccountPressed: (_) async {
              accountOpens++;
            },
          ),
        );
        await tester.pumpAndSettle();
        expectOneCompactAction(tester);
        await tester.tap(find.byKey(const ValueKey('header-account-menu')));
        await tester.pumpAndSettle();
        expect(find.text('내 매장 로그인'), findsOneWidget);
        expect(find.text('체험 역할 · 실제 로그인 아님'), findsOneWidget);
        await tester.tap(find.text('내 매장 로그인'));
        await tester.pumpAndSettle();
        expect(accountOpens, 1);
        await tester.tap(find.byKey(const ValueKey('header-account-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('지우 · 크루'));
        await tester.pumpAndSettle();
        expect(ops.actorId, 'crew');
        expectOneCompactAction(tester);
      },
    );

    testWidgets(
      'authenticated cloud header shows account and role without demo switch at $width',
      (tester) async {
        phone(tester, width);
        final ops = OperationsController(
          endpoint: Uri.parse(
            'https://example.supabase.co/functions/v1/operations',
          ),
          accessToken: () async => 'session',
          client: MockClient((_) async => response(sample())),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        var accountOpens = 0;
        await tester.pumpWidget(
          Tap2workApp(
            controller: WorkController(MemoryStore()),
            operations: ops,
            accountEmail: 'owner@example.com',
            onAccountPressed: (_) async {
              accountOpens++;
            },
          ),
        );
        await tester.pumpAndSettle();
        expectOneCompactAction(tester);
        await tester.tap(find.byKey(const ValueKey('header-account-menu')));
        await tester.pumpAndSettle();
        expect(find.text('계정 · owner@example.com'), findsOneWidget);
        expect(find.textContaining('내 매장 · 사장님'), findsOneWidget);
        expect(find.text('체험 역할 · 실제 로그인 아님'), findsNothing);
        expect(find.text('지우 · 크루'), findsNothing);
        await tester.tap(find.text('계정 · owner@example.com'));
        await tester.pumpAndSettle();
        expect(accountOpens, 1);
        expectOneCompactAction(tester);
      },
    );

    testWidgets(
      'first-shift guide uses the same header and one demo action at $width',
      (tester) async {
        phone(tester, width);
        final work = WorkController(MemoryStore());
        await tester.pumpWidget(Tap2workApp(controller: work));
        await tester.pumpAndSettle();
        expectOneCompactAction(tester);
        await tester.tap(find.byKey(const ValueKey('header-account-menu')));
        await tester.pumpAndSettle();
        expect(find.text('버디 · 민지로 체험'), findsOneWidget);
        await tester.tap(find.text('버디 · 민지로 체험'));
        await tester.pumpAndSettle();
        expect(work.role, DemoRole.buddy);
        expectOneCompactAction(tester);
      },
    );
  }

  testWidgets(
    'long cloud email stays inside the 320px account menu at large text scale',
    (tester) async {
      phone(tester, 320);
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final ops = OperationsController(
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/operations',
        ),
        accessToken: () async => 'session',
        client: MockClient((_) async => response(sample())),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      const email =
          'this-is-a-very-long-owner-address@example-restaurant-domain.com';
      await tester.pumpWidget(
        Tap2workApp(
          controller: WorkController(MemoryStore()),
          operations: ops,
          accountEmail: email,
          onAccountPressed: (_) async {},
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('header-account-menu')));
      await tester.pumpAndSettle();
      final label = find.text('계정 · $email');
      expect(label, findsOneWidget);
      expect(tester.widget<Text>(label).overflow, TextOverflow.ellipsis);
      expect(
        tester
            .getRect(
              find.ancestor(
                of: label,
                matching: find.byType(PopupMenuItem<String>),
              ),
            )
            .right,
        lessThanOrEqualTo(320),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
