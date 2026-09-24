// Menu TAPs share a customer order group; each menu retains its own Small TAPs.
const active = new Set(['접수', '조리 중', '준비 완료']);
export function ensureOrderTaps(state, now) {
  let changed = false;
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
      const preparation = !/뼈|짬뽕/.test(line.name) ? [] : state.taskTemplates.filter(t => t.folderId === (line.name.includes('짬뽕') ? 'noodle-preparation' : 'bone-preparation'));
      const steps = [
        { id: 'order-check', title: '메뉴·수량 확인', manual: `${ticket.number} · ${location}\n${line.name} × ${line.quantity}\n주문표와 요청사항을 대조하세요.` },
        ...preparation.flatMap(t => t.steps.map(s => ({ ...s, id: `${t.id}-${s.id}`, sourceTemplateId: t.id, sourceStepId: s.id }))),
        { id: 'cook-check', title: '매장 레시피로 조리·완성 확인', manual: `${line.name} ${line.quantity}개를 매장 승인 레시피로 조리하세요. 재료 중량·가열 온도·시간·담음새는 사장님이 보드 편집에서 등록한 매뉴얼을 확인하세요. 미등록 기준은 담당자에게 확인하세요.`, tip: '샘플 준비 절차는 매장 검수 전 제안입니다.' },
        { id: 'handoff', title: '주문번호 대조·전달', manual: `${ticket.number} · ${location}의 다른 메뉴 준비 상태를 확인하고 함께 전달하세요.` },
      ];
      state.tasks.push({ id: `customer-${ticket.id}-menu-${index}`, orderId: ticket.id, orderLineIndex: index, orderNumber: ticket.number,
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
