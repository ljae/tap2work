import {readFile,writeFile,readdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import assert from 'node:assert/strict';
const root=new URL('../app/web/manual-media/v1/',import.meta.url);
const sources=[
 {id:'kitchen-book',title:'Basic Kitchen and Food Service Management',author:'BC Cook Articulation Committee / BCcampus (2015)',license:'CC BY 4.0, except where otherwise noted',licenseUrl:'https://creativecommons.org/licenses/by/4.0/',url:'https://opentextbc.ca/basickitchenandfoodservicemanagement/',file:'originals/kitchen-management.epub',originalUrl:'https://opentextbc.ca/basickitchenandfoodservicemanagement/open/download?type=epub',changes:'Publisher EPUB unchanged; internal third-party credits retained. General inventory principles inform the examples.'},
 {id:'hygiene-book',title:'Food Safety, Sanitation, and Personal Hygiene',author:'BC Cook Articulation Committee / go2HR / BCcampus (2015)',license:'CC BY 4.0, except where otherwise noted',licenseUrl:'https://creativecommons.org/licenses/by/4.0/',url:'https://opentextbc.ca/foodsafety/',file:'originals/food-safety.epub',originalUrl:'https://opentextbc.ca/foodsafety/open/download?type=epub',changes:'Publisher EPUB unchanged; internal third-party credits retained. Overseas numeric/legal requirements are not asserted as Korean requirements.'},
 {id:'kitchen-photo',title:'RestaurantKitchen.jpg',author:'Raysonho @ Open Grid Scheduler / Grid Engine',license:'CC0 1.0',licenseUrl:'https://creativecommons.org/publicdomain/zero/1.0/',url:'https://commons.wikimedia.org/wiki/File:RestaurantKitchen.jpg',file:'originals/kitchen.jpg',originalUrl:'https://upload.wikimedia.org/wikipedia/commons/3/3c/RestaurantKitchen.jpg',changes:'Original unchanged. kitchen.jpg is the 960px thumbnail supplied by Wikimedia. Illustrative setting, not a verified store layout.'},
 {id:'hands-photo',title:'Washing hands (cropped).jpg',author:'Sgt. Grace L. Waladkewics / United States Marine Corps',license:'Public domain (US federal government work)',url:'https://commons.wikimedia.org/wiki/File:Washing_hands_(cropped).jpg',file:'originals/handwashing.jpg',originalUrl:'https://upload.wikimedia.org/wikipedia/commons/8/86/Washing_hands_%28cropped%29.jpg',changes:'Public Wikimedia crop retained unchanged. handwashing.jpg is its Wikimedia 500px thumbnail. Original photographer credit preserved.'},
 {id:'hands-video',title:'Fight Germs. Wash Your Hands!',author:'Centers for Disease Control and Prevention (2017)',license:'Public domain (US federal government work)',url:'https://commons.wikimedia.org/wiki/File:Fight_Germs._Wash_Your_Hands!.webm',file:'handwashing.mp4',originalUrl:'https://www.cdc.gov/wcms/video/low-res/cdctv/2017/34753475Handwashing.mp4',changes:'Complete official English MP4 unchanged. Poster extracted at 79 seconds. No endorsement by CDC is implied.'},
 {id:'motion',title:'TAP Work editable motion examples',author:'TAP Work (2026)',license:'CC BY 4.0',licenseUrl:'https://creativecommons.org/licenses/by/4.0/',url:'https://tap2.work/manual-media/v1/',file:'projects.json',changes:'New Korean scene summaries, vector animation, renderer and editor. Original authoring files included; customized versions should identify changes.'},
];
const paths=(await readdir(root,{recursive:true,withFileTypes:true})).filter(e=>e.isFile()).map(e=>path.relative(fileURLToPath(root),path.join(e.parentPath??e.path,e.name)).split(path.sep).join('/')).filter(p=>!['SOURCES.json','source-pack.zip'].includes(p)).sort();
const files=[];
for(const path of paths){assert.ok(/^(?:originals\/)?[a-zA-Z0-9_.-]+$/.test(path),path);assert.ok(/\.(?:html|mjs|css|json|md|ttf|txt|mp4|png|jpg|epub)$/.test(path),path);const b=await readFile(new URL(path,root));files.push({path,bytes:b.length,sha256:createHash('sha256').update(b).digest('hex')});}
const manifest={schemaVersion:1,checkedAt:'2026-10-23',referenceOnly:'https://kmong.com/gig/317668',sources,files};
const out=JSON.stringify(manifest,null,2)+'\n';
if(process.argv.includes('--check')){
 assert.equal(await readFile(new URL('SOURCES.json',root),'utf8'),out,'Run npm run media:build after source changes');
 const zip=await readFile(new URL('source-pack.zip',root));assert.equal(zip.readUInt32LE(0),0x04034b50);
}else{
 await writeFile(new URL('SOURCES.json',root),out);
 const code=`import json,sys,zipfile,pathlib\nr=pathlib.Path(sys.argv[1]);m=json.loads((r/'SOURCES.json').read_text());paths=[x['path'] for x in m['files']]+['SOURCES.json']\nwith zipfile.ZipFile(r/'source-pack.zip','w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:\n for p in sorted(paths):\n  i=zipfile.ZipInfo('tap-work-media/'+p,date_time=(2026,10,23,0,0,0));i.external_attr=0o644<<16;i.compress_type=zipfile.ZIP_DEFLATED;z.writestr(i,(r/p).read_bytes())\n`;
 const result=spawnSync('python3',['-c',code,fileURLToPath(root)],{stdio:'inherit'});if(result.status!==0)throw Error('Source ZIP build failed');
}
console.log(`Manual media: ${sources.length} credited sources, ${files.length} verified files.`);
