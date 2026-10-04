import 'dart:convert';
import 'part_schedule.dart';
import 'operations_repository.dart';

Json copyAllocation(Json value) => jsonDecode(jsonEncode(value)) as Json;
Map<String, Json> copyPatterns(Map<String, Json> value) => {
  for (final e in value.entries) e.key: copyAllocation(e.value),
};

/// Calculations use integer minutes without assuming a 30-minute grid.
/// The current server contract still accepts 30-minute times; a future editor
/// can provide 5-minute values without changing totals, overlaps or cards.
class AllocationInterval {
  const AllocationInterval(this.start, this.end);
  final int start, end;
  int get minutes => end - start;
  bool overlaps(AllocationInterval other) =>
      start < other.end && other.start < end;
  factory AllocationInterval.clock(
    String start,
    String end,
    int boundary, {
    int day = 0,
  }) {
    var a = rosterMinute(start), b = rosterMinute(end);
    if (a < boundary) a += 1440;
    if (b <= a) b += 1440;
    return AllocationInterval(day * 1440 + a, day * 1440 + b);
  }
}

class AllocationTarget {
  const AllocationTarget({
    required this.day,
    required this.band,
    required this.partId,
  });
  final int day;
  final Json band;
  final String partId;
  String get start => band['partTimes']?[partId]?['start'] ?? band['start'];
  String get end => band['partTimes']?[partId]?['end'] ?? band['end'];
  int get capacity =>
      band['headcounts']?[partId] ?? (band['custom'] == true ? 0 : 1);
  bool matches(Json entry) =>
      entry['weekday'] == day &&
      entry['partId'] == partId &&
      entry['start'] == start &&
      entry['end'] == end &&
      (entry['timeBandId'] == null || entry['timeBandId'] == band['id']);
  Json entry(int week) => {
    'week': week,
    'weekday': day,
    'partId': partId,
    if (band['id'] != null) 'timeBandId': band['id'],
    'start': start,
    'end': end,
  };
}

class AllocationGroup {
  AllocationGroup(this.id, this.name);
  final String id, name;
  final List<AllocationTarget> targets = [];
  String get timeLabel {
    final times = {for (final t in targets) '${t.start}–${t.end}'};
    return times.length == 1 ? times.first : '요일·파트별 시간';
  }
}

class AllocationPlan {
  const AllocationPlan(this.patterns, [this.error]);
  final Map<String, Json> patterns;
  final String? error;
  bool get valid => error == null;
}

class AllocationSuggestion {
  const AllocationSuggestion(this.patterns, this.proposed, this.skipped);
  final Map<String, Json> patterns;
  final int proposed, skipped;
}

class CrewHoursSummary {
  const CrewHoursSummary(this.minutes);
  final int minutes;
  // These are planning references, never an entitlement or payroll verdict.
  bool get restReference => minutes >= 15 * 60;
  bool get overtimeReference => minutes >= 36 * 60;
  String get hours => minutes % 60 == 0
      ? '${minutes ~/ 60}'
      : (minutes / 60).toStringAsFixed(1);
  String get label => '$hours/15h';
  String? get hint => overtimeReference
      ? '주 40h 근접·초과 확인'
      : restReference
      ? '주 15h 이상 · 주휴 조건 확인'
      : null;
}

class CrewAllocationPlanner {
  CrewAllocationPlanner({
    required this.workplace,
    required this.people,
    required this.monday,
  });
  final Json workplace;
  final List<Json> people;
  final DateTime monday;
  int get boundary => rosterMinute(workplace['businessDayStart'] ?? '00:00');
  List<Json> get parts => (workplace['parts'] as List? ?? [])
      .cast<Json>()
      .where((p) => p['hidden'] != true)
      .toList();
  List<Json> bands(int day) =>
      (workplace['days']?['$day'] as List? ?? []).cast<Json>();
  Set<int> get openDays => {
    for (var d = 1; d <= 7; d++)
      if (bands(d).isNotEmpty) d,
  };
  int weekOf(Json pattern) =>
      ((monday.difference(DateTime.parse(pattern['anchor'])).inDays) / 7)
          .floor() %
      (pattern['cycleWeeks'] as int);
  List<Json> entries(Json pattern) => (pattern['entries'] as List).cast<Json>();
  List<Json> current(Json pattern) =>
      entries(pattern).where((e) => e['week'] == weekOf(pattern)).toList();
  List<AllocationGroup> groups(Set<int> days) {
    final result = <String, AllocationGroup>{};
    for (final d in days.toList()..sort()) {
      final rows = bands(d);
      final normals = rows.where((b) => b['custom'] != true).toList();
      for (final b in rows) {
        final i = normals.indexOf(b);
        final role = i == 0
            ? '오픈'
            : i == normals.length - 1
            ? '마감'
            : '미들';
        final key = b['custom'] == true ? 'custom-${b['id']}' : 'normal-$role';
        final group = result.putIfAbsent(
          key,
          () => AllocationGroup(key, b['custom'] == true ? b['name'] : role),
        );
        for (final part in parts) {
          final target = AllocationTarget(day: d, band: b, partId: part['id']);
          if (target.capacity > 0) group.targets.add(target);
        }
      }
    }
    final groups = result.values.where((g) => g.targets.isNotEmpty).toList();
    const order = ['normal-오픈', 'normal-미들', 'normal-마감'];
    groups.sort((a, b) {
      final ai = order.indexOf(a.id), bi = order.indexOf(b.id);
      return (ai < 0 ? 3 : ai).compareTo(bi < 0 ? 3 : bi);
    });
    return groups;
  }

  List<String> assigned(Map<String, Json> patterns, AllocationTarget t) => [
    for (final e in patterns.entries)
      if (current(e.value).any(t.matches)) e.key,
  ];
  Map<String, Set<int>> members(
    Map<String, Json> patterns,
    List<AllocationTarget> targets,
  ) {
    final result = <String, Set<int>>{};
    for (final t in targets) {
      for (final id in assigned(patterns, t)) {
        result.putIfAbsent(id, () => {}).add(t.day);
      }
    }
    return result;
  }

  String? validate(Json pattern) {
    if (entries(pattern).length > 28) return '한 크루의 기본 배정은 최대 28개예요.';
    final spans = <AllocationInterval>[];
    final cycle = pattern['cycleWeeks'] as int;
    for (var w = 0; w < cycle * 2 + 1; w++) {
      for (final e in entries(pattern).where((e) => e['week'] == w % cycle)) {
        final span = AllocationInterval.clock(
          e['start'],
          e['end'],
          boundary,
          day: w * 7 + (e['weekday'] as int) - 1,
        );
        if (span.minutes <= 0 || span.minutes >= 1440) return '근무 시간을 확인해 주세요.';
        if (spans.any(span.overlaps)) return '선택한 요일에 겹치는 근무가 있어요.';
        spans.add(span);
      }
    }
    return null;
  }

  AllocationPlan assign(
    Map<String, Json> patterns,
    String id,
    List<AllocationTarget> targets,
  ) {
    final next = copyPatterns(patterns);
    final person = people
        .where((p) => p['id'] == id && p['active'] != false)
        .firstOrNull;
    if (person == null || next[id] == null || targets.isEmpty) {
      return AllocationPlan(patterns, '배정할 크루와 요일을 확인해 주세요.');
    }
    final allowed = person['workProfile']?['partIds'] as List? ?? [];
    for (final t in targets) {
      if (allowed.isNotEmpty && !allowed.contains(t.partId)) {
        return AllocationPlan(patterns, '담당 파트가 맞지 않아요.');
      }
      if (current(next[id]!).any(t.matches)) continue;
      // Count occurrences, including old duplicate rows, before consuming a seat.
      final occupied = next.values.expand(current).where(t.matches).length;
      if (occupied >= t.capacity) {
        return AllocationPlan(patterns, '일부 요일의 필요 인원이 이미 채워졌어요.');
      }
      (next[id]!['entries'] as List).add(t.entry(weekOf(next[id]!)));
    }
    final error = validate(next[id]!);
    return error == null
        ? AllocationPlan(next)
        : AllocationPlan(patterns, error);
  }

  Map<String, Json> remove(
    Map<String, Json> patterns,
    String id,
    List<AllocationTarget> targets,
  ) {
    final next = copyPatterns(patterns), pattern = next[id]!;
    (pattern['entries'] as List).removeWhere(
      (e) => e['week'] == weekOf(pattern) && targets.any((t) => t.matches(e)),
    );
    return next;
  }

  CrewHoursSummary summary(Json pattern) {
    final spans = <AllocationInterval>[];
    final cycle = pattern['cycleWeeks'] as int;
    for (var offset = -1; offset <= 0; offset++) {
      for (final e in entries(
        pattern,
      ).where((e) => e['week'] == (weekOf(pattern) + offset) % cycle)) {
        final span = AllocationInterval.clock(
          e['start'],
          e['end'],
          boundary,
          day: offset * 7 + (e['weekday'] as int) - 1,
        );
        final a = span.start.clamp(boundary, 7 * 1440 + boundary),
            b = span.end.clamp(boundary, 7 * 1440 + boundary);
        if (b > a) spans.add(AllocationInterval(a, b));
      }
    }
    spans.sort((a, b) => a.start.compareTo(b.start));
    var total = 0, end = boundary;
    for (final span in spans) {
      if (span.end > end) {
        total += span.end - (span.start > end ? span.start : end);
        end = span.end;
      }
    }
    return CrewHoursSummary(total);
  }

  List<({String id, Json entry})> unmatched(
    Map<String, Json> patterns,
    Set<int> days,
  ) {
    final targets = groups(days).expand((g) => g.targets).toList();
    return [
      for (final p in patterns.entries)
        for (final e in current(p.value))
          if (days.contains(e['weekday']) && !targets.any((t) => t.matches(e)))
            (id: p.key, entry: e),
    ];
  }

  AllocationSuggestion suggest(
    Map<String, Json> draft,
    Map<String, Json> saved,
    Set<int> days,
  ) {
    // Only selected weekdays in the displayed A/B week are replaced by preview.
    var next = copyPatterns(draft);
    for (final p in next.values) {
      (p['entries'] as List).removeWhere(
        (e) => e['week'] == weekOf(p) && days.contains(e['weekday']),
      );
    }
    var proposed = 0, skipped = 0;
    final targets = groups(days).expand((g) => g.targets).toList();
    for (final p in saved.entries) {
      if (!next.containsKey(p.key)) continue;
      final source = (p.value['previous'] as Json?) ?? p.value;
      for (final e in current(
        source,
      ).where((e) => days.contains(e['weekday']))) {
        final candidates = targets
            .where((t) => t.day == e['weekday'] && t.partId == e['partId'])
            .toList();
        var target = candidates
            .where((t) => t.band['id'] == e['timeBandId'])
            .firstOrNull;
        // Without an ID match only an exact old time is safe to reuse.
        target ??= candidates
            .where((t) => t.start == e['start'] && t.end == e['end'])
            .firstOrNull;
        if (target == null) {
          skipped++;
          continue;
        }
        if (current(next[p.key]!).any(target.matches)) {
          skipped++;
          continue;
        }
        final plan = assign(next, p.key, [target]);
        if (!plan.valid) {
          skipped++;
          continue;
        }
        next = plan.patterns;
        proposed++;
      }
    }
    return AllocationSuggestion(next, proposed, skipped);
  }
}
