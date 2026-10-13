import test from 'node:test';
import assert from 'node:assert/strict';
import {validateLayout} from './workshop.mjs';

test('Painted ground holes retain their shape through serialized maps',()=>{
 const layout={world:6,level:1,width:960,height:600,entities:[
  {kind:'spawn',x:480,y:500},
  {kind:'hole',x:320,y:270,radius:24,points:[-100,-90,100,-90,100,90]}
 ]};
 assert.equal(validateLayout(JSON.parse(JSON.stringify(layout))),true);
 for(const points of [[0],[],[NaN,0],[Infinity,0],[5000,0],[0,400],new Array(514).fill(0)]) {
  const invalid=structuredClone(layout);invalid.entities[1].points=points;
  assert.equal(validateLayout(invalid),false);
 }
 const invalid=structuredClone(layout);invalid.entities[1].kind='tear';assert.equal(validateLayout(invalid),false);
});
