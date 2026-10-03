import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/workplace_screens.dart';
import 'operations_test.dart' show sample, response;

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('workplace sheets at $width with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = sample();
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      for (final section in [
        'hours',
        'parts',
        'permissions',
        'person',
        'invite',
        'verification',
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1100),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: WorkplaceSettings(
                key: ValueKey(section),
                ops: ops,
                section: section,
                person: const {'id': 'test', 'nickname': '테스트 직원'},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: section);
        if (section == 'hours') {
          await tester.tap(find.text('시간설정'));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('3교대'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(find.text('3교대'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('3교대'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('인원 배치').first);
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('오픈'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(find.text('오픈').last);
          await tester.pumpAndSettle();
          expect(find.text('오픈'), findsWidgets);
          await tester.scrollUntilVisible(
            find.text('미들'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text('미들'), findsWidgets);
          await tester.scrollUntilVisible(
            find.text('마감'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text('마감'), findsWidgets);
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('hours retains opening revision and draft after conflict', (
    tester,
  ) async {
    final data = sample();
    data['revision'] = 12;
    Json? written;
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          written = jsonDecode(request.body) as Json;
          return response({'error': '다른 동료가 먼저 업데이트했어요.'}, 409);
        }
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: WorkplaceSettings(ops: ops, section: 'hours'),
      ),
    );
    await tester.tap(find.text('시간설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('2교대'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('2교대'));
    await tester.pumpAndSettle();
    ops.data!['revision'] = 13;
    await tester.tap(find.text('인원 배치').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('일주일 설정 저장'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('일주일 설정 저장'));
    await tester.pumpAndSettle();
    expect(written?['revision'], 12);
    expect(written?['action'], 'save_workplace_hours');
    expect((written?['days']['1'] as List).length, 2);
    expect(find.textContaining('입력한 내용은 그대로'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('오픈'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('오픈'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
