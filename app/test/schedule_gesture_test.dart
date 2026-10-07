import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'calendar_test.dart' as calendar;

Json gestureData() {
  final data = calendar.calendarData();
  data['staffShifts'] = [
    for (var i = 0; i < 2; i++)
      <String, dynamic>{
        'id': 'shift-$i',
        'tapperId': i == 0 ? 'cook' : 'other',
        'partId': i == 0 ? 'kitchen' : 'hall',
        'date': '2026-09-28',
        'start': '09:00',
        'end': '14:00',
        'status': 'planned',
      },
  ];
  return data;
}

void applyWrite(Json data, Json input) {
  final row = (data['staffShifts'] as List).cast<Json>().firstWhere(
    (s) => s['id'] == input['id'],
  );
  for (final key in ['start', 'end', 'partId', 'scheduleDate', 'dayOffset']) {
    if (input.containsKey(key)) row[key] = input[key];
  }
  data['revision']++;
}

void main() {
  testWidgets(
    'only selected block edits locally and outside card tap saves once',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final data = gestureData();
      final writes = <Json>[];
      await calendar.mount(
        tester,
        data: data,
        readOnly: false,
        width: 1200,
        write: (input) {
          writes.add(input);
          applyWrite(data, input);
        },
      );
      final source = find.byKey(
        const ValueKey('roster-2026-09-28-kitchen-shift-0'),
      );
      final other = find.byKey(
        const ValueKey('roster-2026-09-28-hall-shift-1'),
      );
      await tester.longPress(source);
      await tester.pumpAndSettle();
      expect(find.byType(Draggable<Json>), findsOneWidget);
      expect(
        find.byKey(const ValueKey('resize-shift-1-2026-09-28')),
        findsNothing,
      );
      for (var i = 0; i < 2; i++) {
        final handle = find.byKey(const ValueKey('resize-shift-0-2026-09-28'));
        await tester.drag(handle, const Offset(0, 48));
        await tester.pumpAndSettle();
        expect(writes, isEmpty);
      }
      expect(find.text('09:00–16:00'), findsOneWidget);
      expect(find.text('09:00–14:00'), findsOneWidget);
      await tester.tap(other);
      await tester.pumpAndSettle();
      expect(writes, hasLength(1));
      expect(writes.single['id'], 'shift-0');
      expect(writes.single['end'], '16:00');
      expect(writes.single['revision'], 12);
      expect(find.byType(Draggable<Json>), findsNothing);
      expect(find.text('담당 크루'), findsNothing);
      await tester.longPress(other);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('오늘'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('오늘'));
      await tester.pumpAndSettle();
      expect(
        writes,
        hasLength(1),
        reason: 'unchanged selection makes no request',
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'continuous resize past closing retains gesture and prior crew adjustment at $width',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final data = gestureData();
        final writes = <Json>[];
        final ops = await calendar.mount(
          tester,
          data: data,
          readOnly: false,
          width: width,
          write: (input) {
            writes.add(input);
            applyWrite(data, input);
          },
        );
        await tester.longPress(
          find.byKey(const ValueKey('roster-2026-09-28-kitchen-shift-0')),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 2; i++) {
          if (i > 0) {
            await tester.longPress(
              find.byKey(const ValueKey('roster-2026-09-28-hall-shift-1')),
            );
            await tester.pumpAndSettle();
          }
          expect(find.byType(Draggable<Json>), findsOneWidget);
          final handle = find.byKey(ValueKey('resize-shift-$i-2026-09-28'));
          await tester.ensureVisible(handle);
          await tester.pumpAndSettle();
          final element = tester.element(handle);
          final gesture = await tester.startGesture(tester.getCenter(handle));
          for (var step = 0; step < 6; step++) {
            await gesture.moveBy(const Offset(0, 24));
            await tester.pump();
            expect(
              tester.element(handle),
              same(element),
              reason: 'time cells must not replace the active card',
            );
          }
          await gesture.up();
          await tester.pumpAndSettle();
          expect(writes.length, i);
          await tester.ensureVisible(find.text('오늘'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('오늘'));
          await tester.pumpAndSettle();
          expect(writes.last['end'], '17:00');
          expect(ops.error, isNull);
        }
        await ops.refresh();
        await tester.pumpAndSettle();
        expect(
          ops.rows('staffShifts').map((s) => s['end']),
          everyElement('17:00'),
        );
        expect(writes.length, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final resize in [true, false]) {
    for (final fails in [true, false]) {
      testWidgets(
        'pending ${resize ? 'resize' : 'move'} keeps adjusted time until ${fails ? 'failure' : 'success'}',
        (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
          final data = gestureData();
          final gate = Completer<void>();
          final ops = await calendar.mount(
            tester,
            data: data,
            width: 1200,
            readOnly: false,
            beforeWrite: (_) => gate.future,
            write: (v) => applyWrite(data, v),
          );
          final source = find.byKey(
            const ValueKey('roster-2026-09-28-kitchen-shift-0'),
          );
          await tester.longPress(source);
          await tester.pumpAndSettle();
          final timeline = find.byKey(const ValueKey('roster-timeline'));
          final timelineElement = tester.element(timeline);
          if (resize) {
            final handle = find.byKey(
              const ValueKey('resize-shift-0-2026-09-28'),
            );
            final gesture = await tester.startGesture(tester.getCenter(handle));
            for (var i = 0; i < 6; i++) {
              await gesture.moveBy(const Offset(0, 24));
              await tester.pump();
            }
            await gesture.up();
          } else {
            final rect = tester.getRect(source);
            final gesture = await tester.startGesture(
              Offset(rect.center.dx, rect.top + 35),
            );
            await gesture.moveTo(
              tester.getCenter(
                find.byKey(
                  const ValueKey('roster-drop-2026-09-28-kitchen-930'),
                ),
              ),
            );
            await tester.pump();
            await gesture.up();
          }
          await tester.pumpAndSettle();
          expect(ops.busy, isFalse);
          await tester.ensureVisible(find.text('오늘'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('오늘'));
          await tester.pumpAndSettle();
          expect(ops.busy, isTrue);
          expect(tester.element(timeline), same(timelineElement));
          final edited = resize ? '09:00–17:00' : '15:30–20:30';
          expect(find.text(edited), findsOneWidget);
          expect(ops.rows('staffShifts').first['end'], '14:00');
          if (fails) {
            gate.completeError(Exception('network failure'));
          } else {
            gate.complete();
          }
          await tester.pumpAndSettle();
          expect(ops.busy, isFalse);
          expect(tester.element(timeline), same(timelineElement));
          if (fails) {
            expect(find.text(edited), findsOneWidget);
            expect(find.text('다시 저장'), findsOneWidget);
            await tester.tap(find.text('변경 취소'));
            await tester.pumpAndSettle();
            expect(find.text(edited), findsNothing);
            expect(ops.error, isNotNull);
            expect(ops.rows('staffShifts').first['end'], '14:00');
          } else {
            expect(find.text(edited), findsOneWidget);
            expect(
              ops.rows('staffShifts').first['end'],
              resize ? '17:00' : '20:30',
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'moving beyond closing keeps source identity when the grid expands',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final data = gestureData();
      Json? sent;
      await calendar.mount(
        tester,
        data: data,
        readOnly: false,
        width: 1200,
        write: (v) {
          sent = v;
          applyWrite(data, v);
        },
      );
      final source = find.byKey(
        const ValueKey('roster-2026-09-28-kitchen-shift-0'),
      );
      await tester.longPress(source);
      await tester.pumpAndSettle();
      final draggable = find.ancestor(
        of: source,
        matching: find.byType(Draggable<Json>),
      );
      final element = tester.element(draggable);
      final rect = tester.getRect(source);
      final gesture = await tester.startGesture(
        Offset(rect.center.dx, rect.top + 35),
      );
      final target = find.byKey(
        const ValueKey('roster-drop-2026-09-28-kitchen-930'),
      );
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      expect(tester.element(draggable), same(element));
      expect(find.byKey(const ValueKey('roster-drop-preview')), findsOneWidget);
      await gesture.moveBy(const Offset(0, 72));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(sent, isNull);
      await tester.ensureVisible(find.text('오늘'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('오늘'));
      await tester.pumpAndSettle();
      expect(sent?['start'], '17:00');
      expect(sent?['end'], '22:00');
      expect(tester.takeException(), isNull);
    },
  );
}
