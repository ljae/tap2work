import { readFile, writeFile, rename, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
import { ensureOrderTaps, syncOrderFromTap } from './order_taps.mjs';
import { seedSales, salesDashboard } from './sales.mjs';
import { ensureLayout, validateLayout } from './layout.mjs';
import { ensureStaff, staffView, mutateStaff } from './staff.mjs';
import { ensureChecklists, saveChecklists, checklistLibrary, checklistSlots, checklistRoles, libraryTemplates, reopenStep, mediaLink } from './checklists.mjs';

const dayMs = 86400000;
export const actors = [
  { id: 'owner', name: '서연', role: 'owner', label: '사장님', emoji: '🌻' },
  { id: 'manager', name: '민지', role: 'manager', label: '매니저', emoji: '🌿' },
  { id: 'cook', name: '현우', role: 'cook', label: '조리 담당', emoji: '🍳' },
  { id: 'crew', name: '지우', role: 'crew', label: '크루', emoji: '🐣' },
];
const slots = checklistSlots;
const roles = checklistRoles;
const koreanDate = now => new Date(new Date(now).getTime() + 9 * 3600000).toISOString().slice(0, 10);
const iso = now => new Date(now).toISOString();
function fail(message, status = 400) { throw new StoreError(message, status); }
function text(value, name, max = 200) { if (typeof value !== 'string' || !value.trim() || value.length > max) fail(`${name}을 확인해 주세요.`); return value.trim(); }
function amount(value) { if (typeof value !== 'number' || !Number.isFinite(value) || value < 0 || value > 100000) fail('수량은 0~100,000 사이로 입력해 주세요.'); return value; }
const seedZones = () => [
  { id: 'storage', name: '창고', emoji: '📦', description: '쌀·감자·포장 용기. 선반별 라벨을 확인해요.', x: .04, y: .04 },
  { id: 'fridge', name: '냉장고', emoji: '🧊', description: '등뼈·우거지·사리·계란 보관. 생뼈와 손질 채소 칸을 나눠요.', x: .55, y: .04 },
  { id: 'prep', name: '뼈 전처리대', emoji: '🍖', description: '핏물 빼기·초벌·소분. 생뼈 도구와 채소 도구를 구분해요.', x: .04, y: .28 },
  { id: 'stove', name: '육수·뼈찜 조리대', emoji: '🍲', description: '육수 솥과 뼈찜 화구. 허용된 장비만 안내를 받고 사용해요.', x: .55, y: .28 },
  { id: 'sink', name: '세척대', emoji: '🫧', description: '냄비·앞접시·뼈 통을 모으고 매장 절차대로 세척해요.', x: .04, y: .52 },
  { id: 'pass', name: '배식대·셀프바', emoji: '🍽️', description: '완성 뼈찜 전달, 기본 국물·반찬 셀프바가 있는 구역이에요.', x: .55, y: .52 },
  { id: 'entrance', name: '입구·탈의', emoji: '🚪', description: '개인 물품 보관과 출근 인사를 나누는 곳이에요.', x: .04, y: .76 },
  { id: 'exit', name: '비상구', emoji: '🟢', description: '실제 비상 동선은 현장에서 버디와 확인해요.', x: .55, y: .76 },
];
// Fresh demo stores start from the 뼈찜 collection; existing files keep their own lists (see ensureChecklists).
function seedChecklists(zones) {
  const { folder, templates } = libraryTemplates('bonejjim', zones);
  return { checklistVersion: 1, checklistFolders: [{ id: 'general', name: '기본 업무' }, folder], taskTemplates: templates };
}
const tapGroups = [
  ['order-work', '주문처리'], ['marketing', '마케팅'], ['bone-preparation', '뼈찜 조리'],
  ['noodle-preparation', '뼈짬뽕 조리'], ['service', '응대'], ['maintenance', '정비'], ['settlement', '정산'],
];
const tapFolder = id => ({
  'kitchen-peak': 'order-work', packing: 'order-work', 'hall-peak': 'service',
  'bone-prep': 'bone-preparation', broth: 'bone-preparation', 'sauce-side': 'bone-preparation',
  'staff-open': 'maintenance', 'hall-open': 'service', break: 'maintenance',
  'kitchen-close': 'maintenance', 'hall-close': 'maintenance',
})[id.replace('library-bonejjim-', '')];
function ensureTapBoard(state) {
  if (state.tapBoardVersion === 1) return false;
  state.checklistFolders ??= [];
  for (const [id, name] of tapGroups) if (!state.checklistFolders.some(folder => folder.id === id)) state.checklistFolders.push({ id, name });
  for (const template of state.taskTemplates ?? []) {
    const target = tapFolder(template.id);
    if (target && template.folderId === 'bonejjim') template.folderId = target;
  }
  const make = (id, title, folderId, zone, steps) => ({ id: `demo-${id}`, title, emoji: '🍲', folderId,
    slot: '준비', requiredRole: 'cook', zone, version: 1, sourceIds: ['S19'],
    steps: steps.map((title, index) => ({ id: `step-${index + 1}`, title,
      manual: '오늘 매장 기준과 주문표를 확인한 뒤 담당자와 진행해요. 후기의 제공 사례는 현재 매장 절차가 아닙니다.', tip: '수량·시간·온도는 매장 검수 후 입력해 주세요.' })) });
  const samples = [
    make('bone-order', '샘플 주문 · 산뼈찜 2인', 'order-work', 'stove', ['주문번호·메뉴·수량 확인', '사이즈·제외 요청 확인', '조리 완료 기준 확인', '당일 소스·사리 제공 기준 확인', '본품·추가품 대조 후 전달']),
    make('spicy-order', '샘플 주문 · 화산뼈찜', 'order-work', 'stove', ['맵기·추가 토핑 확인', '조리 완료 기준 확인', '당일 국물·소스 기준 확인', '본품과 추가품 대조 후 전달']),
    make('noodle-order', '샘플 주문 · 뼈짬뽕', 'order-work', 'stove', ['면 또는 밥 요청 확인', '준비분과 주문 대조', '조리 완료 기준 확인', '동반품 대조 후 전달']),
    make('noodle-prep', '뼈짬뽕 · 국물·면/밥 준비', 'noodle-preparation', 'stove', ['오늘 판매·면/밥 변경 기준 확인', '승인된 국물·뼈 준비분 확인', '면·밥 준비분 확인', '채소·그릇·도구 확인', '조리 라인에 인계']),
    make('marketing', '오늘 메뉴 안내 준비', 'marketing', 'pass', ['오늘 판매 메뉴 확인', '품절·변경 사항 확인', '안내 문구 확인']),
    make('settlement', '마감 정산 준비', 'settlement', 'pass', ['오늘 주문 내역 확인', '확인 필요한 차이 기록', '담당자에게 인계']),
  ];
  for (const sample of samples) if (!state.taskTemplates.some(template => template.id === sample.id)) state.taskTemplates.push(sample);
  state.bigTapOrder = [...tapGroups.map(([id]) => id), ...state.checklistFolders.map(folder => folder.id).filter(id => !tapGroups.some(([group]) => group === id))];
  state.tapBoardVersion = 1;
  return true;
}
export function seedOperations(now = new Date()) {
  const earlier = new Date(new Date(now).getTime() - 3 * dayMs).toISOString();
  const zones = seedZones();
  return {
    schemaVersion: 1, revision: 1, store: { name: '우리뼈찜 · 서정리', note: '뼈찜·뼈곰탕 샘플 매장 · 실제 주문/알림 없음' },
    actors, day: koreanDate(now), sales: seedSales(now),
    // Item IDs stay stable so existing demo files and tests keep working; names follow the 뼈찜 sample store.
    items: [
      { id: 'tomato', name: '돼지등뼈', emoji: '🍖', unit: 'kg', quantity: 2, minimum: 3, orderQuantity: 4, price: 7800, supplier: '한돈유통', zone: 'fridge', reviewDays: 2, lastOrderedAt: earlier, lastCheckedAt: null },
      { id: 'eggs', name: '계란(볶음밥용)', emoji: '🥚', unit: '판', quantity: 1, minimum: 2, orderQuantity: 3, price: 6500, supplier: '싱싱농장', zone: 'fridge', reviewDays: 3, lastOrderedAt: earlier, lastCheckedAt: null },
      { id: 'lettuce', name: '우거지(시래기)', emoji: '🥬', unit: '봉', quantity: 5, minimum: 2, orderQuantity: 3, price: 3500, supplier: '싱싱농장', zone: 'fridge', reviewDays: 1, lastOrderedAt: null, lastCheckedAt: null },
      { id: 'rice', name: '쌀 20kg', emoji: '🍚', unit: '포', quantity: 2, minimum: 1, orderQuantity: 1, price: 58000, supplier: '우리식자재', zone: 'storage', reviewDays: 7, lastOrderedAt: null, lastCheckedAt: null },
      { id: 'potato', name: '감자', emoji: '🥔', unit: 'kg', quantity: 6, minimum: 4, orderQuantity: 10, price: 2400, supplier: '싱싱농장', zone: 'storage', reviewDays: 3, lastOrderedAt: null, lastCheckedAt: null },
      { id: 'udon', name: '우동사리', emoji: '🍜', unit: '봉', quantity: 12, minimum: 10, orderQuantity: 30, price: 900, supplier: '우리식자재', zone: 'fridge', reviewDays: 3, lastOrderedAt: null, lastCheckedAt: null },
      { id: 'container', name: '포장 용기(대)', emoji: '🥡', unit: '세트', quantity: 40, minimum: 30, orderQuantity: 100, price: 350, supplier: '포장마을', zone: 'storage', reviewDays: 7, lastOrderedAt: null, lastCheckedAt: null },
    ],
    tasks: [],
    ...seedChecklists(zones),
    orders: [], activity: [],
    shifts: [
      { id: 's1', person: '민지', role: '매니저', time: '09:00–18:00', status: '근무', covering: null },
      { id: 's2', person: '현우', role: '조리 담당', time: '10:00–19:00', status: '근무', covering: null },
      { id: 's3', person: '지우', role: '크루', time: '11:00–15:00', status: '근무', covering: null },
      { id: 's4', person: '가은', role: '크루', time: '18:00–22:00', status: '휴가', covering: null },
    ],
    coverRequests: [],
    zones,
    privateSummary: { laborEstimate: 326000, note: '사장님 메모 · 가은님의 휴가 승인 완료. 저녁 대체 근무 확인 필요. (예시)' },
  };
}

function allowed(actor, task) { return ['owner', 'manager'].includes(actor.role) || task.requiredRole === 'all' || task.requiredRole === actor.role; }
function leadership(actor) { if (!['owner', 'manager'].includes(actor.role)) fail('사장님 또는 매니저가 처리할 수 있어요.', 403); }
function stockReview(item) {
  if (!item.lastOrderedAt) return null;
  return { id: `stock-${item.id}-${item.lastOrderId || new Date(item.lastOrderedAt).getTime()}`, dueAt: new Date(new Date(item.lastOrderedAt).getTime() + item.reviewDays * dayMs).toISOString() };
}
function ensureDueTasks(state, now) {
  let changed = ensureLayout(state);
  if (ensureStaff(state, now)) changed = true;
  if (ensureChecklists(state)) changed = true;
  if (ensureTapBoard(state)) changed = true;
  if (!state.sales) { state.sales = seedSales(now); changed = true; }
  const date = koreanDate(now);
  if (state.day !== date) { state.day = date; changed = true; }
  if (ensureOrderTaps(state, now)) changed = true;
  for (const template of state.taskTemplates) {
    const id = `daily-${template.id}-v${template.version}-${date}`;
    if (!state.tasks.some(task => task.templateId === template.id && task.date === date && !task.archivedAt)) {
      state.tasks.push({ ...structuredClone(template), templateId: template.id, id, date, dueAt: iso(now), kind: 'routine', boardStatus: 'todo', completedAt: null, completedBy: null }); changed = true;
    }
  }
  for (const item of state.items) {
    const review = stockReview(item);
    if (!review) continue;
    const { id, dueAt } = review;
    for (const task of state.tasks.filter(task => task.itemId === item.id && task.id !== id && !task.completedAt && !task.supersededAt)) {
      task.supersededAt = iso(now); task.supersededReason = '마지막 발주 기준 확인 업무로 대체'; changed = true;
    }
    const existing = state.tasks.find(task => task.id === id);
    if (existing && !existing.completedAt && existing.dueAt !== dueAt) {
      existing.dueAt = dueAt; existing.date = koreanDate(dueAt); changed = true;
    }
    if (new Date(dueAt) <= new Date(now) && !existing) {
      state.tasks.push({ id, itemId: item.id, title: `${item.name} 재고 확인`, emoji: item.emoji, slot: '준비', requiredRole: 'all', zone: item.zone, kind: 'stock', dueAt, date: koreanDate(dueAt), completedAt: null, completedBy: null }); changed = true;
    }
  }
  return changed;
}
export class OperationsStore {
  #queue = Promise.resolve();
  constructor(filename, clock = () => new Date(), { persistence = null, actor = null } = {}) { this.filename = filename; this.clock = clock; this.persistence = persistence; this.trustedActor = actor; this.persistedRevision = null; }
  async #read() {
    if (this.persistence) { const state = await this.persistence.read(); this.persistedRevision = state.revision; return state; }
    try { return JSON.parse(await readFile(this.filename, 'utf8')); }
    catch (error) { if (error.code !== 'ENOENT') throw error; const state = seedOperations(this.clock()); await this.#save(state); return state; }
  }
  async #save(state) {
    if (this.persistence) { await this.persistence.save(state, this.persistedRevision); this.persistedRevision = state.revision; return; }
    await mkdir(path.dirname(this.filename), { recursive: true });
    const temporary = `${this.filename}.${randomUUID()}.tmp`;
    await writeFile(temporary, JSON.stringify(state, null, 2) + '\n', { flag: 'wx' });
    await rename(temporary, this.filename);
  }
  #serial(callback) { const operation = this.#queue.then(callback); this.#queue = operation.catch(() => {}); return operation; }
  #actor(id) { if (this.trustedActor) return this.trustedActor; const actor = actors.find(item => item.id === id); if (!actor) fail('체험할 역할을 선택해 주세요.', 403); return actor; }
  #view(state, actor) {
    const result = structuredClone(state);
    Object.assign(result, staffView(state, actor, this.clock()));
    result.actor = actor;
    result.serverTime = iso(this.clock());
    result.demo = true;
    result.authenticated = Boolean(this.trustedActor);
    if (this.trustedActor) result.actors = [this.trustedActor];
    result.dashboard = salesDashboard(state.sales, this.clock(), actor.role === 'owner');
    delete result.sales;
    result.tasks = result.tasks.filter(task => !task.supersededAt && !task.archivedAt && (task.kind === 'stock' ? new Date(task.dueAt) <= this.clock() && (!task.completedAt || koreanDate(task.completedAt) === state.day) : task.date === state.day));
    for (const item of result.items) {
      const review = stockReview(item);
      const task = review && state.tasks.find(task => task.id === review.id);
      item.reviewDueAt = review?.dueAt ?? null;
      item.reviewState = !review ? 'no_order' : task?.completedAt ? 'completed' : new Date(review.dueAt) <= this.clock() ? 'pending' : 'scheduled';
      item.reviewCompletedBy = task?.completedBy ?? null;
      item.reviewCompletedAt = task?.completedAt ?? null;
    }
    for (const task of result.tasks) {
      task.canComplete = allowed(actor, task) && !task.completedAt;
      if (task.kind === 'routine') {
        const index = state.taskTemplates.findIndex(row => row.id === task.templateId);
        const current = state.taskTemplates[index];
        task.folderId = task.boardFolderId ?? current?.folderId ?? (state.checklistFolders.some(folder => folder.id === task.folderId) ? task.folderId : 'general');
        task.displayOrder = task.boardOrder ?? (index < 0 ? state.taskTemplates.length : index);
        task.boardStatus = task.completedAt ? 'done' : task.boardStatus ?? (task.steps?.some(step => step.completedAt) ? 'processing' : 'todo');
      }
    }
    if (actor.role !== 'owner') delete result.privateSummary;
    if (!['owner', 'manager'].includes(actor.role)) {
      for (const item of result.items) delete item.price;
      for (const order of result.orders) { delete order.total; for (const line of order.lines) delete line.price; }
    }
    result.checklistLibrary = checklistLibrary;
    if (!['owner', 'manager'].includes(actor.role)) delete result.taskTemplates;
    return result;
  }
  snapshot(actorId) {
    const actor = this.#actor(actorId);
    return this.#serial(async () => {
      const state = await this.#read();
      if (ensureDueTasks(state, this.clock())) { state.revision++; await this.#save(state); }
      return this.#view(state, actor);
    });
  }
  mutate(actorId, input) {
    const actor = this.#actor(actorId);
    return this.#serial(async () => {
      const state = await this.#read();
      const now = this.clock();
      if (ensureDueTasks(state, now)) { state.revision++; await this.#save(state); }
      if (input.revision !== state.revision) fail('다른 동료가 먼저 업데이트했어요. 최신 내용을 확인하고 다시 눌러 주세요.', 409);
      const who = { id: actor.id, name: actor.name, role: actor.label };
      const activity = message => state.activity.unshift({ id: randomUUID(), at: iso(now), actor: who, message });
      const itemFor = id => { const item = state.items.find(item => item.id === id); if (!item) fail('재료를 찾지 못했어요.', 404); return item; };
      switch (input.action) {
        case 'save_step_manual': {
          leadership(actor);
          const task = state.tasks.find(t => t.id === input.taskId && !t.archivedAt && t.date === state.day);
          const step = task?.steps?.find(s => s.id === input.stepId);
          if (!step || step.completedAt) fail('아직 완료하지 않은 오늘 Small Tap만 편집할 수 있어요.', 409);
          const manual = text(input.manual, '매뉴얼', 700);
          const videoUrl = mediaLink(input.videoUrl), imageUrl = mediaLink(input.imageUrl);
          step.manualHistory ??= [];
          step.manualHistory.push({ manual: step.manual, videoUrl: step.videoUrl ?? '', imageUrl: step.imageUrl ?? '', at: iso(now), actor: who });
          Object.assign(step, { manual, videoUrl, imageUrl });
          const template = state.taskTemplates.find(t => t.id === (step.sourceTemplateId ?? task.templateId));
          const source = template?.steps.find(s => s.id === (step.sourceStepId ?? step.id));
          if (source) { Object.assign(source, { manual, videoUrl, imageUrl }); template.version++; }
          activity(`${task.title} · ${step.title} 매뉴얼 저장`); break;
        }
        case 'save_layout': {
          leadership(actor);
          const updated = validateLayout(input, state);
          state.layout = { ...updated.layout, updatedAt: iso(now), updatedBy: who };
          state.zones = updated.zones;
          activity(`매장 배치 저장 · 테이블 ${state.zones.filter(zone => zone.kind === 'table').length}개`);
          break;
        }
        case 'save_checklists': {
          leadership(actor); saveChecklists(input, state, now);
          state.bigTapOrder = [...(state.bigTapOrder ?? []).filter(id => state.checklistFolders.some(folder => folder.id === id)), ...state.checklistFolders.map(folder => folder.id).filter(id => !(state.bigTapOrder ?? []).includes(id))];
          activity('업무 폴더·카드·매뉴얼 저장'); break;
        }
        case 'reopen_step': {
          const task = state.tasks.find(task => task.id === input.taskId);
          if (!task) fail('업무를 찾지 못했어요.', 404);
          if (task.archivedAt || task.date !== state.day) fail('오늘 업무만 되돌릴 수 있어요.', 409);
          reopenStep(task, input.stepId, actor, ['owner', 'manager'].includes(actor.role));
          task.boardStatus = 'processing';
          activity(`${task.title} · 확인 되돌림`); break;
        }
        case 'complete_step':
        case 'complete_task': {
          const task = state.tasks.find(task => task.id === input.taskId);
          if (!task) fail('업무를 찾지 못했어요.', 404);
          if (task.archivedAt) fail('업무가 변경되었어요. 최신 카드를 확인해 주세요.', 409);
          if (task.supersededAt || new Date(task.dueAt) > now) fail('발주 기준 확인 예정일이 바뀌었어요. 최신 업무를 확인해 주세요.', 409);
          if (task.kind === 'routine' && task.date !== state.day) fail('오늘 업무를 다시 확인해 주세요.', 409);
          if (task.completedAt) fail(`${task.completedBy.name}님이 이미 확인했어요.`, 409);
          if (!allowed(actor, task)) fail('이 업무의 담당 직급이 아니에요. 매니저에게 알려 주세요.', 403);
          if (input.action === 'complete_step') {
            const step = task.steps?.find(row => row.id === input.stepId);
            if (task.kind !== 'routine' || !step) fail('행위를 찾지 못했어요.', 404);
            if (step.completedAt) fail('동료가 이미 확인한 행위예요.', 409);
            step.completedAt = iso(now); step.completedBy = who; task.boardStatus = 'processing';
            activity(`${task.title} · ${step.title} 완료`);
            if (task.steps.every(row => row.completedAt)) { task.completedAt = iso(now); task.completedBy = who; task.boardStatus = 'done'; }
            break;
          }
          if (task.kind === 'routine') for (const step of task.steps ?? []) if (!step.completedAt) {
            step.completedAt = iso(now); step.completedBy = who; step.completionSource = 'tap_bulk';
          }
          if (task.kind === 'stock') { const item = itemFor(task.itemId); item.quantity = amount(input.quantity); item.lastCheckedAt = iso(now); item.checkedBy = who; }
          task.completedAt = iso(now); task.completedBy = who; task.boardStatus = 'done'; activity(`${task.title} 완료`); break;
        }
        case 'move_tap': {
          const task = state.tasks.find(row => row.id === input.taskId && row.kind === 'routine' && row.date === state.day && !row.archivedAt);
          if (!task) fail('오늘 Tap을 찾지 못했어요.', 404);
          if (!allowed(actor, task)) fail('이 Tap의 담당자가 아니에요.', 403);
          if (!state.checklistFolders.some(folder => folder.id === input.folderId)) fail('BIG TAP을 찾지 못했어요.');
          if (!['todo', 'processing', 'done'].includes(input.status)) fail('Tap 상태를 확인해 주세요.');
          const moving = task.orderId ? state.tasks.filter(t => t.orderId === task.orderId && !t.archivedAt) : [task];
          for (const task of moving) {
          if (!allowed(actor, task)) fail('이 Tap의 담당자가 아니에요.', 403);
          if (input.status === 'done' && !task.completedAt) {
            for (const step of task.steps ?? []) if (!step.completedAt) { step.completedAt = iso(now); step.completedBy = who; step.completionSource = 'tap_bulk'; }
            task.completedAt = iso(now); task.completedBy = who;
          }
          if (input.status !== 'done' && task.completedAt) {
            if (task.completedBy?.id !== actor.id && !['owner', 'manager'].includes(actor.role)) fail('완료한 본인이나 리더만 되돌릴 수 있어요.', 403);
            for (const step of task.steps ?? []) if (step.completedAt) {
              delete step.completedAt; delete step.completedBy; delete step.completionSource;
            }
            task.completedAt = null; task.completedBy = null;
          }
          }
          const laneStatus = row => {
            const group = row.orderId ? state.tasks.filter(t => t.orderId === row.orderId && !t.archivedAt) : [row];
            return group.every(t => t.completedAt) ? 'done' : group.some(t => t.completedAt || t.boardStatus === 'processing') ? 'processing' : 'todo';
          };
          const lane = state.tasks.filter(row => !moving.some(t => t.id === row.id) && row.kind === 'routine' && row.date === state.day && !row.archivedAt && laneStatus(row) === input.status)
            .sort((a, b) => (a.boardOrder ?? (state.taskTemplates.findIndex(t => t.id === a.templateId) < 0 ? state.taskTemplates.length : state.taskTemplates.findIndex(t => t.id === a.templateId))) - (b.boardOrder ?? (state.taskTemplates.findIndex(t => t.id === b.templateId) < 0 ? state.taskTemplates.length : state.taskTemplates.findIndex(t => t.id === b.templateId))));
          const before = input.beforeTaskId == null ? lane.length : lane.findIndex(row => row.id === input.beforeTaskId);
          if (before < 0) fail('삽입할 Tap을 찾지 못했어요.', 409);
          for (const member of moving) { member.boardFolderId = input.folderId; member.boardStatus = input.status; }
          lane.splice(before, 0, ...moving);
          lane.forEach((row, index) => { row.boardOrder = index; });
          activity(`${task.title} · ${input.status} 이동`); break;
        }
        case 'reorder_small_taps': {
          leadership(actor);
          const task = state.tasks.find(row => row.id === input.taskId && row.kind === 'routine' && row.date === state.day);
          if (!task || !Array.isArray(input.stepIds) || input.stepIds.length !== task.steps.length || new Set(input.stepIds).size !== task.steps.length || input.stepIds.some(id => !task.steps.some(step => step.id === id))) fail('Small Tap 순서를 확인해 주세요.');
          task.steps.sort((a, b) => input.stepIds.indexOf(a.id) - input.stepIds.indexOf(b.id));
          activity(`${task.title} · Small Tap 순서 변경`); break;
        }
        case 'reorder_big_taps': {
          leadership(actor);
          if (!Array.isArray(input.folderIds) || input.folderIds.length !== state.checklistFolders.length || new Set(input.folderIds).size !== input.folderIds.length || input.folderIds.some(id => !state.checklistFolders.some(folder => folder.id === id))) fail('BIG TAP 순서를 확인해 주세요.');
          state.bigTapOrder = input.folderIds;
          activity('BIG TAP 순서 변경'); break;
        }
        case 'check_stock': {
          const item = itemFor(input.itemId); item.quantity = amount(input.quantity); item.lastCheckedAt = iso(now); item.checkedBy = who;
          for (const task of state.tasks.filter(task => task.itemId === item.id && !task.completedAt && !task.supersededAt && new Date(task.dueAt) <= now)) { task.completedAt = iso(now); task.completedBy = who; }
          activity(`${item.name} 재고 ${item.quantity}${item.unit} 확인`); break;
        }
        case 'place_order': {
          leadership(actor);
          if (!Array.isArray(input.lines) || !input.lines.length || input.lines.length > 20) fail('발주할 재료를 선택해 주세요.');
          if (input.lines.some(line => !line || typeof line !== 'object')) fail('발주 항목을 확인해 주세요.');
          if (new Set(input.lines.map(line => line.itemId)).size !== input.lines.length) fail('같은 재료가 중복되었어요.');
          const lines = input.lines.map(line => {
            const item = itemFor(line.itemId); const quantity = amount(line.quantity); if (quantity <= 0) fail('발주 수량은 0보다 커야 해요.');
            if (state.orders.some(order => order.status === 'ordered' && order.lines.some(line => line.itemId === item.id))) fail(`${item.name}은 이미 입고 대기 중이에요.`, 409);
            return { itemId: item.id, name: item.name, unit: item.unit, supplier: item.supplier, quantity, price: item.price };
          });
          const order = { id: `PO-${randomUUID().slice(0, 8).toUpperCase()}`, createdAt: iso(now), placedBy: who, status: 'ordered', lines, total: lines.reduce((sum, line) => sum + line.quantity * line.price, 0), receivedAt: null };
          state.orders.unshift(order);
          for (const line of lines) { const item = itemFor(line.itemId); item.lastOrderedAt = iso(now); item.lastOrderId = order.id; item.restockRequestedBy = null; }
          activity(`데모 발주 ${lines.length}개 재료 · 실제 전송 없음`); break;
        }
        case 'receive_order': {
          leadership(actor); const order = state.orders.find(order => order.id === input.orderId);
          if (!order) fail('발주 내역이 없어요.', 404);
          if (order.status !== 'ordered') fail('이미 입고 확인된 발주예요.', 409);
          order.status = 'received'; order.receivedAt = iso(now); order.receivedBy = who;
          for (const line of order.lines) itemFor(line.itemId).quantity += line.quantity;
          activity(`${order.id} 입고 확인 · 재고 반영`); break;
        }
        case 'request_restock': { const item = itemFor(input.itemId); item.restockRequestedBy = who; activity(`${item.name} 보충 요청`); break; }
        case 'review_policy': {
          leadership(actor); const item = itemFor(input.itemId);
          if (!Number.isInteger(input.reviewDays) || input.reviewDays < 1 || input.reviewDays > 90) fail('발주 후 확인 일수는 1~90일로 정해 주세요.');
          item.reviewDays = input.reviewDays; item.minimum = amount(input.minimum); activity(`${item.name} 재고 확인 기준 변경`); break;
        }
        case 'create_task': {
          leadership(actor); if (!slots.includes(input.slot) || !roles.includes(input.requiredRole) || !state.zones.some(zone => zone.id === input.zone)) fail('시간대·담당 직급·위치를 선택해 주세요.');
          const template = { id: randomUUID(), title: text(input.title, '업무 이름', 100), emoji: '📝', slot: input.slot, requiredRole: input.requiredRole, zone: input.zone, folderId: 'general', version: 1, sourceIds: [], steps: [{ id: randomUUID(), title: text(input.title, '업무 이름', 100), manual: '매장 절차를 버디와 확인한 뒤 진행하고 결과를 확인해요.', tip: '매장에 맞는 방법과 완료 기준을 편집해 주세요.' }] };
          state.taskTemplates.push(template); ensureDueTasks(state, now); activity(`${template.title} · ${template.slot} 반복 업무 등록`); break;
        }
        case 'offer_cover': {
          const shift = state.shifts.find(shift => shift.id === input.shiftId);
          if (!shift || shift.status !== '휴가' || shift.covering) fail('대체 근무가 필요한 시간인지 확인해 주세요.');
          if (!state.coverRequests.some(request => request.shiftId === shift.id && request.actor.id === actor.id && request.status === 'pending')) state.coverRequests.push({ id: randomUUID(), shiftId: shift.id, actor: who, status: 'pending', at: iso(now) });
          activity(`${shift.person}님 공석 시간에 대체 근무 가능 의사 전달`); break;
        }
        case 'assign_cover': {
          leadership(actor); const request = state.coverRequests.find(request => request.id === input.requestId);
          if (!request || request.status !== 'pending') fail('대기 중인 신청이 아니에요.', 409);
          const shift = state.shifts.find(shift => shift.id === request.shiftId);
          if (shift.covering) fail('이미 대체 근무자가 정해졌어요.', 409);
          shift.covering = request.actor; request.status = 'accepted';
          for (const other of state.coverRequests.filter(other => other.shiftId === shift.id && other.status === 'pending')) other.status = 'closed';
          activity(`${shift.time} 대체 근무 · ${request.actor.name}님 확정`); break;
        }
        case 'update_shift': {
          leadership(actor); const shift = state.shifts.find(shift => shift.id === input.shiftId);
          if (!shift || !['근무', '휴가'].includes(input.status)) fail('직원과 근무 상태를 확인해 주세요.');
          if (shift.status === input.status) fail('이미 같은 근무 상태예요.', 409);
          shift.status = input.status; shift.covering = null; shift.updatedBy = who; shift.updatedAt = iso(now);
          for (const request of state.coverRequests.filter(request => request.shiftId === shift.id && request.status === 'pending')) request.status = 'closed';
          activity(`${shift.person}님 · ${shift.time} ${shift.status}로 변경`); break;
        }
        case 'edit_zone': {
          leadership(actor); const zone = state.zones.find(zone => zone.id === input.zoneId); if (!zone) fail('위치를 찾지 못했어요.', 404);
          zone.name = text(input.name, '장소 이름', 30); zone.description = text(input.description, '위치 안내', 500);
          validateLayout({ layout: state.layout, zones: state.zones }, state);
          state.layout.updatedAt = iso(now); state.layout.updatedBy = who;
          activity(`${zone.name} 위치 안내 업데이트`); break;
        }
        default: if (!mutateStaff(state, input, actor, now, who, activity)) fail('지원하지 않는 작업이에요.');
      }
      if (['move_tap', 'complete_task', 'complete_step', 'reopen_step'].includes(input.action)) syncOrderFromTap(state, input.taskId);
      state.activity = state.activity.slice(0, 100);
      ensureDueTasks(state, now);
      state.revision++; await this.#save(state);
      return this.#view(state, actor);
    });
  }
}
