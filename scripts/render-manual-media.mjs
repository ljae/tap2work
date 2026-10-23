// Optional authoring tool, not a deploy dependency. Install @napi-rs/canvas 0.1.80
// in an isolated tools directory and pass its absolute index.js path. ffmpeg
// must be available. Browser preview and published MP4 use the same renderer.
import {readFile,writeFile} from 'node:fs/promises';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {renderMotion,validateProject,duration} from '../app/web/manual-media/v1/motion.mjs';
const argument=process.argv.find(a=>a.startsWith('--canvas-module='));
if(!argument)throw Error('Pass --canvas-module=/absolute/path/to/@napi-rs/canvas/index.js');
const {createCanvas,GlobalFonts}=await import(pathToFileURL(argument.slice('--canvas-module='.length)));
const root=new URL('../app/web/manual-media/v1/',import.meta.url);
if(!GlobalFonts.registerFromPath(fileURLToPath(new URL('PretendardVariable.ttf',root)),'Pretendard'))throw Error('Font failed to load');
const projects=JSON.parse(await readFile(new URL('projects.json',root)));
for(const source of projects){
  if(!/^[a-z]+$/.test(source.id))throw Error('Invalid media filename');
  const project=validateProject(source),canvas=createCanvas(960,540),ctx=canvas.getContext('2d');
  renderMotion(canvas,project,0,{reduced:true});await writeFile(new URL(source.id+'-poster.png',root),canvas.toBuffer('image/png'));
  const fps=24,child=spawn('ffmpeg',['-y','-hide_banner','-loglevel','error','-f','rawvideo','-pixel_format','rgba','-video_size','960x540','-framerate',String(fps),'-i','pipe:0','-an','-c:v','libx264','-preset','fast','-crf','23','-pix_fmt','yuv420p','-movflags','+faststart',fileURLToPath(new URL(source.id+'.mp4',root))],{stdio:['pipe','inherit','inherit']});
  const finished=once(child,'close');
  for(let frame=0;frame<Math.ceil(duration(project)*fps);frame++){
    renderMotion(canvas,project,frame/fps);
    const buffer=Buffer.from(ctx.getImageData(0,0,960,540).data.buffer);
    if(!child.stdin.write(buffer))await once(child.stdin,'drain');
  }
  child.stdin.end();const [code]=await finished;if(code!==0)throw Error('ffmpeg failed');
  console.log(source.id,duration(project)+'s');
}
