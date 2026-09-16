import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync,readdirSync} from 'node:fs';
import worker,{countryOf} from './worker.mjs';
function database() {
  const db=new DatabaseSync(':memory:'); for(const file of readdirSync(new URL('migrations/',import.meta.url)).sort()) db.exec(readFileSync(new URL('migrations/'+file,import.meta.url),'utf8'));
  return {prepare(sql) {return {bind(...args){return {async first(){return db.prepare(sql).get(...args)},async all(){return {results:db.prepare(sql).all(...args)}},async run(){return db.prepare(sql).run(...args)}}}}},async batch(writes){db.exec('BEGIN');try {const results=await Promise.all(writes.map(w=>w.run()));db.exec('COMMIT');return results;}catch(e){db.exec('ROLLBACK');throw e;}}};
}
const token='a'.repeat(64);
function call(env,path,{body,country='FR',auth=token}={}) {
  const req=new Request('https://test'+path,{method:body===undefined?'GET':'POST',headers:{Authorization:'Bearer '+auth,'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body)});
  Object.defineProperty(req,'cf',{value:{country}}); return worker.fetch(req,env);
}
test('geolocation only trusts Cloudflare metadata',()=>{assert.equal(countryOf({cf:{country:'BE'}}),'BE');assert.equal(countryOf({cf:{country:'T1'}}),'ZZ');assert.equal(countryOf({}),'ZZ')});
test('complete run, idempotency, country filtering, world isolation, and invalid submissions',async()=>{
  const env={DB:database()};
  assert.equal((await call(env,'/v1/runs',{body:{name:'Test',world:3}})).status,400);
  assert.equal((await call(env,'/v1/runs',{body:{name:'Test',world:1},auth:'bad'})).status,401);
  const start=await call(env,'/v1/runs',{body:{name:'Étoile',world:1,country:'US'}}); assert.equal(start.status,201);
  const run=await start.json(); assert.equal(run.country,'FR');
  const path='/v1/runs/'+run.id+'/checkpoint';
  assert.equal((await call(env,path,{body:{level:10,elapsedMs:1000,deaths:0}})).status,409);
  assert.equal((await call(env,path,{body:{level:1,elapsedMs:999999,deaths:0}})).status,400);
  assert.equal((await call(env,path,{body:{level:1,elapsedMs:100,deaths:0},auth:'b'.repeat(64)})).status,404);
  for(let level=1;level<=10;level++) assert.equal((await call(env,path,{body:{level,elapsedMs:level*100,deaths:1}})).status,200);
  assert.equal((await call(env,path,{body:{level:10,elapsedMs:1000,deaths:1}})).status,200);
  const global=await (await call(env,'/v1/leaderboard?world=1')).json(); assert.equal(global.scores.length,1);assert.equal(global.scores[0].name,'Étoile');assert.equal(global.scores[0].country,'FR');
  assert.equal((await (await call(env,'/v1/leaderboard?world=1&scope=country',{country:'BE'})).json()).scores.length,0);
  assert.equal((await (await call(env,'/v1/leaderboard?world=1&scope=country',{country:'FR'})).json()).scores.length,1);
  assert.equal((await (await call(env,'/v1/leaderboard?world=2')).json()).scores.length,0);
  assert.equal((await (await call(env,'/v1/leaderboard?world=3')).json()).scores.length,0);
});
test('payload and rate limit are bounded',async()=>{
 const env={DB:database()};
 assert.equal((await call(env,'/v1/runs',{body:{name:'x'.repeat(3000),world:1}})).status,413);
 assert.equal((await call({...env,API_LIMITER:{limit:async()=>({success:false})}},'/v1/location')).status,429);
});
test('new worlds store the run skin and reject invalid skins',async()=>{
 const env={DB:database()};
 for(const skin of [0,6,1.5,'2',null]) assert.equal((await call(env,'/v1/runs',{body:{name:'Test',world:4,skin}})).status,400);
 for(const world of [4,5,6]) {
  const skin=world-1; const start=await call(env,'/v1/runs',{body:{name:'Abysses',world,skin}}); assert.equal(start.status,201);
  const run=await start.json();
  for(let level=1;level<=10;level++) assert.equal((await call(env,'/v1/runs/'+run.id+'/checkpoint',{body:{level,elapsedMs:level*100,deaths:3}})).status,200);
  const board=await (await call(env,'/v1/leaderboard?world='+world)).json();
  assert.equal(board.scores.length,1);assert.equal(board.scores[0].skin,skin);assert.equal(board.scores[0].deaths,3);
 }
});
test('top ten uses each player best run and its associated skin',async()=>{
 const env={DB:database()};
 for(let i=0;i<14;i++) await env.DB.prepare('INSERT INTO scores VALUES(?,?,?,?,?,?,?,?,?)').bind('r'+i,'owner'+i,4,'Player'+i,'FR',10000+i*100,i,1,(i%5)+1).run();
 await env.DB.prepare('INSERT INTO scores VALUES(?,?,?,?,?,?,?,?,?)').bind('old','owner0',4,'OldSkin','FR',99000,0,0,5).run();
 await env.DB.prepare('INSERT INTO scores VALUES(?,?,?,?,?,?,?,?,?)').bind('tie','owner1',4,'FewerDeaths','FR',10100,0,2,4).run();
 const {scores}=await (await call(env,'/v1/leaderboard?world=4')).json();
 assert.equal(scores.length,10);assert.equal(scores[0].skin,1);assert.equal(scores[1].name,'FewerDeaths');assert.equal(scores[1].skin,4);assert.equal(scores[9].name,'Player9');
});
test('schema migration preserves old scores and active runs',()=>{
 const db=new DatabaseSync(':memory:');
 db.exec(readFileSync(new URL('migrations/0001_scores.sql',import.meta.url),'utf8'));
 db.exec("INSERT INTO runs VALUES('run','owner',2,'Existing','FR',100,6,7000,2); INSERT INTO scores VALUES('score','owner',1,'Existing','FR',30000,4,200)");
 db.exec(readFileSync(new URL('migrations/0002_worlds_and_skins.sql',import.meta.url),'utf8'));
 assert.equal(db.prepare('SELECT skin FROM scores').get().skin,1);
 assert.equal(db.prepare('SELECT elapsed_ms FROM scores').get().elapsed_ms,30000);
 assert.equal(db.prepare('SELECT level FROM runs').get().level,6);
});
