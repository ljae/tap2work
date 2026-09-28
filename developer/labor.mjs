import { payrollSettings, applyPayrollEstimate } from './payroll_settings.mjs';
// Standard adult fixed-hour Korean hourly-pay estimate. All money is gross.
// Policy/contract/holiday eligibility is explicitly reviewed per employee/week.
export const laborRuleVersion = 'KR-2026-09-27';
const dayMs = 86400000;
const kstDay = ms => new Date(ms + 9 * 3600000).toISOString().slice(0, 10);
export const weekOf = day => {
  const d = new Date(`${day}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - (d.getUTCDay() + 6) % 7);
  return d.toISOString().slice(0, 10);
};
export function laborEstimate(segments, review, week, rate, planned = false) {
  const from = Date.parse(`${week}T00:00:00+09:00`), until = from + 7 * dayMs;
  const minutes = new Map();
  for (const segment of segments) {
    const start = Math.max(from, Date.parse(segment.start));
    const end = Math.min(until, Date.parse(segment.end));
    for (let at = Math.floor(start / 60000) * 60000; at < end; at += 60000) {
      const row = minutes.get(at) ?? {workday: segment.workday ?? kstDay(Date.parse(segment.start)), intervals: []};
      row.intervals.push([Math.max(start, at), Math.min(end, at + 60000)]);
      minutes.set(at, row);
    }
  }
  const durationOf = row => {
    let end = -Infinity, duration = 0;
    for (const [a,b] of row.intervals.sort((a,b)=>a[0]-b[0])) { duration += Math.max(0, b-Math.max(a,end)); end=Math.max(end,b); }
    return duration / 60000;
  };
  let worked = 0, overtime = 0, night = 0, holiday50 = 0, holiday100 = 0, regular = 0;
  const daily = new Map();
  const holidays = new Set(review?.holidayDates ?? []);
  const ordinary = review?.ordinaryHourlyWon ?? rate;
  for (const at of [...minutes.keys()].sort((a, b) => a - b)) {
    const date = kstDay(at), row = minutes.get(at), workday = row.workday, amount = durationOf(row), previous = daily.get(workday) ?? 0, dayCount = previous + amount;
    daily.set(workday, dayCount); worked += amount;
    const local = new Date(at + 9 * 3600000), hour = local.getUTCHours();
    if (hour >= 22 || hour < 6) night += amount;
    if (holidays.has(date)) {
      const first = Math.min(amount, Math.max(0, 480 - previous));
      holiday50 += first; holiday100 += amount - first;
      // Holiday premium supersedes extension premium, but night is additive.
      regular += first;
    } else {
      const weekday = (new Date(`${workday}T00:00:00Z`).getUTCDay() + 6) % 7;
      const contract = review?.shortTime ? (review.dailyContractMinutes?.[weekday] ?? 480) : 480;
      const normal = Math.min(amount, Math.max(0, Math.min(480, contract) - previous), Math.max(0, 2400 - regular));
      overtime += amount - normal; regular += normal;
    }
  }
  const alerts = [];
  const crossesWeek = segments.some(s => Date.parse(s.start) < until && Date.parse(s.end) > from && (Date.parse(s.start) < from || (s.workday && s.workday < week)));
  const holidayBoundary = segments.some(s => Date.parse(s.start) < until && Date.parse(s.end) > from && (s.workday ?? kstDay(Date.parse(s.start))) !== kstDay(Date.parse(s.end) - 1) && (holidays.has(s.workday ?? kstDay(Date.parse(s.start))) || holidays.has(kstDay(Date.parse(s.end) - 1))));
  if (crossesWeek || holidayBoundary) alerts.push('주 경계 또는 휴일 경계를 넘는 연속근무는 수당 귀속을 별도로 확인해 주세요. 합계를 보류했어요.');
  const configured = review?.scope === 'standard' && ['under5', 'fivePlus'].includes(review?.size);
  if (!review) alerts.push('계산 조건을 설정해 주세요.');
  if (review?.scope !== 'standard') alerts.push('성인·고정 근로시간 계약인지 확인해 주세요. 특례·탄력근로 등은 별도 검토가 필요해요.');
  if (!review?.size || review.size === 'unknown') alerts.push('상시근로자 5인 이상 여부를 확인해 주세요. 등록된 직원 수와 달라요.');
  if (review?.holidaysConfirmed !== true) alerts.push('이번 주 유급휴일·휴일근로 날짜를 확인해 주세요.');
  if (review?.averageWeeklyMinutes == null) alerts.push('4주 평균 소정근로시간을 입력해 주세요.');
  const eligible = review?.averageWeeklyMinutes >= 900;
  if (eligible && review?.attendance !== 'met' && review?.attendance !== 'unmet') alerts.push('이번 주 개근·주휴 요건을 확인해 주세요.');
  if (planned && worked) alerts.push('배정 예상은 휴게를 빼기 전 금액이에요. 실제 근태·휴게로 다시 확인해 주세요.');
  if (worked > 3120 && review?.size === 'fivePlus') alerts.push('주 52시간을 초과했어요. 근무 배정을 확인해 주세요.');
  if (review?.shortTime && overtime > 0) alerts.push('단시간 근로자의 소정시간 초과근로 동의를 확인해 주세요.');
  if ((review?.shortTime ? overtime : Math.max(0, worked - 2400)) > 720 && review?.size === 'fivePlus') alerts.push('연장근로가 12시간을 초과했어요. 동의·한도를 확인해 주세요.');
  if (week.startsWith('2026') && rate < 10320) alerts.push('2026년 최저시급 10,320원 미만으로 설정돼 있어요.');
  if (!week.startsWith('2026')) alerts.push('해당 연도의 최저임금·법령 기준을 별도로 확인해 주세요.');
  const premium = configured && review.size === 'fivePlus';
  const baseWon = Math.round(worked * rate / 60);
  const extensionWon = configured ? Math.round(premium ? overtime * ordinary / 120 : 0) : null;
  const nightWon = configured ? Math.round(premium ? night * ordinary / 120 : 0) : null;
  const holidayWon = configured ? Math.round(premium ? (holiday50 / 2 + holiday100) * ordinary / 60 : 0) : null;
  const weeklyRestWon = !review || review.averageWeeklyMinutes == null ? null : !eligible || review.attendance === 'unmet' ? 0 : review.attendance === 'met' ? Math.round(review.restMinutes * ordinary / 60) : null;
  const paidHolidayWon = review?.holidaysConfirmed ? Math.round((review.otherPaidHolidayMinutes ?? 0) * ordinary / 60) : null;
  const ready = !crossesWeek && !holidayBoundary && configured && weeklyRestWon !== null && paidHolidayWon !== null;
  return { workedMinutes: worked, overtimeMinutes: overtime, nightMinutes: night, holidayMinutes: holiday50 + holiday100,
    baseWon, extensionWon, nightWon, holidayWon, weeklyRestWon, paidHolidayWon,
    totalWon: ready ? baseWon + extensionWon + nightWon + holidayWon + weeklyRestWon + paidHolidayWon : null,
    alerts, status: ready ? 'estimate' : 'needs_review' };
}
export function laborView(state, sessionsFor, day) {
  const policy=payrollSettings(state);
  const weeks = new Set([weekOf(day), ...(state.laborReviews ?? []).map(r => r.week), ...state.staffShifts.map(s => weekOf(s.date))]);
  return { ruleVersion: laborRuleVersion, weeks: [...weeks].sort().map(week => ({ week, people: state.tappers.filter(t => t.active && t.rank !== 'owner').map(t => {
    const savedReview = (state.laborReviews ?? []).find(r => r.week === week && r.tapperId === t.id);
    const review = policy.configured ? {...savedReview,size:policy.businessSize} : savedReview;
    const rate = review?.hourlyWon ?? t.hourlyWon;
    const planned = state.staffShifts.filter(s => s.tapperId === t.id && s.status !== 'leave').map(s => {
      const start = Date.parse(`${s.date}T${s.start}:00+09:00`);
      let end = Date.parse(`${s.date}T${s.end}:00+09:00`); if (end <= start) end += dayMs;
      return { start: new Date(start).toISOString(), end: new Date(end).toISOString() };
    });
    const sessions = sessionsFor(t.id);
    const actual = sessions.flatMap(s => s.segments.map(segment => ({...segment, workday: kstDay(Date.parse(s.start))}))); 
    const result = { tapperId: t.id, nickname: t.nickname, hourlyWon: rate, review: review ?? null,
      planned: applyPayrollEstimate(laborEstimate(planned, review, week, rate, true), planned, policy, week, rate), actual: applyPayrollEstimate(laborEstimate(actual, review, week, rate), actual, policy, week, rate) };
    for (const session of sessions.filter(s => kstDay(Date.parse(s.start)) >= week && kstDay(Date.parse(s.start)) <= kstDay(Date.parse(`${week}T00:00:00+09:00`) + 6*dayMs))) {
      const work = session.segments.reduce((n,s)=>n+(Date.parse(s.end)-Date.parse(s.start))/60000,0);
      const pause = (Date.parse(session.end)-Date.parse(session.start))/60000 - work;
      if (work >= 240 && pause < (work >= 480 ? 60 : 30)) {
        result.actual.alerts.push('법정 휴게시간 또는 누락된 휴게 기록을 확인해 주세요.'); break;
      }
    }
    const last = state.attendance.filter(e => e.tapperId === t.id && !e.voidedAt).sort((a,b) => a.at.localeCompare(b.at)).at(-1);
    if (last && last.type !== 'clock_out') result.actual.alerts.push('퇴근하지 않은 근무는 계산에서 제외했어요.');
    return result;
  }) })) };
}
