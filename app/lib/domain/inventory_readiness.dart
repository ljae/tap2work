import 'operations_repository.dart';

class InventoryReadiness {
  InventoryReadiness(Json item)
    : quantityConfirmed =
          item['lastCheckedAt'] != null ||
          (item['quantityNeedsConfirmation'] != true &&
              item['setupNeedsReview'] != true),
      policyConfirmed =
          item['setupNeedsReview'] != true &&
          '${item['unit'] ?? ''}'.trim().isNotEmpty &&
          '${item['supplier'] ?? ''}'.trim().isNotEmpty &&
          item['supplier'] != '공급처 미설정' &&
          (item['orderQuantity'] as num? ?? 0) > 0,
      quantity = item['quantity'] as num? ?? 0,
      minimum = item['minimum'] as num? ?? 0;
  final bool quantityConfirmed, policyConfirmed;
  final num quantity, minimum;
  bool get orderReady => quantityConfirmed && policyConfirmed;
  String get status => !quantityConfirmed
      ? 'quantity_unknown'
      : !policyConfirmed
      ? 'policy_unknown'
      : quantity <= minimum
      ? 'low'
      : 'sufficient';
}
