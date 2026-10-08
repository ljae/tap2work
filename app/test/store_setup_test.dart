import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/store_setup_screen.dart';
import 'operations_test.dart' show sample, response;
import 'work_controller_test.dart' show MemoryStore;
import 'support/store_setup_fixture.dart';

Future<void> next(WidgetTester t) async {
  await t.tap(find.widgetWithText(FilledButton, '다음'));
  await t.pumpAndSettle();
}

void main() {
  for (final (width, rejected) in [
    (320.0, false),
    (390.0, false),
    (1200.0, false),
    (390.0, true),
  ]) {
    testWidgets(
      'registration stages preserve draft and retry atomically at $width (validation=$rejected)',
      (t) async {
        t.view.physicalSize = Size(width, 1000);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final writes = <Map<String, dynamic>>[];
        final data = {...sample(), 'storeSetupCatalog': setupCatalogFixture()};
        final ops = OperationsController(
          accessToken: () async => 'token',
          client: MockClient((r) async {
            if (r.method == 'POST') {
              writes.add(jsonDecode(r.body));
              if (writes.length == 1) {
                if (rejected) {
                  data['storeSetupCatalog']['releaseId'] = 'updated-release';
                  return response({
                    'error': '기본 매뉴얼을 다시 확인해 주세요.',
                    'setupRejected': true,
                  }, 409);
                }
                return response({'error': '연결을 확인해 주세요.'}, 503);
              }
            }
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        final work = WorkController(MemoryStore());
        addTearDown(work.dispose);
        await t.pumpWidget(
          Tap2workApp(
            controller: work,
            homeOverride: Builder(
              builder: (c) => Scaffold(
                body: TextButton(
                  onPressed: () => openStoreSetup(c, ops),
                  child: const Text('등록 열기'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('등록 열기'));
        await t.pumpAndSettle();
        await next(t);
        expect(find.textContaining('매장 이름을 입력해 주세요.'), findsOneWidget);
        expect(writes, isEmpty);
        await t.enterText(
          find.byKey(const ValueKey('new-workspace-name')),
          '돈까스 연남점',
        );
        t.view.viewInsets = const FakeViewPadding(bottom: 250);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        t.view.resetViewInsets();
        await t.pumpAndSettle();
        await next(t);
        await t.tap(find.widgetWithText(FilterChip, '돈까스'));
        await t.pumpAndSettle();
        expect(find.textContaining('튀김 작업 공통'), findsOneWidget);
        await next(t);
        await t.tap(find.widgetWithText(FilterChip, '배달'));
        await t.pumpAndSettle();
        await t.tap(find.text('이전'));
        await t.pumpAndSettle();
        expect(
          t.widget<FilterChip>(find.widgetWithText(FilterChip, '돈까스')).selected,
          isTrue,
        );
        await next(t);
        expect(
          t.widget<FilterChip>(find.widgetWithText(FilterChip, '배달')).selected,
          isTrue,
        );
        await next(t); // optional location
        await next(t); // weekdays
        await t.tap(find.widgetWithText(FilterChip, '일'));
        await t.pumpAndSettle();
        for (var i = 0; i < 7; i++) {
          await next(t);
          expect(t.takeException(), isNull);
        }
        // manual screen: selected published frying + common + delivery, not Korean.
        expect(find.text('기본 매뉴얼을 준비했어요'), findsOneWidget);
        await t.scrollUntilVisible(
          find.text('튀김 작업 준비'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('튀김 작업 준비'), findsOneWidget);
        expect(find.text('반찬 소분과 배식 준비'), findsNothing);
        await next(t);
        expect(find.text('이 설정으로 시작할까요?'), findsOneWidget);
        expect(writes, isEmpty);
        await t.tap(find.text('매장 등록'));
        await t.pumpAndSettle();
        expect(writes.length, 1);
        if (rejected) {
          expect(find.text('기본 매뉴얼을 준비했어요'), findsOneWidget);
          await next(t);
          await t.tap(find.text('매장 등록'));
          await t.pumpAndSettle();
          expect(writes[1]['requestId'], writes[0]['requestId']);
          expect(writes[1]['setup']['releaseId'], 'updated-release');
          expect(
            writes[1]['setup']['sourceIds'],
            writes[0]['setup']['sourceIds'],
          );
        } else {
          expect(find.text('등록 다시 시도'), findsOneWidget);
          await t.tap(find.text('등록 다시 시도'));
          await t.pumpAndSettle();
          expect(writes[1], writes[0]);
        }
        expect(find.text('매장 준비가 끝났어요'), findsOneWidget);
        final setup = writes.singleWhere(
          (w) => identical(w, writes.first),
        )['setup'];
        expect(setup['businessTypeId'], 'donkatsu');
        expect(setup['menuIds'], ['donkatsu-1', 'donkatsu-2']);
        expect(setup['weekdays'], isNot(contains(7)));
        expect(setup['sourceIds'], contains('chicken/prep'));
        expect(setup['sourceIds'], contains('delivery/open'));
        expect(setup['sourceIds'], isNot(contains('korean/prep')));
        expect(setup['enableOperations'], false);
        expect(setup.containsKey('pos'), false);
        expect(setup.containsKey('deliveryPlatforms'), false);
        expect(t.takeException(), isNull);
        await t.tap(find.text('매장으로 가기'));
        await t.pumpAndSettle();
        expect(find.text('등록 열기'), findsOneWidget);
      },
    );
  }
  testWidgets('missing setup catalog provides retry and no creation', (
    t,
  ) async {
    final ops = OperationsController(
      client: MockClient((_) async => response(sample())),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await t.pumpWidget(MaterialApp(home: StoreSetupScreen(ops: ops)));
    await t.pumpAndSettle();
    expect(find.text('다시 불러오기'), findsOneWidget);
    expect(
      t.widget<FilledButton>(find.widgetWithText(FilledButton, '다음')).onPressed,
      isNull,
    );
  });
  testWidgets(
    'address selection is required for a query; custom parts split staffing pages',
    (t) async {
      final ops = OperationsController(
        client: MockClient(
          (_) async => response({
            ...sample(),
            'storeSetupCatalog': setupCatalogFixture(),
          }),
        ),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      final work = WorkController(MemoryStore());
      addTearDown(work.dispose);
      await t.pumpWidget(
        Tap2workApp(
          controller: work,
          homeOverride: StoreSetupScreen(ops: ops),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('new-workspace-name')),
        '추가 파트 매장',
      );
      await next(t);
      await t.tap(find.widgetWithText(FilterChip, '돈까스'));
      await t.pumpAndSettle();
      await next(t);
      await next(t);
      final address = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == '주소 · 선택',
      );
      await t.enterText(address, '연남동');
      await next(t);
      expect(find.textContaining('표준 주소 검색에서 주소를 선택'), findsOneWidget);
      expect(find.text('매장은 어디에 있나요?'), findsOneWidget);
      await t.enterText(address, '');
      await next(t);
      for (var i = 0; i < 4; i++) {
        await next(t);
      }
      expect(find.text('어떤 파트가 필요한가요?'), findsOneWidget);
      await t.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == '새 파트 이름',
        ),
        '포장',
      );
      await t.ensureVisible(find.text('파트 추가'));
      await t.tap(find.text('파트 추가'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, '포장'), findsOneWidget);
      await next(t);
      expect(find.text('주방 · 필요 인원'), findsOneWidget);
      expect(find.text('포장 · 필요 인원'), findsNothing);
      await next(t);
      expect(find.text('포장 · 필요 인원'), findsOneWidget);
      expect(find.text('주방 · 필요 인원'), findsNothing);
      await next(t);
      expect(find.text('기본 메뉴와 재료를 준비했어요'), findsOneWidget);
      expect(find.text('등심 돈까스'), findsOneWidget);
      expect(find.textContaining('POS'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
