import 'part_schedule.dart';

/// Stable interval packing. A connected overlap group shares up to three lanes;
/// overflow assignments cycle through lanes zero, one and two without changing stored shifts.
Map<String, ({int lane, int count})> scheduleLayout(List<RosterSlot> slots) {
  final order = {for (var i = 0; i < slots.length; i++) slots[i].shiftId: i};
  final sorted = [...slots]
    ..sort((a, b) {
      final time = a.startMinute.compareTo(b.startMinute);
      return time != 0 ? time : order[a.shiftId]!.compareTo(order[b.shiftId]!);
    });
  final result = <String, ({int lane, int count})>{};
  var group = <RosterSlot>[];
  var end = -1;
  void flush() {
    final ends = <int>[];
    final lanes = <String, int>{};
    for (final slot in group) {
      var lane = ends.indexWhere((e) => e <= slot.startMinute);
      if (lane < 0) {
        lane = ends.length;
        ends.add(slot.endMinute);
      } else {
        ends[lane] = slot.endMinute;
      }
      lanes[slot.shiftId!] = lane % 3;
    }
    for (final slot in group) {
      result[slot.shiftId!] = (
        lane: lanes[slot.shiftId!]!,
        count: ends.length.clamp(1, 3),
      );
    }
  }

  for (final slot in sorted) {
    if (slot.startMinute >= end && group.isNotEmpty) {
      flush();
      group = [];
      end = -1;
    }
    group.add(slot);
    if (slot.endMinute > end) end = slot.endMinute;
  }
  flush();
  return result;
}
