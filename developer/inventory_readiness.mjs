// Legacy items with a known opening balance remain usable. Newly created and
// starter items explicitly need a physical count; counting does not validate
// their supplier/order policy or postpone the latest-order deadline.
export function inventoryReadiness(item) {
  const quantityConfirmed = Boolean(item.lastCheckedAt) ||
    (item.quantityNeedsConfirmation !== true && item.setupNeedsReview !== true);
  const policyConfirmed = item.setupNeedsReview !== true &&
    typeof item.unit === 'string' && Boolean(item.unit.trim()) &&
    typeof item.supplier === 'string' && Boolean(item.supplier.trim()) &&
    item.supplier !== '공급처 미설정' && Number(item.orderQuantity) > 0;
  const status = !quantityConfirmed ? 'quantity_unknown' :
    !policyConfirmed ? 'policy_unknown' :
    Number(item.quantity) <= Number(item.minimum) ? 'low' : 'sufficient';
  return { quantityConfirmed, policyConfirmed, inventoryStatus: status,
    orderReady: quantityConfirmed && policyConfirmed };
}
