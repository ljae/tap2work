import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/ui/direct_edit.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'calendar_test.dart' as calendar;

void main() {
  testWidgets(
    'long press reveals actions, wiggles, stops on permission loss and reduced motion',
    (tester) async {
      var enabled = true, active = false, reduced = false;
      late StateSetter update;
      var renamed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) {
              update = set;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduced),
                child: Scaffold(
                  body: DirectEditFrame(
                    enabled: enabled,
                    active: active,
                    onEnter: () => set(() => active = true),
                    onRename: () => renamed++,
                    onDelete: () {},
                    child: const Text('대상 카드'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      expect(find.byTooltip('삭제'), findsNothing);
      await tester.longPress(find.text('대상 카드'));
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.byTooltip('삭제'), findsOneWidget);
      final before = tester
          .widget<Transform>(find.byType(Transform).first)
          .transform
          .clone();
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        tester.widget<Transform>(find.byType(Transform).first).transform,
        before == Matrix4.identity()
            ? isNot(Matrix4.identity())
            : isNot(before),
      );
      await tester.tap(find.byTooltip('이름 변경'));
      expect(renamed, 1);
      update(() => reduced = true);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Transform>(find.byType(Transform).first).transform,
        Matrix4.identity(),
      );
      update(() => enabled = false);
      await tester.pumpAndSettle();
      expect(find.byTooltip('삭제'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'schedule long press exposes trash, date-scoped delete and permission denial',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      Json? sent;
      final initial = calendar.calendarData();
      initial['staffShifts'] = [
        {
          'id': 'assigned',
          'tapperId': 'cook',
          'partId': 'kitchen',
          'date': '2026-09-28',
          'start': '09:00',
          'end': '14:00',
        },
      ];
      await calendar.mount(
        tester,
        data: initial,
        readOnly: false,
        write: (v) => sent = v,
      );
      final slot = find.byKey(
        const ValueKey('roster-2026-09-28-kitchen-assigned'),
      );
      await tester.ensureVisible(slot);
      await tester.longPress(slot);
      await tester.pumpAndSettle();
      expect(find.byTooltip('삭제'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('삭제'));
      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '삭제'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'delete_staff_shift');
      expect(sent?['date'], '2026-09-28');
      expect(sent?['revision'], 12);
      expect(tester.takeException(), isNull);
      final data = initial..['canEditSchedule'] = false;
      await calendar.mount(tester, readOnly: false, data: data);
      await tester.longPress(slot);
      await tester.pumpAndSettle();
      expect(find.byTooltip('삭제'), findsNothing);
    },
  );
  testWidgets(
    'schedule drag saves the original assignment at the target time',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final data = calendar.calendarData();
      data['staffShifts'] = [
        {
          'id': 'move-shift',
          'tapperId': 'cook',
          'partId': 'kitchen',
          'date': '2026-09-28',
          'start': '09:00',
          'end': '10:00',
          'status': 'planned',
        },
      ];
      Json? sent;
      await calendar.mount(
        tester,
        readOnly: false,
        data: data,
        write: (v) => sent = v,
        width: 1200,
      );
      final source = find.byKey(
        const ValueKey('roster-2026-09-28-kitchen-move-shift'),
      );
      await tester.longPress(source);
      await tester.pumpAndSettle();
      final target = find.byKey(
        const ValueKey('roster-drop-2026-09-28-kitchen-660'),
      );
      final start = tester.getCenter(source), end = tester.getCenter(target);
      await tester.dragFrom(start, end - start);
      await tester.pumpAndSettle();
      expect(sent, isNull);
      await tester.tap(find.text('오늘'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'save_staff_shift');
      expect(sent?['id'], 'move-shift');
      expect(sent?['start'], '11:00');
      expect(sent?['end'], '12:00');
      expect(sent?['revision'], 12);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'name field survives dialog exit motion and disposes with its route',
    (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await directEditName(context, '원래 이름');
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '수정 이름');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
      expect(result, '수정 이름');
      expect(tester.takeException(), isNull);
    },
  );
}
