import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/components.dart';
import 'package:tap2work/ui/water_search.dart';
import 'calendar_test.dart' show calendarData;
import 'checklist_test.dart' show fixture;
import 'manual_workspace_test.dart' show directoryData;
import 'operations_test.dart' show response;
import 'work_controller_test.dart' show MemoryStore;

const capture = bool.fromEnvironment('CAPTURE_MOBILE_SPACE');
const captureDirectory = String.fromEnvironment(
  'CAPTURE_DIRECTORY',
  defaultValue: '../.local/mobile-space-20261022/captures',
);

void main() {
  setUpAll(() async {
    if (!capture) return;
    for (final font in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final width in [320.0, 390.0, 1200.0, 1600.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'scroll frees content space and navigation survives at $width/$scale',
        (t) async {
          t.view.physicalSize = Size(width, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final workData = fixture();
          final data = {...workData, ...calendarData(), ...directoryData()};
          data['day'] = '2026-09-28';
          data['tasks'] = [
            for (var i = 0; i < 16; i++)
              {
                ...(workData['tasks'] as List).first as Json,
                'id': 'work-$i',
                'title': '오픈 준비 $i',
              },
          ];
          data['staffShifts'] = [
            {
              'id': 'shift',
              'tapperId': 'cook',
              'partId': 'kitchen',
              'scheduleDate': data['day'],
              'date': data['day'],
              'dayOffset': 0,
              'start': '09:00',
              'end': '14:00',
            },
          ];
          data['ownerWorkflow'] = {'pending': []};
          (data['checklistFolders'] as List).addAll(<Map<String, String>>[
            for (var i = 0; i < 15; i++) {'id': 'extra-$i', 'name': '추가 폴더 $i'},
          ]);
          var writes = 0;
          final ops = OperationsController(
            readOnly: true,
            client: MockClient((r) async {
              if (r.method == 'POST') writes++;
              return response(data);
            }),
          );
          final work = WorkController(MemoryStore());
          addTearDown(ops.dispose);
          addTearDown(work.dispose);
          await ops.refresh();
          final boundary = GlobalKey();
          await t.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: Tap2workApp(controller: work, operations: ops),
            ),
          );
          await t.pumpAndSettle();
          Future<void> shot(String name) async {
            expect(t.takeException(), isNull, reason: name);
            if (!capture) return;
            await t.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final out = Directory(captureDirectory)
                ..createSync(recursive: true);
              File(
                '${out.path}/$name-${width.toInt()}-$scale.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          final top = find.byKey(const ValueKey('workspace-top-header'));
          final originalHeight = t.getSize(top).height;
          expect(originalHeight, greaterThan(120));
          final contentWidth = (width - 48).clamp(0.0, 1240.0);
          void expectContentBounds(Finder finder) {
            final bounds = t.getRect(finder);
            expect(bounds.width, closeTo(contentWidth, .01));
            expect(bounds.left, closeTo((width - contentWidth) / 2, .01));
          }

          expectContentBounds(find.byType(WaterSearch));
          expectContentBounds(find.byKey(const ValueKey('work-view-toolbar')));
          final brand = t.getRect(find.byType(BrandHeader));
          expect(brand.width, closeTo(contentWidth + 48, .01));
          expect(brand.left, closeTo((width - contentWidth - 48) / 2, .01));
          await shot('work');
          await t.drag(find.byKey(const ValueKey(0)), const Offset(0, -330));
          await t.pumpAndSettle();
          expect(t.getSize(top).height, 0);
          expect(
            find.byKey(const ValueKey('floating-menu-1')).hitTestable(),
            findsOneWidget,
          );
          await shot('work-collapsed');
          await t.tap(find.byKey(const ValueKey('floating-menu-0')));
          await t.pumpAndSettle();
          expect(t.getSize(top).height, originalHeight);
          await t.drag(find.byKey(const ValueKey(0)), const Offset(0, -150));
          await t.pumpAndSettle();
          expect(t.getSize(top).height, 0);
          await t.drag(find.byKey(const ValueKey(0)), const Offset(0, 90));
          await t.pumpAndSettle();
          expect(t.getSize(top).height, originalHeight);
          await t.tap(find.byKey(const ValueKey('floating-menu-1')));
          await t.pumpAndSettle();
          await shot('manual');
          expect(find.byType(WaterSearch), findsOneWidget);
          expectContentBounds(find.byKey(const ValueKey('manual-controls')));
          expect(find.byKey(const ValueKey('manual-results')), findsNothing);
          await t.drag(
            find.byKey(const ValueKey('manual-directory')),
            const Offset(0, -320),
          );
          await t.pumpAndSettle();
          expect(t.getSize(top).height, 0);
          expect(
            t.getSize(find.byKey(const ValueKey('manual-controls'))).height,
            0,
          );
          await shot('manual-collapsed');
          await t.drag(
            find.byKey(const ValueKey('manual-directory')),
            const Offset(0, 90),
          );
          await t.pumpAndSettle();
          await t.tap(find.byKey(const ValueKey('manual-folder-picker')));
          await t.pumpAndSettle();
          await shot('folders');
          await t.tap(find.byKey(const ValueKey('manual-folder-choice-close')));
          await t.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('manual-node-group:general')),
            findsNothing,
          );
          await t.tap(find.byKey(const ValueKey('manual-node-tap:b')));
          await t.pumpAndSettle();
          await shot('folder-content');
          await t.ensureVisible(
            find.byKey(const ValueKey('manual-detail-task:s3:b')),
          );
          await t.pumpAndSettle();
          await t.tap(find.byKey(const ValueKey('manual-detail-task:s3:b')));
          await t.pumpAndSettle();
          expect(find.text('청소 상세 매뉴얼'), findsOneWidget);
          await shot('manual-editor');
          // Read only preview editor: close without submitting any change.
          await t.tap(find.byTooltip('닫기').last);
          await t.pumpAndSettle();
          await t.tap(find.byKey(const ValueKey('floating-menu-2')));
          await t.pumpAndSettle();
          final controls = find.byKey(const ValueKey('schedule-header'));
          expect(t.getSize(top).height, 72);
          expect(find.byType(WaterSearch), findsNothing);
          expectContentBounds(controls);
          await shot('week');
          await t.drag(
            find.byKey(const ValueKey('schedule-scroll')),
            const Offset(0, -360),
          );
          await t.pumpAndSettle();
          expect(t.getSize(top).height, 0);
          expect(t.getSize(controls).height, 0);
          expect(
            find
                .byKey(const ValueKey('roster-part-heading-kitchen'))
                .hitTestable(),
            findsOneWidget,
          );
          await shot('week-collapsed');
          await t.drag(
            find.byKey(const ValueKey('schedule-scroll')),
            const Offset(0, 100),
          );
          await t.pumpAndSettle();
          expect(t.getSize(top).height, 72);
          await t.tap(find.widgetWithText(TextButton, '월간'));
          await t.pumpAndSettle();
          await shot('month');
          expectContentBounds(controls);
          await t.tap(find.byKey(const ValueKey('floating-menu-3')));
          await t.pumpAndSettle();
          expectContentBounds(
            find.byKey(const ValueKey('workspace-content-3')),
          );
          expect(find.byType(WaterSearch), findsNothing);
          await shot('store');
          await t.tap(find.byKey(const ValueKey('floating-menu-0')));
          await t.pumpAndSettle();
          expectContentBounds(find.byType(WaterSearch));
          expect(writes, 0);
        },
      );
    }
  }
}
