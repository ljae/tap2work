import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/components.dart';
import 'package:tap2work/ui/time_band_editor.dart';
import 'package:tap2work/ui/workplace_screens.dart';

const parts = <Json>[
  {'id': 'kitchen', 'name': '주방'},
  {'id': 'hall', 'name': '홀'},
];
Json fixture() => {
  'revision': 12,
  'actor': {'id': 'owner', 'role': 'owner'},
  'canEditTasks': true,
  'workplace': {
    'parts': parts,
    'days': {
      for (var d = 1; d <= 7; d++)
        '$d': <Json>[
          {
            'id': 'legacy-band-$d-0',
            'legacyIndex': 0,
            'name': '전체',
            'start': '09:00',
            'end': '22:00',
          },
        ],
    },
  },
};
Future<OperationsController> mount(
  WidgetTester tester, {
  bool readOnly = false,
  bool conflict = false,
  Json? initialData,
  void Function(Json)? write,
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final data = initialData ?? fixture();
  final ops = OperationsController(
    readOnly: readOnly,
    client: MockClient((r) async {
      if (r.method == 'POST') {
        final body = jsonDecode(r.body) as Json;
        write?.call(body);
        if (conflict) {
          return http.Response(
            jsonEncode({'error': '다른 동료가 먼저 저장했어요.'}),
            409,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        data['revision'] = 13;
        data['workplace']['days'] = body['days'];
      }
      return http.Response(
        jsonEncode(data),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
  addTearDown(ops.dispose);
  await ops.refresh();
  await tester.pumpWidget(
    MaterialApp(
      home: WorkplaceSettings(ops: ops, section: 'hours'),
    ),
  );
  await tester.pumpAndSettle();
  return ops;
}

void main() {
  testWidgets(
    'add overlapping band to weekdays, preserve legacy IDs and conflict draft',
    (tester) async {
      Json? written;
      final ops = await mount(
        tester,
        conflict: true,
        write: (v) => written = v,
      );
      await tester.scrollUntilVisible(find.text('시간대 추가'), 180);
      await tester.pumpAndSettle();
      await tester.tap(find.text('시간대 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '점심 피크');
      await tester.tap(find.widgetWithText(FilterChip, '주방'));
      await tester.scrollUntilVisible(
        find.descendant(
          of: find.byType(TimeBandEditor),
          matching: find.widgetWithText(FilterChip, '화'),
        ),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(TimeBandEditor),
          matching: find.widgetWithText(FilterChip, '화'),
        ),
      );
      await tester.tap(find.text('시간대 적용'));
      await tester.pumpAndSettle();
      expect(find.byType(TimeBandEditor), findsNothing);
      ops.data!['revision'] = 99;
      await tester.tap(find.text('일주일 설정 저장'));
      await tester.pumpAndSettle();
      expect(written?['revision'], 12);
      final monday = written!['days']['1'] as List;
      final tuesday = written!['days']['2'] as List;
      expect(monday.first['id'], 'legacy-band-1-0');
      expect(monday.last['id'], startsWith('custom-'));
      expect(tuesday.last['id'], monday.last['id']);
      expect(monday.last['headcounts'], {'kitchen': 1, 'hall': 0});
      expect(find.textContaining('입력한 내용은 그대로'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'editor validates required selection and protects discarded draft at narrow width',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showAppFormSheet<Json>(
                  context: context,
                  builder: (_) => const TimeBandEditor(
                    parts: parts,
                    openDays: {1, 2},
                    initialDays: {1},
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시간대 적용'));
      await tester.pumpAndSettle();
      expect(find.textContaining('이름, 파트'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '피크');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('변경을 버릴까요?'), findsOneWidget);
      await tester.tap(find.text('계속 수정'));
      await tester.pumpAndSettle();
      expect(find.text('피크'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'saved band links disable after local edits and preview never writes',
    (tester) async {
      var writes = 0;
      await mount(tester, readOnly: true, write: (_) => writes++);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '연결 업무'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, '일주일 설정 저장'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('2교대'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'copy preserves shared IDs, edit keeps identity, delete only changes the draft',
    (tester) async {
      final writes = <Json>[];
      await mount(tester, write: writes.add);
      await tester.scrollUntilVisible(find.text('다른 영업일에 복사'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('다른 영업일에 복사'));
      await tester.tap(find.text('일주일 설정 저장'));
      await tester.pumpAndSettle();
      final days = writes.last['days'] as Map;
      expect(
        days.values.every((rows) => rows.first['id'] == 'legacy-band-1-0'),
        isTrue,
      );
      await tester.scrollUntilVisible(find.text('시간대 수정'), -200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('시간대 수정'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '이른 오픈');
      await tester.tap(find.text('시간대 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('일주일 설정 저장'));
      await tester.pumpAndSettle();
      expect(writes.last['days']['1'].first['id'], 'legacy-band-1-0');
      expect(writes.last['days']['1'].first['name'], '이른 오픈');
      expect(writes.last['days']['1'].first['legacyIndex'], 0);
      await tester.scrollUntilVisible(find.text('시간대 삭제'), -200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('시간대 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '시간대 삭제'));
      await tester.pumpAndSettle();
      expect(writes.length, 2);
      await tester.tap(find.text('일주일 설정 저장'));
      await tester.pumpAndSettle();
      expect(writes.last['days']['1'], isEmpty);
      expect(writes.last['days']['2'], isNotEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'saved linked work uses shared sheet and local changes disable entry',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('연결 업무'));
      await tester.pumpAndSettle();
      expect(find.text('전체 · 연결 업무'), findsOneWidget);
      await tester.tap(find.byType(CloseButton).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2교대'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '연결 업무').first)
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'preset confirmation preserves custom bands and linked IDs when reducing shifts',
    (tester) async {
      final data = fixture();
      final custom = <String, dynamic>{
        'id': 'custom-peak',
        'custom': true,
        'name': '피크',
        'start': '11:00',
        'end': '13:00',
        'headcounts': {'kitchen': 3, 'hall': 0},
      };
      data['workplace']['days']['1'] = [
        {
          'id': 'legacy-band-1-0',
          'legacyIndex': 0,
          'name': '오픈',
          'start': '09:00',
          'end': '13:00',
        },
        {
          'id': 'legacy-band-1-1',
          'legacyIndex': 1,
          'name': '미들',
          'start': '13:00',
          'end': '17:00',
        },
        {
          'id': 'legacy-band-1-2',
          'legacyIndex': 2,
          'name': '마감',
          'start': '17:00',
          'end': '22:00',
        },
        custom,
      ];
      data['taskTemplates'] = [
        {
          'id': 'tap',
          'settings': {
            'assignment': {
              'timeBandIds': ['legacy-band-1-2'],
            },
          },
          'steps': [],
        },
      ];
      Json? written;
      await mount(tester, initialData: data, write: (v) => written = v);
      await tester.tap(find.text('한 타임'));
      await tester.pumpAndSettle();
      expect(find.text('교대 기본값을 적용할까요?'), findsOneWidget);
      await tester.tap(find.text('계속 수정'));
      await tester.pumpAndSettle();
      expect(written, isNull);
      await tester.tap(find.text('한 타임'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('기본값 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('일주일 설정 저장'));
      await tester.pumpAndSettle();
      final rows = (written!['days']['1'] as List).cast<Json>();
      expect(rows.map((b) => b['id']), [
        'legacy-band-1-0',
        'legacy-band-1-2',
        'custom-peak',
      ]);
      expect(rows.last, custom);
      expect(rows[1]['custom'], true);
      expect(rows[1]['legacyIndex'], 2);
      expect(rows[1]['start'], '17:00');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'referenced band removal explains downstream effects without mutating links',
    (tester) async {
      final data = fixture();
      data['taskTemplates'] = [
        {
          'id': 'tap',
          'steps': [
            {
              'id': 'task',
              'settings': {
                'assignment': {
                  'mode': 'scheduled',
                  'timeBandIds': ['legacy-band-1-0'],
                },
              },
            },
          ],
        },
      ];
      data['crewPatterns'] = [
        {
          'id': 'pattern',
          'entries': [
            {'weekday': 1, 'timeBandId': 'legacy-band-1-0'},
          ],
        },
      ];
      final before = jsonEncode([data['taskTemplates'], data['crewPatterns']]);
      final writes = <Json>[];
      await mount(tester, initialData: data, write: writes.add);
      expect(find.textContaining('휴무로 저장하면 해당 요일'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('시간대 삭제'), 180);
      await tester.pumpAndSettle();
      await tester.tap(find.text('시간대 삭제'));
      await tester.pumpAndSettle();
      final dialog = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Text),
      );
      expect(
        tester.widgetList<Text>(dialog).map((w) => w.data).join(),
        contains('TAP·Task는 이후 해당 요일에 새로 생성되지 않아요'),
      );
      expect(
        tester.widgetList<Text>(dialog).map((w) => w.data).join(),
        contains('연결된 반복 배정은 다시 적용하기 전에'),
      );
      expect(
        tester.widgetList<Text>(dialog).map((w) => w.data).join(),
        contains('이미 배정한 근무와 완료 기록은 유지돼요'),
      );
      await tester.tap(find.widgetWithText(FilledButton, '시간대 삭제'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      expect(jsonEncode([data['taskTemplates'], data['crewPatterns']]), before);
      await tester.tap(find.text('일주일 설정 저장'));
      await tester.pumpAndSettle();
      expect(writes.single['days']['1'], isEmpty);
      expect(
        writes.single.keys.toSet(),
        containsAll(['action', 'revision', 'days']),
      );
      expect(writes.single.containsKey('taskTemplates'), isFalse);
      expect(writes.single.containsKey('crewPatterns'), isFalse);
    },
  );
}
