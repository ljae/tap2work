// Menu TAPs share a customer order group; each menu retains its own Small TAPs.
const active = new Set(['접수', '조리 중', '준비 완료']);
export function ensureOrderTaps(state, now) {
  let changed = false;
  if (state.orderCompositionVersion !== 2) {
    for (const task of state.tasks.filter(t => t.orderId && !t.archivedAt && !t.completedAt)) {
      const preparation = (task.steps ?? []).filter(step => step.sourceTemplateId);
      if (!preparation.length) continue;
      task.archivedPreparationSteps = [...(task.archivedPreparationSteps ?? []), ...preparation];
      task.steps = task.steps.filter(step => !step.sourceTemplateId);
    }
    state.orderCompositionVersion = 2; changed = true;
  }
  if (state.orderTapVersion !== 2) {
    const obsolete = new Set(['demo-bone-order', 'demo-spicy-order', 'demo-noodle-order']);
    state.taskTemplates = state.taskTemplates.filter(t => !obsolete.has(t.id));
    for (const task of state.tasks) if (obsolete.has(task.templateId) || (task.orderId && task.orderLineIndex == null)) {
      task.archivedAt ||= new Date(now).toISOString();
    }
    state.orderTapVersion = 2; changed = true;
  }
  for (const ticket of state.sales.tickets) {
    if (!active.has(ticket.status) || new Date(ticket.createdAt) > now) continue;
    for (const [index, line] of ticket.lines.entries()) {
      const existing = state.tasks.find(t => t.orderId === ticket.id && t.orderLineIndex === index && !t.archivedAt);
      if (existing) {
        if (existing.date !== state.day) { existing.originalDate ??= existing.date; existing.date = state.day; changed = true; }
        continue;
      }
      const old = state.tasks.find(t => t.orderId === ticket.id && t.orderLineIndex == null);
      const location = ticket.table || ticket.channel;
      const steps = [
        { id: 'order-check', title: '메뉴·수량 확인', manual: `${ticket.number} · ${location}\n${line.name} × ${line.quantity}\n주문표와 요청사항을 대조하세요.` },
        { id: 'cook-check', title: '준비분으로 주문 조리·완성 확인', manual: `${line.name} ${line.quantity}개에 필요한 사전 준비분을 확인하고 매장 승인 기준대로 마무리 조리하세요. 사전 준비 자체는 별도 Tap에서 진행합니다.`, tip: '수량·온도·시간은 매장 기준을 확인하세요.' },
        { id: 'handoff', title: '주문번호 대조·전달', manual: `${ticket.number} · ${location}의 다른 메뉴 준비 상태를 확인하고 함께 전달하세요.` },
      ];
      state.tasks.push({ id: `customer-${ticket.id}-menu-${index}`, orderId: ticket.id, orderLineIndex: index,
        menuId: line.menuId, menuQuantity: line.quantity, orderNumber: ticket.number,
        orderChannel: ticket.channel, orderTable: ticket.table, orderCreatedAt: ticket.createdAt,
        title: `${line.name} × ${line.quantity}`, folderId: 'order-work', slot: '피크', requiredRole: 'cook',
        zone: 'stove', kind: 'routine', date: state.day, dueAt: ticket.createdAt,
        boardStatus: old?.boardStatus ?? (ticket.status === '접수' ? 'todo' : 'processing'), completedAt: null, completedBy: null, steps });
      changed = true;
    }
  }
  return changed;
}
export function syncOrderFromTap(state, taskId) {
  const task = state.tasks.find(t => t.id === taskId);
  if (!task?.orderId) return;
  const ticket = state.sales.tickets.find(t => t.id === task.orderId);
  if (!ticket) return;
  const group = state.tasks.filter(t => t.orderId === task.orderId && !t.archivedAt);
  ticket.status = group.every(t => t.completedAt) ? '완료' : group.some(t => t.completedAt || t.boardStatus === 'processing') ? '조리 중' : '접수';
}
