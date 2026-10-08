import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/manual_work_screen.dart';
import 'operations_test.dart' show sample, response;

void main() {
  for (final width in [320.0, 1200.0]) {
    testWidgets('manual work diagnosis and batch creation at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = sample();
      data['taskTemplates'] = [
        {
          'id': 'batch',
          'title': '국물 배치',
          'knowledge': {'scope': 'process'},
          'settings': {
            'usage': 'event',
            'eventKind': 'batch',
            'operatingStandard': '제품별 매장 기준',
          },
          'workStatus': {'code': 'event', 'label': '작업할 때 생성'},
        },
        {
          'id': 'ref',
          'title': '조리 참고',
          'workStatus': {'code': 'reference', 'label': '필요할 때 보는 매뉴얼이에요'},
        },
      ];
      Map<String, dynamic>? sent;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') sent = jsonDecode(request.body);
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(MaterialApp(home: ManualWorkScreen(ops: ops)));
      await tester.pumpAndSettle();
      expect(find.text('필요할 때 보는 매뉴얼이에요'), findsOneWidget);
      await tester.tap(find.text('작업 시작'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('체크리스트 만들기'));
      await tester.pumpAndSettle();
      expect(find.text('제품·배치 이름을 입력해 주세요.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '오전 육수 1차');
      await tester.tap(find.text('체크리스트 만들기'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'start_manual_work');
      expect(sent?['subject'], '오전 육수 1차');
      expect(sent?['requestId'], startsWith('work-'));
      expect(tester.takeException(), isNull);
    });
  }
}
