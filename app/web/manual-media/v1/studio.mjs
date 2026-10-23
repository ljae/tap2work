import {validateProject,decodeProject,projectLink,renderMotion,duration} from './motion.mjs';
const $=s=>document.querySelector(s),canvas=$('#canvas'),status=$('#status');
let project,templates=[],playing=false,recording=false,time=0,last=0,dirty=false;
const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
function message(value,error=false){status.textContent=value;status.classList.toggle('error',error);}
function draw(){renderMotion(canvas,project,time,{reduced});}
function stop(){playing=false;last=0;$('#play').textContent='미리보기 재생';}
function update(){dirty=true;stop();time=0;try{validateProject(project);draw();$('#share').value=projectLink(project);message('수정본 링크 또는 JSON 원본으로 보관해 주세요.');}catch(e){$('#share').value='';message(e.message,true);}}
function input(parent,label,value,onChange,{type='text',max=40,min,step}={}){
  const wrap=document.createElement('label');wrap.textContent=label;const el=document.createElement(type==='textarea'?'textarea':'input');
  if(type!=='textarea')el.type=type;el.value=value;if(type!=='number')el.maxLength=max;else{el.min=min;el.max=max;el.step=step;}
  el.addEventListener('input',()=>{onChange(type==='number'?Number(el.value):el.value);update();});wrap.append(el);parent.append(wrap);
}
function button(parent,label,fn){const b=document.createElement('button');b.type='button';b.textContent=label;b.addEventListener('click',fn);parent.append(b);return b;}
function fields(){
  $('#title').value=project.title;$('#accent').value=project.accent;$('#scenes').replaceChildren();
  project.scenes.forEach((s,i)=>{const card=document.createElement('section');card.className='card scene';const head=document.createElement('h3');head.textContent=`장면 ${i+1}`;card.append(head);
    input(card,'단계 제목 · 최대 40자',s.title,v=>s.title=v);input(card,'설명 · 최대 80자',s.detail,v=>s.detail=v,{type:'textarea',max:80});
    input(card,'장면 길이(초) · 2~30',s.seconds,v=>s.seconds=v,{type:'number',min:2,max:30,step:.5});
    const actions=document.createElement('div');actions.className='actions';
    button(actions,'위로',()=>{[project.scenes[i-1],project.scenes[i]]=[s,project.scenes[i-1]];fields();update();}).disabled=i===0;
    button(actions,'아래로',()=>{[project.scenes[i+1],project.scenes[i]]=[s,project.scenes[i+1]];fields();update();}).disabled=i===project.scenes.length-1;
    button(actions,'삭제',()=>{project.scenes.splice(i,1);fields();update();}).disabled=project.scenes.length===1;
    card.append(actions);$('#scenes').append(card);
  });
  $('#add').disabled=project.scenes.length>=10;
}
async function saveBlob(blob,name){const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(a.href),1000);}
function frame(now){if(!playing)return;if(last)time+=(now-last)/1000;last=now;draw();if(time>=duration(project)){stop();return;}requestAnimationFrame(frame);}
try{
  const response=await fetch('projects.json');if(!response.ok)throw Error('예시를 불러오지 못했어요. 새로고침해 주세요.');templates=await response.json();
  for(const p of templates){const option=document.createElement('option');option.value=p.id;option.textContent=p.title;$('#template').append(option);}
  const encoded=new URLSearchParams(location.hash.slice(1)).get('p');const selected=templates.find(p=>p.id===new URLSearchParams(location.search).get('scene'))??templates[1];
  project=encoded?decodeProject(encoded):validateProject(selected);$('#template').value=selected.id;fields();await document.fonts.load('600 30px Pretendard');draw();$('#share').value=projectLink(project);
}catch(e){message(e.message,true);for(const b of document.querySelectorAll('button'))b.disabled=true;}
$('#title').addEventListener('input',e=>{project.title=e.target.value;update();});$('#accent').addEventListener('input',e=>{project.accent=e.target.value;update();});
$('#template').addEventListener('change',e=>{if(recording)return;if(dirty&&!confirm('저장하지 않은 수정 내용이 있어요. 다른 예시로 바꿀까요?')){e.target.value=project.id??'';return;}project=validateProject(templates.find(p=>p.id===e.target.value));fields();update();});
$('#add').addEventListener('click',()=>{if(project.scenes.length>=10)return;project.scenes.push({title:'새 단계',detail:'우리 매장에서 확인할 행동을 적어 주세요.',seconds:5,icon:'check'});fields();update();});
$('#play').addEventListener('click',()=>{try{validateProject(project);if(playing){stop();return;}if(time>=duration(project))time=0;playing=true;last=0;$('#play').textContent='일시정지';requestAnimationFrame(frame);}catch(e){message(e.message,true);}});
$('#restart').addEventListener('click',()=>{stop();time=0;draw();});
$('#copy').addEventListener('click',async()=>{try{const value=projectLink(project);$('#share').value=value;await navigator.clipboard.writeText(value);dirty=false;message('링크를 복사했어요. 매뉴얼 편집의 영상 링크에 붙여 넣고 저장하세요.');}catch(e){$('#share').focus();$('#share').select();message(e.message+' 아래 링크를 직접 복사할 수도 있어요.',true);}});
$('#save').addEventListener('click',async()=>{try{await saveBlob(new Blob([JSON.stringify(validateProject(project),null,2)],{type:'application/json'}),'tap-work-motion.json');dirty=false;message('편집 가능한 JSON 원본을 저장했어요.');}catch(e){message(e.message,true);}});
$('#load').addEventListener('change',async e=>{try{const f=e.target.files[0];if(!f)return;if(f.size>128000)throw Error('128KB 이내의 JSON 원본을 선택해 주세요.');const next=validateProject(JSON.parse(await f.text()));project=next;fields();update();message('원본을 불러왔어요. 미리보기를 확인해 주세요.');}catch(e){message(e.message,true);}finally{e.target.value='';}});
$('#poster').addEventListener('click',()=>{try{validateProject(project);canvas.toBlob(b=>{if(b)saveBlob(b,'tap-work-motion.png');});}catch(e){message(e.message,true);}});
$('#record').addEventListener('click',async()=>{
  let stream,recorder,recordError;const disabled=new Map();
  try{
    validateProject(project);if(typeof MediaRecorder==='undefined'||!canvas.captureStream)throw Error('이 브라우저는 영상 내보내기를 지원하지 않아요. 수정본 링크나 JSON을 사용해 주세요.');
    const mime=['video/mp4','video/webm;codecs=vp9','video/webm;codecs=vp8','video/webm'].find(t=>MediaRecorder.isTypeSupported(t));if(!mime)throw Error('지원하는 영상 형식이 없어요. 수정본 링크를 사용해 주세요.');
    stop();recording=true;time=0;draw();for(const el of document.querySelectorAll('button,input,textarea,select')){disabled.set(el,el.disabled);el.disabled=true;}
    stream=canvas.captureStream(30);recorder=new MediaRecorder(stream,{mimeType:mime,videoBitsPerSecond:1800000});const chunks=[];recorder.ondataavailable=e=>{if(e.data.size)chunks.push(e.data);};
    const done=new Promise(resolve=>{recorder.onstop=resolve;});
    const started=performance.now();await new Promise((resolve,reject)=>{
      let frameId;function finish(error){cancelAnimationFrame(frameId);document.removeEventListener('visibilitychange',visibility);error?reject(error):resolve();}
      function visibility(){if(document.hidden)finish(Error('화면이 가려져 녹화를 중지했어요. 화면을 열어 둔 채 다시 시도해 주세요.'));}
      function capture(now){time=Math.min((now-started)/1000,duration(project));renderMotion(canvas,project,time);message(`영상 내보내는 중 · ${Math.floor(time)} / ${duration(project)}초`);if(time>=duration(project)){finish();return;}frameId=requestAnimationFrame(capture);}
      recorder.onerror=()=>{recordError=Error('영상을 저장하지 못했어요. 다시 시도해 주세요.');finish(recordError);};recorder.start(1000);document.addEventListener('visibilitychange',visibility);frameId=requestAnimationFrame(capture);
    });
    recorder.stop();await done;if(recordError)throw recordError;await saveBlob(new Blob(chunks,{type:mime}),mime.startsWith('video/mp4')?'tap-work-motion.mp4':'tap-work-motion.webm');message('영상을 저장했어요. 앱에는 수정본 링크를 넣으면 파일 업로드 없이 볼 수 있어요.');
  }catch(e){if(recorder?.state==='recording')recorder.stop();message(e.message,true);}finally{stream?.getTracks().forEach(t=>t.stop());recording=false;for(const [el,value]of disabled)el.disabled=value;}
});
document.addEventListener('visibilitychange',()=>{if(document.hidden&&!recording)stop();});
window.addEventListener('beforeunload',e=>{if(dirty||recording){e.preventDefault();e.returnValue='';}});
