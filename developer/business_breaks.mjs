import { StoreError } from './store.mjs';
const minute = value => value.split(':').reduce((h,m) => h*60+Number(m),0);
const time = value => `${String(Math.floor(value/60)%24).padStart(2,'0')}:${String(value%60).padStart(2,'0')}`;
const valid = value => typeof value === 'string' && /^(?:[01]\d|2[0-3]):(?:00|30)$/.test(value);
export function interval(start,end,boundary='00:00') {
  let s=minute(start), e=minute(end), b=minute(boundary);
  if(s<b)s+=1440;
  if(e<=s)e+=1440;
  return [s,e];
}
export function normalizeBreaks(days, breaks, boundary) {
  const fail = () => {throw new StoreError('브레이크 타임은 해당 요일 영업시간 안에서 30분 단위로 설정해 주세요.',400);};
  if(!breaks || typeof breaks!=='object' || Array.isArray(breaks))fail();
  const next={};
  for(const [day,pause] of Object.entries(breaks)) {
    if(!/^[1-7]$/.test(day) || !valid(pause?.start) || !valid(pause?.end) || pause.start===pause.end)fail();
    const rows=(days[day]??[]).filter(b=>!b.custom);
    if(!rows.length)fail();
    const windows=rows.map(b=>interval(b.start,b.end,boundary));
    let [s,e]=interval(pause.start,pause.end,boundary);
    const opening=Math.min(...windows.map(w=>w[0]));
    if(s<opening && e+1440<=Math.max(...windows.map(w=>w[1]))) {s+=1440;e+=1440;}
    if(s<Math.min(...windows.map(w=>w[0])) || e>Math.max(...windows.map(w=>w[1])))fail();
    next[day]={start:pause.start,end:pause.end};
  }
  return next;
}
export function operatingSegments(band,pause,boundary) {
  if(!pause)return [{start:band.start,end:band.end,suffix:''}];
  const [s,e]=interval(band.start,band.end,boundary);
  let [bs,be]=interval(pause.start,pause.end,boundary);
  if(be<=s && bs+1440<e) {bs+=1440;be+=1440;}
  if(be<=s || bs>=e)return [{start:band.start,end:band.end,suffix:''}];
  const spans=[];
  if(s<bs)spans.push({start:time(s),end:time(bs),suffix:''});
  if(be<e)spans.push({start:time(be),end:time(e),suffix:spans.length?'-after-break':'', ...(be>=1440 ? {dayOffset:1} : {})});
  return spans;
}
