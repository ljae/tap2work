import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/service_workflow_controller.dart';
import 'package:tap2work/ui/service_workflow_screen.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'manual_workspace_test.dart' show directoryData;
import 'operations_test.dart' show response;

Json fixture() => {
  ...directoryData(),
  'revision': 7,
  'tappers': [
    {'id': 'buddy', 'nickname': '버디', 'actorId': 'cook', 'active': true},
  ],
  'serviceWorkflow': {
    'day': '2026-10-14',
    'canConfigure': true,
    'briefing': {
      'manualIds': ['a'],
      'manuals': [
        {'id': 'a', 'title': '위생 TAP', 'version': 1, 'hash': 'manual-hash'},
      ],
      'note': '오늘 변경 안내',
      'hash': 'brief-hash',
    },
    'manuals': [
      {'id': 'a', 'title': '위생 TAP', 'hash': 'manual-hash', 'version': 1},
    ],
    'guides': [
      {
        'id': 'test-guide',
        'title': 'CS 본보기',
        'hash': 'guide-hash',
        'sourceLocale': 'ko',
        'steps': [
          {
            'id': 'practice',
            'title': '시범과 연습',
            'manual': '버디와 함께 실제 안내를 연습해요.',
          },
        ],
      },
    ],
    'records': [],
  },
};
Future<void> mount(
  WidgetTester tester,
  OperationsController ops,
  double width,
) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await ops.refresh();
  await tester.pumpWidget(MaterialApp(home: ServiceWorkflowScreen(ops: ops)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'acknowledgement shows only for the current actor day and manual version',
    (tester) async {
      final data = fixture();
      final flow = data['serviceWorkflow'] as Json;
      flow['briefing']['manuals'][0].addAll({'hash': 'h1', 'version': 1});
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            flow['records'] = [
              {
                'kind': 'briefing',
                'day': flow['day'],
                'actor': {'id': 'owner'},
                'briefingNote': flow['briefing']['note'],
                'manuals': [
                  {'id': 'a', 'version': 1, 'hash': 'h1'},
                ],
              },
            ];
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, 390);
      await tester.tap(find.text('안내 확인'));
      await tester.pumpAndSettle();
      expect(find.text('오늘 안내를 확인했어요'), findsOneWidget);
      expect(find.text('안내 확인'), findsNothing);
      flow['briefing']['manuals'][0]['hash'] = 'h2';
      await ops.refresh();
      await tester.pumpAndSettle();
      expect(find.text('안내 확인'), findsOneWidget);
      flow['briefing']['manuals'][0]['hash'] = 'h1';
      flow['day'] = '2026-10-15';
      await ops.refresh();
      await tester.pumpAndSettle();
      expect(find.text('안내 확인'), findsOneWidget);
    },
  );
  testWidgets(
    'pending handovers come before collapsed resolved history and navigation stays visible',
    (tester) async {
      final data = fixture();
      data['serviceWorkflow']['records'] = [
        {
          'kind': 'handoff',
          'note': '다른 사람 인계',
          'nextAction': '다른 담당 일',
          'day': '2026-10-14',
          'canResolve': false,
        },
        {
          'kind': 'handoff',
          'note': '지난 인계',
          'nextAction': '끝난 일',
          'day': '2026-10-13',
          'resolution': {'note': '해결 내용'},
        },
        {
          'kind': 'handoff',
          'note': '내 인계',
          'nextAction': '내가 처리할 일',
          'day': '2026-10-14',
          'canResolve': true,
        },
      ];
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, 390);
      await tester.tap(find.text('교대·마감'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('내가 처리할 일')).dy,
        lessThan(tester.getTopLeft(find.text('다른 담당 일')).dy),
      );
      expect(find.text('끝난 일'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('처리한 인계 보기 · 1'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('CS·개선').hitTestable(), findsOneWidget);
      await tester.tap(find.text('처리한 인계 보기 · 1'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('해결 내용'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('해결 내용'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'editing guards dismissal and saving disables the action until response',
    (tester) async {
      final pending = Completer<http.Response>();
      int writes = 0;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            writes++;
            return pending.future;
          }
          return response(fixture());
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, 390);
      await tester.tap(find.text('교대·마감'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('인계 남기기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '다음 행동');
      await tester.enterText(find.byType(TextField).last, '확인한 사실');
      await tester.tap(find.byType(CloseButton).last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text(AppStrings('ko').text('ui.audit21')));
      await tester.pumpAndSettle();
      expect(find.text('확인한 사실'), findsOneWidget);
      await tester.tap(find.text('저장'));
      await tester.pump();
      expect(find.text(AppStrings('ko').text('common.saving')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                AppStrings('ko').text('common.saving'),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(writes, 1);
      pending.complete(response(fixture()));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'briefing retry reuses its request after a lost response and refresh',
    (tester) async {
      final data = fixture(), writes = <Json>[];
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            writes.add(jsonDecode(r.body) as Json);
            if (writes.length == 1) {
              data['revision'] = 8;
              return http.Response(jsonEncode({'error': 'response lost'}), 503);
            }
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, 390);
      await tester.tap(find.text('안내 확인').first);
      await tester.pumpAndSettle();
      await ops.refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.text('안내 확인').first);
      await tester.pumpAndSettle();
      expect(writes.length, 2);
      expect(writes[1]['requestId'], writes[0]['requestId']);
      expect(writes[1]['revision'], writes[0]['revision']);
    },
  );
  testWidgets(
    'eight languages remain usable on a 320px phone with enlarged text',
    (tester) async {
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(fixture())),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final locale in appSupportedLocales) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: appSupportedLocales,
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.5)),
              child: child!,
            ),
            home: ServiceWorkflowScreen(
              key: ValueKey(locale.toLanguageTag()),
              ops: ops,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final strings = AppStrings(locale.toLanguageTag());
        await tester.tap(find.text(strings.text('service.cs')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(strings.text('service.feedback')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(strings.text('service.feedback')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
      }
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'short shift flow and CS draft reading fit $width without completing work',
      (tester) async {
        final data = fixture(), writes = <Json>[];
        final ops = OperationsController(
          client: MockClient((r) async {
            if (r.method == 'POST') writes.add(jsonDecode(r.body) as Json);
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await mount(tester, ops, width);
        await tester.tap(find.text('안내 확인').first);
        await tester.pumpAndSettle();
        expect(writes.single['action'], 'record_service');
        expect(writes.single['kind'], 'briefing');
        expect(writes.single['briefingHash'], 'brief-hash');
        expect(writes.single['revision'], 7);
        expect(writes.single['requestId'], isNotEmpty);
        await tester.tap(find.text('교대·마감'));
        await tester.pumpAndSettle();
        expect(find.text('인계 남기기'), findsOneWidget);
        await tester.tap(find.text('CS·개선'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('검토용 CS 안내'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('CS 본보기'));
        await tester.tap(find.text('CS 본보기'));
        await tester.pumpAndSettle();
        expect(find.textContaining('한국어 원문'), findsOneWidget);
        expect(find.text('버디와 함께 실제 안내를 연습해요.'), findsOneWidget);
        expect(writes.length, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'handover requires next action and preserves inputs and request ID on failed retry',
    (tester) async {
      final data = fixture(), writes = <Json>[];
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            writes.add(jsonDecode(r.body) as Json);
            if (writes.length == 1) {
              return http.Response(jsonEncode({'error': '잠시 후 다시 시도'}), 503);
            }
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, 390);
      await tester.tap(find.text('교대·마감'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('인계 남기기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      await tester.enterText(find.byType(TextField).first, '깨끗한 컵 보충');
      await tester.enterText(find.byType(TextField).last, '컵이 부족해요');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(find.text('컵이 부족해요'), findsOneWidget);
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(writes.length, 2);
      expect(writes[0]['requestId'], writes[1]['requestId']);
      expect(writes[0]['revision'], 7);
      expect(writes[1]['revision'], 7);
      expect(writes[1]['nextAction'], '깨끗한 컵 보충');
      expect(writes[1]['assigneeId'], isNull);
      expect(find.byType(TextField), findsNothing);
    },
  );
  test('draft cannot submit after actor or workspace changes', () async {
    var writes = 0;
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') writes++;
        return response(fixture());
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    final draft = ServiceWorkflowDraft(ops);
    ops.actorId = 'crew';
    expect(
      await draft.save('record_service', {
        'kind': 'feedback',
        'note': '의견',
        'cause': 'unknown',
      }),
      false,
    );
    expect(writes, 0);
  });
  testWidgets(
    'public preview reads guides without submitting confirmation or registration',
    (tester) async {
      var writes = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((r) async {
          if (r.method == 'POST') writes++;
          return response(fixture());
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, 320);
      final ack = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '안내 확인'),
      );
      expect(ack.onPressed, isNull);
      await tester.tap(find.text('CS·개선'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('검토용 CS 안내'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('CS 본보기'));
      await tester.tap(find.text('CS 본보기'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, '검토한 안내 등록'),
            )
            .onPressed,
        isNull,
      );
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
