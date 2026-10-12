import '../state/operations_controller.dart';

const manualCategoryIds = [
  'startup',
  'periodic',
  'routine',
  'recipe',
  'reference',
];

/// Finding a document is independent of the TAP's saved execution policy.
String manualCategoryOf(Json value) {
  if (value['menuManualId'] != null) return 'recipe';
  final override = value['manualCategoryOverride'];
  if (manualCategoryIds.contains(override)) return override as String;
  final projected = value['manualCategory'];
  if (manualCategoryIds.contains(projected)) return projected as String;
  final knowledge = value['knowledge'] as Map? ?? const {};
  final use = knowledge['useCase'];
  if (use == 'training') return 'reference';
  if (manualCategoryIds.contains(use)) return use as String;
  if ((knowledge['topics'] as List? ?? []).contains('recipe')) return 'recipe';
  if (value['kind'] == 'legal' || (knowledge['topics'] as List? ?? []).contains('compliance') && knowledge['suggestedUse'] == 'reference') {
    return 'startup';
  }
  if(value['sourceId']=='food/equipment') return 'periodic';
  if(value['sourceId']=='food/incident') return 'reference';
  final recurrence = value['settings']?['recurrence'];
  if (recurrence is Map && recurrence['mode'] != 'daily') return 'periodic';
  if (knowledge['suggestedUse'] == 'reference' ||
      value['settings']?['usage'] == 'reference') {
    return 'reference';
  }
  return 'routine';
}
