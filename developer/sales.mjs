// Synthetic restaurant tickets, separate from supplier purchase orders.
const dayMs = 86400000;
const dateKR = value => new Date(new Date(value).getTime() + 9 * 3600000).toISOString().slice(0, 10);
export function seedSales(now) {
  // Sample menu of the 뼈찜 demo store. Prices are illustrative, not the real restaurant's price list.
  const menus = [
    { id: 'bowl', name: '산뼈찜 (소)', category: '뼈찜', price: 32000 },
    { id: 'pork', name: '화산뼈찜 (소) · 매운맛', category: '뼈찜', price: 33000 },
    { id: 'tomato', name: '산뼈찜 (중)', category: '뼈찜', price: 42000 },
    { id: 'soup', name: '뼈곰탕', category: '식사', price: 10000 },
    { id: 'salad', name: '뼈짬뽕', category: '식사', price: 11000 },
    { id: 'tea', name: '우동사리', category: '추가', price: 3000 },
    { id: 'water', name: '음료', category: '음료', price: 2000 },
    { id: 'special', name: '계란볶음밥', category: '추가', price: 4000 },
  ];
  const tickets = [];
  const midnight = new Date(`${dateKR(now)}T00:00:00+09:00`).getTime();
  for (let day = 6; day >= 0; day--) {
    for (let index = 0; index < 24; index++) {
      // Today's records never lie in the future, even when seeded before opening.
      const at = day === 0
        ? index > 18
          ? Math.max(midnight, new Date(now).getTime() - (24 - index) * 3 * 60000)
          : midnight + Math.floor((new Date(now).getTime() - midnight) * (index + 1) / 25)
        : midnight - day * dayMs + (11 * 60 + index * 20) * 60000;
      const menu = menus[(index + day) % 7];
      const status = day === 0 && index > 18 ? ['접수', '조리 중', '조리 중', '준비 완료', '접수'][index - 19] : index === 4 ? '취소' : '완료';
      const lines = [{ menuId: menu.id, name: menu.name, quantity: 1 + index % 3, unitPrice: menu.price, discountPerUnit: index % 9 === 0 ? 500 : 0, returnedQuantity: index === 8 ? 1 : 0 }];
      if (index % 2 === 0) lines.push({ menuId: 'tea', name: '우동사리', quantity: 1, unitPrice: 3000, discountPerUnit: 0, returnedQuantity: 0 });
      tickets.push({ id: `S-${day}-${index + 1}`, number: `${day === 0 ? '오늘' : day + '일전'}-${101 + index}`, createdAt: new Date(at).toISOString(), channel: ['매장', '포장', '배달'][index % 3], table: index % 3 === 0 ? `${1 + index % 6}번 테이블` : null, status, payment: index === 23 ? '미결제' : '결제', lines,
        ...(day === 0 && index === 20 ? { platform: '배달의민족', request: '수저 제외 (샘플 요청)' } : {}) });
    }
  }
  return { source: 'sample', seededAt: new Date(now).toISOString(), menus, tickets };
}

export function salesDashboard(sales, now, showMoney) {
  const today = dateKR(now);
  const reports = [];
  for (const days of [1, 7]) {
    const startDay = dateKR(new Date(`${today}T00:00:00+09:00`).getTime() - (days - 1) * dayMs);
    for (const channel of ['전체', '매장', '포장', '배달']) {
      const tickets = sales.tickets.filter(ticket => dateKR(ticket.createdAt) >= startDay && dateKR(ticket.createdAt) <= today && new Date(ticket.createdAt) <= new Date(now) && (channel === '전체' || ticket.channel === channel));
      const menus = sales.menus.map(menu => ({ id: menu.id, name: menu.name, category: menu.category, orderedQuantity: 0, soldQuantity: 0, pendingQuantity: 0, revenue: 0 }));
      const hours = Array.from({ length: 24 }, (_, hour) => ({ hour, count: 0, revenue: 0 }));
      const summary = { orderCount: 0, paidCount: 0, cancelledCount: 0, activeCount: 0, gross: 0, discount: 0, refund: 0, revenue: 0, average: 0 };
      const statuses = Object.fromEntries(['접수', '조리 중', '준비 완료', '완료', '취소'].map(status => [status, 0]));
      for (const ticket of tickets) {
        statuses[ticket.status]++;
        if (ticket.status === '취소') { summary.cancelledCount++; continue; }
        summary.orderCount++;
        const active = ['접수', '조리 중', '준비 완료'].includes(ticket.status);
        if (active) summary.activeCount++;
        const paid = ticket.payment === '결제';
        if (paid) summary.paidCount++;
        const hour = hours[new Date(new Date(ticket.createdAt).getTime() + 9 * 3600000).getUTCHours()];
        hour.count++;
        for (const line of ticket.lines) {
          let menu = menus.find(menu => menu.id === line.menuId);
          // Retain historical sales when a menu is removed from the current catalog.
          if (!menu) { menu = { id: line.menuId, name: line.name, category: '이전 메뉴', orderedQuantity: 0, soldQuantity: 0, pendingQuantity: 0, revenue: 0 }; menus.push(menu); }
          menu.orderedQuantity += line.quantity;
          if (active) menu.pendingQuantity += line.quantity;
          if (!paid) continue;
          const gross = line.unitPrice * line.quantity;
          const discount = line.discountPerUnit * line.quantity;
          const refund = (line.unitPrice - line.discountPerUnit) * line.returnedQuantity;
          const revenue = gross - discount - refund;
          menu.soldQuantity += line.quantity - line.returnedQuantity;
          menu.revenue += revenue;
          hour.revenue += revenue;
          summary.gross += gross; summary.discount += discount; summary.refund += refund; summary.revenue += revenue;
        }
      }
      summary.average = summary.paidCount ? Math.round(summary.revenue / summary.paidCount) : 0;
      if (!showMoney) {
        for (const field of ['gross', 'discount', 'refund', 'revenue', 'average', 'paidCount']) delete summary[field];
        for (const menu of menus) { delete menu.revenue; delete menu.soldQuantity; }
        for (const hour of hours) delete hour.revenue;
      }
      reports.push({ days, channel, startDay, endDay: today, summary, statuses, menus, hours });
    }
  }
  // Active tickets are not limited by the reporting period: yesterday's unfinished work remains visible.
  const queue = sales.tickets.filter(ticket => ['접수', '조리 중', '준비 완료'].includes(ticket.status) && new Date(ticket.createdAt) <= new Date(now)).sort((a, b) => a.createdAt.localeCompare(b.createdAt)).map(ticket => ({ id: ticket.id, number: ticket.number, channel: ticket.channel, table: ticket.table, platform: ticket.platform ?? null, request: ticket.request ?? null, status: ticket.status, createdAt: ticket.createdAt, elapsedMinutes: Math.floor((new Date(now) - new Date(ticket.createdAt)) / 60000), lines: ticket.lines.map(line => ({ menuId: line.menuId, name: line.name, quantity: line.quantity })) }));
  return { source: sales.source, seededAt: sales.seededAt, asOf: new Date(now).toISOString(), showMoney, reports, queue };
}
