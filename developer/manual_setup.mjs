import { StoreError } from './store.mjs';
const commonIds=new Set(['bonejjim/staff-open','bonejjim/hall-open','bonejjim/hall-close']);
const conditionSteps={'bonejjim/hall-open':{'step-3':'selfbar'},'bonejjim/hall-close':{'step-1':'selfbar'},'food/hall-open':{'selfbar':'selfbar'},'food/hall-close':{'selfbar':'selfbar','burner':'tableBurner'}};
export function presentSource(e){return commonIds.has(e.sourceId)?{...e,collectionId:'food',collectionName:'외식업 공통',knowledge:{...e.knowledge,scope:'food'}}:e;}
export function saveManualSetup(state,value){
 if(!value||typeof value!=='object')throw new StoreError('매뉴얼 구성 정보를 확인해 주세요.',400);
 const conditions={};for(const key of ['selfbar','tableBurner']){const v=value.conditions?.[key]??null;if(v!==null&&typeof v!=='boolean')throw new StoreError('매장 특성을 확인해 주세요.',400);conditions[key]=v;}
 const places={};for(const key of ['waste','supplies']){const v=value.places?.[key]??null;if(v!==null&&!state.zones.some(z=>z.id===v))throw new StoreError('연결할 장소를 확인해 주세요.',400);places[key]=v;}
 state.store.manualSetup={conditions,places,revision:(state.store.manualSetup?.revision??0)+1};
}
export function sourceFor(state,t){return state.catalogLinks?.[t.id]?.sourceId??t.composedSourceId??(t.id?.startsWith('library-')?t.id.slice(8).replace('bonejjim-','bonejjim/'):null);}
export function composeManual(state,t){
 const config=state.store.manualSetup;if(!config)return t;
 const sourceId=sourceFor(state,t),rules=conditionSteps[sourceId]??{};
 const steps=t.steps.filter(s=>!rules[s.id]||config.conditions?.[rules[s.id]]!==false);
 const refs=[];
 if(['bonejjim/hall-close','bonejjim/kitchen-close','food/hall-close','food/kitchen-close','food/waste'].includes(sourceId))for(const key of ['waste','supplies']){const p=state.zones.find(z=>z.id===config.places?.[key]);if(p)refs.push({key,zoneId:p.id,label:key==='waste'?'폐기물 배출 장소':'비품 보관 장소',name:p.name,address:[p.floor,p.area,p.description].filter(Boolean).join(' · ')});}
 return {...t,steps,sharedPlaces:refs,composedSourceId:sourceId};
}
export function retireUnstartedComposition(state, now = new Date()){
 for(const task of state.tasks){const t=state.taskTemplates.find(t=>t.id===task.templateId);if(!t||!conditionSteps[sourceFor(state,t)]||task.completedAt||task.startedAt||task.boardStatus==='processing'||task.steps?.some(s=>s.completedAt)||task.workEvent)continue;task.archivedAt=now.toISOString();}
}
