import { effectiveWorkplaceBands } from './work_assignments.mjs';
import { shiftDate } from './business_day.mjs';
import { StoreError } from './store.mjs';
export function validateRecurrence(value) {
  const fail=()=>{throw new StoreError('반복 주기와 날짜를 확인해 주세요.');};
  if(!value || !['daily','weekly','monthly'].includes(value.mode))fail();
  const weekdays=value.weekdays??[];
  if(!Array.isArray(weekdays)||weekdays.some(d=>!Number.isInteger(d)||d<1||d>7)||new Set(weekdays).size!==weekdays.length)fail();
  if(value.mode==='weekly'&&!weekdays.length)fail();
  if(value.mode==='monthly'&&(!Number.isInteger(value.monthDay)||value.monthDay<1||value.monthDay>31))fail();
  if(value.holidayPolicy!=null&&value.holidayPolicy!=='next_open')fail();
  return {mode:value.mode,weekdays:value.mode==='weekly'?weekdays:[],...(value.mode==='monthly'?{monthDay:value.monthDay}:{}),...(value.holidayPolicy?{holidayPolicy:value.holidayPolicy}:{})};
}
export function scheduledOn(recurrence,date) {
  if(!recurrence||recurrence.mode==='daily')return true;
  const d=new Date(`${date}T12:00:00+09:00`);
  if(recurrence.mode==='weekly')return recurrence.weekdays.includes(d.getUTCDay()||7);
  const last=new Date(Date.UTC(d.getUTCFullYear(),d.getUTCMonth()+1,0)).getUTCDate();
  return d.getUTCDate()===Math.min(recurrence.monthDay,last);
}
// One shared checklist per open day. Consecutive closed-day occurrences coalesce.
// Legacy recurrence retains its calendar semantics until explicitly configured.
export function recurringOn(state,template,date) {
  const r=template.settings?.recurrence;
  if(r?.holidayPolicy!=='next_open')return scheduledOn(r,date);
  if(!effectiveWorkplaceBands(state,date).length)return false;
  if(scheduledOn(r,date))return true;
  if(r.mode==='daily')return true;
  for(let i=1;i<=366;i++) {
    const prior=shiftDate(date,-i);
    if(template.generationNotBeforeBusinessDate && prior<template.generationNotBeforeBusinessDate)return false;
    if(effectiveWorkplaceBands(state,prior).length)return false;
    if(scheduledOn(r,prior))return true;
  }
  return false;
}
export function effectiveTemplate(template,date) {
  const scheduled=template.scheduledSettings;
  return scheduled && scheduled.effectiveFrom<=date ? {...template,settings:scheduled.settings,zone:scheduled.zone,version:(template.version??1)+1} : template;
}
