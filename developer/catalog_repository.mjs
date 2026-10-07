import {createHash} from 'node:crypto';
import {manualCatalog} from './manual_market.mjs';
import {validateCatalog} from './manual_catalog_schema.mjs';
import {StoreError} from './store.mjs';

export function canonicalJson(value) {
  if(Array.isArray(value))return `[${value.map(canonicalJson).join(',')}]`;
  if(value && typeof value==='object')return `{${Object.keys(value).sort().map(k=>`${JSON.stringify(k)}:${canonicalJson(value[k])}`).join(',')}}`;
  return JSON.stringify(value);
}
export function releaseHash(release) {
  return createHash('sha256').update(canonicalJson({schemaVersion:2,taxonomy:release.taxonomy,entries:release.entries})).digest('hex');
}
function validateTaxonomy(taxonomy){
  if(!taxonomy||!Array.isArray(taxonomy.industries)||!Array.isArray(taxonomy.purposes))throw new StoreError('콘텐츠 분류 형식을 확인해 주세요.',400);
  for(const values of [taxonomy.industries,taxonomy.purposes]){
    if(!values.length||values.length>100||new Set(values.map(x=>x.id)).size!==values.length)throw new StoreError('콘텐츠 분류 ID를 확인해 주세요.',400);
    for(const value of values)if(!/^[a-zA-Z0-9_-]{1,100}$/.test(value.id??'')||typeof value.name!=='string'||!value.name.trim()||value.name.length>100)throw new StoreError('콘텐츠 분류 이름을 확인해 주세요.',400);
  }
}
export function validateRelease(value,{assignId=false}={}){
  if(!value||value.schemaVersion!==2)throw new StoreError('지원하지 않는 콘텐츠 버전이에요.',400);
  if(Buffer.byteLength(JSON.stringify(value))>2*1024*1024)throw new StoreError('콘텐츠 발행본은 2MB 이하여야 해요.',413);
  validateTaxonomy(value.taxonomy);
  let entries;
  try{entries=validateCatalog(value.entries,value.taxonomy);}catch{throw new StoreError('콘텐츠 항목과 출처 형식을 확인해 주세요.',400);}
  const release={schemaVersion:2,taxonomy:structuredClone(value.taxonomy),entries};
  const hash=releaseHash(release);
  // Legacy IDs survive the first seed; arbitrary content cannot borrow that ID.
  const exactLegacy=value.releaseId===manualCatalog.releaseId && canonicalJson({taxonomy:release.taxonomy,entries:release.entries})===canonicalJson({taxonomy:manualCatalog.taxonomy,entries:manualCatalog.entries});
  if(!assignId && value.releaseId!==hash && !exactLegacy)throw new StoreError('콘텐츠 발행본 해시가 맞지 않아요.',400);
  release.releaseId=assignId?hash:value.releaseId;
  return release;
}
export class DatabaseCatalogRepository {
  constructor(rest,{channel='stable'}={}){this.rest=rest;this.channel=channel;}
  async readPublished(){
    const result=await this.rest('rpc/tap2work_catalog_read',{method:'POST',body:JSON.stringify({p_channel:this.channel})});
    if(!result||!Number.isSafeInteger(result.revision)||result.revision<1)throw new StoreError('공용 매뉴얼을 불러오지 못했어요. 다시 시도해 주세요.',503);
    const release=validateRelease(result.release);
    return {revision:result.revision,release};
  }
}
