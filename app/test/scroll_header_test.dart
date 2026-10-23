import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/ui/scroll_header.dart';

void main() {
  for (final bouncing in [false, true]) {
    testWidgets('viewport growth does not reopen header; bouncing=$bouncing', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 700);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppScrollHeaderScope(
              resetKey: 0,
              child: Column(
                children: [
                  const AppScrollHeader(
                    key: ValueKey('header'),
                    child: SizedBox(height: 260),
                  ),
                  Expanded(
                    child: ListView(
                      physics: bouncing
                          ? const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            )
                          : const ClampingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                      children: const [SizedBox(height: 580)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final list = find.byType(ListView);
      final header = find.byKey(const ValueKey('header'));
      final gesture = await t.startGesture(t.getCenter(list));
      await gesture.moveBy(const Offset(0, -80));
      await t.pump();
      var previous = t.getSize(header).height;
      for (var frame = 0; frame < 30; frame++) {
        await t.pump(const Duration(milliseconds: 16));
        final height = t.getSize(header).height;
        expect(height, lessThanOrEqualTo(previous + .01));
        previous = height;
      }
      await gesture.up();
      await t.pumpAndSettle();
      expect(t.getSize(header).height, 0);
      // The expanded viewport now fits the list. An upward pull still restores it.
      await t.drag(list, const Offset(0, 90));
      await t.pumpAndSettle();
      expect(t.getSize(header).height, 260);
      await t.fling(list, const Offset(0, -300), 1500);
      await t.pumpAndSettle();
      expect(t.getSize(header).height, 0);
      expect(t.takeException(), isNull);
    });
  }
  for (final reduced in [false, true]) {
    testWidgets(
      'header follows vertical gestures and ignores other movement; reduced=$reduced',
      (t) async {
        final vertical = ScrollController(), horizontal = ScrollController();
        addTearDown(vertical.dispose);
        addTearDown(horizontal.dispose);
        final scope = ValueNotifier(0);
        addTearDown(scope.dispose);
        await t.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(
                body: ValueListenableBuilder<int>(
                  valueListenable: scope,
                  builder: (_, value, _) => AppScrollHeaderScope(
                    resetKey: value,
                    child: Column(
                      children: [
                        const AppScrollHeader(
                          key: ValueKey('header'),
                          child: SizedBox(height: 120, child: Text('검색·메뉴')),
                        ),
                        SizedBox(
                          height: 60,
                          child: ListView(
                            controller: horizontal,
                            scrollDirection: Axis.horizontal,
                            children: const [SizedBox(width: 3000)],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: vertical,
                            children: const [SizedBox(height: 3000)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final header = find.byKey(const ValueKey('header'));
        final list = find.byWidgetPredicate(
          (w) => w is ListView && w.controller == vertical,
        );
        vertical.jumpTo(100);
        await t.pumpAndSettle();
        expect(t.getSize(header).height, 120);
        await t.drag(
          find.byWidgetPredicate(
            (w) => w is ListView && w.controller == horizontal,
          ),
          const Offset(-200, 0),
        );
        await t.pumpAndSettle();
        expect(t.getSize(header).height, 120);
        await t.drag(list, const Offset(0, -180));
        await t.pumpAndSettle();
        expect(t.getSize(header).height, 0);
        expect(find.text('검색·메뉴').hitTestable(), findsNothing);
        await t.drag(list, const Offset(0, 90));
        await t.pumpAndSettle();
        expect(t.getSize(header).height, 120);
        await t.drag(list, const Offset(0, -180));
        await t.pumpAndSettle();
        scope.value++;
        await t.pumpAndSettle();
        expect(t.getSize(header).height, 120);
        await t.sendEventToBinding(
          PointerScrollEvent(
            position: t.getCenter(list),
            scrollDelta: const Offset(0, 160),
          ),
        );
        await t.pumpAndSettle();
        expect(t.getSize(header).height, 0);
        await t.sendEventToBinding(
          PointerScrollEvent(
            position: t.getCenter(list),
            scrollDelta: const Offset(0, -80),
          ),
        );
        await t.pumpAndSettle();
        expect(t.getSize(header).height, 120);
        expect(t.takeException(), isNull);
      },
    );
  }
  for (final keyboard in [false, true]) {
    testWidgets(
      'navigation stays visible for ${keyboard ? 'keyboard' : 'assistive navigation'}',
      (t) async {
        await t.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                accessibleNavigation: !keyboard,
                viewInsets: EdgeInsets.only(bottom: keyboard ? 250 : 0),
              ),
              child: AppScrollHeaderScope(
                resetKey: 0,
                child: Scaffold(
                  body: Column(
                    children: [
                      const AppScrollHeader(
                        key: ValueKey('header'),
                        child: SizedBox(height: 120),
                      ),
                      Expanded(
                        child: ListView(
                          children: const [SizedBox(height: 3000)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await t.drag(find.byType(ListView), const Offset(0, -200));
        await t.pumpAndSettle();
        expect(t.getSize(find.byKey(const ValueKey('header'))).height, 120);
        expect(t.takeException(), isNull);
      },
    );
  }
}
