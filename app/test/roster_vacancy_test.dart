import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/domain/part_schedule.dart';
import 'calendar_test.dart' show calendarData;

void main() {
  const parts = [WorkPart('kitchen', '주방')];
  test('partial coverage yields only missing spans', () {
    final data = calendarData();
    data['staffShifts'] = [
      {
        'id': 'a',
        'tapperId': 'cook',
        'partId': 'kitchen',
        'date': '2026-09-28',
        'start': '10:00',
        'end': '12:00',
      },
    ];
    final slots = slotsForDay(data, DateTime(2026, 9, 28), parts);
    final gaps = slots.where((s) => s.crewId == null).toList();
    expect(gaps.map((s) => '${s.start}-${s.end}'), [
      '09:00-10:00',
      '12:00-14:00',
    ]);
    expect(gaps.every((s) => s.vacancy), isTrue);
    expect(slots.where((s) => s.crewId != null).length, 1);
    expect(data['rosterTemplates'][0]['end'], '14:00');
  });
  test('two required people cannot be covered twice by the same person', () {
    final data = calendarData();
    data['rosterTemplates'] = [
      for (final id in ['one', 'two'])
        {
          'id': id,
          'weekday': 1,
          'partId': 'kitchen',
          'start': '09:00',
          'end': '14:00',
        },
    ];
    data['staffShifts'] = [
      for (final id in ['a', 'duplicate'])
        {
          'id': id,
          'tapperId': 'cook',
          'partId': 'kitchen',
          'date': '2026-09-28',
          'start': '09:00',
          'end': '14:00',
        },
    ];
    final gaps = slotsForDay(
      data,
      DateTime(2026, 9, 28),
      parts,
    ).where((s) => s.crewId == null);
    expect(gaps.length, 1);
    final coverage = rosterCoverage(data, DateTime(2026, 9, 28), parts);
    expect(coverage.needed - coverage.covered, 300);
  });
  test('night coverage preserves actual gap date across business boundary', () {
    final data = calendarData();
    data['workplace'] = <String, dynamic>{
      ...data['workplace'],
      'businessDayStart': '04:00',
    };
    data['rosterTemplates'] = [
      {
        'id': 'night',
        'weekday': 1,
        'partId': 'kitchen',
        'start': '01:00',
        'end': '04:00',
      },
    ];
    data['staffShifts'] = [
      {
        'id': 'a',
        'tapperId': 'cook',
        'partId': 'kitchen',
        'date': '2026-09-28',
        'start': '23:00',
        'end': '02:00',
      },
    ];
    final gap = slotsForDay(
      data,
      DateTime(2026, 9, 28),
      parts,
    ).where((s) => s.crewId == null).single;
    expect(gap.start, '02:00');
    expect(gap.end, '04:00');
    expect(gap.actualDate, '2026-09-29');
  });
}
