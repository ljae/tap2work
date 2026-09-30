import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tap2work/ui/work_assignment_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/components.dart';
import 'package:tap2work/ui/tap_settings_screen.dart';
import 'operations_test.dart' show response;
import 'work_controller_test.dart' show MemoryStore;
import 'support/ui_ux_audit_cases.dart';

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'band assignment draft survives close and discards without writes at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 840);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final ops = OperationsController(
          client: MockClient((r) async {
            expect(r.method, 'GET', reason: 'cancel/discard must not save');
            return response(sheetData());
          }),
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
                    builder: (_) => sheetCases(ops)['assignment-scheduled']!,
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CloseButton));
        await tester.pumpAndSettle();
        expect(find.text('변경을 버릴까요?'), findsOneWidget);
        await tester.tap(find.text('계속 수정'));
        await tester.pumpAndSettle();
        expect(find.byType(TapSettingsScreen), findsOneWidget);
        await tester.scrollUntilVisible(
          find.textContaining('오픈 09:00–14:00'),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester
              .widget<FilterChip>(
                find.ancestor(
                  of: find.textContaining('오픈 09:00–14:00'),
                  matching: find.byType(FilterChip),
                ),
              )
              .selected,
          isTrue,
        );
        await tester.tap(find.byType(CloseButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('변경 버리기'));
        await tester.pumpAndSettle();
        expect(find.byType(TapSettingsScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [320.0, 390.0, 1200.0]) {
    for (final mode in ['scheduled', 'crew']) {
      testWidgets(
        'raw assignment chip $mode at $width keeps long label readable',
        (tester) async {
          tester.view.physicalSize = Size(width, 840);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.5;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          const longName = auditLongName;
          final data = sheetData();
          for (final bands in (data['workplace']['days'] as Map).values) {
            (bands as List).first['name'] = longName;
          }
          data['tappers'] = [
            {'id': 'crew', 'nickname': longName, 'active': true},
          ];
          final ops = OperationsController(
            client: MockClient((_) async => response(data)),
          );
          final work = WorkController(MemoryStore());
          addTearDown(ops.dispose);
          addTearDown(work.dispose);
          await ops.refresh();
          await tester.pumpWidget(
            Tap2workApp(
              controller: work,
              homeOverride: AppEditorScaffold(
                title: '담당 설정',
                body: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    WorkAssignmentField(
                      ops: ops,
                      value: {
                        'mode': mode,
                        'partId': 'kitchen',
                        'timeBandIds': ['audit-open'],
                        'crewIds': ['crew'],
                      },
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final label = find.textContaining(longName);
          await tester.scrollUntilVisible(
            label,
            240,
            scrollable: find.byType(Scrollable).first,
          );
          final paragraph = tester.renderObject<RenderParagraph>(label);
          expect(paragraph.didExceedMaxLines, isFalse, reason: '$mode/$width');
          final measured = TextPainter(
            text: paragraph.text,
            textDirection: TextDirection.ltr,
            textScaler: paragraph.textScaler,
          )..layout(maxWidth: paragraph.size.width);
          expect(
            paragraph.size.height,
            greaterThanOrEqualTo(measured.height),
            reason: 'All lines must be visible',
          );
          measured.dispose();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
