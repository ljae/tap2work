import { parseManualMediaReference } from './manual_media_reference.mjs';
import { StoreError } from './store.mjs';
const fail=m=>{throw new StoreError(m,400);};
const str=(v,max,required=false)=>{if(typeof v!=='string'||v.length>max||required&&!v.trim())fail('장소 이름과 설명을 확인해 주세요.');return v.trim();};
export function placePhoto(value){
 if(value==null||value==='')return '';
 if(parseManualMediaReference(value))return value;
 if(typeof value!=='string'||value.length>500000)fail('사진은 350KB 이내로 선택해 주세요.');
 if(/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/.test(value))return value;
 try{const u=new URL(value);if(u.protocol==='https:'&&!u.username&&!u.password)return value;}catch{}
 fail('사진은 JPG·PNG·WebP 또는 HTTPS 주소를 사용해 주세요.');
}
export function savePlace(state,input,now){
 const p=input.place;
 if(!p||typeof p.id!=='string'||!/^[a-zA-Z0-9_-]{1,80}$/.test(p.id))fail('장소 ID를 확인해 주세요.');
 const old=state.zones.find(z=>z.id===p.id);
 if(!old&&state.zones.length>=80)fail('장소는 최대 80개까지 등록할 수 있어요.');
 if(!['table','equipment','storage','entrance','area'].includes(p.kind))fail('장소 종류를 선택해 주세요.');
 if(old&&old.kind!==p.kind&&[...state.items,...(state.preparedItems??[]),...state.tasks,...state.taskTemplates].some(x=>x.zone===p.id))fail('업무·재고에 연결된 장소의 종류는 유지해 주세요.');
 const next={...(old??{id:p.id,mapped:false,x:0,y:0,width:1,height:1,seats:0,shape:'rect',rotation:0}),kind:p.kind,name:str(p.name,30,true),floor:str(p.floor??'',30),area:str(p.area??'',40),description:str(p.description??'',500),photo:placePhoto(p.photo),updatedAt:now.toISOString()};
 if(p.kind==='table'){if(!Number.isInteger(p.seats)||p.seats<1||p.seats>20)fail('좌석 수는 1~20석이에요.');next.seats=p.seats;}else next.seats=0;
 if(state.zones.some(z=>z.id!==p.id&&z.name===next.name&&(z.floor??'')===next.floor&&(z.area??'')===next.area))fail('같은 구역에 같은 이름의 장소가 있어요.');
 const photoBytes=state.zones.filter(z=>z.id!==p.id).reduce((sum,z)=>sum+(z.photo?.startsWith('data:')?z.photo.length:0),0)+(next.photo.startsWith('data:')?next.photo.length:0);
 if(photoBytes>1500000)fail('등록 사진의 총 용량이 찼어요. 기존 사진을 줄이거나 제거해 주세요.');
 if(old)Object.assign(old,next);else state.zones.push(next);
}
