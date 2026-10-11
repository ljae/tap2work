import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/components.dart';
import 'package:tap2work/ui/time_wheel.dart';
import 'work_controller_test.dart' show MemoryStore;

void main() {
  test('studio text and action colors keep readable contrast', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final background in [
      AppColors.paper,
      AppColors.surface,
      AppColors.elevated,
    ]) {
      expect(contrast(AppColors.ink, background), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.muted, background), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.green, background), greaterThanOrEqualTo(4.5));
    }
    expect(
      contrast(AppColors.paper, AppColors.green),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.accent, AppColors.accentSoft),
      greaterThanOrEqualTo(4.5),
    );
  });

  for (final size in [const Size(320, 700), const Size(844, 390)]) {
    testWidgets(
      'time draft wraps midnight, synchronizes wheels, cancels and applies at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var saved = '23:30';
        var writes = 0;
        final work = WorkController(MemoryStore());
        addTearDown(work.dispose);
        await tester.pumpWidget(
          Tap2workApp(
            controller: work,
            homeOverride: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.5),
                  disableAnimations: true,
                ),
                child: Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () async {
                        final next = await showTimeWheel(
                          context,
                          title: '영업 종료',
                          value: saved,
                        );
                        if (next != null) {
                          saved = next;
                          writes++;
                        }
                      },
                      child: const Text('열기'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        final plus = find.byKey(const ValueKey('time-plus-30'));
        await tester.ensureVisible(plus);
        await tester.pumpAndSettle();
        await tester.tap(plus);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('time-draft-preview')))
              .data,
          '00:00',
        );
        final wheels = tester
            .widgetList<CupertinoPicker>(find.byType(CupertinoPicker))
            .toList();
        expect(wheels.first.scrollController!.selectedItem, 0);
        expect(wheels.last.scrollController!.selectedItem, 0);
        expect(writes, 0);
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
        expect(saved, '23:30');
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        final minus = find.byKey(const ValueKey('time-minus-30'));
        await tester.ensureVisible(minus);
        await tester.pumpAndSettle();
        await tester.tap(minus);
        await tester.pumpAndSettle();
        await tester.tap(find.text('적용'));
        await tester.pumpAndSettle();
        expect(saved, '23:00');
        expect(writes, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'time quick controls stay visible above actions with iPhone safe areas',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
      addTearDown(tester.view.reset);
      final work = WorkController(MemoryStore());
      addTearDown(work.dispose);
      await tester.pumpWidget(
        Tap2workApp(
          controller: work,
          homeOverride: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showTimeWheel(context, title: 'Time', value: '09:30'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final plus = find.byKey(const ValueKey('time-plus-30'));
      final minus = find.byKey(const ValueKey('time-minus-30'));
      expect(plus.hitTestable(), findsOneWidget);
      expect(minus.hitTestable(), findsOneWidget);
      expect(
        tester.getBottomRight(plus).dy,
        lessThan(tester.getTopLeft(find.byType(AppSheetFooter)).dy),
      );
      await tester.tap(plus);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('time-draft-preview')))
            .data,
        '10:00',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('full-page editor title clears the native status bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: AppEditorScaffold(
          title: 'Welcome',
          body: Text('Body'),
          footer: AppSheetFooter(children: [Text('Continue')]),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Welcome')).dy,
      greaterThanOrEqualTo(59),
    );
    expect(
      tester.getBottomRight(find.text('Continue')).dy,
      lessThanOrEqualTo(810),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'navigation selection follows rapid taps and reduced motion immediately',
    (tester) async {
      var selected = 0;
      var reduce = false;
      late StateSetter change;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) {
              change = set;
              return MediaQuery(
                data: MediaQueryData(disableAnimations: reduce),
                child: Scaffold(
                  bottomNavigationBar: FloatingMenu(
                    selectedIndex: selected,
                    onSelected: (v) => set(() => selected = v),
                    items: const [
                      FloatingMenuItem('업무', Icons.check_circle_outline),
                      FloatingMenuItem('매뉴얼', Icons.book_outlined),
                      FloatingMenuItem('근무표', Icons.calendar_month),
                      FloatingMenuItem('우리매장', Icons.grid_view),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('floating-menu-3')));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byKey(const ValueKey('floating-menu-1')));
      await tester.pump(const Duration(milliseconds: 40));
      expect(selected, 1);
      change(() => reduce = true);
      await tester.pumpAndSettle();
      final indicator = tester.widget<AnimatedAlign>(
        find.byKey(const ValueKey('navigation-indicator')),
      );
      expect(indicator.duration, Duration.zero);
      expect((indicator.alignment as Alignment).x, closeTo(-1 / 3, .001));
      expect(tester.takeException(), isNull);
    },
  );
}
