import { defaultWorkplace, validatePart, rosterTemplates, validRosterDate, validRosterTimes } from './parts.mjs';
import { randomBytes, randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
const fail = (message, status = 400) => { throw new StoreError(message, status); };
const label = value => {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > 40) fail('이름은 1–40자로 입력해 주세요.');
  return value.trim();
};
export const permissionActions = {
  tasks: ['create_task', 'save_checklists', 'save_tap_settings', 'save_step_manual', 'move_manual_node', 'import_recommended_taps'],
  complete: ['complete_task', 'complete_step', 'reopen_step', 'move_tap', 'complete_preparation'],
  schedule: ['save_roster_slot', 'reset_roster_slot', 'delete_staff_shift', 'save_staffing_slots', 'assign_staffing_slot', 'save_staff_shift', 'save_shift_pattern', 'assign_cover', 'update_shift'],
  stock: ['check_stock', 'count_prepared_item'],
  orders: ['place_order', 'receive_order'],
};
export const workplaceDefaults = defaultWorkplace;
export function workplaceView(state, actor) {
  const config = structuredClone(state.workplace ?? workplaceDefaults());
  if (actor.role !== 'owner') delete config.restrictions;
  return config;
}
export function checkWorkplacePermission(state, actor, action) {
  if (actor.role === 'owner') return;
  const rules = state.workplace?.restrictions?.[actor.role] ?? {};
  for (const [key, actions] of Object.entries(permissionActions)) {
    if (rules[key] === false && actions.includes(action)) fail('사장님이 이 직책의 작업 권한을 껐어요.', 403);
  }
}
export function mutateWorkplace(state, input, actor, now, activity, authenticated) {
  const actions = ['save_roster_slot', 'reset_roster_slot', 'save_order_system', 'save_workplace_parts', 'save_workplace_day', 'save_workplace_permissions', 'save_staff_profile', 'create_demo_invite', 'revoke_demo_invite'];
  if (!actions.includes(input.action)) return false;
  if (['save_roster_slot','reset_roster_slot'].includes(input.action)) {
    if (!['owner','manager'].includes(actor.role)) fail('매니저 이상만 슬롯을 바꿀 수 있어요.', 403);
    const weekday = validRosterDate(input.date);
    validatePart(state, input.partId);
    const template = rosterTemplates(state).find(t => t.id === input.templateId && t.weekday === weekday && t.partId === input.partId);
    const existing = (state.rosterOverrides ?? []).find(t => t.date === input.date && t.templateId === input.templateId && t.partId === input.partId);
    if (!template && !existing) fail('슬롯이 변경됐어요. 다시 열어 주세요.', 409);
    if (input.action === 'save_roster_slot') validRosterTimes(input.start, input.end);
    state.rosterOverrides = (state.rosterOverrides ?? []).filter(t => t !== existing);
    if (input.action === 'save_roster_slot') state.rosterOverrides.push({ date: input.date, partId: input.partId, templateId: input.templateId, name: template?.name ?? existing.name, start: input.start, end: input.end });
    activity('날짜별 파트 슬롯 시간 조정'); return true;
  }
  if (actor.role !== 'owner') fail('사장님만 이 설정을 바꿀 수 있어요.', 403);
  const config = structuredClone(state.workplace ?? workplaceDefaults());
  switch (input.action) {
    case 'save_order_system': {
      if (typeof input.enabled !== 'boolean') fail('주문처리 연결 사용 여부를 선택해 주세요.');
      state.store.profile ??= {};
      state.store.profile.orderSystem = { enabled: input.enabled, connectionStatus: 'not_connected' };
      activity(input.enabled ? '주문처리 보드 표시 켜기' : '주문처리 보드 표시 끄기'); return true;
    }
    case 'save_workplace_parts': {
      if (!Array.isArray(input.parts) || !input.parts.length || input.parts.length > 12) fail('파트는 1–12개로 설정해 주세요.');
      const parts = input.parts.map(part => {
        const old = config.parts.find(p => p.id === part.id);
        if (part.id && !old) fail('파트가 변경됐어요. 다시 확인해 주세요.', 409);
        const roles = old?.roles ?? [];
        if (!Array.isArray(roles) || roles.some(r => !['cook','crew','service','prep','dishwashing','cashier','manager','owner'].includes(r)) || new Set(roles).size !== roles.length) fail('파트 업무 역할을 확인해 주세요.');
        return { id: old?.id ?? randomUUID(), name: label(part.name), hidden: part.hidden === true, roles, duties: old?.duties ?? [] };
      });
      if (new Set(parts.map(p => p.id)).size !== parts.length || new Set(parts.map(p => p.name)).size !== parts.length) fail('중복 파트 이름을 확인해 주세요.');
      if (!parts.some(p => !p.hidden)) fail('보이는 파트가 하나 이상 필요해요.');
      for (const part of config.parts) if (!parts.some(p => p.id === part.id)) fail('기록을 보존하기 위해 파트를 삭제하는 대신 숨겨 주세요.');
      config.parts = parts;
      break;
    }
    case 'save_workplace_day': {
      if (!Number.isInteger(input.weekday) || input.weekday < 1 || input.weekday > 7) fail('요일을 확인해 주세요.');
      const bands = input.bands;
      if (!Array.isArray(bands) || bands.length > 6) fail('시간대는 최대 6개예요.');
      const validTime = t => typeof t === 'string' && /^(?:[01]\d|2[0-3]):(?:00|30)$/.test(t);
      for (const [i, band] of bands.entries()) {
        if (!validTime(band.start) || !validTime(band.end) || band.start >= band.end || (i && bands[i-1].end !== band.start)) fail('시간대는 같은 날, 30분 단위로 빈틈 없이 나눠 주세요.');
      }
      if (new Set(bands.map(b => label(b.name))).size !== bands.length) fail('시간대 이름이 중복됐어요.');
      const normalized = bands.map(b => ({ name: label(b.name), start: b.start, end: b.end }));
      for (const day of input.allDays === true ? [1,2,3,4,5,6,7] : [input.weekday]) config.days[day] = normalized;
      break;
    }
    case 'save_workplace_permissions': {
      if (!['manager','cook','crew'].includes(input.role)) fail('직책을 확인해 주세요.');
      if (!input.permissions || Object.keys(input.permissions).some(k => !Object.hasOwn(permissionActions, k) || typeof input.permissions[k] !== 'boolean')) fail('권한을 확인해 주세요.');
      config.restrictions[input.role] = { ...input.permissions };
      break;
    }
    case 'save_staff_profile': {
      const person = state.tappers.find(t => t.id === input.tapperId && t.active);
      if (!person) fail('직원을 찾지 못했어요.', 404);
      if (!Array.isArray(input.partIds) || input.partIds.some(id => !config.parts.some(p => p.id === id)) || new Set(input.partIds).size !== input.partIds.length) fail('파트를 확인해 주세요.');
      if (!Array.isArray(input.bands) || input.bands.length > 6 || input.bands.some(b => !['오픈','미들','마감'].includes(b))) fail('시간대를 확인해 주세요.');
      person.workProfile = { partIds: input.partIds, bands: [...new Set(input.bands)] };
      break;
    }
    case 'create_demo_invite': {
      if (authenticated) fail('실제 계정 초대는 아직 연결되지 않았어요. 체험 매장에서 확인해 주세요.', 409);
      if (!['hourly','employee','manager'].includes(input.role)) fail('초대 직책을 확인해 주세요.');
      state.demoInvites ??= [];
      state.demoInvites = state.demoInvites.filter(i => i.role !== input.role);
      state.demoInvites.push({ role: input.role, code: randomBytes(5).toString('hex').slice(0,8).toUpperCase(), expiresAt: new Date(now.getTime()+7*86400000).toISOString(), uses: 0, limit: 20, demo: true });
      activity('체험 초대 코드 생성 · 계정 가입 불가'); return true;
    }
    case 'revoke_demo_invite': state.demoInvites = (state.demoInvites ?? []).filter(i => i.role !== input.role); activity('체험 초대 코드 폐기'); return true;
  }
  state.workplace = config;
  activity('파트·시간대·직원 설정 업데이트');
  return true;
}
