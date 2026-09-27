import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/completion_text.dart';
import 'package:tap2work/ui/tap_card.dart';

import 'checklist_test.dart' show fixture;
import 'operations_test.dart' show response;
import 'tap_workspace_test.dart' show mountBoard, openGroup;

void main() {
  testWidgets('preview TAP stays in place while falling then moves to done', (
    tester,
  ) async {
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(fixture())),
    );
    addTearDown(ops.dispose);
    await mountBoard(tester, ops);
    await openGroup(tester, '기본 업무  ·  2');
    final tap = find.byKey(const ValueKey('tap-daily-prep'));
    final start = tester.getTopLeft(tap);
    tester.widget<TapCard>(tap).onCheck!();
    await tester.pump();
    expect(tester.widget<TapCard>(tap).completionTrigger, isNotNull);
    expect(tester.getTopLeft(tap), start);
    await tester.pump(const Duration(milliseconds: 170));
    final title = find.descendant(
      of: tap,
      matching: find.byType(CompletionText),
    );
    final opacity = tester.widget<Opacity>(
      find.descendant(of: title, matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, inExclusiveRange(0, 1));
    expect(tester.widget<TapCard>(tap).checked, isTrue);
    expect(tester.getTopLeft(tap), start);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester
          .widget<Opacity>(
            find.descendant(of: title, matching: find.byType(Opacity)),
          )
          .opacity,
      0,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(tap).dx, greaterThan(start.dx));
    expect(tester.widget<TapCard>(tap).completionTrigger, isNull);
  });

  testWidgets(
    'a successful preview Small TAP completion visibly drops its title',
    (tester) async {
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(fixture())),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops);
      await openGroup(tester, '기본 업무  ·  2');
      final tap = find.byKey(const ValueKey('tap-daily-prep'));
      await tester.ensureVisible(tap);
      // Open through the visible card to exercise the same path as the app.
      await tester.tap(
        find.descendant(of: tap, matching: find.text('Small TAP')).first,
      );
      await tester.pumpAndSettle();

      final small = find.byKey(const ValueKey('small-s1'));
      await tester.tap(
        find.descendant(of: small, matching: find.byTooltip('완료하기')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 170));
      final title = find.descendant(
        of: small,
        matching: find.byType(CompletionText),
      );
      final opacity = tester.widget<Opacity>(
        find.descendant(of: title, matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, lessThan(1));
      expect(opacity.opacity, greaterThan(0));
      await tester.pumpAndSettle();
      expect(
        ops
            .rows('tasks')
            .firstWhere(
              (row) => row['id'] == 'daily-prep',
            )['steps'][0]['completedAt'],
        isNotNull,
      );
    },
  );

  testWidgets(
    'opening a TAP reveals its heading before the animation settles',
    (tester) async {
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(fixture())),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops);
      await openGroup(tester, '기본 업무  ·  2');
      final tap = find.byKey(const ValueKey('tap-daily-prep'));
      await tester.ensureVisible(tap);
      await tester.tap(
        find.descendant(of: tap, matching: find.text('Small TAP')).first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final body = find.byKey(const ValueKey('tap-body/general/daily-prep'));
      final reveal = tester.widget<SlideTransition>(
        find.ancestor(of: body, matching: find.byType(SlideTransition)).first,
      );
      expect(reveal.position.value.dy, greaterThan(0));
      expect(reveal.position.value.dy, lessThan(.035));
      expect(find.byKey(const ValueKey('tap-daily-prep')), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('small-s1')), findsOneWidget);
    },
  );

  testWidgets('reduced motion moves a completed TAP without a holding frame', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(fixture())),
    );
    addTearDown(ops.dispose);
    await mountBoard(tester, ops);
    await openGroup(tester, '기본 업무  ·  2');
    final tap = find.byKey(const ValueKey('tap-daily-prep'));
    final start = tester.getTopLeft(tap);
    tester.widget<TapCard>(tap).onCheck!();
    await tester.pump();
    expect(tester.getTopLeft(tap).dx, greaterThan(start.dx));
    expect(tester.widget<TapCard>(tap).holdCompletion, isFalse);
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('reduced motion keeps the completed title static', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: CompletionText(
              text: '설거지 완료',
              style: TextStyle(fontSize: 17),
              trigger: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('설거지 완료'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CompletionText),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });
}
