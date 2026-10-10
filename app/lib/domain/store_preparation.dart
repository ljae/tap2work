import 'operations_repository.dart';
import 'part_schedule.dart';

/// Readiness hints are not access gates. Use the same dated, headcount-based
/// roster coverage as the schedule, not the existence of one assignment.
class StorePreparationStatus {
  StorePreparationStatus(Json data) {
    List<Json> rows(String key) => (data[key] as List? ?? []).cast<Json>();
    final days = data['workplace']?['days'] as Map? ?? {};
    hasHours = days.values.any((v) => v is List && v.isNotEmpty);
    final active = rows('tappers').where((p) => p['active'] == true).toList();
    hasCrew = active.any((p) => p['rank'] != 'owner');
    final activeIds = active.map((p) => p['id']).toSet();
    final day = DateTime.tryParse('${data['day']}');
    final parts = (data['workplace']?['parts'] as List? ?? [])
        .cast<Json>()
        .map(WorkPart.fromJson)
        .where((p) => !p.hidden)
        .toList();
    final coverage = day == null
        ? (needed: 0, covered: 0)
        : rosterCoverage(
            {
              ...data,
              'staffShifts': rows(
                'staffShifts',
              ).where((s) => activeIds.contains(s['tapperId'])).toList(),
            },
            day,
            parts,
          );
    neededMinutes = coverage.needed;
    coveredMinutes = coverage.covered;
    hasAssignments = coverage.covered > 0;
    hasManuals = rows('taskTemplates').any((t) => t['archivedAt'] == null);
    hasTodayTasks = rows('tasks').any((t) => t['archivedAt'] == null);
    menusToReview = rows('catalogMenus')
        .where(
          (m) =>
              m['archivedAt'] == null &&
              (m['setupNeedsReview'] == true ||
                  m['setupNeedsReview'] != false &&
                      (m['price'] as num? ?? 0) <= 0),
        )
        .length;
    inventoryToReview = rows('items')
        .where(
          (i) =>
              i['archivedAt'] == null &&
              (i['inventoryStatus'] != null
                  ? [
                      'quantity_unknown',
                      'policy_unknown',
                    ].contains(i['inventoryStatus'])
                  : i['setupNeedsReview'] == true ||
                        i['quantityNeedsConfirmation'] == true),
        )
        .length;
  }
  late final bool hasHours, hasCrew, hasAssignments, hasManuals, hasTodayTasks;
  late final int neededMinutes,
      coveredMinutes,
      menusToReview,
      inventoryToReview;
}
