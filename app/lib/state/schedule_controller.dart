import 'package:flutter/foundation.dart';
import '../domain/part_schedule.dart';
import 'operations_controller.dart';

/// Presentation state only. Server state and optimistic revisions stay in the
/// operations repository; rebuilding the screen never creates assignments.
class ScheduleController extends ChangeNotifier {
  ScheduleController(this.operations) {
    selected =
        DateTime.tryParse(operations.data?['day'] ?? '') ?? DateTime.now();
    operations.addListener(_changed);
  }
  final OperationsController operations;
  late DateTime selected;
  String? partId;
  bool month = false;
  DateTime get monday => DateTime(
    selected.year,
    selected.month,
    selected.day,
  ).subtract(Duration(days: selected.weekday - 1));
  List<WorkPart> get parts {
    final rows =
        (operations.data?['workplace']?['parts'] as List? ??
                [
                  {'id': 'kitchen', 'name': '주방'},
                  {'id': 'hall', 'name': '홀'},
                  {'id': 'management', 'name': '관리'},
                ])
            .cast<Json>();
    final active = rows
        .map(WorkPart.fromJson)
        .where(
          (p) =>
              !p.hidden ||
              operations.rows('staffShifts').any((s) => s['partId'] == p.id),
        )
        .toList();
    return active;
  }

  List<WorkPart> get visibleParts =>
      parts.where((p) => partId == null || p.id == partId).toList();
  List<RosterSlot> slots(DateTime day) =>
      slotsForDay(operations.data ?? {}, day, visibleParts)
          .where(
            (s) =>
                s.crewId != null &&
                (operations.isLeader ||
                    operations
                        .rows('tappers')
                        .any(
                          (p) =>
                              p['id'] == s.crewId &&
                              p['actorId'] == operations.actorId,
                        )),
          )
          .toList();
  bool isPast(DateTime day) {
    final today =
        DateTime.tryParse(operations.data?['day'] ?? '') ??
        DateTime.now().toUtc().add(const Duration(hours: 9));
    return rosterDate(day).compareTo(rosterDate(today)) < 0;
  }

  bool get history => isPast(selected);
  bool get editable =>
      !history &&
      operations.isLeader &&
      operations.data?['canEditSchedule'] != false &&
      !operations.readOnly &&
      !operations.busy;
  void selectPart(String? id) {
    partId = id;
    notifyListeners();
  }

  void move(int amount) {
    selected = month
        ? DateTime(selected.year, selected.month + amount, 1)
        : selected.add(Duration(days: amount * 7));
    notifyListeners();
  }

  void selectDay(DateTime day) {
    selected = day;
    month = false;
    notifyListeners();
  }

  void setMonth(bool value) {
    month = value;
    notifyListeners();
  }

  void _changed() => notifyListeners();
  @override
  void dispose() {
    operations.removeListener(_changed);
    super.dispose();
  }
}
