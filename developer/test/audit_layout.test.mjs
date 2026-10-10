import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateLayout } from '../layout.mjs';

test('first-floor table edit preserves other-floor places and server guards', () => {
  const place = (id, floor, x) => ({id, floor, x, y:0, width:1, height:1, seats:0, kind:'storage', name:id, description:'안내', photo:'https://example.com/test.jpg', area:'후면'});
  const state = {layout:{name:'테스트',columns:12,rows:12},store:{},items:[],preparedItems:[],tasks:[],taskTemplates:[],zones:[place('first','1층',0),place('second','2층',0)]};
  const added = {id:'new',floor:'1층',kind:'table',name:'새 테이블',description:'',x:4,y:0,width:3,height:2,seats:6};
  const input = {floorScope:'1층',layout:state.layout,zones:[state.zones[0],added]};
  const saved = validateLayout(input,state);
  assert.deepEqual(saved.zones.find(z=>z.id==='second'),state.zones[1]);
  assert.equal(saved.zones.find(z=>z.id==='first').photo,state.zones[0].photo);
  assert.equal(saved.zones.find(z=>z.id==='first').area,'후면');
  assert.equal(saved.zones.find(z=>z.id==='new').floor,'1층');
  assert.equal(saved.zones.find(z=>z.id==='new').seats,6);
  assert.throws(()=>validateLayout({...input,zones:[state.zones[0],{...added,floor:undefined}]},state),/다른 층/);
  assert.throws(()=>validateLayout({...input,zones:[...input.zones,state.zones[1]]},state),/다른 층/);
  assert.throws(()=>validateLayout({...input,zones:[state.zones[0],{...added,x:0}]},state),/겹쳐/);
  assert.throws(()=>validateLayout({...input,zones:[state.zones[0],{...added,x:11}]},state),/경계/);
});
