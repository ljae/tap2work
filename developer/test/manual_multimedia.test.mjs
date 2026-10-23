import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {OperationsStore,emptyOperations} from '../operations.mjs';
import {manualCatalog,checklistBackup} from '../manual_market.mjs';
import {contentHash} from '../manual_catalog_schema.mjs';
import {validateProject,projectLink,decodeProject} from '../../app/web/manual-media/v1/motion.mjs';
import previous from '../../docs/market/releases/394a7e42f8a61c6df34cebdcadd352b582114df996b0718a3a3187a4f20d1013.json' with {type:'json'};
const root=new URL('../../app/web/manual-media/v1/',import.meta.url);
const json=path=>JSON.parse(readFileSync(new URL(path,root)));
const ids=['food/shift','food/kitchen-open','food/receiving','food/complaint-service','food/kitchen-close'];

test('multimedia upgrade preserves every source, procedure, safety tip and unrelated content',()=>{
 assert.equal(manualCatalog.entries.length,previous.entries.length);
 for(const old of previous.entries){const next=manualCatalog.entries.find(e=>e.sourceId===old.sourceId);assert.ok(next);
  if(!ids.includes(old.sourceId)){assert.deepEqual(next,old);continue;}
  assert.deepEqual(next.steps.map(s=>[s.id,s.title,s.manual,s.tip,s.tags]),old.steps.map(s=>[s.id,s.title,s.manual,s.tip,s.tags]));
  assert.deepEqual(next.knowledge,old.knowledge);assert.notEqual(contentHash(next),contentHash(old));
 }
 assert.equal(json('manuals.json').flatMap(e=>e.steps).length,23);
});

test('every packaged asset has exact bytes and preserved credits; ZIP matches the source manifest',()=>{
 const manifest=json('SOURCES.json');assert.equal(manifest.sources.length,6);
 for(const source of manifest.sources){assert.ok(source.author);assert.ok(source.license);assert.ok(source.changes);assert.ok(source.url.startsWith('https://'));assert.ok(manifest.files.some(f=>f.path===source.file));}
 for(const file of manifest.files){const data=readFileSync(new URL(file.path,root));assert.equal(data.length,file.bytes,file.path);assert.equal(createHash('sha256').update(data).digest('hex'),file.sha256,file.path);}
 const check=spawnSync('python3',['-c',`import zipfile,json,hashlib,sys\nwith zipfile.ZipFile(sys.argv[1]) as z:\n m=json.loads(z.read('tap-work-media/SOURCES.json'))\n for f in m['files']:\n  b=z.read('tap-work-media/'+f['path']);assert len(b)==f['bytes'];assert hashlib.sha256(b).hexdigest()==f['sha256']\n assert set(z.namelist())=={'tap-work-media/SOURCES.json'}|{'tap-work-media/'+f['path'] for f in m['files']}\n`,fileURLToPath(new URL('source-pack.zip',root))],{encoding:'utf8'});
 assert.equal(check.status,0,check.stderr);
});

test('editable motion links round-trip exact Unicode scenes and reject unsafe or oversized projects',()=>{
 for(const source of json('projects.json')){const project=validateProject(source),url=projectLink(source);assert.ok(url.length<=2000);assert.deepEqual(decodeProject(new URLSearchParams(new URL(url).hash.slice(1)).get('p')),project);}
 const p=json('projects.json')[0];
 for(const mutate of [x=>x.scenes[0].seconds=0,x=>x.scenes[0].detail='x'.repeat(81),x=>x.accent='url(javascript:alert(1))',x=>x.scenes=Array(11).fill(x.scenes[0]),x=>x.title='',x=>x.scenes=Array(5).fill({...x.scenes[0],seconds:30})]){const bad=structuredClone(p);mutate(bad);assert.throws(()=>validateProject(bad));}
 assert.throws(()=>decodeProject('a'.repeat(1901)));assert.throws(()=>decodeProject('!'));assert.throws(()=>decodeProject('bm90IGpzb24'));
});

test('market media imports, customized motion URLs and backup restore preserve independent editable copies',async()=>{
 let state=emptyOperations(new Date('2026-10-23T01:00:00Z'),'owner-one','사장님');
 const actor={id:'owner-one',role:'owner',name:'사장님'};
 const store=new OperationsStore(null,()=>new Date('2026-10-23T01:00:00Z'),{actor,persistence:{read:async()=>structuredClone(state),save:async(next,revision)=>{assert.equal(revision,state.revision);state=structuredClone(next);}}});
 const act=async(action,values)=>store.mutate(actor.id,{action,revision:(await store.snapshot(actor.id)).revision,...values});
 await act('import_market_taps',{operationId:'media-import-20261023',releaseId:manualCatalog.releaseId,folderMode:'purpose',sourceIds:ids});
 assert.equal(state.taskTemplates.length,5);assert.deepEqual(state.tasks,[]);
 for(const t of state.taskTemplates){assert.equal(t.settings.enabled,false);assert.equal(t.registration.status,'pending');const source=manualCatalog.entries.find(e=>e.sourceId===state.catalogLinks[t.id].sourceId);assert.equal(contentHash(t),contentHash(source));}
 const t=state.taskTemplates.find(t=>state.catalogLinks[t.id].sourceId==='food/kitchen-open');const old=structuredClone(t);
 const project=json('projects.json')[1];project.scenes[0].detail='우리 매장 오른쪽 작업대와 파란 도구함을 확인해요.';const customized=projectLink(project);
 const steps=structuredClone(t.steps);steps[0].videoUrl=customized;steps[0].manual+='\n매장 위치: 오른쪽 작업대.';
 await act('save_manual_tap',{templateId:t.id,title:t.title,emoji:t.emoji,folderId:t.folderId,steps});
 assert.equal(state.catalogLinks[t.id].mode,'personalized');assert.equal(state.taskTemplates.find(x=>x.id===t.id).steps[0].videoUrl,customized);assert.equal(manualCatalog.entries.find(e=>e.sourceId==='food/kitchen-open').steps[0].videoUrl,old.steps[0].videoUrl);
 const backup=checklistBackup(state);assert.equal(backup.templates.length,1);assert.equal(backup.templates[0].steps[0].imageUrl,old.steps[0].imageUrl);assert.equal(backup.templates[0].steps[0].videoUrl,customized);
 await act('restore_checklist_backup',{operationId:'media-restore-20261023',backup});assert.equal(state.taskTemplates.length,6);assert.equal(state.taskTemplates.at(-1).steps[0].videoUrl,customized);assert.equal(state.taskTemplates.at(-1).settings.enabled,false);
 const before=structuredClone(state);await assert.rejects(()=>act('save_manual_tap',{templateId:t.id,title:t.title,emoji:t.emoji,folderId:t.folderId,steps:[{...steps[0],videoUrl:'javascript:alert(1)'}]}),{status:400});assert.deepEqual(state,before);
});
