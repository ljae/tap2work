import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/payroll_settings_screen.dart';
import 'operations_test.dart' show sample, response;

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'settlement settings remain readable at $width with large text',
      (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final ops = OperationsController(
          readOnly: true,
          client: MockClient((_) async => response(sample())),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1200),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: PayrollSettingsScreen(ops: ops),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('지급 주기'), findsOneWidget);
        await tester.tap(find.widgetWithText(ChoiceChip, '주급'));
        await tester.pumpAndSettle();
        expect(find.text('매주 월요일부터 7일간이에요.'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('정산 설정 저장'),
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, '정산 설정 저장'),
              )
              .onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('conflict keeps original revision and unsaved settlement draft', (
    tester,
  ) async {
    final data = sample()..['revision'] = 17;
    Json? sent;
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') {
          sent = jsonDecode(r.body);
          return response({'error': '다른 변경이 있어요.'}, 409);
        }
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await tester.pumpWidget(MaterialApp(home: PayrollSettingsScreen(ops: ops)));
    await tester.pumpAndSettle();
    ops.data!['revision'] = 18;
    await tester.scrollUntilVisible(
      find.text('5인 이상'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('5인 이상'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5인 이상'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('정산 설정 저장'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('정산 설정 저장'));
    await tester.pumpAndSettle();
    expect(sent!['revision'], 17);
    expect(sent!['settings']['businessSize'], 'fivePlus');
    expect(find.byType(PayrollSettingsScreen), findsOneWidget);
    expect(find.textContaining('입력한 내용은 유지'), findsOneWidget);
  });
}
