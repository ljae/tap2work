import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/domain/inventory_readiness.dart';
import 'package:tap2work/domain/edit_conflict.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/shared_welcome_screen.dart';
import 'shared_welcome_test.dart' show welcomeData, mountShared;
import 'operations_test.dart' show response;

void main() {
  testWidgets(
    'new visible important welcome can be skipped once, without ack; later unseen version still appears',
    (tester) async {
      final data = welcomeData();
      final posts = <Json>[];
      final ops = OperationsController(
        accessToken: () async => 'test-session',
        client: MockClient((request) async {
          if (request.method == 'POST') {
            posts.add(jsonDecode(request.body) as Json);
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mountShared(tester, ops);
      expect(find.byType(SharedWelcomeScreen), findsOneWidget);
      data['welcome']['revision'] = 2;
      data['welcome']['importantRevision'] = 2;
      data['welcome']['body'] = '画面に表示された新しい重要案内';
      await ops.refresh(force: true);
      await tester.pumpAndSettle();
      expect(find.text('画面に表示された新しい重要案内'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('shared-welcome-work')));
      await tester.pumpAndSettle();
      expect(find.byType(SharedWelcomeScreen), findsNothing);
      expect(posts, isEmpty);
      expect(ops.data?['welcomeNeedsAcknowledgment'], true);
      data['welcome']['revision'] = 3;
      data['welcome']['importantRevision'] = 3;
      await ops.refresh(force: true);
      await tester.pumpAndSettle();
      expect(find.byType(SharedWelcomeScreen), findsOneWidget);
      expect(posts, isEmpty);
    },
  );
  test('unknown quantities, reviewed policy and known zero stay distinct', () {
    final draft = <String, dynamic>{
      'quantity': 0,
      'minimum': 5,
      'unit': '봉',
      'orderQuantity': 10,
      'supplier': '가상 공급처',
      'setupNeedsReview': true,
    };
    expect(InventoryReadiness(draft).status, 'quantity_unknown');
    expect(InventoryReadiness(draft).orderReady, false);
    draft['lastCheckedAt'] = '2026-10-10T03:00:00Z';
    expect(InventoryReadiness(draft).status, 'policy_unknown');
    draft['setupNeedsReview'] = false;
    expect(InventoryReadiness(draft).status, 'low');
    expect(InventoryReadiness(draft).orderReady, true);
    draft['quantity'] = 8;
    expect(InventoryReadiness(draft).status, 'sufficient');
    draft.remove('lastCheckedAt');
    draft['quantityNeedsConfirmation'] = true;
    expect(InventoryReadiness(draft).status, 'quantity_unknown');
  });
  test(
    'manual setup merges separate place fields and welcome preserves remote body',
    () {
      final base = <String, dynamic>{
        'store': {
          'manualSetup': {
            'conditions': {'selfbar': false},
            'places': {'waste': 'a', 'dry': 'd'},
          },
        },
        'welcome': {'title': '원래 제목', 'body': '원래 본문', 'sourceLocale': 'ko'},
      };
      final latest = copyEditSnapshot(base);
      latest['store']['manualSetup']['places']['dry'] = 'new-d';
      latest['welcome']['body'] = '다른 파트너의 본문';
      final request = <String, dynamic>{
        'setup': {
          'conditions': {'selfbar': false},
          'places': {'waste': 'new-a', 'dry': 'd'},
        },
      };
      final merge = mergeEdit(
        editProjection('save_manual_setup', request, base)!,
        editProjection('save_manual_setup', request, latest)!,
        editorDraftValues('save_manual_setup', request),
      );
      expect(merge.conflicts, isEmpty);
      final payload = editorMergedRequest(
        'save_manual_setup',
        request,
        merge.values,
      );
      expect(payload['setup']['places']['waste'], 'new-a');
      expect(payload['setup']['places']['dry'], 'new-d');
      final welcome = <String, dynamic>{
        'welcome': {'title': '내 제목', 'body': '원래 본문', 'sourceLocale': 'ko'},
        'important': true,
      };
      final changed = mergeEdit(
        editProjection('save_welcome', welcome, base)!,
        editProjection('save_welcome', welcome, latest)!,
        editorDraftValues('save_welcome', welcome),
      );
      expect(changed.conflicts, isEmpty);
      final saved = editorMergedRequest(
        'save_welcome',
        welcome,
        changed.values,
      );
      expect(saved['welcome']['title'], '내 제목');
      expect(saved['welcome']['body'], '다른 파트너의 본문');
      expect(saved['important'], true);
    },
  );
}
