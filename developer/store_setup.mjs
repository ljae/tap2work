import { saveTapSettings, taskSettings } from './task_settings.mjs';
import { StoreError } from './store.mjs';
import { saveStoreProfile } from './store_profile.mjs';
import { mutateWorkplace, workplaceDefaults } from './workplace.mjs';
import { manualCatalog, mutateManualMarket } from './manual_market.mjs';

// Presets select published content; they never create a second content catalog.
import { businessTypes } from './business_types.mjs';

export function storeSetupCatalog(catalog = manualCatalog) {
  const collections = new Set(['common', 'delivery', ...businessTypes.map(t => t.collectionId)]);
  return { releaseId: catalog.releaseId, businessTypes, purposes: catalog.taxonomy.purposes,
    entries: catalog.entries.filter(e => e.kind !== 'legal' && collections.has(e.collectionId))
      .map(e => ({sourceId:e.sourceId, collectionId:e.collectionId, title:e.title, purposeId:e.purposeId, steps:e.steps.map(s=>({title:s.title,manual:s.manual}))})) };
}

export function applyStoreSetup(state, input, actor, now, catalog = manualCatalog) {
  const setup = input.setup;
  if (!setup || typeof setup !== 'object' || Array.isArray(setup)) throw new StoreError('매장 설정을 확인해 주세요.');
  const type = businessTypes.find(t => t.id === setup.businessTypeId);
  if (!type) throw new StoreError('매장 업종을 선택해 주세요.');
  if (!Array.isArray(setup.serviceModes) || !setup.serviceModes.length) throw new StoreError('운영 형태를 선택해 주세요.');
  saveStoreProfile(state, 'basic', {name:input.name, industryId:type.industryId, serviceModes:setup.serviceModes, address:setup.address, arrivalNote:setup.arrivalNote});
  state.store.profile.businessTypeId = type.id;
  const days = setup.weekdays;
  if (!Array.isArray(days) || !days.length || days.some(d=>!Number.isInteger(d)||d<1||d>7) || new Set(days).size!==days.length) throw new StoreError('영업 요일을 선택해 주세요.');
  const time = v => typeof v === 'string' && /^(?:[01]\d|2[0-3]):(?:00|30)$/.test(v);
  if (!time(setup.opening) || !time(setup.closing) || setup.opening === setup.closing) throw new StoreError('영업 시작·종료 시간을 확인해 주세요.');
  const parts = setup.partIds;
  state.workplace ??= workplaceDefaults();
  if (!Array.isArray(parts) || !parts.length || new Set(parts).size!==parts.length || parts.some(p=>!['kitchen','hall','management'].includes(p))) throw new StoreError('사용할 파트를 선택해 주세요.');
  if (!setup.headcounts || typeof setup.headcounts!=='object' || Array.isArray(setup.headcounts) || Object.keys(setup.headcounts).some(p=>!parts.includes(p)) || parts.some(p=>!Number.isInteger(setup.headcounts[p])||setup.headcounts[p]<0||setup.headcounts[p]>12)) throw new StoreError('파트별 필요 인원을 0~12명으로 입력해 주세요.');
  mutateWorkplace(state,{action:'save_workplace_parts',parts:state.workplace.parts.map(p=>({...p,hidden:!parts.includes(p.id)}))},actor,now,()=>{},true);
  const shifts = setup.shiftCount ?? 1;
  const minute = t => Number(t.slice(0,2))*60+Number(t.slice(3));
  const start = minute(setup.opening), duration = (minute(setup.closing)-start+1440)%1440;
  if (![1,2,3].includes(shifts) || duration < shifts*30) throw new StoreError('교대마다 30분 이상의 시간이 필요해요.');
  const clockText = n => `${String(Math.floor(n/60)%24).padStart(2,'0')}:${String(n%60).padStart(2,'0')}`;
  const bands = Array.from({length:shifts},(_,i)=>({id:`setup-shift-${i+1}`,name:shifts===1?'전체':`${i+1}교대`,start:clockText(start+Math.floor(duration/30*i/shifts)*30),end:clockText(start+Math.floor(duration/30*(i+1)/shifts)*30),headcounts:setup.headcounts,crewIds:{}}));
  const weekly = Object.fromEntries(Array.from({length:7},(_,i)=>[i+1,days.includes(i+1)?structuredClone(bands):[]]));
  const breaks = setup.breakTime == null ? {} : Object.fromEntries(days.map(d=>[d,setup.breakTime]));
  mutateWorkplace(state,{action:'save_workplace_hours',days:weekly,breaks,businessDayStart:setup.opening,defaultAssignmentsEnabled:true},actor,now,()=>{},true);
  if (!['unset','none','okpos','other'].includes(setup.pos)) throw new StoreError('POS 사용 여부를 선택해 주세요.');
  saveStoreProfile(state,'pos',{configured:setup.pos!=='unset',enabled:!['unset','none'].includes(setup.pos),devices:['okpos','other'].includes(setup.pos)?[{id:'pos-main',providerId:setup.pos,count:1,functions:[]}]:[]});
  const platforms=setup.deliveryPlatforms;
  if (!Array.isArray(platforms) || new Set(platforms).size!==platforms.length || (!setup.serviceModes.includes('delivery') && platforms.length)) throw new StoreError('배달 플랫폼을 확인해 주세요.');
  saveStoreProfile(state,'delivery',{configured:!setup.serviceModes.includes('delivery')||platforms.length>0,enabled:platforms.length>0,platforms:platforms.map(id=>({id:`delivery-${id}`,providerId:id}))});
  const available=storeSetupCatalog(catalog);
  const allowed=new Set(available.entries.filter(e=>['common',type.collectionId,...(setup.serviceModes.includes('delivery')?['delivery']:[])].includes(e.collectionId)).map(e=>e.sourceId));
  if (setup.releaseId!==catalog.releaseId) throw new StoreError('기본 매뉴얼이 업데이트됐어요. 목록을 새로 확인해 주세요.',409);
  if (!Array.isArray(setup.sourceIds) || setup.sourceIds.some(id=>!allowed.has(id)) || new Set(setup.sourceIds).size!==setup.sourceIds.length || typeof setup.enableOperations!=='boolean') throw new StoreError('기본 매뉴얼 선택을 확인해 주세요.');
  if (setup.sourceIds.length) {
    // No replace: creation is isolated and all imported definitions keep source links.
    mutateManualMarket(state,{action:'configure_manual_business',operationId:`setup-${input.requestId}`,releaseId:catalog.releaseId,industryId:'food',specialization:type.name,sourceIds:setup.sourceIds,replaceExisting:false,enableOperations:setup.enableOperations},actor,now,catalog);
    for (const template of state.taskTemplates) saveTapSettings(state,{templateId:template.id,assignmentScopeVersion:2,settings:{...taskSettings(template),recurrence:{mode:'weekly',weekdays:days}}},now);
    state.checklistFolders=state.checklistFolders.filter(f=>f.id!=='general'||state.taskTemplates.some(t=>t.folderId===f.id));
  }
  state.manualBusinessProfile ??= {industryId:'food',specialization:type.name,configuredAt:now.toISOString(),releaseId:catalog.releaseId};
  state.store.onboarding={version:1,completedAt:now.toISOString()};
}
