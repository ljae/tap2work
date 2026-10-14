// Retire customer-order execution without deleting tickets, checks or stock history.
export function retireCustomerOrderWork(state, now) {
  let changed = false;
  const obsolete = new Set(['demo-bone-order', 'demo-spicy-order', 'demo-noodle-order']);
  for (const template of state.taskTemplates ?? []) {
    if (obsolete.has(template.id) && !template.archivedAt) {
      template.archivedAt = new Date(now).toISOString();
      template.archivedReason = 'customer_order_work_retired';
      changed = true;
    }
  }
  const folder = state.checklistFolders?.find(row => row.id === 'order-work');
  if (folder?.name === '주문처리') { folder.name = '주방 운영'; changed = true; }
  return changed;
}
