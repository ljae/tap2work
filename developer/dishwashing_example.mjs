import { StoreError } from './store.mjs';
const sourceSteps = [
  {id:'return-sort',title:'반납 식기를 종류별로 나누기',placeKey:'return',manual:'반납대 사진과 매장 표기를 확인해 큰 접시·작은 접시·그릇·컵·수저를 각각 지정된 구역으로 나눠요. 식기 모양이나 재질에 따라 세척 방법이 다를 수 있으니 처음 보는 식기는 담당자에게 확인해요. 깨지거나 이가 나간 식기는 사용 가능한 식기와 섞지 말고 매장 절차에 따라 알립니다. 완료 기준: 각 식기의 반납 위치를 확인했고 혼합된 식기를 구분했어요.',tip:'예시를 매장 식기 종류와 실제 반납대 칸 이름으로 수정하고 장소 사진을 등록해 주세요.'},
  {id:'waste',title:'잔반은 지정된 통에 버리기',placeKey:'waste',manual:'세척대로 옮기기 전에 식기에 남은 음식을 연결된 잔반통에 제거해요. 포장·휴지·이쑤시개 등은 매장 분리 기준에 따라 따로 버립니다. 남은 음식과 고형물을 싱크대 배수구로 밀어 넣지 않아요. 폐기물 종류가 불명확하면 담당자에게 확인해요. 완료 기준: 음식과 이물질을 지정된 곳에 제거했고 배수구에 고형물이 들어가지 않았어요.',tip:'통의 실제 위치와 버릴 수 있는 음식·이물질 구분을 매장 기준으로 기재하세요.'},
  {id:'drain',title:'거름망과 배수 상태 확인하기',placeKey:'wash',manual:'세척 전 지정된 거름망이 제자리에 있는지, 잔반이 쌓여 있는지, 물이 정상적으로 빠지는지 확인해요. 거름망 청소와 세제·장비 사용은 안내받은 매장 절차를 따릅니다. 배수 불량이나 이상이 있으면 사용을 멈추고 수행 불가로 기록한 뒤 담당자에게 알려요. 완료 기준: 거름망과 배수 상태를 확인했고 이상이 있다면 조치 확인 전 완료로 표시하지 않았어요.',tip:'세제 희석·세척 온도·장비 조작은 제품 안내와 검수된 매장 기준으로 추가하세요.'},
  {id:'dry-sort',title:'세척한 식기를 지정된 건조 칸에 놓기',placeKey:'dry',manual:'세척 결과를 확인한 뒤 연결된 건조대 사진과 표기를 보고 큰 접시·작은 접시·그릇·컵·수저를 각각 지정된 칸에 놓아요. 여기의 예시는 실제 선반 구성을 뜻하지 않아요. 미세척 식기와 세척한 식기를 구별하고 매장에서 정한 건조·보관 기준을 따릅니다. 완료 기준: 식기 종류별 건조 위치를 확인했고 오염된 식기가 섞이지 않았어요.',tip:'예: 큰 접시 아래 칸/작은 접시 가운데 칸/컵·수저 전용 구역. 실제 매장을 확인해 수정하세요.'},
];
export function addDishwashingExample(state,actor,now) {
  if(!['owner','manager'].includes(actor.role)) throw new StoreError('매뉴얼 편집 권한을 확인해 주세요.',403);
  if(state.dishwashingExampleVersion===1) return false;
  if(state.taskTemplates.length>646) throw new StoreError('매뉴얼 등록 한도를 확인해 주세요.');
  const folderId='dishwashing-guide';
  if(!state.checklistFolders.some(f=>f.id===folderId)) {state.checklistFolders.push({id:folderId,name:'설거지 본보기'});(state.bigTapOrder??=[]).push(folderId);}
  const rows=[
    ['start','설거지 · 시작 준비','오픈',sourceSteps.slice(0,3),'routine'],
    ['handover','설거지 · 교대 인수인계','준비',[sourceSteps[2],sourceSteps[3],{id:'handover',title:'다음 교대에 남은 일과 이상 전달하기',manual:'세척 대기 식기, 잔반통 상태, 세제·도구 부족, 배수 이상과 조치 상황을 다음 담당자와 확인해요. 미해결 수행 불가는 이상 기록에 남기고 해결한 것처럼 체크하지 않아요. 완료 기준: 이어서 할 일과 주의할 내용을 다음 담당자에게 전달했어요.',tip:'근무표의 실제 교대 시간대에 연결해 사용하고 식기마다 체크하지 않아요.'}],'routine'],
    ['close','설거지 · 마감 확인','마감',[sourceSteps[1],sourceSteps[2],sourceSteps[3]],'routine'],
    ['reference','설거지 · 영업 중 방법 찾기','피크',sourceSteps,'reference'],
  ];
  for(const [id,title,slot,steps,usage] of rows) state.taskTemplates.push({id:`dishwashing-example-${id}`,title,emoji:'🫧',folderId,slot,requiredRole:'all',partId:null,zone:null,assignmentScopeVersion:2,version:1,sourceIds:[],manualCustomization:{kind:'created',at:now.toISOString()},knowledge:{scope:'food',useCase:usage==='reference'?'training':'routine',suggestedUse:usage,topics:['설거지'],menuNames:[],ingredientNames:[],safetyReviewRequired:false},settings:{type:'cleaning',usage,enabled:false,recurrence:{mode:'daily',weekdays:[]},allowBulkComplete:false,enforceSequence:false,estimatedMinutes:null,knowledgeIds:[],assignment:{mode:'anyone'}},steps:structuredClone(steps).map(s=>({...s,imageUrl:'',videoUrl:'',sourceUrl:'',tags:['설거지'],contentRevision:1}))});
  state.dishwashingExampleVersion=1;
  return true;
}
