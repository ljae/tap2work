import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:image/image.dart' as image;
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/tap_card.dart';
import 'package:tap2work/ui/tap_workspace.dart';
import '../test/checklist_test.dart' show fixture;
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

// Widget-render captures with fictional dish content and a generated diagram.
// This harness never loads real store photos or writes production content.
void main() {
  testWidgets('render actual Task entry and integrated action slides', (
    tester,
  ) async {
    for (final font in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final output = Directory('../.local/manual-navigation-implementation')
      ..createSync(recursive: true);
    final diagram = image.Image(width: 640, height: 300);
    image.fill(diagram, color: image.ColorRgb8(24, 26, 28));
    image.fillRect(
      diagram,
      x1: 24,
      y1: 36,
      x2: 270,
      y2: 264,
      color: image.ColorRgb8(44, 69, 61),
      radius: 16,
    );
    image.fillRect(
      diagram,
      x1: 318,
      y1: 36,
      x2: 608,
      y2: 264,
      color: image.ColorRgb8(53, 61, 69),
      radius: 16,
    );
    for (final x in [385, 465, 545]) {
      image.fillCircle(
        diagram,
        x: x,
        y: 105,
        radius: 25,
        color: image.ColorRgb8(230, 235, 237),
      );
      image.fillCircle(
        diagram,
        x: x,
        y: 195,
        radius: 25,
        color: image.ColorRgb8(160, 171, 175),
      );
    }
    final diagramUrl =
        'data:image/png;base64,${base64Encode(image.encodePng(diagram))}';
    for (final scene in [
      (320.0, 1.0),
      (390.0, 1.0),
      (1200.0, 1.0),
      (390.0, 1.5),
    ]) {
      tester.view.physicalSize = Size(scene.$1, 900);
      tester.platformDispatcher.textScaleFactorTestValue = scene.$2;
      final data = fixture();
      final task = (data['tasks'] as List).first as Json;
      task['title'] = '식기 정리 · 가상 예시';
      task['steps'] = [
        {
          'id': 'dish-1',
          'title': '잔반을 먼저 비워요',
          'manual':
              '가상 예시예요. 접시와 그릇의 잔반은 매장에서 지정한 배출처에 먼저 비워요.\n음식물과 이물질이 배수구로 들어가지 않도록 확인해요.',
          'tip': '실제 배출처와 분류 기준은 우리 매장의 안내를 확인해요.',
          'imageUrl': diagramUrl,
        },
        {
          'id': 'dish-2',
          'title': '식기 종류별로 나눠요',
          'manual':
              '접시·그릇·컵·수저를 지정된 반납 위치에 나눠 놓아요. 날카로운 도구와 깨진 식기는 별도 기준을 따라요.',
          'tip': '쌓는 높이와 분류 위치는 매장 기준을 확인해요.',
        },
        {
          'id': 'dish-3',
          'title': '거름망과 배수를 확인해요',
          'manual':
              '세척용 싱크대의 거름망에 쌓인 잔여물을 지정된 배출처에 비워요. 물이 정상적으로 빠지는지 확인하고 막힘은 담당자에게 알려요.',
          'tip': '막힘을 힘으로 밀어 넣거나 임의로 배관을 분해하지 않아요.',
        },
        {
          'id': 'dish-4',
          'title': '깨끗한 식기를 종류별로 말려요',
          'manual': '세척을 마친 식기를 종류별 지정 건조 위치에 놓아요. 물이 빠지고 오염 없이 건조되는지 확인해요.',
          'tip': '실제 건조대와 보관 위치는 매장 안내를 따라요.',
        },
      ];
      var writes = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((request) async {
          if (request.method == 'POST') writes++;
          return response(data);
        }),
      );
      final work = WorkController(MemoryStore());
      await ops.refresh();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Tap2workApp(
            controller: work,
            homeOverride: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: TapWorkspace(ops: ops, onStock: (_) async {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String state) async {
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final rendered = await boundary.toImage();
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          File(
            '${output.path}/$state-${scene.$1.toInt()}-text${scene.$2}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
      }

      await capture('board');
      tester
          .widget<TapCard>(find.byKey(const ValueKey('tap-daily-prep')))
          .onOpen();
      await tester.pumpAndSettle();
      tester
          .widget<TapCard>(find.byKey(const ValueKey('small-dish-1')))
          .onOpen();
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .any((raw) => raw.image != null),
        isTrue,
      );
      await capture('action');
      await tester.tap(find.byKey(const ValueKey('manual-action-next')));
      await tester.pumpAndSettle();
      await capture('action-text');
      expect(writes, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      ops.dispose();
      work.dispose();
    }
  });
}
