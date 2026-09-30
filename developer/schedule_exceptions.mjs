import { StoreError } from './store.mjs';

export const kstDate = time => new Date(time + 9 * 3600000).toISOString().slice(0, 10);
const clock = time => new Date(time + 9 * 3600000).toISOString().slice(11, 16);
export const rangeFields = (start, end) => ({ date: kstDate(start), start: clock(start), end: clock(end) });
export function hasAttendance(state, shift, interval) {
  const [start, end] = interval(shift);
  return (state.attendance ?? []).some(e => e.tapperId === shift.tapperId &&
    (kstDate(Date.parse(e.at)) === shift.date || (Date.parse(e.at) >= start && Date.parse(e.at) < end)));
}
export function timeBandFields(state, entry, weekday) {
  if (entry.timeBandId == null || entry.timeBandId === '') return {};
  const band = state.workplace?.days?.[weekday]?.find(b => b.id === entry.timeBandId);
  if (!band) throw new StoreError('시간대가 바뀌었어요. 요일의 시간대를 다시 선택해 주세요.', 409);
  return { timeBandId: band.id };
}
// Absolute KST intervals allow OFF periods on the next day of an overnight shift.
export function requestedRanges(shift, input, interval) {
  const [a, b] = interval(shift);
  if (input.kind === 'leave') return { work: [], vacant: [[a, b]] };
  const validClock = v => typeof v === 'string' && /^(?:[01]\d|2[0-3]):(?:00|30)$/.test(v);
  if (!validClock(input.start) || !validClock(input.end) || input.start === input.end) throw new StoreError('시작·종료를 30분 단위로 확인해 주세요.', 400);
  let c = Date.parse(`${shift.date}T${input.start}:00+09:00`);
  if (c < a) c += 86400000;
  let d = Date.parse(`${shift.date}T${input.end}:00+09:00`);
  while (d <= c) d += 86400000;
  if (c < a || d > b || (c === a && d === b)) throw new StoreError('기존 근무 안의 일부 시간을 선택해 주세요.', 400);
  const outside = [[a, c], [d, b]].filter(([x, y]) => x < y);
  return input.kind === 'partial_off' ? { work: outside, vacant: [[c, d]] } : { work: [[c, d]], vacant: outside };
}
