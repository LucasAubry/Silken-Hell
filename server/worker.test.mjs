import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync,readdirSync} from 'node:fs';
import worker,{countryOf} from './worker.mjs';
function database() {
  const db=new DatabaseSync(':memory:'); for(const file of readdirSync(new URL('migrations/',import.meta.url)).filter(n=>/^\d{4}_[a-z0-9_]+\.sql$/.test(n)).sort()) db.exec(readFileSync(new URL('migrations/'+file,import.meta.url),'utf8'));
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
  assert.equal((await call(env,'/v1/runs',{body:{name:'Test',world:8}})).status,400);
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
 for(const world of [4,5,6,7]) {
  const skin=world%5+1; const start=await call(env,'/v1/runs',{body:{name:'Abysses',world,skin}}); assert.equal(start.status,201);
  const run=await start.json();
  for(let level=1;level<=10;level++) assert.equal((await call(env,'/v1/runs/'+run.id+'/checkpoint',{body:{level,elapsedMs:level*100,deaths:3}})).status,200);
  const board=await (await call(env,'/v1/leaderboard?world='+world)).json();
  assert.equal(board.scores.length,1);assert.equal(board.scores[0].skin,skin);assert.equal(board.scores[0].deaths,3);
 }
});
test('first page includes every run and its associated skin',async()=>{
 const env={DB:database()};
 for(let i=0;i<14;i++) await env.DB.prepare('INSERT INTO scores VALUES(?,?,?,?,?,?,?,?,?)').bind('r'+i,'owner'+i,4,'Player'+i,'FR',10000+i*100,i,1,(i%5)+1).run();
 await env.DB.prepare('INSERT INTO scores VALUES(?,?,?,?,?,?,?,?,?)').bind('old','owner0',4,'Player0','FR',99000,0,0,5).run();
 await env.DB.prepare('INSERT INTO scores VALUES(?,?,?,?,?,?,?,?,?)').bind('tie','owner1',4,'Player1','FR',10100,0,2,4).run();
 const {scores}=await (await call(env,'/v1/leaderboard?world=4')).json();
 assert.equal(scores.length,10);assert.equal(scores[0].skin,1);assert.equal(scores[1].name,'Player1');assert.equal(scores[1].skin,4);assert.equal(scores[9].name,'Player8');
});
test('all nicknames on one computer remain visible across stable pages',async()=>{
 const env={DB:database()};
 for(let i=0;i<23;i++) await env.DB.prepare('INSERT INTO scores VALUES(?,?,?,?,?,?,?,?,?)').bind('r'+i,'shared-PC',5,'Player'+i,i%2?'FR':'BE',10000+i*100,i,1,i%5+1).run();
 await env.DB.prepare('INSERT INTO scores VALUES(?,?,?,?,?,?,?,?,?)').bind('old','shared-PC',5,'Player0','BE',99000,0,0,5).run();
 const rows=[];
 for(let page=1;page<=3;page++) {
  const data=await (await call(env,'/v1/leaderboard?world=5&page='+page)).json();
  assert.equal(data.total,24);assert.equal(data.page,page);assert.equal(data.hasMore,page<3);
  assert.equal(data.scores.length,page===3?4:10);rows.push(...data.scores);
 }
 assert.equal(new Set(rows.map(r=>r.name)).size,23);assert.equal(rows[0].skin,1);
 const local=await (await call(env,'/v1/leaderboard?world=5&scope=country&page=2')).json();
 assert.equal(local.total,11);assert.equal(local.scores.length,1);assert.equal(local.scores[0].country,'FR');
 for(const page of ['0','-1','1.5','no']) assert.equal((await call(env,'/v1/leaderboard?world=5&page='+page)).status,400);
});
test('schema migration preserves old scores and active runs',()=>{
 const db=new DatabaseSync(':memory:');
 db.exec(readFileSync(new URL('migrations/0001_scores.sql',import.meta.url),'utf8'));
 db.exec("INSERT INTO runs VALUES('run','owner',2,'Existing','FR',100,6,7000,2); INSERT INTO scores VALUES('score','owner',1,'Existing','FR',30000,4,200)");
 db.exec(readFileSync(new URL('migrations/0002_worlds_and_skins.sql',import.meta.url),'utf8'));
 assert.equal(db.prepare('SELECT skin FROM scores').get().skin,1);
 assert.equal(db.prepare('SELECT elapsed_ms FROM scores').get().elapsed_ms,30000);
 assert.equal(db.prepare('SELECT level FROM runs').get().level,6);
 db.exec(readFileSync(new URL('migrations/0003_abyss.sql',import.meta.url),'utf8'));
 assert.equal(db.prepare('SELECT elapsed_ms FROM scores').get().elapsed_ms,30000);
 assert.equal(db.prepare('SELECT level FROM runs').get().level,6);
 assert.equal(db.prepare('SELECT world FROM scores').get().world,1);
});

test('a nickname keeps its best time across computers, with the matching skin and deaths',async()=>{
 const env={DB:database()};
 for(const [id,owner,ms,skin,deaths,country] of [
  ['first','pc-a',20000,1,8,'FR'],['better','pc-b',15000,4,3,'BE'],['slower','pc-c',25000,2,0,'FR']]) {
  await env.DB.prepare('INSERT INTO scores VALUES(?,?,?,?,?,?,?,?,?)').bind(id,owner,1,'Même pseudo',country,ms,deaths,1,skin).run();
 }
 const data=await (await call(env,'/v1/leaderboard?world=1')).json();
 assert.equal(data.total,3); assert.deepEqual(data.scores.slice(0,1),[{name:'Même pseudo',country:'BE',time:16,rawTime:15,penalty:1,deaths:3,skin:4}]);
 const local=await (await call(env,'/v1/leaderboard?world=1&scope=country',{country:'BE'})).json();
 assert.equal(local.total,1); assert.equal(local.scores[0].time,16);
});
const map={world:1,level:1,width:960,height:600,entities:[{kind:'spawn',x:480,y:300},{kind:'tear',x:90,y:100},{kind:'mob',type:'abyss_fish',x:200,y:200},{kind:'boss',type:'wasp',x:300,y:180},{kind:'boss',type:'wasp',x:650,y:180}]};
test('Workshop supports mixed maps, ownership, independent stars, ranking, and pagination',async()=>{
 const env={DB:database()};
 let response=await call(env,'/v1/workshop',{body:{title:'Ma carte',author:'Lucas',layout:map}}); assert.equal(response.status,201);
 const {id}=await response.json();
 assert.deepEqual((await (await call(env,'/v1/workshop/'+id)).json()).layout,map);
 assert.equal((await call(env,'/v1/workshop',{auth:'b'.repeat(64),body:{id,title:'Vol',author:'Autre',layout:map}})).status,403);
 for(let i=0;i<3;i++) assert.equal((await call(env,'/v1/workshop/'+id+'/star',{body:{starred:true}})).status,200);
 let list=await (await call(env,'/v1/workshop')).json(); assert.equal(list.maps[0].stars,1); assert.equal(list.maps[0].starred,true);
 await call(env,'/v1/workshop/'+id+'/star',{auth:'b'.repeat(64),body:{starred:true}});
 for(let i=0;i<9;i++) await call(env,'/v1/workshop',{body:{title:'Carte '+i,author:'Créateur',layout:map}});
 list=await (await call(env,'/v1/workshop')).json(); assert.equal(list.maps.length,8);assert.equal(list.maps[0].id,id);assert.equal(list.maps[0].stars,2);assert.equal(list.hasMore,true);
 assert.equal((await (await call(env,'/v1/workshop?page=2')).json()).maps.length,2);
 await call(env,'/v1/workshop/'+id+'/star',{body:{starred:false}});
 list=await (await call(env,'/v1/workshop')).json();assert.equal(list.maps[0].stars,1);assert.equal(list.maps[0].starred,false);
 assert.equal((await call(env,'/v1/workshop',{body:{id,title:'Mise à jour',author:'Lucas',layout:map}})).status,200);
 assert.equal((await (await call(env,'/v1/workshop')).json()).maps[0].stars,1);
});
test('Workshop rejects malformed/executable map objects and invalid votes',async()=>{
 const env={DB:database()};
 for(const invalid of [{...map,world:8},{...map,entities:[]},{...map,entities:[{kind:'spawn',x:30,y:30},{kind:'boss',type:'../../secret',x:20,y:20}]},{...map,entities:[{kind:'spawn',x:30,y:30},{kind:'mob',type:'fish',x:40,y:40,speed:'boom'}]}]) {
  assert.equal((await call(env,'/v1/workshop',{body:{title:'T',author:'A',layout:invalid}})).status,400);
 }
 assert.equal((await call(env,'/v1/workshop',{auth:'bad',body:{title:'T',author:'A',layout:map}})).status,401);
 assert.equal((await call(env,'/v1/workshop',{body:{title:'T',author:'A',layout:map,padding:'x'.repeat(140000)}})).status,413);
 const {id}=await (await call(env,'/v1/workshop',{body:{title:'T',author:'A',layout:map}})).json();
 assert.equal((await call(env,'/v1/workshop/'+id+'/star',{body:{starred:1}})).status,400);
 assert.equal((await call(env,'/v1/workshop?page=-1')).status,400);
});
test('Workshop preserves infernal larva spawners and magma larvae in any biome',async()=>{
 const env={DB:database()};
 const layout={...map,world:4,entities:[...map.entities,{kind:'magma_spawner',x:220,y:250,rx:31,ry:23},{kind:'mob',type:'magma_larva',x:350,y:250,speed:245}]};
 const posted=await call(env,'/v1/workshop',{body:{title:'Larves',author:'QA',layout}});
 assert.equal(posted.status,201);
 const {id}=await posted.json();
 assert.deepEqual((await (await call(env,'/v1/workshop/'+id)).json()).layout,layout);
});
test('Renaissance completes after six ordered bosses and publishes its own leaderboard',async()=>{
 const env={DB:database()};
 const run=await (await call(env,'/v1/runs',{body:{name:'Renaissance',world:3,skin:4}})).json();
 const path='/v1/runs/'+run.id+'/checkpoint';
 assert.equal((await call(env,path,{body:{level:6,elapsedMs:600,deaths:1}})).status,409);
 for(let level=1;level<=6;level++) {
  const res=await call(env,path,{body:{level,elapsedMs:level*100,deaths:1}}); assert.equal(res.status,200);
  assert.equal((await res.json()).completed,level===6);
 }
 assert.equal((await call(env,path,{body:{level:6,elapsedMs:600,deaths:1}})).status,200);
 assert.equal((await call(env,path,{body:{level:7,elapsedMs:700,deaths:1}})).status,400);
 const scores=(await (await call(env,'/v1/leaderboard?world=3')).json()).scores;
 assert.equal(scores.length,1); assert.equal(scores[0].skin,4); assert.equal(scores[0].deaths,1);
 const layout={...map,world:3,level:2,entities:[{kind:'spawn',x:100,y:100},{kind:'boss',type:'storm',x:500,y:220}]};
 assert.equal((await call(env,'/v1/workshop',{body:{title:'Orage',author:'Test',layout}})).status,201);
 assert.equal((await call(env,'/v1/workshop',{body:{title:'Orage',author:'Test',layout:{...layout,level:7}}})).status,400);
});
test('Renaissance migration retains historical runs and scores',()=>{
 const db=new DatabaseSync(':memory:');
 for(const file of readdirSync(new URL('migrations/',import.meta.url)).filter(n=>/^\d{4}_[a-z0-9_]+\.sql$/.test(n)).sort().filter(n=>n<'0005')) db.exec(readFileSync(new URL('migrations/'+file,import.meta.url),'utf8'));
 db.exec("INSERT INTO runs VALUES('old-run','old-owner',2,'Existing','FR',100,4,7000,2,3); INSERT INTO scores VALUES('old-score','old-owner',7,'Existing','FR',30000,4,200,5)");
 db.exec(readFileSync(new URL('migrations/0005_renaissance.sql',import.meta.url),'utf8'));
 assert.equal(db.prepare('SELECT level FROM runs').get().level,4);
 assert.equal(db.prepare('SELECT skin FROM scores').get().skin,5);
 assert.equal(db.prepare('SELECT elapsed_ms FROM scores').get().elapsed_ms,30000);
});

test('death penalties rerank all historical raw times without double counting',async()=>{
 const env={DB:database()};
 for(const [id,name,raw,deaths] of [['a','Rapide',10000,40],['b','Prudent',11000,0],['c','Rapide',10500,10]])
  await env.DB.prepare('INSERT INTO scores VALUES(?,?,?,?,?,?,?,?,?)').bind(id,'o',2,name,'FR',raw,deaths,1,1).run();
 const {scores}=await (await call(env,'/v1/leaderboard?world=2')).json();
 assert.equal(scores.length,3); assert.equal(scores[0].name,'Prudent');
 assert.equal(scores[1].name,'Rapide');assert.equal(scores[1].rawTime,10.5);assert.ok(Math.abs(scores[1].time-(10.5+10/3))<1e-9);assert.ok(Math.abs(scores[1].penalty-10/3)<1e-9);
 const again=await (await call(env,'/v1/leaderboard?world=2')).json();assert.deepEqual(again.scores,scores);
});

test('Workshop preserves encounter tuning and rejects unsafe multipliers',async()=>{
 const env={DB:database()};const layout=structuredClone(map);
 layout.entities[3].movementRate=2;layout.entities[3].attackRate=.5;
 layout.entities.push({kind:'magma_spawner',x:400,y:300,spawnDelay:.4,spawnInterval:1.2});
 let response=await call(env,'/v1/workshop',{body:{title:'Cadences',author:'Test',layout}});
 assert.equal(response.status,201);
 const {id}=await response.json();assert.deepEqual((await (await call(env,'/v1/workshop/'+id)).json()).layout,layout);
 for(const value of [0,6,'2']) {
  layout.entities[3].attackRate=value;
  response=await call(env,'/v1/workshop',{body:{title:'Cadences',author:'Test',layout}});assert.equal(response.status,400);
 }
});


test('Workshop preserves separate abyss terrain and head boss',async()=>{
 const env={DB:database()};const layout=structuredClone(map);
 layout.entities.push({kind:'boss',type:'skeleton_head',x:650,y:250});
 for(const type of ['skeleton_tail','skeleton_rib','skeleton_spine'])
  layout.entities.push({kind:'abyss_part',type,x:250,y:300,w:40,h:120,rotation:90});
 const response=await call(env,'/v1/workshop',{body:{title:'Os séparés',author:'Test',layout}});
 assert.equal(response.status,201);
 const {id}=await response.json();assert.deepEqual((await (await call(env,'/v1/workshop/'+id)).json()).layout,layout);
 layout.entities.at(-1).type='skeleton_head';
 assert.equal((await call(env,'/v1/workshop',{body:{title:'Invalide',author:'Test',layout}})).status,400);
});


test('hardcore bosses each publish a single encounter without hiding repeat records',async()=>{
 const env={DB:database()};
 for(const world of [9,10,11,12,13,14]) {
  for(let i=0;i<2;i++) {
   const start=await call(env,'/v1/runs',{body:{name:'gillou',world,skin:2}});assert.equal(start.status,201);
   const run=await start.json();const response=await call(env,'/v1/runs/'+run.id+'/checkpoint',{body:{level:1,elapsedMs:100,deaths:0}});
   assert.equal(response.status,200);assert.equal((await response.json()).completed,true);
  }
  const data=await (await call(env,'/v1/leaderboard?world='+world)).json();assert.equal(data.total,2);
 }
 assert.equal((await call(env,'/v1/leaderboard?world=14&page=1000001')).status,200);
});

test('delayed connection preserves the original clock and migration preserves all history',async()=>{
 const env={DB:database()};
 const start=await call(env,'/v1/runs',{body:{name:'Offline',world:14,startedAtMs:Date.now()-12000}});
 assert.equal(start.status,201);const run=await start.json();
 assert.equal((await call(env,'/v1/runs/'+run.id+'/checkpoint',{body:{level:1,elapsedMs:11000,deaths:7}})).status,200);
 assert.equal((await call(env,'/v1/runs',{body:{name:'Future',world:14,startedAtMs:Date.now()+100000}})).status,400);
 const db=new DatabaseSync(':memory:');
 for(const file of readdirSync(new URL('migrations/',import.meta.url)).filter(n=>/^\d{4}_[a-z0-9_]+\.sql$/.test(n)&&n<'0006').sort()) db.exec(readFileSync(new URL('migrations/'+file,import.meta.url),'utf8'));
 db.exec("INSERT INTO scores VALUES('old','owner',2,'Saved','FR',1000,2,123,1)");
 db.exec(readFileSync(new URL('migrations/0006_hardcore.sql',import.meta.url),'utf8'));
 assert.equal(db.prepare('SELECT COUNT(*) AS n FROM scores').get().n,1);
 db.exec("INSERT INTO scores VALUES('hardcore','owner',14,'gillou','ZZ',2264850,513,124,2)");
 assert.equal(db.prepare('SELECT elapsed_ms+deaths*1000/3 AS total FROM scores WHERE world=14').get().total,2435850);
});
