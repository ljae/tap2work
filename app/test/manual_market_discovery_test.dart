import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/domain/manual_market_catalog.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/manual_market_screen.dart';
import 'manual_market_test.dart' as market;
import 'operations_test.dart' show response;

Json release() =>
    jsonDecode(File('../docs/market/current.json').readAsStringSync());
void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'owner setup applies industry and selected operating defaults at $width',
      (tester) async {
        final data = market.fixture()..['manualCatalog'] = release();
        Json? sent;
        final ops = OperationsController(
          client: MockClient((r) async {
            if (r.method == 'POST') sent = jsonDecode(r.body);
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await market.mount(
          tester,
          ops,
          ManualMarketScreen(ops: ops, setup: true),
          width: width,
        );
        await tester.enterText(
          find.widgetWithText(TextField, '우리 사업장 특성'),
          '고기집 · 뼈찜',
        );
        await tester.tap(find.byKey(const ValueKey('market-industry')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('음식·음료').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('market-starter')),
        );
        await tester.tap(find.byKey(const ValueKey('market-starter')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('담은 7개 확인'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(SwitchListTile, '기존 운영 매뉴얼을 새 구성으로 교체'),
        );
        await tester.tap(
          find.widgetWithText(SwitchListTile, '선택한 운영 업무를 매일 사용'),
        );
        await tester.tap(find.text('선택한 7개로 구성하기'));
        await tester.pumpAndSettle();
        expect(sent?['action'], 'configure_manual_business');
        expect(sent?['industryId'], 'food');
        expect(sent?['specialization'], '고기집 · 뼈찜');
        expect(sent?['replaceExisting'], true);
        expect(sent?['enableOperations'], true);
        expect(sent?['sourceIds'], hasLength(7));
        expect(tester.takeException(), isNull);
      },
    );
  }
  test(
    'all legacy collections are discoverable; industry includes common legal and operations',
    () {
      final catalog = ManualMarketCatalog(release());
      expect(catalog.entries.length, 109);
      expect(
        catalog
            .search(industry: 'beauty')
            .any((e) => e['sourceId'] == 'legal/employment'),
        isTrue,
      );
      expect(
        catalog
            .search(industry: 'beauty')
            .any((e) => e['collectionId'] == 'bonejjim'),
        isFalse,
      );
      expect(
        catalog
            .search(query: '개인 정보', kind: 'legal')
            .any((e) => e['sourceId'] == 'legal/privacy'),
        isTrue,
      );
      expect(catalog.search(query: '없는검색결과123'), isEmpty);
      expect(
        catalog
            .search(query: '약국')
            .any((e) => e['sourceId'] == 'business/health'),
        isTrue,
      );
      expect(
        catalog.search(query: '카페').any((e) => e['collectionId'] == 'bonejjim'),
        isFalse,
      );
      for (final industry in catalog.industries) {
        expect(
          catalog.search(industry: industry['id'], kind: 'legal'),
          isNotEmpty,
        );
        expect(
          catalog.search(industry: industry['id'], kind: 'operation'),
          isNotEmpty,
        );
      }
    },
  );
  testWidgets(
    'industry picker and legal filter batch import into an existing group',
    (tester) async {
      final data = market.fixture()..['manualCatalog'] = release();
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body);
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await market.mount(tester, ops, ManualMarketScreen(ops: ops), width: 390);
      await tester.tap(find.byKey(const ValueKey('market-industry')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('미용·뷰티').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('법적 기준'));
      await tester.pumpAndSettle();
      expect(find.text('6개 항목'), findsWidgets);
      await tester.tap(find.text('이 결과 담기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('담은 6개 확인'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('기존 그룹에 모으기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택한 6개 가져오기'));
      await tester.pumpAndSettle();
      expect(sent?['folderMode'], 'existing');
      expect(sent?['folderId'], 'general');
      expect(sent?['sourceIds'], hasLength(6));
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'search across industries retains basket and failed import at $width',
      (tester) async {
        final data = market.fixture()..['manualCatalog'] = release();
        Json? sent;
        final ops = OperationsController(
          client: MockClient((r) async {
            if (r.method == 'POST') {
              sent = jsonDecode(r.body);
              return response({'error': '동료가 수정했어요'}, 409);
            }
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await market.mount(
          tester,
          ops,
          ManualMarketScreen(ops: ops),
          width: width,
          scale: 1.5,
        );
        expect(
          find.byType(Checkbox),
          findsNothing,
          reason: 'first view shows balanced categories, not a long food list',
        );
        await tester.enterText(find.byType(TextField), '근로계약');
        await tester.pumpAndSettle();
        final legal = find.byKey(const ValueKey('market-legal/employment'));
        await tester.ensureVisible(legal);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: legal, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(const ValueKey('market-browse')),
          const Offset(0, 1000),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '네일');
        await tester.pumpAndSettle();
        final checkbox = find.byType(Checkbox).first;
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
        await tester.tap(find.text('담은 2개 확인'));
        await tester.pumpAndSettle();
        expect(find.text('업무별 자동 분류'), findsOneWidget);
        expect(find.text('근로계약·임금 서류 확인'), findsOneWidget);
        await tester.tap(find.text('선택한 2개 가져오기'));
        await tester.pumpAndSettle();
        expect(sent?['folderMode'], 'purpose');
        expect(sent?['sourceIds'], hasLength(2));
        expect(sent?['revision'], 2);
        expect(find.text('동료가 수정했어요'), findsOneWidget);
        expect(find.text('선택한 2개 가져오기'), findsOneWidget);
        await tester.tap(find.text('더 찾아보기'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '네일',
        );
        expect(find.text('담은 2개 확인'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'legal detail exposes applicability and official source; zero results recover',
    (tester) async {
      final data = market.fixture()..['manualCatalog'] = release();
      final ops = OperationsController(
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await market.mount(tester, ops, ManualMarketScreen(ops: ops), width: 390);
      await tester.enterText(find.byType(TextField), '근로계약');
      await tester.pumpAndSettle();
      await tester.tap(find.text('근로계약·임금 서류 확인'));
      await tester.pumpAndSettle();
      expect(find.text('적용 대상'), findsOneWidget);
      expect(find.textContaining('고용노동부 · 소규모 사업장'), findsOneWidget);
      expect(find.textContaining('체크 완료가 법적 충족'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('market-browse')),
        const Offset(0, 1000),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '없는검색결과123');
      await tester.pumpAndSettle();
      expect(find.text('공통 업무 보기'), findsOneWidget);
      await tester.ensureVisible(find.text('공통 업무 보기'));
      await tester.tap(find.text('공통 업무 보기'));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
