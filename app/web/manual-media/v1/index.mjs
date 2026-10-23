const element=(tag,text,className)=>{const e=document.createElement(tag);if(text)e.textContent=text;if(className)e.className=className;return e;};
const link=(text,url,download=false)=>{const e=element('a',text,'button');e.href=url;if(download)e.download='';return e;};
try{
 const [projects,manuals,sources]=await Promise.all(['projects.json','manuals.json','SOURCES.json'].map(async file=>{const r=await fetch(file);if(!r.ok)throw Error('자료를 불러오지 못했어요. 새로고침해 주세요.');return r.json();}));
 const selected=new URLSearchParams(location.search).get('guide');
 const guides=projects.map((p,i)=>({project:p,manual:manuals[i]}));
 if(selected)guides.sort((a,b)=>(b.project.id===selected)-(a.project.id===selected));
 for(const {project:p,manual:m}of guides){
  const card=element('article',null,'card');card.id=p.id;const img=element('img');img.className='preview';img.src=p.id+'-poster.png';img.alt=m.title+'의 단계별 흐름';img.loading='lazy';card.append(img,element('h2',m.title),element('p',`${m.steps.length}개 단계 · 문구·사진·영상 링크 수정 가능`));
  const video=element('video');video.controls=true;video.preload='none';video.playsInline=true;video.src=p.id+'.mp4';video.poster=p.id+'-poster.png';video.setAttribute('aria-label',m.title+' 모션 예시');card.append(video);
  const actions=element('div',null,'actions');actions.append(link('모션 수정','studio.html?scene='+p.id),link('JSON 원본',p.id+'.json',true));card.append(actions);
  const details=element('details');details.append(element('summary','전체 단계와 매장별 수정 팁'));const list=element('ol',null,'steps');
  for(const s of m.steps){const item=element('li');item.append(element('strong',s.title),element('p',s.manual),element('p',s.tip,'muted'));if(s.imageUrl){const photo=element('img');photo.className='preview';photo.loading='lazy';photo.src=new URL(s.imageUrl).pathname.split('/').at(-1);photo.alt=s.title+' 참고 사진';item.append(photo);}if(s.videoUrl?.endsWith('/handwashing.mp4')){const v=element('video');v.controls=true;v.preload='none';v.playsInline=true;v.src='handwashing.mp4';v.poster='handwashing-poster.jpg';item.append(v,element('p','CDC 손 씻기 시범 · 영어 원본 전체 영상 · Public domain (US)','credits'));}list.append(item);}
  details.append(list);card.append(details);document.querySelector('#guides').append(card);
 }
 for(const s of sources.sources){const card=element('article',null,'card');card.append(element('h3',s.title),element('p',s.author),element('p',s.license+' · '+s.changes,'credits'));const actions=element('div',null,'actions');actions.append(link('출처 페이지',s.url));if(s.file)actions.append(link('원본 받기',s.file,true));if(s.licenseUrl)actions.append(link('사용 조건',s.licenseUrl));card.append(actions);document.querySelector('#source-list').append(card);}
}catch(e){document.querySelector('#guides').append(element('p',e.message,'error'));}
