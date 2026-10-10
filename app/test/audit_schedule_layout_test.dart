import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/business_hours_slider.dart';
import 'time_band_editor_test.dart' show fixture, mount;
import 'floor_plan_test.dart' show layoutSample, openMap, tapVisible;
import 'operations_test.dart' show response;

List<Json> bands(List<String> clocks) => [
  for (var i = 0; i < clocks.length - 1; i++)
    {
      'id': 'band-$i',
      'name': i == 0 ? '오픈' : '마감',
      'start': clocks[i],
      'end': clocks[i + 1],
      'headcounts': {'kitchen': 2},
      'crewIds': {
        'kitchen': ['crew-a'],
      },
    },
];

void main() {
  test('hours retain valid cuts including three shifts and midnight', () {
    expect(
      retainedShiftBoundaries(600, 1560, bands(['10:00', '16:00', '22:00'])),
      [600, 960, 1560],
    );
    expect(
      retainedShiftBoundaries(660, 1320, bands(['10:00', '16:00', '22:00'])),
      [660, 960, 1320],
    );
    expect(
      retainedShiftBoundaries(
        600,
        1560,
        bands(['10:00', '14:00', '18:00', '22:00']),
      ),
      [600, 840, 1080, 1560],
    );
    expect(
      retainedShiftBoundaries(1140, 1680, bands(['19:00', '01:00', '03:00'])),
      [1140, 1500, 1680],
    );
    expect(
      retainedShiftBoundaries(600, 900, bands(['10:00', '16:00', '22:00'])),
      isNull,
    );
    expect(
      retainedShiftBoundaries(960, 1320, bands(['10:00', '16:00', '22:00'])),
      isNull,
    );
  });

  testWidgets(
    'outside-hours edit preserves 16:00 cut, identity and other weekdays',
    (tester) async {
      final data = fixture();
      for (var d = 1; d <= 7; d++) {
        data['workplace']['days']['$d'] = d == 2
            ? <Json>[]
            : bands(['10:00', '16:00', '22:00']);
      }
      final original =
          jsonDecode(jsonEncode(data['workplace']['days'])) as Json;
      Json? posted;
      await mount(tester, initialData: data, write: (v) => posted = v);
      await tester.tap(find.text('개별'));
      await tester.pumpAndSettle();
      tester
          .widget<BusinessHoursSlider>(find.byType(BusinessHoursSlider))
          .onHours(600, 1560);
      await tester.pumpAndSettle();
      await tester.tap(find.text('인원 배치').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('일주일 설정 저장'));
      await tester.pumpAndSettle();
      expect(posted!['days']['1'][0]['end'], '16:00');
      expect(posted!['days']['1'][1]['start'], '16:00');
      expect(posted!['days']['1'][1]['end'], '02:00');
      expect(posted!['days']['1'][0]['id'], original['1'][0]['id']);
      expect(posted!['days']['1'][0]['crewIds'], original['1'][0]['crewIds']);
      expect(
        posted!['days']['1'][0]['headcounts'],
        original['1'][0]['headcounts'],
      );
      for (var d = 2; d <= 7; d++) {
        expect(posted!['days']['$d'], original['$d']);
      }
      expect(find.text('교대 시간 변경을 확인해 주세요'), findsNothing);
    },
  );

  testWidgets(
    'shortened hours show exact impact and require confirmation before POST',
    (tester) async {
      final data = fixture();
      for (var d = 1; d <= 7; d++) {
        data['workplace']['days']['$d'] = bands(['10:00', '16:00', '22:00']);
      }
      var posts = 0;
      await mount(tester, initialData: data, write: (_) => posts++);
      await tester.tap(find.text('개별'));
      await tester.pumpAndSettle();
      tester
          .widget<BusinessHoursSlider>(find.byType(BusinessHoursSlider))
          .onHours(600, 900);
      await tester.pumpAndSettle();
      await tester.tap(find.text('인원 배치').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('일주일 설정 저장'));
      await tester.pumpAndSettle();
      expect(posts, 0);
      expect(find.textContaining('10:00–16:00 / 16:00–22:00'), findsOneWidget);
      expect(find.textContaining('10:00–12:30 / 12:30–15:00'), findsOneWidget);
      await tester.tap(find.text('돌아가서 수정'));
      await tester.pumpAndSettle();
      expect(posts, 0);
      await tester.tap(find.text('일주일 설정 저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('변경 확인 후 저장'));
      await tester.pumpAndSettle();
      expect(posts, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new first-floor table keeps floor through coordinate size and seat edits',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = layoutSample();
      state['zones'] = <Json>[
        {
          'id': 'first',
          'kind': 'storage',
          'name': '1층 보관',
          'floor': '1층',
          'area': '후면',
          'photo': 'https://example.com/test.jpg',
          'description': '기존 위치 안내',
          'x': 0,
          'y': 0,
          'width': 1,
          'height': 1,
          'seats': 0,
        },
        {
          'id': 'second',
          'kind': 'storage',
          'name': '2층 보관',
          'floor': '2층',
          'description': '다른 층',
          'x': 0,
          'y': 0,
          'width': 1,
          'height': 1,
          'seats': 0,
        },
      ];
      Json? posted;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') posted = jsonDecode(r.body) as Json;
          return response(state);
        }),
      );
      addTearDown(ops.dispose);
      await openMap(tester, ops);
      await tapVisible(tester, find.widgetWithText(FilledButton, '배치 설정'));
      await tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, '테이블·기기 추가'),
      );
      await tester.enterText(find.widgetWithText(TextFormField, '이름'), '새 테이블');
      await tester.tap(find.text('배치에 적용'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('이름·크기·좌석 수정'));
      await tester.enterText(
        find.widgetWithText(TextFormField, '가로 위치 (칸)'),
        '5',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '가로 크기 (칸)'),
        '3',
      );
      await tester.enterText(find.widgetWithText(TextFormField, '좌석 수'), '6');
      await tester.tap(find.text('배치에 적용'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(ChoiceChip, '1층 보관'));
      await tapVisible(tester, find.text('이름·크기·좌석 수정'));
      await tester.enterText(
        find.widgetWithText(TextFormField, '이름'),
        '1층 보관 수정',
      );
      await tester.tap(find.text('배치에 적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-layout')));
      await tester.pumpAndSettle();
      expect(posted!['floorScope'], '1층');
      final zones = (posted!['zones'] as List).cast<Json>();
      final added = zones.singleWhere((z) => z['name'] == '새 테이블');
      expect(added['floor'], '1층');
      expect(added['x'], 4);
      expect(added['width'], 3);
      expect(added['seats'], 6);
      final existing = zones.singleWhere((z) => z['id'] == 'first');
      expect(existing['floor'], '1층');
      expect(existing['area'], '후면');
      expect(existing['photo'], 'https://example.com/test.jpg');
      expect(existing['description'], '기존 위치 안내');
      expect(zones.any((z) => z['id'] == 'second'), isFalse);
      expect(ops.rows('zones').last['floor'], '2층');
      expect(tester.takeException(), isNull);
    },
  );
}
