import {decodeProject,validateProject,renderMotion,duration} from './motion.mjs';
const canvas=document.querySelector('#canvas'),status=document.querySelector('#status'),play=document.querySelector('#play');
let project,playing=false,time=0,last=0;
try{
  const encoded=new URLSearchParams(location.hash.slice(1)).get('p');
  if(encoded)project=decodeProject(encoded);
  else{const scene=new URLSearchParams(location.search).get('scene')??'opening';if(!['shift','opening','receiving','service','closing'].includes(scene))throw Error('장면을 찾지 못했어요.');project=validateProject(await (await fetch(scene+'.json')).json());}
  await document.fonts.load('600 30px Pretendard');renderMotion(canvas,project,0,{reduced:true});
  document.querySelector('#edit').href='studio.html'+location.search+location.hash;
}catch(e){status.textContent=e.message;play.disabled=true;document.querySelector('#restart').disabled=true;}
function frame(now){if(!playing)return;if(last)time+=(now-last)/1000;last=now;renderMotion(canvas,project,time);if(time>=duration(project)){playing=false;play.textContent='다시 재생';return;}requestAnimationFrame(frame);}
play.addEventListener('click',()=>{if(!project)return;playing=!playing;last=0;if(time>=duration(project))time=0;play.textContent=playing?'일시정지':'재생';if(playing)requestAnimationFrame(frame);});
document.querySelector('#restart').addEventListener('click',()=>{time=0;last=0;if(project)renderMotion(canvas,project,0,{reduced:true});});
document.addEventListener('visibilitychange',()=>{if(document.hidden){playing=false;last=0;play.textContent='재생';}});
