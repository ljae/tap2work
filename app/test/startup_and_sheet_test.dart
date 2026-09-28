import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/app_loading_screen.dart';
import 'package:tap2work/ui/checklist_editor.dart';
import 'package:tap2work/ui/components.dart';
import 'manual_workspace_test.dart' show directoryData;
import 'operations_test.dart' show response;
import 'work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'startup paints immediately and retries a failed initialization',
    (tester) async {
      var attempt = 0;
      final ready = Completer<Widget>();
      await tester.pumpWidget(
        AppStartup(
          progressStore: MemoryStore(),
          initialize: () {
            attempt++;
            return attempt == 1
                ? ready.future
                : Future.value(const MaterialApp(home: Text('ready')));
          },
        ),
      );
      expect(find.text('매장을 준비하고 있어요'), findsOneWidget);
      expect(find.text('ready'), findsNothing);
      ready.completeError(StateError('offline'));
      await tester.pump();
      expect(find.text('다시 시도'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
      expect(attempt, 2);
    },
  );

  testWidgets(
    'store loading hides incomplete navigation then opens on real data',
    (tester) async {
      final pending = Completer<void>();
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async {
          await pending.future;
          return response(directoryData());
        }),
      );
      final work = WorkController(MemoryStore());
      addTearDown(ops.dispose);
      addTearDown(work.dispose);
      await tester.pumpWidget(Tap2workApp(controller: work, operations: ops));
      final loading = ops.refresh();
      await tester.pump();
      expect(find.byType(AppLoadingScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('floating-menu-0')), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('매장을 준비하고 있어요'), findsOneWidget);
      pending.complete();
      await loading;
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadingScreen), findsNothing);
      expect(find.byKey(const ValueKey('floating-menu-0')), findsOneWidget);
    },
  );

  testWidgets(
    'failed store retry returns to loading immediately then succeeds',
    (tester) async {
      var attempt = 0;
      final retry = Completer<void>();
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async {
          attempt++;
          if (attempt == 1) return response({'error': 'offline'}, 503);
          await retry.future;
          return response(directoryData());
        }),
      );
      final work = WorkController(MemoryStore());
      addTearDown(ops.dispose);
      addTearDown(work.dispose);
      await ops.refresh();
      await tester.pumpWidget(Tap2workApp(controller: work, operations: ops));
      await tester.pump();
      expect(find.text('다시 시도'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(find.text('매장을 준비하고 있어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
      retry.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('floating-menu-0')), findsOneWidget);
    },
  );

  testWidgets('slow startup offers context and respects reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppLoadingScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 12));
    expect(find.textContaining('연결이 조금 늦어지고'), findsOneWidget);
    expect(find.byType(AppLinearProgress), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'manual sheet at $width keeps save above keyboard and protects draft',
      (tester) async {
        tester.view.physicalSize = Size(width, 840);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final ops = OperationsController(
          readOnly: true,
          client: MockClient((_) async => response(directoryData())),
        );
        final work = WorkController(MemoryStore());
        addTearDown(ops.dispose);
        addTearDown(work.dispose);
        await ops.refresh();
        await tester.pumpWidget(
          Tap2workApp(
            controller: work,
            homeOverride: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showAppSheet(
                    context,
                    builder: (_) => const SizedBox.shrink(),
                  ),
                  child: const Text('unused'),
                ),
              ),
            ),
          ),
        );
        final context = tester.element(find.text('unused'));
        unawaited(
          showAppSheet(
            context,
            builder: (_) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
                disableAnimations: true,
              ),
              child: ManualTaskEditor(
                ops: ops,
                templateId: 'a',
                sourceStepId: 's1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Task 이름'),
          '새로운 업무',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        final save = find.widgetWithText(FilledButton, '매뉴얼 저장');
        expect(tester.getRect(save).bottom, lessThanOrEqualTo(560));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(CloseButton));
        await tester.pumpAndSettle();
        expect(find.text('계속 편집'), findsOneWidget);
        await tester.tap(find.text('계속 편집'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextFormField, '새로운 업무'), findsOneWidget);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(ops.rows('taskTemplates').first['steps'][0]['title'], '새로운 업무');
        expect(find.byType(ManualTaskEditor), findsNothing);
      },
    );
  }
}
