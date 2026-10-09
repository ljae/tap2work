import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tap2work/ui/components.dart';

void main() {
  testWidgets(
    'toolbar keeps 48px actions and hidden tools reachable with enlarged text',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 72,
                  child: AppToolbarScroll(
                    child: Row(
                      children: [
                        for (var i = 0; i < 8; i++)
                          AppToolbarButton(
                            icon: Icons.tune,
                            label: '설정 $i',
                            onPressed: () => calls++,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final last = find.widgetWithText(TextButton, '설정 7');
      expect(last.hitTestable(), findsNothing);
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      final size = tester.getSize(last);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(last);
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'button shrinks, restores after cancellation and fires only once',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressBounce(
                child: FilledButton(
                  onPressed: () => taps++,
                  child: const Text('저장'),
                ),
              ),
            ),
          ),
        ),
      );
      final button = find.byType(FilledButton);
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 100));
      final animation = find.descendant(
        of: find.byType(PressBounce),
        matching: find.byType(AnimatedContainer),
      );
      expect(
        tester.widget<AnimatedContainer>(animation).transform!.entry(0, 0),
        .95,
      );
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(taps, 0);
      expect(
        tester.widget<AnimatedContainer>(animation).transform!.entry(0, 0),
        1,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(taps, 1);
    },
  );

  testWidgets('reduced motion disables bounce and shimmer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Column(
              children: [
                PressBounce(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('저장'),
                  ),
                ),
                const Expanded(child: WorkspaceSkeleton()),
              ],
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    final animation = find.descendant(
      of: find.byType(PressBounce),
      matching: find.byType(AnimatedContainer),
    );
    expect(
      tester.widget<AnimatedContainer>(animation).transform!.entry(0, 0),
      1,
    );
    expect(
      tester.widgetList<Shimmer>(find.byType(Shimmer)).every((s) => !s.enabled),
      isTrue,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'form sheet keeps draft on barrier tap and consults PopScope on close',
    (tester) async {
      var attempted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppSheet<void>(
                  context,
                  builder: (sheetContext) => PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, _) {
                      attempted = !didPop;
                    },
                    child: Scaffold(
                      appBar: AppBar(
                        leading: CloseButton(
                          onPressed: () => Navigator.maybePop(sheetContext),
                        ),
                      ),
                      body: const Text('저장 전 초안'),
                    ),
                  ),
                ),
                child: const Text('설정'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      expect(find.text('저장 전 초안'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('저장 전 초안'), findsOneWidget);
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(attempted, isTrue);
      expect(find.text('저장 전 초안'), findsOneWidget);
    },
  );
}
