// Menu TAPs share a customer order group; each menu retains its own Small TAPs.
const active = new Set(['접수', '조리 중', '준비 완료']);
export function ensureOrderTaps(state, now) {
  let changed = false;
  // The old standing packing checklist belongs to history. New packing work is
  // generated from each customer ticket so it cannot drift from the order.
  if ((state.orderCompositionVersion ?? 0) < 2) {
    for (const task of state.tasks.filter(t => t.orderId && !t.archivedAt && !t.completedAt)) {
      const preparation = (task.steps ?? []).filter(step => step.sourceTemplateId);
      if (!preparation.length) continue;
      task.archivedPreparationSteps = [...(task.archivedPreparationSteps ?? []), ...preparation];
      task.steps = task.steps.filter(step => !step.sourceTemplateId);
    }
    state.orderCompositionVersion = 2; changed = true;
  }
  if (state.orderCompositionVersion < 3) {
    for (const template of state.taskTemplates.filter(t => /(?:^|-)packing$/.test(t.id))) template.archivedAt ??= new Date(now).toISOString();
    for (const task of state.tasks.filter(t => /(?:^|-)packing$/.test(t.templateId ?? ''))) task.archivedAt ??= new Date(now).toISOString();
    state.orderCompositionVersion = 3; changed = true;
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
        if (existing.completedAt) {
          if (existing.date !== state.day) { existing.originalDate ??= existing.date; existing.date = state.day; changed = true; }
          continue;
        }
        const extra = channelSteps(ticket);
        for (const step of extra) if (!existing.steps.some(s => s.id === step.id)) {
          const handoffIndex = existing.steps.findIndex(s => s.id === 'handoff');
          existing.steps.splice(handoffIndex < 0 ? existing.steps.length : handoffIndex, 0, step);
          changed = true;
        }
        const obsolete = existing.steps.find(s => s.id === 'delivery-handoff');
        if (obsolete) {
          existing.archivedChannelSteps ??= [];
          existing.archivedChannelSteps.push(obsolete);
          const handoff = existing.steps.find(s => s.id === 'handoff');
          if (obsolete.completedAt && handoff && !handoff.completedAt) Object.assign(handoff, { completedAt: obsolete.completedAt, completedBy: obsolete.completedBy, completionSource: 'delivery_handoff_migration' });
          existing.steps = existing.steps.filter(s => s !== obsolete);
          changed = true;
        }
        const handoff = existing.steps.find(s => s.id === 'handoff');
        if (handoff && !handoff.completedAt && !handoff.manualHistory?.length && handoff.title === '주문번호 대조·전달') {
          const next = handoffStep(ticket);
          if (handoff.title !== next.title || handoff.manual !== next.manual) { Object.assign(handoff, next); changed = true; }
        }
        if (existing.orderChannel !== ticket.channel || (existing.orderPlatform ?? null) !== (ticket.platform ?? null) || (existing.customerRequest ?? null) !== (ticket.request ?? null)) {
          Object.assign(existing, { orderChannel: ticket.channel, orderPlatform: ticket.platform ?? null, customerRequest: ticket.request ?? null }); changed = true;
        }
        if (existing.date !== state.day) { existing.originalDate ??= existing.date; existing.date = state.day; changed = true; }
        continue;
      }
      const old = state.tasks.find(t => t.orderId === ticket.id && t.orderLineIndex == null);
      const location = ticket.table || ticket.channel;
      const steps = [
        { id: 'order-check', title: '메뉴·수량 확인', manual: `${ticket.number} · ${location}\n${line.name} × ${line.quantity}\n주문표와 요청사항을 대조하세요.` },
        { id: 'cook-check', title: '준비분으로 주문 조리·완성 확인', manual: `${line.name} ${line.quantity}개에 필요한 사전 준비분을 확인하고 매장 승인 기준대로 마무리 조리하세요. 사전 준비 자체는 별도 Tap에서 진행합니다.`, tip: '수량·온도·시간은 매장 기준을 확인하세요.' },
        ...channelSteps(ticket).filter(step => step.id === 'pack-check'),
        handoffStep(ticket),
      ];
      state.tasks.push({ id: `customer-${ticket.id}-menu-${index}`, orderId: ticket.id, orderLineIndex: index,
        menuId: line.menuId, menuQuantity: line.quantity, orderNumber: ticket.number,
        orderChannel: ticket.channel, orderTable: ticket.table, orderPlatform: ticket.platform ?? null, customerRequest: ticket.request ?? null, orderCreatedAt: ticket.createdAt,
        title: `${line.name} × ${line.quantity}`, folderId: 'order-work', slot: '피크', requiredRole: 'cook',
        zone: 'stove', kind: 'routine', date: state.day, dueAt: ticket.createdAt,
        boardStatus: old?.boardStatus ?? (ticket.status === '접수' ? 'todo' : 'processing'), completedAt: null, completedBy: null, steps });
      changed = true;
    }
  }
  return changed;
}
function channelSteps(ticket) {
  if (ticket.channel === '매장') return [];
  return [{ id: 'pack-check', title: '포장·구성품 확인', manual: `${ticket.number} 주문의 포장 상태와 구성품을 매장 기준으로 확인하세요.` }];
}
function handoffStep(ticket) {
  if (ticket.channel === '배달') return { id: 'handoff', title: '기사 전달·주문번호 확인', manual: `${ticket.number} · ${ticket.platform ?? '배달'} 주문번호와 요청사항을 대조한 뒤 기사에게 전달하세요.` };
  if (ticket.channel === '포장') return { id: 'handoff', title: '포장 주문번호 대조·전달', manual: `${ticket.number} 포장 구성품과 주문번호를 대조한 뒤 전달하세요.` };
  return { id: 'handoff', title: '주문번호 대조·전달', manual: `${ticket.number} · ${ticket.table ?? '매장'}의 다른 메뉴 준비 상태를 확인하고 함께 전달하세요.` };
}
export function syncOrderFromTap(state, taskId) {
  const task = state.tasks.find(t => t.id === taskId);
  if (!task?.orderId) return;
  const ticket = state.sales.tickets.find(t => t.id === task.orderId);
  if (!ticket) return;
  const group = state.tasks.filter(t => t.orderId === task.orderId && !t.archivedAt);
  ticket.status = group.every(t => t.completedAt) ? '완료' : group.some(t => t.completedAt || t.boardStatus === 'processing') ? '조리 중' : '접수';
}
