import {randomUUID} from 'node:crypto';
import {StoreError} from './store.mjs';
const fail = (message, status=400) => {throw new StoreError(message,status);};
const name = (value,max=100) => {if(typeof value!=='string'||!value.trim()||value.trim().length>max)fail(`이름은 1~${max}자로 입력해 주세요.`);return value.trim();};
function remember(state, value, actor, now) {
  (state.operationEditHistory ??= []).push({value:structuredClone(value),actor:actor.id,at:new Date(now).toISOString()});
}
// Definitions are edited independently of historical execution snapshots.
export function editManualNode(state,input,actor,now) {
  const {kind,operation,id}=input;
  if(!['group','tap','task'].includes(kind)||!['rename','delete','add'].includes(operation))fail('편집할 항목을 확인해 주세요.');
  if(operation==='add') {
    const title=name(input.name,kind==='group'?40:100);
    if(kind==='group') {if(state.checklistFolders.length>=30)fail('그룹은 최대 30개예요.');state.checklistFolders.push({id:randomUUID(),name:title});return;}
    if(kind==='tap') {
      if(!state.checklistFolders.some(f=>f.id===input.parentId))fail('그룹을 선택해 주세요.');
      if(state.taskTemplates.length>=650)fail('TAP 개수 한도를 넘었어요.');
      state.taskTemplates.push({id:randomUUID(),title,emoji:'📋',folderId:input.parentId,slot:'오픈',requiredRole:'all',partId:null,zone:null,version:1,steps:[]});return;
    }
    const target=state.taskTemplates.find(t=>t.id===input.parentId);
    if(!target||target.steps.length>=30)fail('Task를 추가할 TAP을 확인해 주세요.');
    target.steps.push({id:randomUUID(),title,manual:'진행 방법을 입력해 주세요.',tip:'',tags:[]});target.version=(target.version??1)+1;return;
  }
  const template=state.taskTemplates.find(t=>t.id===(kind==='tap'?id:input.parentId));
  const row=kind==='group'?state.checklistFolders.find(f=>f.id===id):kind==='tap'?template:template?.steps.find(s=>s.id===id);
  if(!row)fail('항목이 변경되었어요. 새로고침해 주세요.',409);
  if(operation==='rename') {
    remember(state,row,actor,now);row[kind==='group'?'name':(template?.menuManualId||row.manualTitle!=null)?'manualTitle':'title']=name(input.name,kind==='group'?40:100);
    if(template)template.version=(template.version??1)+1;
    return;
  }
  if(template?.menuManualId)fail('메뉴와 연결된 항목 삭제는 메뉴 관리에서 변경해 주세요.');
  if(kind==='group') {
    if(id==='general'||state.taskTemplates.some(t=>t.folderId===id)||(state.preparedItems??[]).some(p=>p.folderId===id))fail('기본 그룹 또는 연결된 TAP이 있는 그룹은 삭제할 수 없어요.');
    remember(state,row,actor,now);state.checklistFolders=state.checklistFolders.filter(f=>f!==row);state.bigTapOrder=(state.bigTapOrder??[]).filter(v=>v!==id);
  } else if(kind==='tap') {
    remember(state,row,actor,now);state.taskTemplates=state.taskTemplates.filter(t=>t!==row);
  } else {
    remember(state,row,actor,now);template.steps=template.steps.filter(s=>s!==row);template.version=(template.version??1)+1;
  }
}
export function editWorkNode(state,input,actor,now) {
  const task=state.tasks.find(t=>t.id===input.taskId&&t.kind==='routine'&&t.date===state.day&&!t.archivedAt&&!t.supersededAt);
  if(!task||task.completedAt||task.preparedOutputMovementId)fail('오늘 미완료 업무만 편집할 수 있어요.',409);
  if(!['rename','delete'].includes(input.operation))fail('편집 동작을 확인해 주세요.');
  const step=input.stepId?task.steps.find(s=>s.id===input.stepId):null;
  if(input.stepId&&(!step||step.completedAt))fail('미완료 Task만 편집할 수 있어요.',409);
  const template=state.taskTemplates.find(t=>t.id===(step?.sourceTemplateId??task.templateId));
  const source=step?template?.steps.find(s=>s.id===(step.sourceStepId??step.id)):template;
  if(task.orderId||task.preparedItemId)fail('주문·준비품 연결 업무는 연결된 원본에서 관리해 주세요.');
  if(input.operation==='rename') {
    const title=name(input.name);remember(state,step??task,actor,now);(step??task).title=title;
    if(source)source.title=title;if(template)template.version=(template.version??1)+1;return;
  }
  if(step) {
    if(task.steps.length<=1||(source&&template.steps.length<=1))fail('마지막 Task는 삭제할 수 없어요. TAP을 삭제해 주세요.');
    remember(state,step,actor,now);task.steps=task.steps.filter(s=>s!==step);
    if(source){template.steps=template.steps.filter(s=>s!==source);template.version=(template.version??1)+1;}
  } else {
    if(task.steps.some(s=>s.completedAt))fail('완료한 Task가 있는 TAP은 삭제할 수 없어요.');
    remember(state,task,actor,now);task.archivedAt=new Date(now).toISOString();
    if(template)state.taskTemplates=state.taskTemplates.filter(t=>t!==template);
  }
}
