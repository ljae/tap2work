export function validateProject(value) {
  const text=(s,max)=>typeof s==='string'&&s.trim()&&s.length<=max?s.trim():null;
  if(value?.format!=='tap2work-motion'||value.version!==1||!text(value.title,40)||
      !/^#[0-9a-f]{6}$/i.test(value.accent??'')||!Array.isArray(value.scenes)||value.scenes.length<1||value.scenes.length>10) throw Error('제목·색상과 1~10개 장면을 확인해 주세요.');
  const scenes=value.scenes.map(s=>{
    if(!text(s.title,40)||!text(s.detail,80)||!Number.isFinite(s.seconds)||s.seconds<2||s.seconds>30)throw Error('장면 제목·설명과 2~30초 길이를 확인해 주세요.');
    return {title:s.title.trim(),detail:s.detail.trim(),seconds:s.seconds,icon:['hands','check','box','chat','power'].includes(s.icon)?s.icon:'check'};
  });
  if(scenes.reduce((n,s)=>n+s.seconds,0)>120)throw Error('영상 전체 길이는 120초 이내로 맞춰 주세요.');
  return {format:'tap2work-motion',version:1,title:value.title.trim(),accent:value.accent,scenes};
}
export const duration=p=>p.scenes.reduce((n,s)=>n+s.seconds,0);
export function encodeProject(value) {
  const p=validateProject(value);
  const compact=[p.title,p.accent,p.scenes.map(s=>[s.title,s.detail,s.seconds,s.icon])];
  const bytes=new TextEncoder().encode(JSON.stringify(compact));
  let binary='';for(const b of bytes)binary+=String.fromCharCode(b);
  return btoa(binary).replaceAll('+','-').replaceAll('/','_').replace(/=+$/,'');
}
export function decodeProject(encoded) {
  if(typeof encoded!=='string'||encoded.length>1900||!/^[A-Za-z0-9_-]+$/.test(encoded))throw Error('수정본 링크를 확인해 주세요.');
  const text=atob(encoded.replaceAll('-','+').replaceAll('_','/'));
  const data=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(Uint8Array.from(text,c=>c.charCodeAt(0))));
  if(!Array.isArray(data)||data.length!==3||!Array.isArray(data[2]))throw Error('수정본 형식이 올바르지 않아요.');
  return validateProject({format:'tap2work-motion',version:1,title:data[0],accent:data[1],scenes:data[2].map(s=>({title:s[0],detail:s[1],seconds:s[2],icon:s[3]}))});
}
export function projectLink(project,base='https://tap2.work/manual-media/v1/player.html') {
  const url=base+'#p='+encodeProject(project);
  if(url.length>2000)throw Error('링크에 담을 문구가 길어요. 설명을 줄이거나 JSON 원본으로 보관해 주세요.');
  return url;
}
function box(ctx,x,y,w,h,r,fill){ctx.fillStyle=fill;ctx.beginPath();ctx.roundRect(x,y,w,h,r);ctx.fill();}
function lines(ctx,text,x,y,width,size,max=3,color='#f1f6f0'){
  ctx.font=`600 ${size}px Pretendard, sans-serif`;ctx.fillStyle=color;
  let line='',row=0;
  for(const char of text){
    if(ctx.measureText(line+char).width>width&&line){ctx.fillText(line,x,y+row*size*1.45);line=char;row++;if(row>=max)return;}
    else line+=char;
  }
  if(line)ctx.fillText(line,x,y+row*size*1.45);
}
function icon(ctx,name,x,y,size,color){
  ctx.save();ctx.translate(x,y);ctx.scale(size/100,size/100);ctx.strokeStyle=color;ctx.lineWidth=6;ctx.lineCap='round';ctx.lineJoin='round';ctx.beginPath();
  if(name==='box'){ctx.rect(18,28,64,55);ctx.moveTo(18,28);ctx.lineTo(40,12);ctx.lineTo(88,12);ctx.lineTo(82,28);ctx.moveTo(50,28);ctx.lineTo(50,83);ctx.moveTo(50,28);ctx.lineTo(68,12);}
  else if(name==='chat'){ctx.roundRect(12,16,76,55,13);ctx.moveTo(32,71);ctx.lineTo(24,90);ctx.lineTo(52,71);ctx.moveTo(30,36);ctx.lineTo(70,36);ctx.moveTo(30,52);ctx.lineTo(60,52);}
  else if(name==='power'){ctx.arc(50,52,33,-Math.PI*.3,Math.PI*1.3);ctx.moveTo(50,9);ctx.lineTo(50,46);}
  else if(name==='hands'){ctx.moveTo(20,67);ctx.lineTo(42,42);ctx.lineTo(66,46);ctx.lineTo(85,24);ctx.moveTo(21,84);ctx.lineTo(44,63);ctx.lineTo(68,66);ctx.lineTo(90,46);ctx.moveTo(36,14);ctx.lineTo(33,26);ctx.moveTo(55,17);ctx.lineTo(51,29);}
  else {ctx.roundRect(14,14,72,72,18);ctx.moveTo(30,50);ctx.lineTo(45,65);ctx.lineTo(72,36);}
  ctx.stroke();ctx.restore();
}
export function renderMotion(canvas,project,seconds,{reduced=false}={}) {
  const ctx=canvas.getContext('2d');const w=1280,h=720;
  ctx.save();ctx.scale(canvas.width/w,canvas.height/h);ctx.fillStyle='#111c18';ctx.fillRect(0,0,w,h);
  const total=duration(project);let elapsed=Math.min(Math.max(seconds,0),total-.001),index=0,local=elapsed;
  while(index<project.scenes.length-1&&local>=project.scenes[index].seconds)local-=project.scenes[index++].seconds;
  const scene=project.scenes[index],accent=project.accent;
  const glow=ctx.createRadialGradient(1110,80,0,1110,80,530);glow.addColorStop(0,accent+'22');glow.addColorStop(1,'#111c1800');ctx.fillStyle=glow;ctx.fillRect(0,0,w,h);
  ctx.textBaseline='top';lines(ctx,'TAP Work  /  매장 교육 예시',64,42,1000,23,1,'#b1c5b8');
  lines(ctx,project.title,64,96,1150,48,2);
  const count=project.scenes.length, gap=Math.min(220,1080/count),start=(w-gap*(count-1))/2;
  const cy=285;
  ctx.lineWidth=4;ctx.strokeStyle='#3b5144';ctx.beginPath();ctx.moveTo(start,cy);ctx.lineTo(start+gap*(count-1),cy);ctx.stroke();
  if(index>0){ctx.strokeStyle=accent;ctx.beginPath();ctx.moveTo(start,cy);ctx.lineTo(start+gap*index,cy);ctx.stroke();}
  for(let i=0;i<count;i++){
    const x=start+gap*i;const selected=i===index;
    if(selected&&!reduced){ctx.strokeStyle=accent+'50';ctx.lineWidth=3;ctx.beginPath();ctx.arc(x,cy,48+Math.sin(local*2)*4,0,Math.PI*2);ctx.stroke();}
    box(ctx,x-36,cy-36,72,72,23,i<=index?accent:'#2a3d33');
    ctx.fillStyle=i<=index?'#111c18':'#b1c5b8';ctx.font='700 28px Pretendard, sans-serif';ctx.textAlign='center';ctx.fillText(String(i+1),x,cy-16);ctx.textAlign='left';
  }
  const rise=reduced?0:Math.max(0,1-local/.35)*14;
  box(ctx,64,375+rise,1152,248,28,'#1d2c25');icon(ctx,scene.icon,88,414+rise,92,accent);
  lines(ctx,scene.title,208,406+rise,940,37,2);
  lines(ctx,scene.detail,208,492+rise,940,29,3,'#b1c5b8');
  box(ctx,64,659,1152,5,3,'#2a3d33');box(ctx,64,659,1152*Math.min(elapsed/total,1),5,3,accent);
  lines(ctx,`${index+1} / ${count}  ·  실제 작업은 매장 기준과 함께 확인해요`,64,681,1100,18,1,'#b1c5b8');
  ctx.restore();return {index,total,elapsed};
}
