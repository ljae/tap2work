/// Actual clock events only: planned shifts never become attendance.
class AttendanceSession {
  AttendanceSession(this.crewId, this.events);
  final String crewId;
  final List<Map<String, dynamic>> events;
  DateTime get day => koreanAttendanceTime(events.first['at'] as String);
  bool get hasClockIn => events.any((e) => e['type'] == 'clock_in');
  bool get hasClockOut => events.any((e) => e['type'] == 'clock_out');
}

DateTime koreanAttendanceTime(String value) =>
    DateTime.parse(value).toUtc().add(const Duration(hours: 9));

List<AttendanceSession> attendanceSessions(List<Map<String, dynamic>> records) {
  final events =
      records
          .where(
            (e) =>
                e['voidedAt'] == null &&
                e['tapperId'] is String &&
                e['at'] is String &&
                DateTime.tryParse(e['at']) != null &&
                const [
                  'clock_in',
                  'clock_out',
                  'break_start',
                  'break_end',
                ].contains(e['type']),
          )
          .toList()
        ..sort(
          (a, b) => DateTime.parse(a['at']).compareTo(DateTime.parse(b['at'])),
        );
  final result = <AttendanceSession>[];
  final open = <String, AttendanceSession>{};
  for (final event in events) {
    final crew = event['tapperId'] as String;
    if (event['type'] == 'clock_in' || open[crew] == null) {
      final session = AttendanceSession(crew, []);
      result.add(session);
      open[crew] = session;
    }
    open[crew]!.events.add(event);
    if (event['type'] == 'clock_out') open.remove(crew);
  }
  return result;
}
