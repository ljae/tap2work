import {StoreError} from './store.mjs';
import {validateRecurrence} from './work_recurrence.mjs';
const fail=()=>{throw new StoreError('가상 매장 본보기의 설정과 연결을 확인해 주세요.',400);};
const validId=id=>typeof id==='string'&&/^[a-zA-Z0-9_-]{1,80}$/.test(id);
const unique=rows=>Array.isArray(rows)&&new Set(rows.map(r=>r.id)).size===rows.length&&rows.every(r=>validId(r.id));
const text=(v,max)=>typeof v==='string'&&v.trim()&&v.length<=max;
export function validateExampleStores(stores,entries) {
  if(stores==null)stores=[];
  if(!Array.isArray(stores)||stores.length>20||!unique(stores))fail();
  const sourceMap=new Map(entries.map(entry=>[entry.sourceId,entry]));
  for(const store of stores){
    if(store.fictional!==true||!text(store.name,100)||!text(store.summary,500)||!text(store.notice,500))fail();
    const clock=value=>typeof value==='string'&&/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(value);
    if(!store.hours||!clock(store.hours.open)||!clock(store.hours.close)||!clock(store.hours.breakStart)||!clock(store.hours.breakEnd)||!Array.isArray(store.hours.openDays)||!store.hours.openDays.length||new Set(store.hours.openDays).size!==store.hours.openDays.length||store.hours.openDays.some(d=>!Number.isInteger(d)||d<1||d>7))fail();
    if(!Array.isArray(store.roles)||store.roles.length>10||!store.roles.every(role=>['owner','manager','crew'].includes(role.id)&&text(role.name,80)))fail();
    if(!Array.isArray(store.standards)||store.standards.length>30||!store.standards.every(row=>text(row.name,100)&&text(row.value,1000)))fail();
    if(!unique(store.parts)||store.parts.length>20||!store.parts.every(p=>text(p.name,80)))fail();
    if(!unique(store.bands)||store.bands.length>20||!store.bands.every(b=>/^\d{2}:\d{2}$/.test(b.start)&&/^\d{2}:\d{2}$/.test(b.end)&&text(b.name,80)))fail();
    if(!unique(store.places)||store.places.length>80||!store.layout||![store.layout.width,store.layout.height].every(v=>Number.isInteger(v)&&v>0&&v<=40))fail();
    for(const place of store.places){
      if(!text(place.name,80)||!['table','equipment','storage','entrance','area'].includes(place.type)||![place.x,place.y,place.width,place.height].every(Number.isInteger)||place.x<0||place.y<0||place.width<1||place.height<1||place.x+place.width>store.layout.width||place.y+place.height>store.layout.height)fail();
      if(place.type==='table'&&(!Number.isInteger(place.seats)||place.seats<1||place.seats>30))fail();
    }
    for(let i=0;i<store.places.length;i++)for(let j=i+1;j<store.places.length;j++){
      const a=store.places[i],b=store.places[j];
      if(a.type!=='area'&&b.type!=='area'&&a.x<b.x+b.width&&a.x+a.width>b.x&&a.y<b.y+b.height&&a.y+a.height>b.y)fail();
    }
    if(!Array.isArray(store.staffing)||store.staffing.length>30||!store.staffing.every(row=>store.bands.some(b=>b.id===row.timeBandId)&&row.parts&&Object.entries(row.parts).every(([id,n])=>store.parts.some(p=>p.id===id)&&Number.isInteger(n)&&n>=0&&n<=30)))fail();
    const seats=store.places.filter(p=>p.type==='table').reduce((n,p)=>n+p.seats,0);if(seats!==store.capacity)fail();
    if(!Array.isArray(store.tapSettings)||store.tapSettings.length>100||new Set(store.tapSettings.map(row=>row.sourceId)).size!==store.tapSettings.length)fail();
    for(const row of store.tapSettings){
      const source=sourceMap.get(row.sourceId),settings=row.settings;
      if(!source||source.knowledge?.exampleStoreId!==store.id||!store.parts.some(p=>p.id===row.partId)||!Array.isArray(row.timeBandIds)||!row.timeBandIds.every(id=>store.bands.some(b=>b.id===id)))fail();
      if(!settings||!['reference','routine','event'].includes(settings.usage)||typeof settings.enabled!=='boolean'||typeof settings.allowBulkComplete!=='boolean'||typeof settings.enforceSequence!=='boolean')fail();
      validateRecurrence(settings.recurrence);
      const category=source.knowledge.useCase;
      if(['startup','recipe','reference'].includes(category)&&(settings.usage!=='reference'||settings.enabled))fail();
      if(category==='periodic'&&settings.recurrence.mode==='daily')fail();
      if(settings.usage==='event'&&!['batch','opened','thawed','received'].includes(settings.eventKind))fail();
      if(!Array.isArray(row.locationIds)||!row.locationIds.every(id=>store.places.some(p=>p.id===id)))fail();
    }
    if(!Array.isArray(store.menus)||!store.menus.every(menu=>sourceMap.get(menu.recipeSourceId)?.knowledge.useCase==='recipe'))fail();
  }
  for(const entry of entries){
    const id=entry.knowledge?.exampleStoreId;if(id&&!stores.some(s=>s.id===id))fail();
    for(const related of entry.knowledge?.relatedSourceIds??[])if(!sourceMap.has(related)||related===entry.sourceId)fail();
  }
}
