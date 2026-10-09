import { contentHash } from './manual_catalog_schema.mjs';
import { composeManual, saveManualSetup, retireUnstartedComposition } from './manual_setup.mjs';
import { savePlace } from './place_guide.mjs';
import {workEligibility,workStatus,startManualWork,eventReplay,knowledgeSnapshots} from './knowledge_work.mjs';
import { storeSetupCatalog } from './store_setup.mjs';
import {manualPrintView,saveManualPrintTranslation} from './manual_print.mjs';
import {manualCatalog,replaceMixedBreak,syncManualCatalog,manualMarketReplay,reconcileCatalogLinks,catalogView,checklistBackup,mutateManualMarket} from './manual_market.mjs';
import { ensureDefaultAssignments, scheduleRange } from './default_assignments.mjs';
import { tapOnly, assertContentOnly, policyReport, convertPolicy, updateContentRevisions } from './tap_policy.mjs';
import { businessDate, boundaryOf, shiftDate } from './business_day.mjs';
import { assignmentContext, assignmentOccurrences, assignmentView, assignmentPermission, snapshotAssignments } from './work_assignments.mjs';
import { languageContext } from './localization.mjs';
import {editManualNode, editWorkNode} from './direct_edit.mjs';
import { ensurePartModel, actorWithParts, rosterTemplates } from './parts.mjs';
import { workplaceView, mutateWorkplace, checkWorkplacePermission } from './workplace.mjs';
import { moveManualNode } from './manual_directory.mjs';
import { readFile, writeFile, rename, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
import { ensureOrderTaps, syncOrderFromTap } from './order_taps.mjs';
import { ensurePreparedItems, ensurePreparationTaps, consumePreparedForTask, finishPreparation, savePreparedItem, countPreparedItem } from './prepared_items.mjs';
import { seedSales, salesDashboard } from './sales.mjs';
import { ensureLayout, validateLayout } from './layout.mjs';
import { ensureStaff, staffView, mutateStaff } from './staff.mjs';
import { ensureChecklists, saveChecklists, checklistLibrary, checklistSlots, checklistRoles, libraryTemplates, reopenStep, mediaLink, manualTags } from './checklists.mjs';
import { saveStoreProfile, saveHiringDraft } from './store_profile.mjs';
import { saveTapSettings, repeatsOn, taskSettings, canCompleteStep, completeStepIssue, bulkCompleteIssue } from './task_settings.mjs';
import { recommendedTaps, importRecommendedTaps } from './work_recommendations.mjs';

function manualSearchIndex(state) {
  const rows = new Map();
  const add = (task, template) => {
    if(template)task=composeManual(state,task);
    for (const step of task.steps ?? []) {
      const sourceTemplateId = step.sourceTemplateId ?? task.templateId ?? task.id;
      const sourceStepId = step.sourceStepId ?? step.id;
      const key = `${sourceTemplateId}/${sourceStepId}`;
      if (rows.has(key)) continue;
      rows.set(key, {
        manualCustomization:task.manualCustomization??null, sharedPlaces:task.sharedPlaces??[], zone:task.zone??null, id: key, taskId: template ? null : task.id, stepId: step.id,
        tapTitle: task.manualTitle ?? task.title, title: step.manualTitle ?? step.title,
        folderId: task.folderId ?? 'general',
        folderName: state.checklistFolders.find(folder => folder.id === task.folderId)?.name ?? '기본 업무',
        tapId: template ? task.id : `occurrence:${task.id}`,
        templateId: template ? task.id : null,
        menuManualId: task.menuManualId ?? null,
        knowledgeIds: task.settings?.knowledgeIds??[],
        sourceStepId: step.id,
        editable: template,
        estimatedMinutes: tapOnly(task) ? null : step.settings?.estimatedMinutes ?? null,
        tapEstimatedMinutes:tapOnly(task) ? task.settings?.estimatedMinutes ?? null : null,contentRevision:step.contentRevision ?? 1,
        manual: step.manual ?? '', tip: step.tip ?? '', tags: step.tags ?? [],
        imageUrl: step.imageUrl ?? '', videoUrl: step.videoUrl ?? '', sourceUrl: step.sourceUrl ?? '',
      });
    }
  };
  for (const template of state.taskTemplates ?? []) if (!template.archivedAt && (template.folderId !== 'order-work' || template.menuManualId)) add(template, true);
  for (const task of state.tasks ?? []) if (task.steps?.length && !task.orderId && task.folderId !== 'order-work' && !task.archivedAt && !task.supersededAt && task.date === state.day) add(task, false);
  return [...rows.values()];
}

function menuManualText(menu) {
  const name = menu.name;
  if (menu.id === 'bowl' || menu.id === 'tomato') return `${name}의 주문 옵션을 확인하고, 매장에서 승인한 산뼈찜 레시피와 제공 기준에 맞춰 준비해요. 완성 후 메뉴와 추가품을 주문표에 대조해요.`;
  if (menu.id === 'pork') return `${name}의 맵기와 추가 토핑·제외 요청을 확인해요. 매장에서 승인한 화산뼈찜 레시피에 따라 준비하고 본품과 추가품을 대조해요.`;
  if (menu.id === 'salad') return `${name}의 면·밥 선택과 제외 요청을 확인해요. 매장에서 승인한 국물·면 조리 기준에 따라 준비하고 동반품을 대조해요.`;
  if (menu.id === 'soup') return `${name} 주문을 확인하고 매장에서 승인한 뼈곰탕 국물·고명·제공 기준에 따라 준비해요. 완성된 메뉴를 주문표에 대조해요.`;
  if (menu.id === 'tea') return `${name} 추가 주문을 확인하고 매장에서 정한 사리 준비·제공 기준에 따라 준비해요. 함께 나갈 본품 주문을 대조해요.`;
  if (menu.id === 'special') return `${name} 주문을 확인하고 매장에서 승인한 볶음밥 조리·제공 기준에 따라 준비해요. 함께 나갈 본품 주문을 대조해요.`;
  if (menu.id === 'water') return `${name}의 종류·요청 사항을 확인하고, 매장 제공 기준에 따라 준비한 뒤 주문표에 대조해요.`;
  return `${name} 주문의 옵션과 요청 사항을 확인해요. 매장에서 승인한 이 메뉴의 조리·제공 기준에 따라 준비하고 완성된 메뉴를 주문표에 대조해요.`;
}

function ensureMenuManuals(state) {
  let changed = false;
  if ((state.sales?.menus ?? []).some(menu => !menu.archivedAt) && !state.checklistFolders.some(folder => folder.id === 'store-recipes')) {
    state.checklistFolders.push({ id: 'store-recipes', name: '메뉴·레시피' });
    state.bigTapOrder = [...(state.bigTapOrder ?? []), 'store-recipes'];
    changed = true;
  }
  for (const menu of state.sales?.menus ?? []) {
    const id = `menu-manual-${menu.id}`;
    const template = state.taskTemplates.find(row => row.id === id);
    if (menu.archivedAt) {
      if (template && !template.archivedAt) { template.archivedAt = menu.archivedAt; changed = true; }
      continue;
    }
    if (template) {
      if (template.folderId !== 'store-recipes') { template.folderId = 'store-recipes'; changed = true; }
      if (template.title !== menu.name) {
        const defaultManual = menuManualText({ ...menu, name: template.title });
        if (template.steps[0]?.manual === defaultManual) template.steps[0].manual = menuManualText(menu);
        template.title = menu.name;
        if (template.steps[0]) template.steps[0].title = menu.name;
        template.version++;
        changed = true;
      }
      continue;
    }
    state.taskTemplates.push({ id, menuManualId: menu.id, title: menu.name, emoji: '🍽️', folderId: 'store-recipes', slot: '피크', requiredRole: 'cook', zone: null, assignmentScopeVersion:2, version: 1, sourceIds: [], settings: { type: 'order', enabled: false, recurrence: { mode: 'daily', weekdays: [] }, allowBulkComplete: false, enforceSequence: false }, steps: [{ id: 'menu', title: menu.name, manual: menuManualText(menu), tip: '조리 시간과 상세 레시피는 매장 기준에 맞게 설정해 주세요.', contentRevision:1 }] });
    changed = true;
  }
  return changed;
}

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
function ensurePosGuides(state, now = new Date()) {
  if (state.sales?.source !== 'sample' || state.posGuideVersion === 2) return false;
  const archivedAt = new Date(now).toISOString();
  for (const row of [...(state.taskTemplates ?? []), ...(state.tasks ?? [])]) {
    if (!['demo-pos-toss', 'demo-pos-payhere'].includes(row.id) && !['demo-pos-toss', 'demo-pos-payhere'].includes(row.templateId)) continue;
    row.archivedAt ??= archivedAt;
  }
  const template = {
    id: 'demo-pos-okpos', title: '오케이포스(OKPOS) 결제 안내 · 샘플', emoji: '💳',
    folderId: 'settlement', slot: '피크', requiredRole: 'all',
    zone: state.zones.some(zone => zone.id === 'pass') ? 'pass' : state.zones[0]?.id,
    version: 1, sourceIds: [], steps: [
      { id: 'amount', title: '복합결제 · 금액별', manual: '오케이포스(OKPOS) 샘플 안내: 결제 화면에서 복합결제를 누르고 분할 금액을 입력해요. 결제 수단을 선택해 결제한 뒤 나머지 금액에도 반복해요. 마지막 잔액을 확인하고 영수증 결제 내역을 대조해요.', tags: ['복합결제', '분할결제', '금액별', '더치페이'], sourceUrl: 'https://okpos.gitbook.io/okpos/undefined-3/undefined/payment/mixed_media' },
      { id: 'menu', title: '더치페이 · 상품별', manual: '오케이포스(OKPOS) 샘플 안내: 결제 화면에서 더치페이를 누르고 이번에 결제할 상품을 선택해 결제해요. 남은 상품에도 반복하고 영수증을 각각 확인해요.', tags: ['더치페이', '상품별', '메뉴별', '따로결제'], sourceUrl: 'https://okpos.gitbook.io/okpos/undefined-3/undefined/payment/per_person' },
      { id: 'cancel', title: '결제 취소 안내 확인', manual: '취소할 거래와 원 결제 내역을 먼저 확인해요. 구체적인 취소 절차는 매장 장비의 버전에 맞는 오케이포스 공식 안내와 매장 담당자에게 확인해요.', tags: ['결제취소', '환불', '취소'], sourceUrl: 'https://okpos.gitbook.io/okpos/undefined-3/undefined/receipts' },
    ].map(step => ({ ...step, tip: '샘플 안내예요. 실제 POS 연결이나 결제 기능은 없어요. 매장 장비와 공식 안내를 확인해 주세요.' })),
  };
  if (!state.taskTemplates.some(row => row.id === template.id)) state.taskTemplates.push(template);
  state.posGuideVersion = 2;
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

// New authenticated workspaces may start without fictional people, stock or sales.
// Version markers prevent the legacy demo upgrades from adding samples later.
export function emptyOperations(now = new Date(), ownerId, ownerName = '사장님') {
  const state = seedOperations(now);
  ensureStaff(state, now);
  Object.assign(state, {
    store: { name: '새 매장', note: '', setup: 'blank' }, actors: [],
    sales: { source: 'manual', seededAt: null, menus: [], tickets: [] },
    items: [], orders: [], tasks: [], taskTemplates: [],
    checklistFolders: [{ id: 'general', name: '기본 업무' }],
    bigTapOrder: ['general'], tapBoardVersion: 1, checklistVersion: 1,
    orderCompositionVersion: 3, orderTapVersion: 2, posGuideVersion: 2,
    preparedVersion: 1, preparedItems: [], preparedMovements: [],
    zones: [], layout: { name: '우리 매장', columns: 16, rows: 12, updatedAt: null, updatedBy: null },
    tappers: [{ id: `tapper-${ownerId}`, actorId: ownerId, rank: 'owner', nickname: ownerName,
      duties: ['cashier'], hourlyWon: 0, payPeriod: 'monthly', kakaoUrl: '', phone: '', active: true }],
    staffVersion: 1, staffShifts: [], staffingSlots: [], attendance: [], payAdjustments: [], payRecords: [],
    shifts: [], coverRequests: [], activity: [], privateSummary: { laborEstimate: 0, note: '' },
  });
  return state;
}

function allowed(actor, task, state) { const permission = state && assignmentPermission(state, actor, task); if (permission != null) return permission; return ['owner', 'manager'].includes(actor.role) || (Object.hasOwn(task, 'partId') ? task.partId == null || actor.partIds?.includes(task.partId) : task.requiredRole === 'all' || task.requiredRole === actor.role); }
function leadership(actor) { if (!['owner', 'manager'].includes(actor.role)) fail('사장님 또는 매니저가 처리할 수 있어요.', 403); }
function stockReview(item) {
  if (!item.lastOrderedAt) return null;
  return { id: `stock-${item.id}-${item.lastOrderId || new Date(item.lastOrderedAt).getTime()}`, dueAt: new Date(new Date(item.lastOrderedAt).getTime() + item.reviewDays * dayMs).toISOString() };
}
function ensureDueTasks(state, now, catalog = manualCatalog, catalogRevision = null) {
  let changed = false;
  if(catalogRevision != null){
    if((state.catalogSync?.revision??0)>catalogRevision)fail('공용 매뉴얼이 먼저 업데이트됐어요. 다시 조회해 주세요.',409);
    if(state.catalogSync?.revision!==catalogRevision || state.catalogSync?.releaseId!==catalog.releaseId){
      state.catalogSync={revision:catalogRevision,releaseId:catalog.releaseId};changed=true;
    }
  }
  if(ensureLayout(state))changed=true;
  if (ensureStaff(state, now)) changed = true;
  if (ensureDefaultAssignments(state, now)) changed = true;
  if (ensureChecklists(state)) changed = true;
  if (syncManualCatalog(state,now,catalog)) changed = true;
  if (ensureTapBoard(state)) changed = true;
  if (!state.sales) { state.sales = seedSales(now); changed = true; }
  if (ensureMenuManuals(state)) changed = true;
  if (state.sales?.source === 'sample') for (const ticket of state.sales.tickets ?? []) {
    const match = /^S-\d+-(\d+)$/.exec(ticket.id);
    if (match && ticket.targetMinutes == null) { ticket.targetMinutes = [20, 25, 30][(Number(match[1]) - 1) % 3]; changed = true; }
  }
  if (ensurePosGuides(state, now)) changed = true;
  const date = businessDate(state, now);
  if (state.day !== date) { state.day = date; changed = true; }
  if (ensurePreparedItems(state, now)) changed = true;
  if (ensureOrderTaps(state, now)) changed = true;
  if (ensurePreparationTaps(state, now)) changed = true;
  for (const template of state.taskTemplates) {
    if (workEligibility(state,template,date)[0]!=='ready' || template.archivedAt || template.generationNotBeforeBusinessDate > date || template.menuManualId || template.steps.length === 0 || !repeatsOn(template, date)) continue;
    const existing = state.tasks.filter(task => task.templateId === template.id && task.date === date && !task.archivedAt);
    // Settings changes leave started/completed snapshots alone, including their band set.
    if (existing.some(task => task.timeBandId == null && task.version !== template.version && (task.completedAt || task.boardStatus === 'processing' || task.steps?.some(s => s.completedAt)))) continue;
    for (const occurrence of assignmentOccurrences(state, template, date)) {
      const id = `daily-${template.id}-v${template.version}-${date}${state.store.manualSetup?'-config-'+state.store.manualSetup.revision:''}${occurrence.timeBandId ? `-band-${encodeURIComponent(occurrence.timeBandId)}` : ''}`;
      if (!existing.some(task => (task.timeBandId ?? null) === occurrence.timeBandId)) {
        state.tasks.push({ ...structuredClone(composeManual(state,{...template,...occurrence})), knowledgeSnapshots:knowledgeSnapshots(state,template), templateId: template.id, id, date, businessDayStart: boundaryOf(state), dueAt: iso(now), kind: 'routine', boardStatus: 'todo', completedAt: null, completedBy: null }); changed = true;
      }
    }
  }
  for (const item of state.items) {
    if (item.archivedAt) continue;
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
  if (ensurePartModel(state)) changed = true;
  return changed;
}
export class OperationsStore {
  #queue = Promise.resolve();
  constructor(filename, clock = () => new Date(), { persistence = null, actor = null, catalog = manualCatalog, catalogRevision = null } = {}) { this.catalogRevision = catalogRevision; this.catalog = structuredClone(catalog); this.filename = filename; this.clock = clock; this.persistence = persistence; this.trustedActor = actor; this.persistedRevision = null; }
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
    actor = actorWithParts(state, actor);
    const result = structuredClone(state);
    result.hasSampleArchive = Boolean(state.sampleArchive);
    delete result.sampleArchive;
    delete result.operationEditHistory;
    delete result.catalogHistory;
    delete result.catalogSync;
    delete result.manualPrintTranslations;
    delete result.catalogOperations;
    delete result.catalogLinks;
    delete result.calendarDayHistory;
    delete result.defaultAssignmentOmissions;
    delete result.tapPolicyHistory;
    Object.assign(result, staffView(state, actor, this.clock()));
    result.workplace = workplaceView(state, actor);
    const ownCrew = state.tappers.find(t => t.actorId === actor.id && t.active);
    result.languageContext = languageContext(state,ownCrew);
    result.shiftChangeRequests = (state.shiftChangeRequests ?? []).filter(r => actor.role === 'owner' || r.tapperId === ownCrew?.id);
    if (!['owner','manager'].includes(actor.role)) result.crewPatterns = (state.crewPatterns ?? []).filter(p => p.tapperId === ownCrew?.id);
    if (actor.role !== 'owner') { delete result.demoInvites; delete result.payrollSettings; delete result.payrollSettingsHistory; }
    result.rosterTemplates = rosterTemplates(state);
    result.orderBoardEnabled = state.store?.profile?.orderSystem?.enabled === true;
    result.actor = actor;
    result.canEditSchedule = ['owner','manager'].includes(actor.role) && (actor.role === 'owner' || state.workplace?.restrictions?.[actor.role]?.schedule !== false);
    result.canEditTasks = ['owner', 'manager'].includes(actor.role) && (actor.role === 'owner' || state.workplace?.restrictions?.[actor.role]?.tasks !== false);
    result.serverTime = iso(this.clock());
    result.demo = !this.trustedActor;
    result.authenticated = Boolean(this.trustedActor);
    if (this.trustedActor) result.actors = [this.trustedActor];
    result.dashboard = salesDashboard(state.sales, this.clock(), actor.role === 'owner');
    if (['owner', 'manager'].includes(actor.role)) result.catalogMenus = structuredClone(state.sales.menus);
    result.salesSource = state.sales.source;
    delete result.sales;
    result.items = result.items.filter(item => !item.archivedAt);
    if (actor.role !== 'owner') result.activity = result.activity.filter(entry =>
      entry.kind !== 'pay' && !/^(?:급여 지급 기록|추가보수) [\d,]+원(?:$|\s)/.test(entry.message));
    result.tasks = result.tasks.filter(task => !task.supersededAt && !task.archivedAt && (task.kind === 'stock' ? new Date(task.dueAt) <= this.clock() && (!task.completedAt || koreanDate(task.completedAt) === state.day) : task.date === state.day || task.workEvent && !task.completedAt));
    for (const item of result.items) {
      const review = stockReview(item);
      const task = review && state.tasks.find(task => task.id === review.id);
      item.reviewDueAt = review?.dueAt ?? null;
      item.reviewState = !review ? 'no_order' : task?.completedAt ? 'completed' : new Date(review.dueAt) <= this.clock() ? 'pending' : 'scheduled';
      item.reviewCompletedBy = task?.completedBy ?? null;
      item.reviewCompletedAt = task?.completedAt ?? null;
    }
    if (result.canEditTasks) for (const template of result.taskTemplates) {template.policyReport = policyReport(template);template.workStatus=workStatus(state,template,state.day,this.catalog);}
    const completionEnabled = actor.role === 'owner' || state.workplace?.restrictions?.[actor.role]?.complete !== false;
    const assignments = assignmentContext(state);
    for (const task of result.tasks) {
      task.assignmentView = assignmentView(state, task, null, actor, assignments);
      if (task.assignmentView.mode === 'legacy') delete task.assignmentView;
      delete task.assignmentSnapshot;
      for (const step of task.steps ?? []) { step.assignmentView = assignmentView(state, task, step, actor, assignments); if (step.assignmentView.mode === 'legacy') delete step.assignmentView; delete step.assignmentSnapshot; }
      task.canComplete = completionEnabled && !task.completedAt && (task.steps?.length ? task.steps.some(step => !step.completedAt && canCompleteStep(actor, task, step, state, assignments)) || tapOnly(task) && task.settings?.completionPolicy?.kind === 'quantity' && task.steps.every(step => step.completedAt) && task.steps.every(step => canCompleteStep(actor, task, step, state, assignments)) : allowed(actor, task, state));
      if (task.steps) for (const step of task.steps) step.canComplete = completionEnabled && !step.completedAt && canCompleteStep(actor, task, step, state, assignments);
      if (task.kind === 'routine') {
        const index = state.taskTemplates.findIndex(row => row.id === task.templateId);
        const current = state.taskTemplates[index];
        task.folderId = task.boardFolderId ?? current?.folderId ?? (state.checklistFolders.some(folder => folder.id === task.folderId) ? task.folderId : 'general');
        task.displayOrder = task.boardOrder ?? (index < 0 ? state.taskTemplates.length : index);
        task.boardStatus = task.completedAt ? 'done' : task.boardStatus ?? (task.steps?.some(step => step.completedAt) ? 'processing' : 'todo');
      }
    }
    if (actor.role !== 'owner') delete result.privateSummary;
    if (actor.role !== 'owner') {
      delete result.hiringDrafts;
      if (result.store?.profile) {
        const { industryId, serviceModes, address, arrivalNote, hours, orderSystem } = result.store.profile;
        result.store.profile = { industryId, serviceModes, address, arrivalNote, hours, orderSystem };
      }
    }
    if (!['owner', 'manager'].includes(actor.role)) {
      for (const item of result.items) delete item.price;
      for (const order of result.orders) { delete order.total; for (const line of order.lines) delete line.price; }
    }
    result.checklistLibrary = checklistLibrary;
    if (result.canEditTasks) {result.storeSetupCatalog=storeSetupCatalog(this.catalog);result.manualCatalog=catalogView(state,this.catalog);result.catalogLinks=structuredClone(state.catalogLinks??{});result.checklistBackup=checklistBackup(state);}
    result.manualSearch = manualSearchIndex(state);
    result.manualPrintTemplates = manualPrintView(state);
    if (['owner', 'manager'].includes(actor.role)) result.recommendedTaps = recommendedTaps(state);
    if (!['owner', 'manager'].includes(actor.role)) delete result.taskTemplates;
    return result;
  }
  snapshot(actorId, options = {}) {
    const actor = this.#actor(actorId);
    const dates = scheduleRange(options);
    return this.#serial(async () => {
      const state = await this.#read();
      const now = this.clock();
      const changed = ensureDueTasks(state, now,this.catalog,this.catalogRevision);
      if (ensureDefaultAssignments(state,now,{dates}) || changed) { state.revision++; await this.#save(state); }
      return this.#view(state, actor);
    });
  }
  mutate(actorId, input) {
    let actor = this.#actor(actorId);
    return this.#serial(async () => {
      const state = await this.#read();
      const now = this.clock();
      if (ensureDueTasks(state, now,this.catalog,this.catalogRevision)) { state.revision++; await this.#save(state); }
      if (input.action === 'split_tap_policy' && input.operationId && state.tapPolicyHistory?.some(h => h.operationId === input.operationId && h.actor.id === actor.id && h.template.id === input.templateId)) return this.#view(state,actor);
      actor = actorWithParts(state, actor);
      checkWorkplacePermission(state, actor, input.action);
      if (eventReplay(state,input,actor)) return this.#view(state,actor);
      if (manualMarketReplay(state,input,actor)) return this.#view(state,actor);
      if (input.revision !== state.revision) fail('다른 동료가 먼저 업데이트했어요. 최신 내용을 확인하고 다시 눌러 주세요.', 409);
      const scheduleDates = scheduleRange(input);
      const who = { id: actor.id, name: actor.name, role: actor.label };
      const activity = (message, kind) => state.activity.unshift({ id: randomUUID(), at: iso(now), actor: who, message, ...(kind ? { kind } : {}) });
      const itemFor = id => { const item = state.items.find(item => item.id === id && !item.archivedAt); if (!item) fail('사용 중인 재료를 찾지 못했어요.', 404); return item; };
      const previousTemplates = structuredClone(state.taskTemplates);
      switch (input.action) {
        case 'start_blank_from_sample': {
          if (!this.trustedActor || actor.role !== 'owner') fail('클라우드 매장 사장님만 시작 방식을 바꿀 수 있어요.', 403);
          if (state.store?.setup === 'blank' || state.store?.setup === 'configured' || state.sales?.source !== 'sample' || state.sampleArchive) fail('샘플 매장 상태를 확인해 주세요.', 409);
          const archive = structuredClone(state);
          const blank = emptyOperations(now, actor.id, actor.name);
          for (const key of Object.keys(state)) delete state[key];
          Object.assign(state, blank, { revision: archive.revision, sampleArchive: { savedAt: iso(now), state: archive } });
          activity('샘플 데이터를 보관하고 빈 매장으로 시작'); break;
        }
        case 'save_store': {
          if (actor.role !== 'owner') fail('매장 정보는 사장님만 바꿀 수 있어요.', 403);
          const name = text(input.name, '매장 이름', 80);
          if (input.note != null && typeof input.note !== 'string') fail('매장 안내를 확인해 주세요.');
          const note = input.note == null ? '' : input.note.trim();
          if (note.length > 500) fail('매장 안내는 500자 이내로 입력해 주세요.');
          state.store = { ...state.store, name, note, setup: 'configured' };
          if (state.layout?.name === '우리 매장') state.layout.name = name;
          activity(`매장 정보 · ${name}`); break;
        }
        case 'save_store_profile': {
          if (actor.role !== 'owner') fail('매장 설정은 사장님만 바꿀 수 있어요.', 403);
          saveStoreProfile(state, input.section, input.values);
          activity(`우리매장 · ${input.section} 설정`); break;
        }
        case 'save_hiring_draft': {
          if (actor.role !== 'owner') fail('채용 초안은 사장님만 저장할 수 있어요.', 403);
          const draft = saveHiringDraft(state, input, actor, now);
          activity(`채용 공고 초안 · ${draft.roleId}`); break;
        }
        case 'archive_hiring_draft': {
          if (actor.role !== 'owner') fail('채용 초안은 사장님만 보관할 수 있어요.', 403);
          const draft = (state.hiringDrafts ?? []).find(row => row.id === input.id && row.status === 'draft');
          if (!draft) fail('공고 초안을 찾지 못했어요.', 404);
          draft.status = 'archived'; draft.updatedAt = iso(now); draft.updatedBy = who;
          activity('채용 공고 초안 보관'); break;
        }
        case 'save_inventory_item': {
          leadership(actor);
          const old = input.id ? itemFor(input.id) : null;
          const name = text(input.name, '재료 이름', 80);
          const unit = text(input.unit, '단위', 20);
          const supplier = text(input.supplier, '공급처', 80);
          const emoji = typeof input.emoji === 'string' && input.emoji.trim() && input.emoji.length <= 12 ? input.emoji.trim() : '📦';
          const zone = input.zone == null || input.zone === '' ? null : input.zone;
          if (zone && !state.zones.some(z => z.id === zone)) fail('보관 위치를 확인해 주세요.');
          if (state.items.some(row => row.id !== old?.id && !row.archivedAt && row.name === name)) fail('같은 이름의 재료가 있어요.');
          const minimum = amount(input.minimum), orderQuantity = amount(input.orderQuantity);
          if (orderQuantity <= 0) fail('기본 발주 수량은 0보다 커야 해요.');
          if (!Number.isSafeInteger(input.price) || input.price < 0 || input.price > 100000000) fail('예상 단가는 0~100,000,000원 사이로 입력해 주세요.');
          if (!Number.isInteger(input.reviewDays) || input.reviewDays < 1 || input.reviewDays > 90) fail('발주 후 확인 일수는 1~90일로 정해 주세요.');
          if (old && state.orders.some(order => order.status === 'ordered' && order.lines.some(line => line.itemId === old.id)) && (old.unit !== unit || old.supplier !== supplier)) fail('입고 대기 중에는 단위와 공급처를 바꿀 수 없어요.', 409);
          const editable = { name, unit, supplier, emoji, zone, minimum, orderQuantity, price: input.price, reviewDays: input.reviewDays };
          if (old) Object.assign(old, editable, {setupNeedsReview:false});
          else {
            if (state.items.length >= 500) fail('재료는 최대 500개까지 등록할 수 있어요.');
            state.items.push({ id: randomUUID(), ...editable, quantity: 0, lastOrderedAt: null, lastCheckedAt: null });
          }
          activity(`재료 ${old ? '수정' : '등록'} · ${name}`); break;
        }
        case 'archive_inventory_item': {
          leadership(actor);
          const item = itemFor(input.id);
          if (state.orders.some(order => order.status === 'ordered' && order.lines.some(line => line.itemId === item.id))) fail('입고 대기 중인 재료는 보관 처리할 수 없어요.', 409);
          if (state.tasks.some(task => task.itemId === item.id && !task.completedAt && !task.archivedAt && !task.supersededAt)) fail('미완료 재고 확인 업무를 먼저 처리해 주세요.', 409);
          item.archivedAt = iso(now); item.archivedBy = who;
          activity(`재료 보관 · ${item.name}`); break;
        }
        case 'save_menu': {
          leadership(actor);
          const old = input.id ? state.sales.menus.find(menu => menu.id === input.id && !menu.archivedAt) : null;
          if (input.id && !old) fail('사용 중인 메뉴를 찾지 못했어요.', 404);
          const name = text(input.name, '메뉴 이름', 80), category = text(input.category, '분류', 40);
          if (!Number.isSafeInteger(input.price) || input.price < 0 || input.price > 100000000) fail('메뉴 가격은 0~100,000,000원 사이로 입력해 주세요.');
          if (state.sales.menus.some(menu => menu.id !== old?.id && !menu.archivedAt && menu.name === name)) fail('같은 이름의 메뉴가 있어요.');
          if (old) Object.assign(old, { name, category, price: input.price, setupNeedsReview:false });
          else {
            if (state.sales.menus.length >= 500) fail('메뉴는 최대 500개까지 등록할 수 있어요.');
            state.sales.menus.push({ id: randomUUID(), name, category, price: input.price });
          }
          activity(`메뉴 ${old ? '수정' : '등록'} · ${name}`); break;
        }
        case 'archive_menu': {
          leadership(actor);
          const menu = state.sales.menus.find(row => row.id === input.id && !row.archivedAt);
          if (!menu) fail('사용 중인 메뉴를 찾지 못했어요.', 404);
          if (state.sales.tickets.some(ticket => ['접수', '조리 중', '준비 완료'].includes(ticket.status) && ticket.lines.some(line => line.menuId === menu.id))) fail('진행 중인 주문이 있는 메뉴는 보관 처리할 수 없어요.', 409);
          if ((state.preparedItems ?? []).some(item => item.menuUses?.some(use => use.menuId === menu.id))) fail('준비품 사용량에서 이 메뉴를 먼저 제거해 주세요.', 409);
          menu.archivedAt = iso(now); menu.archivedBy = who;
          activity(`메뉴 보관 · ${menu.name}`); break;
        }
        case 'save_prepared_item': {
          leadership(actor); savePreparedItem(state, input);
          activity('준비품·메뉴별 사용량 설정'); break;
        }
        case 'count_prepared_item': {
          leadership(actor); countPreparedItem(state, input, now, who);
          activity('준비품 실제 수량 보정'); break;
        }
        case 'complete_preparation': {
          const task = state.tasks.find(t => t.id === input.taskId && t.preparedItemId && !t.archivedAt && t.date === state.day);
          if (!task) fail('준비 Tap을 찾지 못했어요.', 404);
          if (task.supersededAt || task.completedAt || !(task.steps?.length ? task.steps.filter(s => !s.completedAt).every(s => canCompleteStep(actor, task, s, state)) : allowed(actor, task, state))) fail('준비 Tap 상태와 담당자를 확인해 주세요.', 409);
          finishPreparation(state, task, input.quantity, now, who);
          for (const step of task.steps) if (!step.completedAt) { snapshotAssignments(state, task, step); step.completedAt = iso(now); step.completedBy = who; }
          snapshotAssignments(state, task); task.completedAt = iso(now); task.completedBy = who; task.boardStatus = 'done';
          activity(`${task.title} · 실제 ${input.quantity} 완성`); break;
        }
        case 'save_manual_print_translation': {
          saveManualPrintTranslation(state,input,actor,now);
          activity('인쇄용 매뉴얼 번역 저장'); break;
        }
        case 'edit_manual_node': {
          leadership(actor); editManualNode(state,input,actor,now); activity('매뉴얼 항목 편집'); break;
        }
        case 'edit_work_node': {
          leadership(actor); editWorkNode(state,input,actor,now); activity('업무 항목 편집'); break;
        }
        case 'save_task_step': {
          leadership(actor);
          const task = state.tasks.find(t => t.id === input.taskId && t.kind === 'routine' && !t.archivedAt && !t.supersededAt && t.date === state.day);
          if (!task || task.completedAt || task.preparedOutputMovementId) fail('오늘 진행 중인 TAP만 편집할 수 있어요.', 409);
          const adding = input.stepId == null;
          const step = adding ? { id: randomUUID(), tip: '', tags: [] } : task.steps.find(s => s.id === input.stepId);
          if (!step || step.completedAt) fail('미완료 Task만 편집할 수 있어요.', 409);
          const title = text(input.title, 'Task 이름', 100), manual = text(input.manual, '매뉴얼', 700);
          const template = state.taskTemplates.find(t => t.id === (step.sourceTemplateId ?? task.templateId) && !t.archivedAt);
          const source = template?.steps.find(s => s.id === (step.sourceStepId ?? step.id));
          if (adding && (task.steps.length >= 30 || (template && template.steps.length >= 30))) fail('Task는 최대 30개까지 추가할 수 있어요.');
          if (!adding) {
            step.manualHistory ??= [];
            step.manualHistory.push({ title: step.title, manual: step.manual, at: iso(now), actor: who });
          }
          assertContentOnly(input);
          Object.assign(step, { title, manual });
          if (adding) task.steps.push(step);
          if (adding && template) template.steps.push(structuredClone(step));
          else if (source) Object.assign(source, { title, manual });
          if (template && (adding || source)) template.version++;
          activity(`${task.title} · Task ${adding ? '추가' : '수정'}`); break;
        }
        case 'save_step_manual': {
          leadership(actor);
          const task = state.tasks.find(t => t.id === input.taskId && !t.archivedAt && !t.supersededAt && t.date === state.day);
          const step = task?.steps?.find(s => s.id === input.stepId);
          if (!step || step.completedAt) fail('아직 완료하지 않은 오늘 Task만 편집할 수 있어요.', 409);
          assertContentOnly(input);
          const manual = text(input.manual, '매뉴얼', 700);
          const videoUrl = mediaLink(input.videoUrl), imageUrl = mediaLink(input.imageUrl), sourceUrl = mediaLink(input.sourceUrl ?? step.sourceUrl), tags = manualTags(input.tags ?? step.tags);
          step.manualHistory ??= [];
          step.manualHistory.push({ manual: step.manual, tags: step.tags ?? [], videoUrl: step.videoUrl ?? '', imageUrl: step.imageUrl ?? '', sourceUrl: step.sourceUrl ?? '', at: iso(now), actor: who });
          Object.assign(step, { manual, videoUrl, imageUrl, sourceUrl, tags });
          const template = state.taskTemplates.find(t => t.id === (step.sourceTemplateId ?? task.templateId));
          const source = template?.steps.find(s => s.id === (step.sourceStepId ?? step.id));
          if (source) { Object.assign(source, { manual, videoUrl, imageUrl, sourceUrl, tags }); template.version++; }
          activity(`${task.title} · ${step.title} 매뉴얼 저장`); break;
        }
        case 'save_manual_setup': {
          leadership(actor);
          saveManualSetup(state,input.setup);
          retireUnstartedComposition(state, now);
          activity('매뉴얼 구성·공통 장소 저장');
          break;
        }
        case 'save_place': {
          leadership(actor);
          savePlace(state,input,now);
          activity('매장 장소 안내 저장');
          break;
        }
        case 'save_layout': {
          leadership(actor);
          const updated = validateLayout(input, state);
          state.layout = { ...updated.layout, updatedAt: iso(now), updatedBy: who };
          state.zones = updated.zones;
          activity(`매장 배치 저장 · 테이블 ${state.zones.filter(zone => zone.kind === 'table').length}개`);
          break;
        }
        case 'move_manual_node': {
          leadership(actor);
          moveManualNode(state, input);
          activity('매뉴얼 디렉토리 이동'); break;
        }
        case 'save_checklists': {
          leadership(actor);
          for (const item of state.preparedItems ?? []) if (!input.folders?.some(folder => folder.id === item.folderId)) fail(`${item.name} 준비 TAP그룹이 연결되어 있어 폴더를 삭제할 수 없어요.`);
          saveChecklists(input, state, now);
          state.bigTapOrder = [...(state.bigTapOrder ?? []).filter(id => state.checklistFolders.some(folder => folder.id === id)), ...state.checklistFolders.map(folder => folder.id).filter(id => !(state.bigTapOrder ?? []).includes(id))];
          activity('업무 폴더·카드·매뉴얼 저장'); break;
        }
        case 'split_tap_policy': {
          leadership(actor);
          const template = state.taskTemplates.find(t => t.id === input.templateId && !t.archivedAt);
          if (!template || tapOnly(template) || template.menuManualId || template.settings?.type === 'order' || template.settings?.type === 'preparation') fail('분리할 기존 일반 TAP을 확인해 주세요.',409);
          if (template.settings?.enforceSequence) fail('순서가 연결된 TAP은 먼저 절차와 순서 규칙을 정리해 주세요.',409);
          if (template.steps.length < 2 || state.taskTemplates.length + template.steps.length > 650) fail('분리할 Task 수와 TAP 한도를 확인해 주세요.');
          if (typeof input.operationId !== 'string' || !input.operationId || input.operationId.length > 150) fail('분리 작업 ID를 확인해 주세요.');
          const before = structuredClone(template), next = [];
          for (const step of template.steps) {
            const settings = {...taskSettings(template)};
            const old = step.settings ?? {};
            if (old.assignment && old.assignment.mode !== 'inherit') settings.assignment = old.assignment;
            settings.completionPolicy = {kind:old.completionKind ?? 'check',quantitySpec:old.quantitySpec ?? null};
            settings.estimatedMinutes = old.estimatedMinutes ?? null;
            const copy = {...structuredClone(template),id:randomUUID(),title:`${template.title} · ${step.title}`.slice(0,100),version:1,
              steps:[structuredClone(step)],generationNotBeforeBusinessDate:shiftDate(state.day,1),
              policyLineage:{templateId:template.id,stepId:step.id},zone:old.zoneOverride ?? template.zone,partId:old.partOverride ?? template.partId,
              requiredRole:old.roleOverride ?? template.requiredRole};
            state.taskTemplates.push(copy);
            saveTapSettings(state,{templateId:copy.id,assignmentScopeVersion:2,acknowledgeLegacyPolicy:true,settings,zone:copy.zone},now);
            next.push(copy.id);
          }
          template.archivedAt=iso(now);
          (state.tapPolicyHistory ??= []).push({at:iso(now),actor:who,operationId:input.operationId,template:before,replacements:next});
          activity(`${template.title} · Task별 TAP 분리 · 다음 영업일부터`);break;
        }
        case 'preview_tap_policy_migration': {
          leadership(actor);
          const template = state.taskTemplates.find(t => t.id === input.templateId && !t.archivedAt);
          if (!template) fail('TAP 양식을 찾지 못했어요.',404);
          return {...this.#view(state,actor),tapPolicyPreview:{templateId:template.id,templateVersion:template.version,revision:state.revision,...policyReport(template)}};
        }
        case 'replace_mixed_break': {
          leadership(actor); replaceMixedBreak(state,input,actor,now,this.catalog);activity('브레이크 공통 업무와 메뉴 준비 분리');break;
        }
        case 'flag_work_issue':
        case 'resolve_work_issue': {
          const task=state.tasks.find(t=>t.id===input.taskId&&t.workEvent&&!t.archivedAt&&!t.completedAt);
          if(!task) fail('진행 중인 작업을 확인해 주세요.',404);
          if(!allowed(actor,task,state)) fail('담당 업무를 확인해 주세요.',403);
          if(typeof input.reason!=='string'||!input.reason.trim()||input.reason.length>500) fail('상태와 조치를 500자 이내로 적어 주세요.');
          if(input.action==='resolve_work_issue') {
            leadership(actor);
            if(task.workIssue?.status!=='open') fail('확인할 이상 기록이 없어요.');
            task.workIssue={...task.workIssue,status:'resolved',resolution:input.reason.trim(),resolvedAt:iso(now),resolvedBy:who};
          } else {
            (task.workIssueHistory??=[]).push(...(task.workIssue?[structuredClone(task.workIssue)]:[]));
            task.workIssue={status:'open',reason:input.reason.trim(),at:iso(now),actor:who};
          }
          activity('작업 이상·조치 기록');break;
        }
        case 'start_manual_work': {
          leadership(actor); startManualWork(state,input,actor,now); activity('작업별 체크리스트 생성'); break;
        }
        case 'save_tap_settings': {
          leadership(actor);
          const before = state.taskTemplates.find(t => t.id === input.templateId);
          const template = saveTapSettings(state, input, now);
          if (input.assignmentScopeVersion === 2 && before && !tapOnly(previousTemplates.find(t => t.id === input.templateId))) {
            (state.tapPolicyHistory ??= []).push({at:iso(now),actor:who,template:previousTemplates.find(t => t.id === input.templateId)});
          }
          activity(`${template.title} · 설정 변경 · 배정 변경은 오늘 미착수 업무부터 반영`); break;
        }
        case 'import_recommended_taps': {
          leadership(actor);
          importRecommendedTaps(state, input.ids);
          ensureDueTasks(state, now,this.catalog,this.catalogRevision);
          activity(`추천 업무 ${input.ids.length}개 선택 가져오기`); break;
        }
        case 'reopen_step': {
          const task = state.tasks.find(task => task.id === input.taskId);
          if (!task) fail('업무를 찾지 못했어요.', 404);
          if (task.preparedOutputMovementId) fail('완성 수량이 반영된 준비 Tap은 되돌릴 수 없어요. 실제 수량 보정을 사용해 주세요.', 409);
          if (task.archivedAt || task.supersededAt || task.date !== state.day) fail('오늘 업무만 되돌릴 수 있어요.', 409);
          if (taskSettings(task).enforceSequence) {
            const index = task.steps.findIndex(step => step.id === input.stepId);
            if (index >= 0 && task.steps.slice(index + 1).some(step => step.completedAt)) fail('뒤의 Task부터 되돌려 주세요.', 409);
          }
          reopenStep(task, input.stepId, actor, ['owner', 'manager'].includes(actor.role));
          delete task.actualQuantity;
          delete task.steps.find(step => step.id === input.stepId)?.actualQuantity;
          delete task.steps.find(step => step.id === input.stepId)?.assignmentSnapshot; delete task.assignmentSnapshot;
          task.boardStatus = 'processing';
          activity(`${task.title} · 확인 되돌림`); break;
        }
        case 'complete_step':
        case 'complete_task': {
          const task = state.tasks.find(task => task.id === input.taskId);
          if (!task) fail('업무를 찾지 못했어요.', 404);
          if (task.archivedAt) fail('업무가 변경되었어요. 최신 카드를 확인해 주세요.', 409);
          if (task.supersededAt || new Date(task.dueAt) > now) fail('발주 기준 확인 예정일이 바뀌었어요. 최신 업무를 확인해 주세요.', 409);
          if (task.kind === 'routine' && !task.workEvent && task.date !== state.day) fail('오늘 업무를 다시 확인해 주세요.', 409);
          if(task.workIssue?.status==='open') fail('이상 기록의 조치를 먼저 확인해 주세요.',409);
          if (task.completedAt) fail(`${task.completedBy.name}님이 이미 확인했어요.`, 409);
          const selectedStep = input.action === 'complete_step' ? task.steps?.find(step => step.id === input.stepId) : null;
          if (!(selectedStep ? canCompleteStep(actor, task, selectedStep, state) : task.steps?.length ? task.steps.filter(s => !s.completedAt).every(s => canCompleteStep(actor, task, s, state)) : allowed(actor, task, state))) fail('이 업무의 담당 직급이 아니에요. 매니저에게 알려 주세요.', 403);
          if (task.preparedItemId && input.action === 'complete_task') fail('실제 완성 수량을 입력해 주세요.');
          if (input.action === 'complete_step') {
            const step = task.steps?.find(row => row.id === input.stepId);
            if (task.kind !== 'routine' || !step) fail('행위를 찾지 못했어요.', 404);
            if (step.completedAt) fail('동료가 이미 확인한 행위예요.', 409);
            const issue = completeStepIssue(actor, task, step, input.quantity, state);
            if (issue) fail(issue, issue.includes('담당') ? 403 : 409);
            if (task.workEvent && task.knowledge?.safetyReviewRequired) {
              if(typeof input.evidence!=='string'||!input.evidence.trim()||input.evidence.length>500) fail('실제 시간·온도·상태와 조치를 기록해 주세요.');
              step.evidence={value:input.evidence.trim(),at:iso(now),actor:who};
            }
            if (task.preparedItemId && task.steps.filter(row => !row.completedAt).length === 1) {
              finishPreparation(state, task, input.quantity, now, who);
            }
            snapshotAssignments(state, task, step); step.completedAt = iso(now); step.completedBy = who;
            if (!tapOnly(task) && step.settings?.completionKind === 'quantity') step.actualQuantity = input.quantity;
            task.boardStatus = 'processing';
            activity(`${task.title} · ${step.title} 완료`);
            if (task.steps.every(row => row.completedAt) && !(tapOnly(task) && task.settings?.completionPolicy?.kind === 'quantity')) { snapshotAssignments(state, task); task.completedAt = iso(now); task.completedBy = who; task.boardStatus = 'done'; }
            break;
          }
          if (task.kind === 'routine') {
            const issue = bulkCompleteIssue(actor, task, state, input.quantity);
            if (issue) fail(issue, issue.includes('담당') ? 403 : 409);
          }
          if (task.kind === 'routine') for (const step of task.steps ?? []) if (!step.completedAt) {
            snapshotAssignments(state, task, step); step.completedAt = iso(now); step.completedBy = who; step.completionSource = 'tap_bulk';
          }
          if (task.kind === 'stock') { const item = itemFor(task.itemId); item.quantity = amount(input.quantity); item.lastCheckedAt = iso(now); item.checkedBy = who; }
          if (tapOnly(task) && task.settings?.completionPolicy?.kind === 'quantity') task.actualQuantity = input.quantity;
          snapshotAssignments(state, task); task.completedAt = iso(now); task.completedBy = who; task.boardStatus = 'done'; activity(`${task.title} 완료`); break;
        }
        case 'move_tap': {
          const task = state.tasks.find(row => row.id === input.taskId && row.kind === 'routine' && row.date === state.day && !row.archivedAt && !row.supersededAt);
          if (!task) fail('오늘 Tap을 찾지 못했어요.', 404);
          if (!(task.steps?.length ? task.steps.some(s => canCompleteStep(actor, task, s, state)) : allowed(actor, task, state))) fail('이 Tap의 담당자가 아니에요.', 403);
          if (!state.checklistFolders.some(folder => folder.id === input.folderId)) fail('TAP그룹을 찾지 못했어요.');
          if (!['todo', 'processing', 'done', 'keep'].includes(input.status)) fail('Tap 상태를 확인해 주세요.');
          const moving = task.orderId ? state.tasks.filter(t => t.orderId === task.orderId && !t.archivedAt && !t.supersededAt) : [task];
          if (moving.some(t => t.preparedItemId && t.completedAt && !['done', 'keep'].includes(input.status))) fail('완성 수량이 반영된 준비 Tap은 되돌릴 수 없어요.', 409);
          if (moving.some(t => t.preparedItemId && !t.completedAt && input.status === 'done')) fail('실제 완성 수량을 입력해 주세요.');
          for (const task of moving) {
          if (!(task.steps?.length ? task.steps.some(s => canCompleteStep(actor, task, s, state)) : allowed(actor, task, state))) fail('이 Tap의 담당자가 아니에요.', 403);
          if (input.status === 'done' && !task.completedAt) {
            const issue = bulkCompleteIssue(actor, task, state, input.quantity);
            if (issue) fail(issue, issue.includes('담당') ? 403 : 409);
            for (const step of task.steps ?? []) if (!step.completedAt) { snapshotAssignments(state, task, step); step.completedAt = iso(now); step.completedBy = who; step.completionSource = 'tap_bulk'; }
            if (tapOnly(task) && task.settings?.completionPolicy?.kind === 'quantity') task.actualQuantity = input.quantity;
            snapshotAssignments(state, task); task.completedAt = iso(now); task.completedBy = who;
          }
          if (input.status !== 'done' && input.status !== 'keep' && task.completedAt) {
            if (task.completedBy?.id !== actor.id && !['owner', 'manager'].includes(actor.role)) fail('완료한 본인이나 리더만 되돌릴 수 있어요.', 403);
            for (const step of task.steps ?? []) if (step.completedAt) {
              delete step.completedAt; delete step.completedBy; delete step.completionSource; delete step.assignmentSnapshot;
            }
            task.completedAt = null; task.completedBy = null; delete task.assignmentSnapshot; delete task.actualQuantity;
          }
          }
          const laneStatus = row => {
            const group = row.orderId ? state.tasks.filter(t => t.orderId === row.orderId && !t.archivedAt && !t.supersededAt) : [row];
            return group.every(t => t.completedAt) ? 'done' : row.orderId ? 'order' : 'todo';
          };
          const destinationLane = input.status === 'done' || (input.status === 'keep' && moving.every(t => t.completedAt)) ? 'done' : task.orderId ? 'order' : 'todo';
          const lane = state.tasks.filter(row => !moving.some(t => t.id === row.id) && row.kind === 'routine' && row.date === state.day && !row.archivedAt && !row.supersededAt && laneStatus(row) === destinationLane)
            .sort((a, b) => (a.boardOrder ?? (state.taskTemplates.findIndex(t => t.id === a.templateId) < 0 ? state.taskTemplates.length : state.taskTemplates.findIndex(t => t.id === a.templateId))) - (b.boardOrder ?? (state.taskTemplates.findIndex(t => t.id === b.templateId) < 0 ? state.taskTemplates.length : state.taskTemplates.findIndex(t => t.id === b.templateId))));
          const before = input.beforeTaskId == null ? lane.length : lane.findIndex(row => row.id === input.beforeTaskId);
          if (before < 0) fail('삽입할 Tap을 찾지 못했어요.', 409);
          for (const member of moving) { member.boardFolderId = input.folderId; if (input.status !== 'keep') member.boardStatus = input.status; }
          lane.splice(before, 0, ...moving);
          lane.forEach((row, index) => { row.boardOrder = index; });
          activity(`${task.title} · ${input.status} 이동`); break;
        }
        case 'reorder_small_taps': {
          leadership(actor);
          const task = state.tasks.find(row => row.id === input.taskId && row.kind === 'routine' && row.date === state.day && !row.archivedAt && !row.supersededAt);
          if (!task || !Array.isArray(input.stepIds) || input.stepIds.length !== task.steps.length || new Set(input.stepIds).size !== task.steps.length || input.stepIds.some(id => !task.steps.some(step => step.id === id))) fail('Task 순서를 확인해 주세요.');
          if (taskSettings(task).enforceSequence) fail('순서대로 수행하는 TAP은 진행 중 순서를 바꿀 수 없어요.', 409);
          task.steps.sort((a, b) => input.stepIds.indexOf(a.id) - input.stepIds.indexOf(b.id));
          activity(`${task.title} · Task 순서 변경`); break;
        }
        case 'reorder_big_taps': {
          leadership(actor);
          if (!Array.isArray(input.folderIds) || input.folderIds.length !== state.checklistFolders.length || new Set(input.folderIds).size !== input.folderIds.length || input.folderIds.some(id => !state.checklistFolders.some(folder => folder.id === id))) fail('TAP그룹 순서를 확인해 주세요.');
          state.bigTapOrder = input.folderIds;
          activity('TAP그룹 순서 변경'); break;
        }
        case 'check_stock': {
          const item = itemFor(input.itemId); item.quantity = amount(input.quantity); item.lastCheckedAt = iso(now); item.checkedBy = who;
          for (const task of state.tasks.filter(task => task.itemId === item.id && !task.completedAt && !task.supersededAt && new Date(task.dueAt) <= now)) { snapshotAssignments(state, task); task.completedAt = iso(now); task.completedBy = who; }
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
          state.taskTemplates.push(template); ensureDueTasks(state, now,this.catalog,this.catalogRevision); activity(`${template.title} · ${template.slot} 반복 업무 등록`); break;
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
          validateLayout({ layout: state.layout, zones: state.zones.filter(z=>z.mapped!==false) }, state);
          state.layout.updatedAt = iso(now); state.layout.updatedBy = who;
          activity(`${zone.name} 위치 안내 업데이트`); break;
        }
        default: if (!mutateManualMarket(state,input,actor,now,this.catalog) && !mutateWorkplace(state, input, actor, now, activity, Boolean(this.trustedActor)) && !mutateStaff(state, input, actor, now, who, activity)) fail('지원하지 않는 작업이에요.');
      }
      if (['move_tap', 'complete_task', 'complete_step', 'reopen_step'].includes(input.action)) syncOrderFromTap(state, input.taskId);
      if (['move_tap', 'complete_task', 'complete_step'].includes(input.action)) {
        const task = state.tasks.find(t => t.id === input.taskId);
        const moving = task?.orderId ? state.tasks.filter(t => t.orderId === task.orderId && !t.archivedAt) : task ? [task] : [];
        for (const row of moving) consumePreparedForTask(state, row, now, who);
      }
      for (const template of state.taskTemplates) {
        if (!previousTemplates.some(t => t.id === template.id)) { convertPolicy(template); }
        if (tapOnly(template)) for (const step of template.steps) assertContentOnly(step);
      }
      if (['save_manual_tap','save_checklists','save_step_manual','edit_manual_node','edit_work_node','save_task_step','create_task','restore_checklist_backup'].includes(input.action)) for (const t of state.taskTemplates) {
        const old=previousTemplates.find(x=>x.id===t.id);
        if(!old||contentHash(old)!==contentHash(t))t.manualCustomization={kind:!old||old.manualCustomization?.kind==='created'?'created':'modified',at:iso(now)};
      }
      updateContentRevisions(previousTemplates,state);
      reconcileCatalogLinks(state,now);
      state.activity = state.activity.slice(0, 100);
      ensureDueTasks(state, now,this.catalog,this.catalogRevision);
      ensureDefaultAssignments(state,now,{dates:scheduleDates});
      state.revision++; await this.#save(state);
      return this.#view(state, actor);
    });
  }
}
