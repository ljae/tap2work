import 'operations_repository.dart';

String rosterDate(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
int rosterMinute(String time) {
  final v = time.split(':').map(int.parse).toList();
  return v[0] * 60 + v[1];
}

String rosterClock(int minute) =>
    '${(minute ~/ 60 % 24).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

class WorkPart {
  const WorkPart(this.id, this.name, {this.hidden = false});
  final String id, name;
  final bool hidden;
  factory WorkPart.fromJson(Json json) =>
      WorkPart(json['id'], json['name'], hidden: json['hidden'] == true);
}

/// A generated requirement or a dated assignment. Original dates are retained
/// for overnight shifts; the grid extends into the following morning.
class RosterSlot {
  const RosterSlot({
    required this.date,
    required this.partId,
    required this.start,
    required this.end,
    required this.name,
    this.templateId,
    this.shiftId,
    this.crewId,
    this.adjusted = false,
  });
  final String date, partId, start, end, name;
  final String? templateId, shiftId, crewId;
  final bool adjusted;
  int get startMinute => rosterMinute(start);
  int get endMinute {
    final e = rosterMinute(end);
    return e <= startMinute ? e + 1440 : e;
  }

  bool get overnight => endMinute > 1440;
}

List<RosterSlot> slotsForDay(
  Json data,
  DateTime day,
  List<WorkPart> parts, {
  bool includeCovered = false,
}) {
  final date = rosterDate(day);
  final templates = (data['rosterTemplates'] as List? ?? []).cast<Json>();
  final overrides = (data['rosterOverrides'] as List? ?? [])
      .cast<Json>()
      .where((r) => r['date'] == date)
      .toList();
  final shifts = (data['staffShifts'] as List? ?? [])
      .cast<Json>()
      .where((r) => r['date'] == date && r['status'] != 'leave')
      .toList();
  final crew = (data['tappers'] as List? ?? []).cast<Json>();
  final result = <RosterSlot>[];
  final seen = <String>{};
  final matchedShifts = <String>{};
  for (final template in templates.where((t) => t['weekday'] == day.weekday)) {
    final override = overrides
        .where(
          (o) =>
              o['templateId'] == template['id'] &&
              o['partId'] == template['partId'],
        )
        .firstOrNull;
    final row = override ?? template;
    seen.add('${template['id']}/${template['partId']}');
    final match = shifts
        .where(
          (s) =>
              !matchedShifts.contains(s['id']) &&
              s['partId'] == row['partId'] &&
              s['start'] == row['start'] &&
              s['end'] == row['end'],
        )
        .firstOrNull;
    if (match != null) matchedShifts.add(match['id']);
    if (includeCovered || match == null) {
      result.add(
        RosterSlot(
          date: date,
          partId: row['partId'],
          start: row['start'],
          end: row['end'],
          name: row['name'] ?? '영업 시간대',
          templateId: template['id'],
          adjusted: override != null,
        ),
      );
    }
  }
  // A later hours change must not silently discard a date-specific adjustment.
  for (final row in overrides.where(
    (r) => !seen.contains('${r['templateId']}/${r['partId']}'),
  )) {
    result.add(
      RosterSlot(
        date: date,
        partId: row['partId'],
        start: row['start'],
        end: row['end'],
        name: row['name'] ?? '조정한 슬롯',
        templateId: row['templateId'],
        adjusted: true,
      ),
    );
  }
  for (final row in shifts) {
    final person = crew.where((p) => p['id'] == row['tapperId']).firstOrNull;
    final part =
        row['partId'] as String? ??
        (row['duty'] == '조리'
            ? 'kitchen'
            : row['duty'] == 'cashier'
            ? 'management'
            : 'hall');
    result.add(
      RosterSlot(
        date: date,
        partId: part,
        start: row['start'],
        end: row['end'],
        name: person?['nickname'] ?? '크루',
        shiftId: row['id'],
        crewId: row['tapperId'],
      ),
    );
  }
  return result.where((r) => parts.any((p) => p.id == r.partId)).toList();
}

/// Count a crew member at most once per half hour, even across two parts or
/// requirements. This also counts a prior day's overnight shift correctly.
({int needed, int covered}) rosterCoverage(
  Json data,
  DateTime monday,
  List<WorkPart> parts,
) {
  var needed = 0, covered = 0;
  final shifts = (data['staffShifts'] as List? ?? [])
      .cast<Json>()
      .where((s) => s['status'] != 'leave')
      .toList();
  final used = <String>{};
  for (var d = 0; d < 7; d++) {
    final day = monday.add(Duration(days: d));
    for (final slot in slotsForDay(
      data,
      day,
      parts,
      includeCovered: true,
    ).where((s) => s.crewId == null)) {
      for (
        var minute = slot.startMinute;
        minute < slot.endMinute;
        minute += 30
      ) {
        needed += 30;
        final at = DateTime.parse(
          '${slot.date}T00:00:00+09:00',
        ).add(Duration(minutes: minute));
        for (final shift in shifts) {
          final part =
              shift['partId'] ??
              (shift['duty'] == '조리'
                  ? 'kitchen'
                  : shift['duty'] == 'cashier'
                  ? 'management'
                  : 'hall');
          final key = '${shift['tapperId']}/${at.millisecondsSinceEpoch}';
          if (part != slot.partId || used.contains(key)) continue;
          final start = DateTime.parse(
            '${shift['date']}T${shift['start']}:00+09:00',
          );
          var end = DateTime.parse('${shift['date']}T${shift['end']}:00+09:00');
          if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
          if (!start.isAfter(at) &&
              !end.isBefore(at.add(const Duration(minutes: 30)))) {
            used.add(key);
            covered += 30;
            break;
          }
        }
      }
    }
  }
  return (needed: needed, covered: covered);
}
