import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';

const fail = (message, status = 400) => { throw new StoreError(message, status); };
const positive = (value, label) => {
  if (!Number.isSafeInteger(value) || value < 1 || value > 100000) fail(`${label}은 1~100,000 사이의 정수로 입력해 주세요.`);
  return value;
};
const nonnegative = (value, label) => {
  if (!Number.isSafeInteger(value) || value < 0 || value > 100000) fail(`${label}은 0~100,000 사이의 정수로 입력해 주세요.`);
  return value;
};
const label = (value, field) => {
  if (typeof value !== 'string' || !value.trim() || value.length > 60) fail(`${field}을 확인해 주세요.`);
  return value.trim();
};

// Prepared portions are operational output, separate from supplier inventory.
export function ensurePreparedItems(state, now) {
  if (state.preparedVersion === 1) return false;
  state.preparedItems ??= [{ id: 'prepared-bone', name: '뼈찜 준비분', unit: '인분', onHand: 3,
    minimum: 4, target: 12, batchQuantity: 10, folderId: 'bone-preparation', zone: 'prep',
    instructions: '매장 승인 뼈찜 레시피로 필요한 분량을 전처리·소분하고 실제 완성 인분을 세세요.',
    menuUses: [
      { menuId: 'bowl', quantity: 2 }, { menuId: 'pork', quantity: 2 },
      { menuId: 'tomato', quantity: 3 },
    ], generation: 0 }];
  state.preparedMovements ??= [];
  // A migrated count is the current count. Prior order work remains evidence,
  // never a reason to consume portions retroactively.
  for (const task of state.tasks.filter(t => t.orderId && !t.archivedAt)) task.preparedUsageVersion ??= 'before_tracking';
  state.preparedVersion = 1;
  return true;
}

export function ensurePreparationTaps(state, now) {
  let changed = false;
  for (const item of state.preparedItems ?? []) {
    const open = state.tasks.find(t => t.preparedItemId === item.id && !t.completedAt && !t.archivedAt && !t.supersededAt);
    if (item.onHand > item.minimum && open) {
      open.supersededAt = new Date(now).toISOString();
      open.supersededReason = '실제 준비 수량이 부족 기준보다 많아져 준비가 필요하지 않음';
      changed = true;
      continue;
    }
    if (open) {
      if (open.date !== state.day) { open.originalDate ??= open.date; open.date = state.day; changed = true; }
      continue;
    }
    if (item.onHand > item.minimum) continue;
    item.generation = (item.generation ?? 0) + 1;
    const planned = Math.max(item.batchQuantity, item.target - item.onHand);
    state.tasks.push({ id: `prepare-${item.id}-${item.generation}`, preparedItemId: item.id,
      title: `${item.name} ${planned}${item.unit} 준비`, plannedQuantity: planned,
      folderId: item.folderId, slot: '준비', requiredRole: 'cook', zone: item.zone,
      kind: 'routine', date: state.day, dueAt: new Date(now).toISOString(),
      boardStatus: 'todo', completedAt: null, completedBy: null,
      steps: [
        { id: 'check', title: '준비 기준 확인', manual: '오늘 필요한 수량과 매장에서 승인한 레시피·안전 기준을 확인하세요.' },
        { id: 'prepare', title: `${item.name} 만들기`, manual: item.instructions || '매장 절차에 따라 준비하고 실제 완성 수량을 세세요. 시작한 수량이 아닌 완성한 수량을 기록하세요.' },
        { id: 'record', title: '완성 수량·보관 확인', manual: '완성 수량과 보관 위치·상태를 확인한 뒤 실제 수량을 입력하세요.' },
      ] });
    changed = true;
  }
  return changed;
}

export function consumePreparedForTask(state, task, now, actor) {
  if (!task.orderId || task.archivedAt || task.preparedUsageVersion || !['processing', 'done'].includes(task.boardStatus)) return false;
  const ticket = state.sales.tickets.find(t => t.id === task.orderId);
  const line = ticket?.lines[task.orderLineIndex];
  if (!line) { task.preparedUsageVersion = 'unmapped'; return true; }
  task.preparedUsageVersion = 1;
  task.preparedUsage = [];
  task.menuId ??= line.menuId;
  task.menuQuantity ??= line.quantity;
  for (const item of state.preparedItems ?? []) {
    const use = item.menuUses.find(row => row.menuId === line.menuId);
    if (!use) continue;
    const quantity = use.quantity * line.quantity;
    item.onHand -= quantity;
    const movement = { id: randomUUID(), type: 'order_use', itemId: item.id, quantity: -quantity,
      taskId: task.id, orderId: task.orderId, menuId: line.menuId, at: new Date(now).toISOString(), actor };
    state.preparedMovements.push(movement);
    task.preparedUsage.push({ itemId: item.id, quantity, movementId: movement.id });
  }
  return true;
}

export function finishPreparation(state, task, quantity, now, actor) {
  const item = state.preparedItems?.find(row => row.id === task.preparedItemId);
  if (!item || task.preparedOutputMovementId) fail('준비 수량을 다시 확인해 주세요.', 409);
  const actual = positive(quantity, '실제 완성 수량');
  item.onHand += actual;
  const movement = { id: randomUUID(), type: 'prepared_output', itemId: item.id, quantity: actual,
    taskId: task.id, at: new Date(now).toISOString(), actor };
  state.preparedMovements.push(movement);
  task.preparedOutputMovementId = movement.id;
  task.preparedActualQuantity = actual;
}

export function savePreparedItem(state, input) {
  const previous = input.id ? state.preparedItems.find(item => item.id === input.id) : null;
  if (input.id && !previous) fail('준비품을 찾지 못했어요.', 404);
  if (!Array.isArray(input.menuUses) || input.menuUses.length > 80) fail('메뉴별 사용량을 확인해 주세요.');
  const menuIds = new Set(state.sales.menus.map(menu => menu.id));
  const uses = input.menuUses.map(row => {
    if (!menuIds.has(row.menuId)) fail('연결할 메뉴를 확인해 주세요.');
    return { menuId: row.menuId, quantity: positive(row.quantity, '메뉴별 사용량') };
  });
  if (new Set(uses.map(row => row.menuId)).size !== uses.length) fail('같은 메뉴를 한 번만 연결해 주세요.');
  if (!state.checklistFolders.some(folder => folder.id === input.folderId)) fail('준비 BIG TAP을 확인해 주세요.');
  if (!state.zones.some(zone => zone.id === input.zone)) fail('준비 장소를 확인해 주세요.');
  const next = { name: label(input.name, '준비품 이름'), unit: label(input.unit, '단위'),
    minimum: nonnegative(input.minimum, '부족 기준'), target: positive(input.target, '목표 수량'),
    batchQuantity: positive(input.batchQuantity, '기본 준비량'), folderId: input.folderId,
    zone: input.zone, menuUses: uses,
    instructions: typeof input.instructions === 'string' && input.instructions.length <= 700
      ? input.instructions.trim() : fail('준비 방법은 700자 이내로 입력해 주세요.') };
  if (next.target <= next.minimum) fail('목표 수량은 부족 기준보다 크게 설정해 주세요.');
  if (previous) Object.assign(previous, next);
  else state.preparedItems.push({ id: randomUUID(), onHand: 0, generation: 0, ...next });
}

export function countPreparedItem(state, input, now, actor) {
  const item = state.preparedItems.find(row => row.id === input.id);
  if (!item) fail('준비품을 찾지 못했어요.', 404);
  const actual = nonnegative(input.quantity, '실제 준비 수량');
  const reason = label(input.reason, '수량 보정 이유');
  const delta = actual - item.onHand;
  item.onHand = actual;
  state.preparedMovements.push({ id: randomUUID(), type: 'count_correction', itemId: item.id,
    quantity: delta, actual, reason, at: new Date(now).toISOString(), actor });
}
