import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/work_controller.dart';
import 'work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'worker must acknowledge real practice; buddy action is separate',
    (tester) async {
      final work = WorkController(MemoryStore());
      await tester.pumpWidget(Tap2workApp(controller: work));
      await tester.ensureVisible(find.byKey(const Key('next-task')));
      await tester.tap(find.byKey(const Key('next-task')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('save-lesson')))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byKey(const Key('practice-check')));
      await tester.tap(find.byKey(const Key('practice-check')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('save-lesson')));
      await tester.tap(find.byKey(const Key('save-lesson')));
      await tester.pumpAndSettle();
      expect(work.practiced, {'welcome'});
      expect(work.approved, isEmpty);
      work.switchRole(DemoRole.buddy);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('approve-welcome')));
      await tester.tap(find.byKey(const Key('approve-welcome')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('practice-check')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('save-lesson')));
      await tester.tap(find.byKey(const Key('save-lesson')));
      await tester.pumpAndSettle();
      expect(work.approved, {'welcome'});
    },
  );

  for (final width in [320.0, 390.0, 430.0]) {
    testWidgets('all worker tabs fit a $width pixel phone', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        Tap2workApp(controller: WorkController(MemoryStore())),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final index in [1, 2, 3, 0]) {
        await tester.tap(find.byKey(ValueKey('floating-menu-$index')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$width / $index');
      }
    });
  }
}
