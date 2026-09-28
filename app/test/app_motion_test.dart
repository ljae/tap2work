import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/ui/components.dart';

void main() {
  testWidgets(
    'global buttons react once to pointer and keyboard; disabled stays still',
    (tester) async {
      var taps = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AppMotionScope(child: child!),
          home: Scaffold(
            body: Column(
              children: [
                PressBounce(
                  child: FilledButton(
                    focusNode: focus,
                    onPressed: () => taps++,
                    child: const Text('저장'),
                  ),
                ),
                const TextButton(onPressed: null, child: Text('잠김')),
              ],
            ),
          ),
        ),
      );
      final button = find.widgetWithText(FilledButton, '저장');
      final scale = find.descendant(
        of: button,
        matching: find.byType(AnimatedScale),
      );
      expect(scale, findsOneWidget); // no nested bounce
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.widget<AnimatedScale>(scale).scale, .95);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(taps, 0);
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.widget<AnimatedScale>(scale).scale, .95);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(taps, 1);
      await tester.tap(find.text('잠김'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.widget<AnimatedScale>(scale).scale, 1);
    },
  );

  testWidgets(
    'rapid content changes keep only current actions and do not replay on refresh',
    (tester) async {
      var selected = 0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) {
              update = set;
              return AppContentTransition(
                trigger: selected,
                child: Text('화면 $selected'),
              );
            },
          ),
        ),
      );
      update(() => selected = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final fade = find.descendant(
        of: find.byType(AppContentTransition),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(fade).opacity, inExclusiveRange(.3, 1));
      update(() => selected = 2);
      await tester.pump();
      expect(find.text('화면 1'), findsNothing);
      expect(find.text('화면 2'), findsOneWidget);
      await tester.pumpAndSettle();
      update(() {});
      await tester.pump();
      expect(tester.widget<Opacity>(fade).opacity, 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion stops an active transition and all loading loops',
    (tester) async {
      var reduce = false;
      var selected = 0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) {
              update = set;
              return MediaQuery(
                data: MediaQueryData(disableAnimations: reduce),
                child: Column(
                  children: [
                    AppContentTransition(
                      trigger: selected,
                      child: Text('화면 $selected'),
                    ),
                    const AppLinearProgress(),
                    const AppCircularProgress(),
                  ],
                ),
              );
            },
          ),
        ),
      );
      update(() => selected = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      update(() => reduce = true);
      await tester.pumpAndSettle();
      final fade = find.descendant(
        of: find.byType(AppContentTransition),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(fade).opacity, 1);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        isNotNull,
      );
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        isNotNull,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'progress animates confirmed changes and reduced dialog closes immediately',
    (tester) async {
      var value = .2;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) {
              update = set;
              return Scaffold(body: AppLinearProgress(value: value));
            },
          ),
        ),
      );
      update(() => value = .8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, inExclusiveRange(.2, .8));
      expect(indicator.semanticsValue, '80');
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('확인'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('닫기'),
                      ),
                    ],
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pump();
      expect(find.text('확인'), findsOneWidget);
      await tester.tap(find.text('닫기'));
      await tester.pump();
      expect(find.text('확인'), findsNothing);
    },
  );
}
