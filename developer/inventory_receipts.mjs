import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
import { checkWorkplacePermission } from './workplace.mjs';

const fail = (message, status = 400) => { throw new StoreError(message, status); };
const amount = value => {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0 || value > 100000) fail('수량은 0~100,000 사이로 입력해 주세요.');
  return value;
};
const clean = value => Number(value.toPrecision(15));
function authorize(state, actor) {
  if (!['owner', 'manager'].includes(actor.role)) fail('입고 확인 권한이 없어요.', 403);
  checkWorkplacePermission(state, actor, 'receive_order');
}
function requestBody(input) {
  if (typeof input.orderId !== 'string' || !input.orderId) fail('발주 내역을 선택해 주세요.');
  if (input.receiptId !== undefined && (typeof input.receiptId !== 'string' || !/^[a-zA-Z0-9-]{8,100}$/.test(input.receiptId))) fail('입고 요청 ID를 확인해 주세요.');
  if (input.lines === undefined) return JSON.stringify({orderId: input.orderId, lines: null});
  if (!Array.isArray(input.lines) || !input.lines.length || input.lines.length > 20) fail('입고할 재료를 선택해 주세요.');
  const lines = input.lines.map(line => {
    if (!line || typeof line.itemId !== 'string' || !line.itemId) fail('입고 항목을 확인해 주세요.');
    return {itemId: line.itemId, quantity: amount(line.quantity)};
  }).sort((a,b) => a.itemId.localeCompare(b.itemId));
  if (new Set(lines.map(line=>line.itemId)).size !== lines.length) fail('같은 재료가 중복되었어요.');
  return JSON.stringify({orderId: input.orderId, lines});
}

// Called after current permission checks but before revision comparison, so a
// committed request whose response was lost is safely replayable with its old revision.
export function receiptReplay(state, input, actor) {
  if (input.action !== 'receive_order' || input.receiptId === undefined) return false;
  authorize(state, actor);
  const fingerprint = requestBody(input);
  const receipt = (state.orders ?? []).flatMap(order => order.receiptHistory ?? []).find(row => row.id === input.receiptId);
  if (!receipt) return false;
  if (receipt.receivedBy.id !== actor.id || receipt.requestBody !== fingerprint) fail('같은 입고 요청의 내용이 달라요.', 409);
  return true;
}

export function receiveInventoryOrder(state, input, actor, now) {
  authorize(state, actor);
  const fingerprint = requestBody(input);
  if (receiptReplay(state, {...input, action: 'receive_order'}, actor)) return state.orders.find(order => order.id === input.orderId);
  const order = state.orders?.find(row => row.id === input.orderId);
  if (!order) fail('발주 내역이 없어요.', 404);
  if (order.status !== 'ordered') fail('이미 입고 확인된 발주예요.', 409);
  const requested = input.lines === undefined ? order.lines.map(line => ({itemId: line.itemId, quantity: clean(line.quantity - (line.receivedQuantity ?? 0))})) : input.lines;
  // Validate the entire batch before changing stock or receipt history.
  const changes = requested.map(line => {
    const ordered = order.lines.find(row => row.itemId === line.itemId);
    if (!ordered) fail('이 발주에 없는 재료예요.');
    const received = amount(ordered.receivedQuantity ?? 0);
    const remaining = clean(amount(ordered.quantity) - received);
    const quantity = amount(line.quantity);
    const tolerance = Number.EPSILON * Math.max(1, remaining, quantity) * 8;
    if (quantity - remaining > tolerance) fail('받은 수량이 남은 발주 수량보다 많아요.', 409);
    const increment = Math.min(quantity, remaining);
    const item = state.items.find(row => row.id === line.itemId && !row.archivedAt);
    if (!item) fail('사용 중인 재료를 찾지 못했어요.', 404);
    const nextQuantity = amount(clean(amount(item.quantity) + increment));
    return {ordered, item, quantity: increment, received: remaining - quantity <= tolerance ? ordered.quantity : clean(received + increment), nextQuantity};
  });
  if (!changes.some(change => change.quantity > 0)) fail('한 항목 이상 받은 수량을 입력해 주세요.');
  const receivedBy = {id: actor.id, name: actor.name, role: actor.label ?? actor.role};
  const receivedAt = new Date(now).toISOString();
  for (const change of changes) {
    change.ordered.receivedQuantity = change.received;
    change.item.quantity = change.nextQuantity;
  }
  order.receiptHistory ??= [];
  order.receiptHistory.push({id: input.receiptId ?? randomUUID(), requestBody: fingerprint, receivedBy, receivedAt,
    lines: changes.filter(change=>change.quantity>0).map(change=>({itemId:change.item.id, name:change.ordered.name, unit:change.ordered.unit, quantity:change.quantity}))});
  if (order.lines.every(line => (line.receivedQuantity ?? 0) >= line.quantity)) {
    order.status = 'received';
    order.receivedAt = receivedAt;
    order.receivedBy = receivedBy;
  }
  return order;
}
