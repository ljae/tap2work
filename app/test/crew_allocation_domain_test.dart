import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/domain/crew_allocation.dart';
import 'package:tap2work/domain/operations_repository.dart';

void main() {
  Json pattern([List<Json> entries = const []]) => {
    'tapperId': 'a',
    'anchor': '2026-09-28',
    'cycleWeeks': 1,
    'entries': entries,
  };
  final workplace = <String, dynamic>{
    'parts': [
      {'id': 'kitchen', 'name': '주방'},
      {'id': 'hall', 'name': '홀'},
    ],
    'days': {
      for (var d = 1; d <= 6; d++)
        '$d': [
          {
            'id': 'day-$d',
            'start': '09:00',
            'end': '14:00',
            'headcounts': {'kitchen': 1, 'hall': 1},
          },
        ],
      '7': <Json>[],
    },
  };
  CrewAllocationPlanner planner({Json? place}) => CrewAllocationPlanner(
    workplace: place ?? workplace,
    people: [
      {
        'id': 'a',
        'workProfile': {
          'partIds': ['kitchen'],
        },
      },
      {'id': 'b'},
    ],
    monday: DateTime(2026, 9, 28),
  );
  List<AllocationTarget> targets(CrewAllocationPlanner p, Set<int> days) => p
      .groups(days)
      .expand((g) => g.targets)
      .where((t) => t.partId == 'kitchen')
      .toList();
  test(
    'multi-day batch is atomic with capacity, role and overlapping shifts',
    () {
      final p = planner();
      final draft = {'a': pattern(), 'b': pattern()};
      var plan = p.assign(draft, 'a', targets(p, {1, 3}));
      expect(plan.valid, true);
      expect(p.current(plan.patterns['a']!).map((e) => e['weekday']), [1, 3]);
      expect(p.summary(plan.patterns['a']!).minutes, 600);
      expect(p.current(draft['a']!), isEmpty);
      expect(p.assign(plan.patterns, 'b', targets(p, {2, 3})).valid, false);
      expect(p.current(plan.patterns['b']!), isEmpty);
      expect(
        p
            .assign(
              draft,
              'a',
              p
                  .groups({1})
                  .first
                  .targets
                  .where((t) => t.partId == 'hall')
                  .toList(),
            )
            .valid,
        false,
      );
      final overlap = {
        'a': pattern([
          {
            'week': 0,
            'weekday': 3,
            'partId': 'hall',
            'start': '12:00',
            'end': '16:00',
          },
        ]),
      };
      expect(p.assign(overlap, 'a', targets(p, {1, 3})).valid, false);
      expect(p.current(overlap['a']!), hasLength(1));
    },
  );
  test(
    'repeated assignment is idempotent and removal preserves other weekdays',
    () {
      final p = planner();
      final first = p
          .assign({'a': pattern()}, 'a', targets(p, {1, 2}))
          .patterns;
      final twice = p.assign(first, 'a', targets(p, {1, 2})).patterns;
      expect(p.current(twice['a']!), hasLength(2));
      expect(
        p
            .current(p.remove(twice, 'a', targets(p, {1}))['a']!)
            .single['weekday'],
        2,
      );
    },
  );
  test(
    'minute totals merge overlaps and support future five-minute intervals',
    () {
      final p = planner();
      final value = pattern([
        {'week': 0, 'weekday': 1, 'start': '09:05', 'end': '10:10'},
        {'week': 0, 'weekday': 1, 'start': '09:30', 'end': '11:05'},
      ]);
      expect(p.summary(value).minutes, 120);
      expect(const CrewHoursSummary(900).restReference, true);
      expect(const CrewHoursSummary(2155).overtimeReference, false);
      expect(const CrewHoursSummary(2160).overtimeReference, true);
    },
  );
  test('overnight cycle collision and previous-week carry are handled', () {
    final p = planner();
    final value = pattern([
      {'week': 0, 'weekday': 7, 'start': '23:00', 'end': '02:00'},
      {'week': 0, 'weekday': 1, 'start': '01:00', 'end': '03:00'},
    ]);
    expect(p.validate(value), isNotNull);
    expect(p.summary(value).minutes, 240);
    final ab = pattern()
      ..['cycleWeeks'] = 2
      ..['anchor'] = '2026-10-05';
    expect(p.weekOf(ab), 1);
  });
  test(
    'ghost uses prior saved schedule, preserves unselected days and rejects obsolete slots',
    () {
      final p = planner();
      final draft = p.assign({'a': pattern()}, 'a', targets(p, {2})).patterns;
      final previous = p
          .assign({'a': pattern()}, 'a', targets(p, {1}))
          .patterns['a']!;
      final saved = {'a': pattern()..['previous'] = previous};
      final suggestion = p.suggest(draft, saved, {1});
      expect(suggestion.proposed, 1);
      expect(suggestion.skipped, 0);
      expect(p.current(suggestion.patterns['a']!).map((e) => e['weekday']), [
        2,
        1,
      ]);
      expect(p.current(draft['a']!).map((e) => e['weekday']), [2]);
      previous['entries'][0]['partId'] = 'removed';
      expect(p.suggest(draft, saved, {1}).skipped, 1);
    },
  );
}
