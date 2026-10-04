import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {validateCatalog} from '../developer/manual_catalog_schema.mjs';
const root=new URL('../docs/market/',import.meta.url);
const source=await readFile(new URL('SOURCE.md',root),'utf8');
const blocks=[...source.matchAll(/```tap2work-tap\s*\n([\s\S]*?)\n```/g)];
if(!blocks.length)throw Error('No tap2work-tap blocks in SOURCE.md');
const entries=blocks.map(m=>JSON.parse(m[1]));
const canonical=validateCatalog(entries);
const content=JSON.stringify(canonical);
const releaseId=createHash('sha256').update(content).digest('hex');
const release={schemaVersion:1,releaseId,entries:canonical};
const output=JSON.stringify(release,null,2)+'\n';
if(process.argv.includes('--check')){
 if(await readFile(new URL(`releases/${releaseId}.json`,root),'utf8')!==output)throw Error('Immutable release does not match source');
 if(await readFile(new URL('current.json',root),'utf8')!==output)throw Error('Run npm run market:build after editing source MD');
}else{
 await mkdir(new URL('releases/',root),{recursive:true});
 const target=new URL(`releases/${releaseId}.json`,root);
 try{const previous=await readFile(target,'utf8');if(previous!==output)throw Error('Immutable release differs');}catch(e){if(e.code!=='ENOENT')throw e;await writeFile(target,output,{flag:'wx'});}
 await writeFile(new URL('current.json',root),output);
}
console.log(`Manual market: ${canonical.length} TAPs, release ${releaseId.slice(0,12)}`);
