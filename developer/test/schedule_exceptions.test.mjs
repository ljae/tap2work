import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mutateStaff } from '../staff.mjs';

const now = new Date('2026-09-30T00:00:00Z');
const owner = {id: 'owner', role: 'owner'}, crew = {id: 'a', role: 'crew'};
function fixture(start = '09:00', end = '18:00') {
  return {
    workplace: {parts: [{id: 'kitchen', name: '주방', duties: ['조리']}, {id: 'hall', name: '홀', duties: ['서빙1']}], days: {1: [{id: 'mon-open', name: '오전', start, end}]}},
    tappers: ['a','b','c'].map(id => ({id, actorId: id, active: true, workProfile: {partIds: id === 'c' ? ['hall'] : ['kitchen']}})),
    staffShifts: [], attendance: [], shiftChangeRequests: [],
  };
}
function act(state, input, actor = owner, at = now) {
  const next = structuredClone(state);
  assert.equal(mutateStaff(next, input, actor, at, () => '', () => {}), true);
  return next;
}
function pattern(state, tapperId = 'a', start = '09:00', end = '18:00') {
  return act(state, {action: 'save_crew_pattern', tapperId, anchor: '2026-10-05', cycleWeeks: 1, entries: [{week: 0, weekday: 1, partId: 'kitchen', timeBandId: 'mon-open', start, end}]});
}
const apply = (s, id = 'a') => act(s, {action: 'apply_crew_pattern', tapperId: id, from: '2026-10-05', until: '2026-10-12'});
const request = (s, kind = 'partial_off', start = '12:00', end = '14:00') => act(s, {action: 'request_shift_change', shiftId: s.staffShifts[0].id, kind, start, end, reason: '개인 일정'}, crew);
const approve = s => act(s, {action: 'review_shift_change', id: s.shiftChangeRequests[0].id, decision: 'approved'});
const replace = (s, tapperId = 'b') => act(s, {action: 'review_shift_change', id: s.shiftChangeRequests[0].id, decision: 'assign_replacement', vacancyId: s.shiftChangeRequests[0].vacancies[0].id, tapperId});

test('middle OFF is pending until owner approval, splits effective work and links exact replacement with timeBandId', () => {
  let s = apply(pattern(fixture()));
  const original = structuredClone(s.staffShifts);
  s = request(s);
  assert.deepEqual(s.staffShifts, original);
  assert.throws(() => act(s, {action:'review_shift_change',id:s.shiftChangeRequests[0].id,decision:'approved'}, {id:'manager',role:'manager'}), {status:403});
  s = approve(s);
  const segments = s.staffShifts.filter(x => x.approvedRequestId);
  assert.deepEqual(segments.map(x => [x.start,x.end]), [['09:00','12:00'],['14:00','18:00']]);
  assert.equal(segments[0].id,original[0].id);
  assert.ok(segments.every(x => x.timeBandId === 'mon-open' && x.base.timeBandId === 'mon-open'));
  s = replace(s);
  const replacement = s.staffShifts.find(x => x.replacementForRequestId);
  assert.deepEqual([replacement.start,replacement.end,replacement.timeBandId],['12:00','14:00','mon-open']);
  assert.equal(s.shiftChangeRequests[0].vacancies[0].replacementShiftId, replacement.id);
  const protectedRows = s.staffShifts.filter(x => x.date === '2026-10-05');
  const nextId = s.staffShifts.find(x => x.date === '2026-10-12').id;
  s = apply(pattern(s,'a','10:00','19:00'));
  assert.deepEqual(s.staffShifts.filter(x => x.date === '2026-10-05'), protectedRows);
  assert.notEqual(s.staffShifts.find(x => x.date === '2026-10-12').id,nextId);
  assert.equal(s.staffShifts.find(x => x.date === '2026-10-12').start,'10:00');
  s = apply(pattern(s,'b'));
  assert.equal(s.staffShifts.filter(x => x.tapperId === 'b' && x.date === '2026-10-05').length,1);
  assert.throws(() => replace(s),{status:409});
});

test('overnight OFF creates next-day segment and replacement, preserving KST date and source base', () => {
  let s = apply(pattern(fixture('22:00','06:00'),'a','22:00','06:00'));
  s = approve(request(s,'partial_off','00:30','02:00'));
  assert.deepEqual(s.staffShifts.filter(x=>x.approvedRequestId).map(x=>[x.date,x.start,x.end]), [['2026-10-05','22:00','00:30'],['2026-10-06','02:00','06:00']]);
  s = replace(s);
  assert.equal(s.staffShifts.find(x=>x.replacementForRequestId).date,'2026-10-06');
  const rows = s.staffShifts.filter(x=>x.approvedRequestId || x.replacementForRequestId);
  s = apply(s);
  assert.deepEqual(s.staffShifts.filter(x=>x.approvedRequestId || x.replacementForRequestId),rows);
});

test('replacement rejects wrong part, inactive crew, overlap, approved OFF and non-owner', () => {
  let s = approve(request(apply(pattern(fixture()))));
  assert.throws(()=>replace(s,'c'),{status:400});
  const inactive=structuredClone(s);inactive.tappers[1].active=false;
  assert.throws(()=>replace(inactive),{status:404});
  const busy=structuredClone(s);busy.staffShifts.push({id:'busy',tapperId:'b',date:'2026-10-05',start:'13:00',end:'15:00',status:'planned'});
  assert.throws(()=>replace(busy),{status:409});
  const off=structuredClone(s);off.shiftChangeRequests.push({id:'off',tapperId:'b',status:'approved',vacancies:[{date:'2026-10-05',start:'12:30',end:'13:30'}]});
  assert.throws(()=>replace(off),{status:409});
  assert.throws(()=>act(s,{action:'review_shift_change',id:s.shiftChangeRequests[0].id,decision:'assign_replacement',vacancyId:s.shiftChangeRequests[0].vacancies[0].id,tapperId:'b'},crew),{status:403});
});

test('leave, attendance and pending requests survive reapply while untouched dates update', () => {
  for (const protection of ['leave','attendance','pending']) {
    let s=apply(pattern(fixture()));
    if(protection==='leave') s=approve(request(s,'leave'));
    if(protection==='pending') s=request(s);
    if(protection==='attendance') s.attendance.push({tapperId:'a',at:'2026-10-04T23:30:00Z',type:'in'});
    const first=structuredClone(s.staffShifts[0]), requests=structuredClone(s.shiftChangeRequests), attendance=structuredClone(s.attendance);
    s=apply(pattern(s,'a','10:00','19:00'));
    assert.deepEqual(s.staffShifts.find(x=>x.id===first.id),first);
    assert.deepEqual(s.shiftChangeRequests,requests);assert.deepEqual(s.attendance,attendance);
    assert.equal(s.staffShifts.find(x=>x.date==='2026-10-12').start,'10:00');
  }
});

test('stale approval, attendance after request, invalid OFF and unknown band are rejected', () => {
  const s=apply(pattern(fixture()));
  assert.throws(()=>request(s,'partial_off','08:00','10:00'),{status:400});
  assert.throws(()=>request(s,'partial_off','09:00','18:00'),{status:400});
  const pending=request(s);pending.staffShifts[0].timeBandId='changed';
  assert.throws(()=>approve(pending),{status:409});
  const attended=request(s);attended.attendance.push({tapperId:'a',at:'2026-10-05T00:00:00Z'});
  assert.throws(()=>approve(attended),{status:409});
  const noBand=fixture();noBand.workplace.days[1][0].id='new';
  assert.throws(()=>pattern(noBand),{status:409});
});

test('edge OFF keeps one segment; rejected/cancelled requests never alter work', () => {
  for(const [start,end,expected] of [['09:00','11:00',['11:00','18:00']],['16:00','18:00',['09:00','16:00']]]) {
    const s=approve(request(apply(pattern(fixture())),'partial_off',start,end));
    assert.deepEqual(s.staffShifts.filter(x=>x.approvedRequestId).map(x=>[x.start,x.end]),[expected]);
  }
  for(const decision of ['rejected','cancelled']) {
    let s=request(apply(pattern(fixture())));const before=structuredClone(s.staffShifts);
    s=act(s,{action:decision==='cancelled'?'cancel_shift_change':'review_shift_change',id:s.shiftChangeRequests[0].id,decision},decision==='cancelled'?crew:owner);
    assert.deepEqual(s.staffShifts,before);
  }
});

test('reapply skips overnight pattern overlapping a next-day linked replacement instead of rejecting range', () => {
  let s=approve(request(apply(pattern(fixture('22:00','06:00'),'a','22:00','06:00')),'partial_off','00:30','02:00'));
  s=replace(s);
  const replacement=structuredClone(s.staffShifts.find(x=>x.replacementForRequestId));
  s=apply(pattern(s,'b','22:00','06:00'),'b');
  assert.deepEqual(s.staffShifts.find(x=>x.id===replacement.id),replacement);
  assert.equal(s.staffShifts.filter(x=>x.tapperId==='b' && x.date==='2026-10-05').length,0);
  assert.equal(s.staffShifts.filter(x=>x.tapperId==='b' && x.date==='2026-10-12').length,1);
});

test('legacy pending requests without band or segment metadata can still be approved', () => {
  let s=apply(pattern(fixture()));
  delete s.staffShifts[0].timeBandId;
  s=request(s,'shorten','10:00','16:00');
  const row=s.shiftChangeRequests[0];
  row.version=JSON.stringify(JSON.parse(row.version).slice(0,7));
  delete row.segments;delete row.vacancies;
  s=approve(s);
  assert.equal(s.staffShifts[0].start,'10:00');
  assert.equal(s.shiftChangeRequests[0].vacancies.length,2);
});
