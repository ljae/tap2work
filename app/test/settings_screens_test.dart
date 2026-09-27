import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/store_profile_screen.dart';
import 'package:tap2work/ui/tap_settings_screen.dart';

import 'operations_test.dart' show response, sample;

Json settingsFixture() => {
  ...sample(),
  'store': {
    'name': '테스트 매장',
    'setup': 'configured',
    'profile': {'industryId': 'restaurant'},
  },
  'taskTemplates': [
    {
      'id': 'tap-1',
      'title': '매장 준비',
      'steps': [
        {'id': 'step-1', 'title': '재료 확인'},
      ],
    },
  ],
};

Future<OperationsController> mountSettings(
  WidgetTester tester,
  Widget Function(OperationsController) screen, {
  Json? data,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final ops = OperationsController(
    client: MockClient((request) async => response(data ?? settingsFixture())),
  );
  addTearDown(ops.dispose);
  await ops.refresh();
  await tester.pumpWidget(MaterialApp(home: screen(ops)));
  await tester.pumpAndSettle();
  return ops;
}

void main() {
  testWidgets('stale TAP link opens the available template', (tester) async {
    await mountSettings(
      tester,
      (ops) =>
          TapSettingsScreen(ops: ops, initialTemplateId: 'removed-template'),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('매장 준비'), findsOneWidget);
  });

  testWidgets('optional quantity target starts empty and accepts input', (
    tester,
  ) async {
    await mountSettings(tester, (ops) => TapSettingsScreen(ops: ops));
    await tester.tap(find.byKey(const ValueKey('kind-step-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('실제 수량 입력').last);
    await tester.pumpAndSettle();
    final target = find.byKey(const ValueKey('target-step-1'));
    await tester.ensureVisible(target);
    expect(tester.widget<TextFormField>(target).initialValue, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank store requires name and industry before save', (
    tester,
  ) async {
    final blank = settingsFixture();
    blank['store'] = {'name': '새 매장', 'setup': 'blank', 'profile': {}};
    await mountSettings(
      tester,
      (ops) => StoreProfileScreen(ops: ops),
      data: blank,
    );
    await tester.ensureVisible(find.text('이 설정 저장'));
    await tester.tap(find.text('이 설정 저장'));
    await tester.pump();
    expect(find.textContaining('매장명과 업종을 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('store note is retained and submitted with basic settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = settingsFixture();
    (data['store'] as Json)['note'] = '교대 시 공유할 안내';
    Json? submitted;
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          submitted = jsonDecode(request.body) as Json;
          return response(data);
        }
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await tester.pumpWidget(MaterialApp(home: StoreProfileScreen(ops: ops)));
    await tester.pumpAndSettle();
    final note = find.widgetWithText(TextField, '팀 안내 · 선택');
    expect(tester.widget<TextField>(note).controller!.text, '교대 시 공유할 안내');
    await tester.ensureVisible(find.text('이 설정 저장'));
    await tester.tap(find.text('이 설정 저장'));
    await tester.pumpAndSettle();
    expect(submitted?['section'], 'basic');
    expect((submitted?['values'] as Json?)?['note'], '교대 시 공유할 안내');
  });
}
