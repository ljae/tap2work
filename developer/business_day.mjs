// Operational dates are distinct from immutable wall-clock attendance/payroll dates.
export const boundaryOf = state => state.workplace?.businessDayStart ?? '00:00';
export const shiftDate = (date, days) => new Date(Date.parse(`${date}T00:00:00Z`) + days * 86400000).toISOString().slice(0,10);
export const businessDate = (state, now) => {
  const [h,m] = boundaryOf(state).split(':').map(Number);
  return new Date(new Date(now).getTime() + (540-h*60-m)*60000).toISOString().slice(0,10);
};
export const actualDate = (state, date, start) => start < boundaryOf(state) ? shiftDate(date,1) : date;
export const bandForPart = (band, partId) => ({...band,...band.partTimes?.[partId]});
export function businessWindow(state,date,boundary = boundaryOf(state)) {
  const start = Date.parse(`${date}T${boundary}:00+09:00`);
  return [start,start+86400000];
}
