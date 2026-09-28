import { validatePart, partForLegacy } from './parts.mjs';
import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';

const fail = message => { throw new StoreError(message, 400); };
const short = (value, label, max, required = false) => {
  if (value == null && !required) return '';
  if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim())) fail(`${label}을 확인해 주세요.`);
  return value.trim();
};
const choice = (value, options, label) => {
  if (!options.includes(value)) fail(`${label}을 선택해 주세요.`);
  return value;
};
const count = (value, label, max = 999) => {
  if (!Number.isInteger(value) || value < 0 || value > max) fail(`${label}을 확인해 주세요.`);
  return value;
};
const rows = (value, label, max) => {
  if (!Array.isArray(value) || value.length > max) fail(`${label}을 확인해 주세요.`);
  return value;
};
const unique = (values, label) => { if (new Set(values).size !== values.length) fail(`${label}이 중복됐어요.`); };
const https = value => {
  if (!value) return '';
  const text = short(value, '안내 링크', 2000);
  try { const url = new URL(text); if (url.protocol === 'https:' && !url.username && !url.password) return url.href; } catch {}
  fail('HTTPS 안내 링크를 입력해 주세요.');
};
const posProviders = ['okpos', 'other'];
const deliveryProviders = ['baemin', 'coupang-eats', 'yogiyo', 'other'];
const roles = ['all', 'crew', 'cook', 'manager', 'owner', 'cashier', 'service', 'dishwashing', 'prep'];
const checked = (value, label) => { if (typeof value !== 'boolean') fail(`${label}을 선택해 주세요.`); return value; };

export function saveStoreProfile(state, section, values) {
  if (!values || typeof values !== 'object' || Array.isArray(values)) fail('매장 설정을 확인해 주세요.');
  const profile = structuredClone(state.store?.profile ?? {});
  switch (section) {
    case 'basic': {
      const name = short(values.name, '매장명', 80, true);
      const industryId = choice(values.industryId, ['restaurant', 'cafe', 'bar', 'bakery', 'other'], '업종');
      profile.industryId = industryId;
      profile.serviceModes = rows(values.serviceModes ?? [], '운영 형태', 3).map(mode => choice(mode, ['hall', 'takeout', 'delivery'], '운영 형태'));
      unique(profile.serviceModes, '운영 형태');
      profile.address = short(values.address, '주소', 200);
      profile.arrivalNote = short(values.arrivalNote, '찾아오는 안내', 300);
      state.store.name = name;
      state.store.note = short(values.note ?? state.store.note ?? '', '매장 안내', 500);
      state.store.setup = 'configured';
      if (state.layout?.name === '우리 매장') state.layout.name = name;
      break;
    }
    case 'pos': {
      const configured = checked(values.configured, 'POS 사용 여부');
      const enabled = configured ? checked(values.enabled, 'POS 사용 여부') : null;
      const devices = rows(values.devices ?? [], 'POS 단말', 10).map(device => ({
        id: short(device?.id, '단말 ID', 100) || randomUUID(),
        providerId: choice(device?.providerId, posProviders, 'POS 제품'),
        customName: short(device?.customName, '제품명', 80),
        model: short(device?.model, '모델명', 80),
        count: count(device?.count, '단말 수', 99),
        functions: rows(device?.functions ?? [], '사용 기능', 5).map(fn => choice(fn, ['orders', 'payment', 'receipt', 'kitchen-print', 'closing'], '사용 기능')),
        guideUrl: https(device?.guideUrl),
      }));
      unique(devices.map(device => device.id), '단말 ID');
      for (const device of devices) unique(device.functions, '사용 기능');
      if (enabled && !devices.length) fail('사용 중인 POS 제품을 선택해 주세요.');
      profile.pos = { configured, enabled,
        devices: !enabled && devices.length === 0 ? (profile.pos?.devices ?? []) : devices };
      break;
    }
    case 'delivery': {
      const configured = checked(values.configured, '배달 사용 여부');
      const enabled = configured ? checked(values.enabled, '배달 사용 여부') : null;
      const platforms = rows(values.platforms ?? [], '배달 플랫폼', 10).map(platform => ({
        id: short(platform?.id, '플랫폼 ID', 100) || randomUUID(),
        providerId: choice(platform?.providerId, deliveryProviders, '배달 플랫폼'),
        customName: short(platform?.customName, '플랫폼명', 80),
        acceptanceMode: choice(platform?.acceptanceMode ?? 'unset', ['unset', 'direct', 'tool'], '접수 방식'),
        device: short(platform?.device, '확인 기기', 80),
        printTicket: checked(platform?.printTicket ?? false, '출력 여부'),
        handoffMode: choice(platform?.handoffMode ?? 'unset', ['unset', 'rider', 'pickup', 'other'], '전달 방식'),
      }));
      unique(platforms.map(platform => platform.id), '플랫폼 ID');
      if (enabled && !platforms.length) fail('사용 중인 배달 플랫폼을 선택해 주세요.');
      profile.delivery = { configured, enabled,
        platforms: !enabled && platforms.length === 0 ? (profile.delivery?.platforms ?? []) : platforms };
      break;
    }
    case 'staffing': {
      const declaredCount = values.declaredCount == null ? null : count(values.declaredCount, '직원 수');
      const roleTargets = rows(values.roleTargets ?? [], '필요 역할', 12).map(row => ({
        ...(row?.partId != null ? {partId: validatePart(state, row.partId), roleId: row.partId} : {roleId: choice(row?.roleId, roles, '역할')}), count: count(row?.count, '목표 인원'),
      }));
      unique(roleTargets.map(row => row.roleId), '역할');
      profile.staffing = { declaredCount, includesOwner: checked(values.includesOwner ?? false, '사장 포함 여부'), roleTargets };
      break;
    }
    case 'hours': {
      const weekdays = rows(values.weekdays ?? [], '영업 요일', 7).map(day => count(day, '요일', 7));
      if (weekdays.some(day => day < 1)) fail('영업 요일을 확인해 주세요.');
      unique(weekdays, '영업 요일');
      const time = value => typeof value === 'string' && /^(?:[01]\d|2[0-3]):(?:00|30)$/.test(value);
      if (!time(values.opening) || !time(values.closing)) fail('영업 시간은 30분 단위로 입력해 주세요.');
      if (!weekdays.length || (!values.endsNextDay && values.closing <= values.opening)) fail('영업 요일과 시작·종료 시간을 확인해 주세요.');
      profile.hours = { weekdays, opening: values.opening, closing: values.closing,
        endsNextDay: checked(values.endsNextDay, '익일 종료 여부') };
      break;
    }
    default: fail('지원하지 않는 매장 설정이에요.');
  }
  state.store.profileVersion = 1;
  state.store.profile = profile;
}

export function saveHiringDraft(state, input, actor, now) {
  const existing = (state.hiringDrafts ?? []).find(row => row.id === input.id);
  if (input.id && !existing) throw new StoreError('공고 초안을 찾지 못했어요.', 404);
  const draft = {
    id: existing?.id ?? randomUUID(),
    partId: input.partId != null ? validatePart(state, input.partId) : partForLegacy(state, input.roleId),
    roleId: input.partId != null ? input.partId : choice(input.roleId, roles.filter(role => role !== 'all' && role !== 'owner'), '파트'),
    headcount: count(input.headcount, '필요 인원', 99),
    employmentType: choice(input.employmentType ?? 'unset', ['unset', 'regular', 'hourly', 'regular-hourly'], '고용형태'),
    weekdays: rows(input.weekdays ?? [], '근무 요일', 7).map(day => count(day, '요일', 7)),
    timeRange: short(input.timeRange, '근무 시간', 80),
    responsibilities: short(input.responsibilities, '업무 설명', 700),
    requirements: short(input.requirements, '필요 조건', 500),
    note: short(input.note, '메모', 500),
    status: 'draft', updatedBy: { id: actor.id, name: actor.name }, updatedAt: now.toISOString(),
  };
  if (draft.headcount < 1) fail('필요 인원은 1명 이상 입력해 주세요.');
  unique(draft.weekdays, '근무 요일');
  state.hiringDrafts ??= [];
  if (existing) Object.assign(existing, draft); else state.hiringDrafts.push(draft);
  return draft;
}
