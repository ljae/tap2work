import {lookup} from 'node:dns/promises';
import {createHash} from 'node:crypto';
import {sourceUrl} from './content_memory.mjs';
const privateIp=ip=>/^(?:0\.|10\.|127\.|169\.254\.|192\.168\.|172\.(?:1[6-9]|2\d|3[01])\.|::|fc|fd|fe80|::ffff:)/i.test(ip);
const normalized=s=>s.normalize('NFKC').replace(/\s+/g,' ').trim().toLowerCase();
export async function checkSource(source,{fetcher=fetch,resolver=lookup,maxBytes=512*1024}={}){
 let url=sourceUrl(source.url);
 try{
  for(let redirects=0;redirects<4;redirects++){
   const addresses=await resolver(new URL(url).hostname,{all:true});
   if(!addresses.length||addresses.some(x=>privateIp(x.address)))return {url:source.url,status:'blocked',contentHash:null,excerptMatched:null};
   const response=await fetcher(url,{redirect:'manual',credentials:'omit',signal:AbortSignal.timeout(10000),headers:{Accept:'text/html,text/plain'}});
   if([301,302,303,307,308].includes(response.status)){
    const location=response.headers.get('location');if(!location)throw Error('Missing redirect');url=sourceUrl(new URL(location,url).href);continue;
   }
   if([404,410].includes(response.status))return {url:source.url,status:'missing',contentHash:null,excerptMatched:false};
   if(!response.ok)return {url:source.url,status:response.status===403?'blocked':'error',contentHash:null,excerptMatched:null};
   if(!/text\/(?:html|plain)/i.test(response.headers.get('content-type')??''))return {url:source.url,status:'unverifiable',contentHash:null,excerptMatched:null};
   const reader=response.body?.getReader();if(!reader)throw Error('Missing source body');
   const chunks=[];let size=0;
   while(true){const {value,done}=await reader.read();if(done)break;size+=value.length;if(size>maxBytes){await reader.cancel();return {url:source.url,status:'unverifiable',contentHash:null,excerptMatched:null};}chunks.push(value);}
   const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
   const body=new TextDecoder().decode(bytes).replace(/<(script|style)\b[^>]*>[\s\S]*?<\/\1>/gi,' ').replace(/<[^>]+>/g,' ').replace(/&nbsp;|&#160;/g,' ').replace(/&amp;/g,'&').replace(/&quot;/g,'"');
   const evidence=Object.values(source.observations).map(x=>x.excerpt);
   return {url:source.url,status:'reachable',contentHash:createHash('sha256').update(bytes).digest('hex'),excerptMatched:evidence.length?evidence.every(x=>normalized(body).includes(normalized(x))):null};
  }
  return {url:source.url,status:'blocked',contentHash:null,excerptMatched:null};
 }catch{return {url:source.url,status:'error',contentHash:null,excerptMatched:null};}
}
