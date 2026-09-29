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
import 'package:tap2work/ui/tap_workspace.dart';
import 'package:tap2work/ui/tap_card.dart';
import 'package:tap2work/ui/manual_workspace.dart';
import 'package:tap2work/ui/calendar_screen.dart';
import '../test/checklist_test.dart' show fixture;
import '../test/manual_workspace_test.dart' show directoryData;
import '../test/calendar_test.dart' show calendarData;
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture direct edit surfaces', (tester) async {
    for (final entry in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final output = Directory('../.local/direct-edit-review')
      ..createSync(recursive: true);
    for (final width in [390.0, 1200.0]) {
      for (final scene in [
        'work',
        'task',
        'manual',
        'manual-content',
        'calendar',
      ]) {
        tester.view.physicalSize = Size(width, 1000);
        final data = scene.startsWith('manual')
            ? directoryData()
            : scene == 'calendar'
            ? calendarData()
            : fixture();
        if (scene.startsWith('manual')) {
          (data['taskTemplates'] as List).add({
            'id': 'empty',
            'title': '빈 TAP',
            'folderId': 'general',
            'steps': [],
          });
          (data['checklistFolders'] as List).add({
            'id': 'empty-folder',
            'name': '빈 폴더',
          });
        }
        final ops = OperationsController(
          readOnly: false,
          client: MockClient((_) async => response(data)),
        );
        final work = WorkController(MemoryStore());
        await ops.refresh();
        final key = GlobalKey();
        final content = scene.startsWith('manual')
            ? ManualWorkspace(ops: ops, query: '')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: scene == 'calendar'
                    ? CalendarScreen(operations: ops)
                    : TapWorkspace(ops: ops, onStock: (_) async {}),
              );
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: Tap2workApp(
              controller: work,
              homeOverride: Scaffold(
                body: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(disableAnimations: true),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (scene == 'task') {
          tester
              .widget<TapCard>(find.byKey(const ValueKey('tap-daily-prep')))
              .onOpen();
          await tester.pumpAndSettle();
        }
        if (scene.startsWith('manual')) {
          await tester.tap(find.byKey(const ValueKey('manual-node-tap:a')));
          await tester.pumpAndSettle();
          if (scene == 'manual-content' && width < 760) {
            await tester.tap(find.text('매뉴얼 2'));
            await tester.pumpAndSettle();
          }
        }
        final target = scene == 'work'
            ? find.byKey(const ValueKey('tap-daily-prep'))
            : scene == 'task'
            ? find.text('도구 나누기')
            : scene == 'manual-content'
            ? find.descendant(
                of: find.byKey(const ValueKey('manual-results')),
                matching: find.text('손 씻기'),
              )
            : scene.startsWith('manual')
            ? find.byKey(const ValueKey('manual-node-group:general'))
            : find.byKey(
                const ValueKey('roster-2026-09-28-kitchen-band-1-kitchen-0'),
              );
        await tester.longPress(target);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${output.path}/$scene-${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        ops.dispose();
        work.dispose();
      }
    }
  });
}
