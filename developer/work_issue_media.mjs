import { createHmac, timingSafeEqual } from 'node:crypto';
import { Buffer } from 'node:buffer';
import { StoreError } from './store.mjs';
import { businessDate } from './business_day.mjs';
import { actorWithParts } from './parts.mjs';
import { canCompleteStep } from './task_settings.mjs';
import { parseManualMediaReference } from './manual_media_reference.mjs';

export function canReportWorkIssue(state, actor, task, stepId=null, completed=false) {
  if (!task || (actor.role !== 'owner' && state.workplace?.restrictions?.[actor.role]?.complete === false)) return false;
  const scoped=actorWithParts(state,actor);
  const steps=task.steps?.length ? task.steps.filter(s=>(completed||!s.completedAt) && (stepId==null || s.id===stepId)) : (stepId==null ? [{}] : []);
  return steps.some(step=>canCompleteStep(scoped,task,step,state));
}
export function assertIssuePhotoPermission(state, member, userId, taskId, now) {
  const task = state?.tasks?.find(t => t.id === taskId && !t.archivedAt && !t.supersededAt && !t.completedAt && (t.workEvent || t.date === businessDate(state,now)));
  if (!canReportWorkIssue(state,{id:userId,role:member.role},task)) throw new StoreError('담당하는 진행 중 업무에만 이상 사진을 등록할 수 있어요.',403,'ISSUE_PHOTO_FORBIDDEN');
}
const signature = (body,key) => createHmac('sha256',key).update('tap2work-work-issue-photo-v1\n'+body).digest();
export function issuePhotoReceipt({userId,workspaceId,taskId,reference},key,now) {
  const body = Buffer.from(JSON.stringify({userId,workspaceId,taskId,reference,expiresAt:new Date(now).getTime()+7*86400000})).toString('base64url');
  return body+'.'+signature(body,key).toString('base64url');
}
export function verifyIssuePhotoReceipt(input,userId,workspaceId,key,now) {
  if (!input.photo) return;
  const invalid = () => {throw new StoreError('이 업무에서 사진을 다시 선택해 주세요.',403,'ISSUE_PHOTO_FORBIDDEN');};
  if (!parseManualMediaReference(input.photo) || typeof input.photoReceipt !== 'string' || input.photoReceipt.length>2000) invalid();
  const pieces = input.photoReceipt.split('.');
  if(pieces.length!==2) invalid();
  const expected = signature(pieces[0],key), actual = Buffer.from(pieces[1],'base64url');
  if(actual.length!==expected.length || !timingSafeEqual(actual,expected)) invalid();
  let claim;try{claim=JSON.parse(Buffer.from(pieces[0],'base64url').toString('utf8'));}catch{invalid();}
  if(claim.userId!==userId||claim.workspaceId!==workspaceId||claim.taskId!==input.taskId||claim.reference!==input.photo||!Number.isFinite(claim.expiresAt)||claim.expiresAt<new Date(now).getTime()) invalid();
}
