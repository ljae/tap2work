// Customer-order work is derived from the same synthetic tickets as Home.
const active = new Set(['접수', '조리 중', '준비 완료']);
export function ensureOrderTaps(state, now) {
  let changed = false;
  if (!state.orderTapVersion) {
    const obsolete = new Set(['demo-bone-order', 'demo-spicy-order', 'demo-noodle-order']);
    state.taskTemplates = state.taskTemplates.filter(t => !obsolete.has(t.id));
    for (const task of state.tasks) if (obsolete.has(task.templateId) && !task.completedAt) {
      task.archivedAt = new Date(now).toISOString();
    }
    state.orderTapVersion = 1; changed = true;
  }
  for (const ticket of state.sales.tickets) {
    if (!active.has(ticket.status) || new Date(ticket.createdAt) > now) continue;
    const existing = state.tasks.find(t => t.orderId === ticket.id);
    if (existing) {
      if (!existing.completedAt && existing.date !== state.day) { existing.date = state.day; changed = true; }
      continue;
    }
    const items = ticket.lines.map(l => `${l.name} × ${l.quantity}`).join(', ');
    const location = ticket.table || ticket.channel;
    const steps = [
      ['주문표 확인', `${ticket.number} · ${location}\n${items}\n메뉴·수량과 고객 요청을 주문표로 대조하세요.`],
      ['재료와 조리 준비', '각 메뉴에 필요한 준비분과 도구를 확인하세요. 조리량·온도·시간은 매장에서 승인한 기준을 따르세요.'],
      ['조리와 완성 확인', `${items}\n담당자가 조리 상태와 담음새를 확인하세요.`],
      ['대조 후 전달', `${location}에 전달하기 전 본품·추가품·수량을 다시 확인하세요. 포장/배달은 포장 상태와 주문번호도 대조하세요.`],
    ];
    state.tasks.push({ id: `customer-${ticket.id}`, orderId: ticket.id, orderNumber: ticket.number,
      orderChannel: ticket.channel, orderTable: ticket.table, orderCreatedAt: ticket.createdAt,
      title: `${ticket.number} · ${items}`, folderId: 'order-work', slot: '피크', requiredRole: 'cook',
      zone: 'stove', kind: 'routine', date: state.day, dueAt: ticket.createdAt,
      boardStatus: ticket.status === '접수' ? 'todo' : 'processing', completedAt: null, completedBy: null,
      steps: steps.map(([title, manual], i) => ({ id: `order-step-${i+1}`, title, manual, tip: '홈의 가상 주문과 연결된 업무입니다.' })) });
    changed = true;
  }
  return changed;
}
export function syncOrderFromTap(state, taskId) {
  const task = state.tasks.find(t => t.id === taskId);
  if (!task?.orderId) return;
  const ticket = state.sales.tickets.find(t => t.id === task.orderId);
  if (!ticket) return;
  ticket.status = task.completedAt ? '완료' : task.boardStatus === 'processing' ? '조리 중' : '접수';
}
