import { operatingSegments } from './business_breaks.mjs';
import { bandForPart } from './business_day.mjs';
// Stable part IDs are the operational classification. Rank remains authorization.
import { StoreError } from './store.mjs';
export function defaultWorkplace() {
  return { parts: [
    { id: 'kitchen', name: '주방', hidden: false, roles: ['cook', 'prep', 'dishwashing'], duties: ['조리'] },
    { id: 'hall', name: '홀', hidden: false, roles: ['crew', 'service'], duties: ['서빙1', '서빙2'] },
    { id: 'management', name: '관리', hidden: false, roles: ['manager', 'owner', 'cashier'], duties: ['cashier'] },
  ], days: {}, restrictions: {} };
}
export const partsOf = state => (state.workplace ?? defaultWorkplace()).parts;
export function partForLegacy(state, value) {
  return partsOf(state).find(p => p.roles?.includes(value) || p.duties?.includes(value))?.id ?? null;
}
export function crewPartIds(state, person) {
  if (person?.workProfile && Object.hasOwn(person.workProfile, 'partIds')) return person.workProfile.partIds.length ? person.workProfile.partIds : partsOf(state).map(p => p.id);
  return [...new Set((person?.duties ?? []).map(d => partForLegacy(state, d)).filter(Boolean))];
}
export function actorWithParts(state, actor) {
  const person = state.tappers?.find(p => p.actorId === actor.id && p.active);
  return { ...actor, partIds: person ? crewPartIds(state, person) : [] };
}
export function validatePart(state, id, { allowAll = false, allowHidden = false } = {}) {
  if (allowAll && id == null) return null;
  const part = partsOf(state).find(p => p.id === id && (allowHidden || !p.hidden));
  if (!part) throw new StoreError('사용 중인 파트를 선택해 주세요.', 400);
  return part.id;
}
// Metadata is deterministic for old records, so reads do not rewrite real data.
export function workplaceBands(bands, weekday) {
  return bands.map((band, index) => band.id ? { ...band } : {
    ...band, id: `legacy-band-${weekday}-${index}`, legacyIndex: index,
  });
}
// Equivalent unversioned bands share one link target across weekdays.
// Existing explicit IDs are never renamed; legacyIndex remains weekday-local.
export function workplaceBandDays(state, { includeHours = false } = {}) {
  const days = structuredClone(state.workplace?.days ?? {});
  const hours = state.store?.profile?.hours;
  if (includeHours && hours) for (let day = 1; day <= 7; day++) {
    days[day] ??= hours.weekdays.includes(day) ? [{name:'전체',start:hours.opening,end:hours.closing}] : [];
  }
  const shared = new Map();
  for (const day of Object.keys(days).sort((a,b) => Number(a)-Number(b))) {
    const occurrences = new Map();
    days[day] = days[day].map((band, index) => {
      if (band.id) return band;
      const counts = partsOf(state).map(p => [p.id, band.headcounts?.[p.id] ?? (band.custom === true ? 0 : 1)]).sort(([a],[b]) => a.localeCompare(b));
      const descriptor = JSON.stringify([band.name, band.start, band.end, counts]);
      const occurrence = occurrences.get(descriptor) ?? 0;
      occurrences.set(descriptor, occurrence + 1);
      const signature = `${descriptor}:${occurrence}`;
      if (!shared.has(signature)) shared.set(signature, `legacy-band-${day}-${index}`);
      return { ...band, id: shared.get(signature), legacyIndex:index };
    });
  }
  return days;
}
export function ensurePartModel(state) {
  let changed = false;
  if (!state.workplace) { state.workplace = defaultWorkplace(); changed = true; }
  if (Object.values(state.workplace.days ?? {}).some(bands => bands.some(b => !b.id))) {
    state.workplace.days = workplaceBandDays(state);
    changed = true;
  }
  for (const person of state.tappers ?? []) {
    if (!person.workProfile || !Object.hasOwn(person.workProfile, 'partIds')) {
      person.workProfile = { ...person.workProfile, partIds: crewPartIds(state, person), bands: person.workProfile?.bands ?? [] }; changed = true;
    }
  }
  for (const row of [...state.staffShifts ?? [], ...state.staffingSlots ?? []]) {
    if (!Object.hasOwn(row, 'partId')) { row.partId = partForLegacy(state, row.duty); changed = true; }
  }
  for (const row of [...state.taskTemplates ?? [], ...state.tasks ?? []]) {
    if (!Object.hasOwn(row, 'partId')) { row.partId = partForLegacy(state, row.requiredRole); changed = true; }
  }
  for (const row of [...(state.hiringDrafts ?? []), ...(state.store?.profile?.staffing?.roleTargets ?? [])]) {
    if (!Object.hasOwn(row, 'partId')) { row.partId = partForLegacy(state, row.roleId); changed = true; }
  }
  if (state.partModelVersion !== 1) { state.partModelVersion = 1; changed = true; }
  return changed;
}
export function rosterTemplates(state) {
  const result = [];
  const workplace = state.workplace ?? defaultWorkplace();
  const hours = state.store?.profile?.hours;
  const identifiedDays = workplaceBandDays(state, {includeHours:true});
  for (let weekday = 1; weekday <= 7; weekday++) {
    const configured = Object.hasOwn(workplace.days ?? {}, weekday);
    const bands = configured || hours ? identifiedDays[weekday] : null;
    if (bands !== null) {
      for (const part of partsOf(state).filter(p => !p.hidden)) for (const [index, band] of bands.entries()) {
        const count = band.headcounts?.[part.id] ?? (band.custom === true ? 0 : 1);
        const key = band.legacyIndex ?? band.id ?? index;
        for (let seat=0; seat<count; seat++) for (const segment of operatingSegments(bandForPart(band,part.id), workplace.breaks?.[weekday], workplace.businessDayStart)) result.push({ id: `band-${weekday}-${part.id}-${key}${seat ? `-seat-${seat}` : ''}${segment.suffix}`, weekday, bandId: band.id ?? `legacy-band-${weekday}-${index}`, partId: part.id, name: band.name, start: segment.start, end: segment.end, ...(segment.dayOffset === undefined ? {} : {dayOffset: segment.dayOffset}), source: 'hours' });
      }
    } else {
      for (const slot of state.staffingSlots ?? []) {
        if (!(slot.weekdays ?? [1,2,3,4,5,6,7]).includes(weekday)) continue;
        const partId = slot.partId ?? partForLegacy(state, slot.duty);
        if (!partsOf(state).some(p => p.id === partId && !p.hidden)) continue;
        result.push({ id: `legacy-${weekday}-${slot.id}`, weekday, partId, name: '기존 슬롯', start: slot.start, end: slot.end, source: 'legacy' });
      }
    }
  }
  return result;
}
export function validRosterDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value) || !Number.isFinite(Date.parse(value)) || new Date(value).toISOString().slice(0,10) !== value) throw new StoreError('근무 날짜를 확인해 주세요.', 400);
  return new Date(`${value}T00:00:00Z`).getUTCDay() || 7;
}
export function validRosterTimes(start, end) {
  if (![start,end].every(t => typeof t === 'string' && /^(?:[01]\d|2[0-3]):(?:00|30)$/.test(t)) || start === end) throw new StoreError('서로 다른 30분 단위 시작·종료 시간을 선택해 주세요.', 400);
}
