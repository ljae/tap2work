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
    'immediate preset preserves custom bands and linked IDs when reducing shifts',
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
      await tester.tap(find.text('영업시간 설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2교대 이상'));
      await tester.pumpAndSettle();
      expect(written, isNull);
      await tester.tap(find.text('인원 배치').first);
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
}
