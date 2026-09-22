import {validateReplay,fingerprint,canonical} from './replay.mjs';
const worlds=[1,2,3,4,5,6,7];
const kinds=new Set(['abyss_part','magma_spawner','spawn','tear','wall','mob','boss','nest','light','lava','vent','hole','tunnel','tornado','current','rain']);
const mobs=new Set(['magma_larva','ange','snake','piege','scie','spinner','imp','crab','abyss_fish','light_jelly','lanternfish','waspling','larva','blackbird_chick','fish','mole','worm','gull','jelly']);
const bosses=new Set(['skeleton_head','storm','merle','hellserpent','wasp','hedgehog','octopus','skeleton_fish']);
export function validateLayout(l) {
 if(!l || !worlds.includes(l.world) || !Number.isInteger(l.level) || l.level<1 || l.level>(l.world===3?6:10) || !Number.isFinite(l.width) || l.width<400 || l.width>4000 || l.height!==600 || !Array.isArray(l.entities) || l.entities.length>1000) return false;
 if(l.biome!==undefined&&![1,2,3,4,5,6,7].includes(l.biome)) return false;
 if(l.difficulty!==undefined&&(!Number.isInteger(l.difficulty)||l.difficulty<1||l.difficulty>5)) return false;
 if(l.difficultyExtra!==undefined&&(!Number.isInteger(l.difficultyExtra)||l.difficultyExtra<0||l.difficultyExtra>999||(l.difficultyExtra>0&&l.difficulty!==5))) return false;
 let spawn=0;
 for(const e of l.entities) {
  if(!e || !kinds.has(e.kind) || (e.kind==='mob'&&!mobs.has(e.type)) || (e.kind==='boss'&&!bosses.has(e.type)) || (e.kind==='abyss_part'&&!['skeleton_tail','skeleton_rib','skeleton_spine'].includes(e.type))) return false;
  for(const k of ['x','y','speed','w','h','rx','ry','radius','phase','dx','rota','seed','schoolId','spawnDelay','spawnInterval','movementRate','attackRate','skeletonStage','rotation']) if(e[k]!==undefined && (!Number.isFinite(e[k]) || Math.abs(e[k])>10000)) return false;
  for(const k of ['movementRate','attackRate']) if(e[k]!==undefined && (e[k]<.1||e[k]>5)) return false;
  for(const k of ['spawnDelay','spawnInterval']) if(e[k]!==undefined && (e[k]<.1||e[k]>120)) return false;
  if(e.skeletonStage!==undefined && (!Number.isInteger(e.skeletonStage)||e.skeletonStage<8||e.skeletonStage>10)) return false;
  if(!Number.isFinite(e.x)||!Number.isFinite(e.y)||e.x<0||e.x>l.width||e.y<0||e.y>600) return false;
  for(const k of ['w','h','rx','ry','radius']) if(e[k]!==undefined&&e[k]<1) return false;
  if(e.kind==='wall'&&(!e.w||!e.h)) return false;
  if(e.customName!==undefined&&(typeof e.customName!=='string'||e.customName.length>60)) return false;
  for(const k of ['electric','has_larme','elite','startUnderground']) if(e[k]!==undefined&&typeof e[k]!=='boolean') return false;
  if(e.kind==='spawn') spawn++;
 }
 return spawn===1;
}
const clean=(v,max)=>typeof v==='string'?v.normalize('NFC').trim().replace(/[\p{C}]/gu,'').slice(0,max):'';
export async function workshop(request,env,{reply,fail,ownerOf,bodyOf}) {
 const url=new URL(request.url), path=url.pathname;
 if(!path.startsWith('/v1/workshop')) return null;
 const optionalOwner=async()=>request.headers.has('Authorization')?ownerOf(request):'';
 if(request.method==='GET'&&path==='/v1/workshop') {
  const page=Number(url.searchParams.get('page')||1);
  if(!Number.isSafeInteger(page)||page<1||page>100000) fail(400,'Page invalide.');
  const world=Number(url.searchParams.get('biome')||0),difficulty=Number(url.searchParams.get('difficulty')||0);
  const sort=url.searchParams.get('sort')||'stars';
  if(![0,...worlds].includes(world)||!Number.isInteger(difficulty)||difficulty<0||difficulty>5||!['stars','easy','hard'].includes(sort)) fail(400,'Filtre invalide.');
  const owner=await optionalOwner();
  const biome="COALESCE(json_extract(m.layout,'$.biome'),m.world)",rating="COALESCE(json_extract(m.layout,'$.difficulty'),1)",extra="COALESCE(json_extract(m.layout,'$.difficultyExtra'),0)";
  const clauses=[],args=[];
  if(world){clauses.push(`${biome}=?`);args.push(world);}
  if(difficulty){clauses.push(`${rating}=?`);args.push(difficulty);}
  const where=clauses.length?' WHERE '+clauses.join(' AND '):'';
  const order=sort==='easy'?`${rating} ASC,${extra} ASC,`:sort==='hard'?`${rating} DESC,${extra} DESC,`:'';
  const {results}=await env.DB.prepare(`SELECT m.id,m.title,m.author,m.world,m.updated_at,${biome} AS biome,${rating} AS difficulty,${extra} AS difficultyExtra,
   (SELECT COUNT(*) FROM workshop_stars s WHERE s.map_id=m.id) AS stars,
   EXISTS(SELECT 1 FROM workshop_stars s WHERE s.map_id=m.id AND s.owner=?) AS starred
   FROM workshop_maps m${where} ORDER BY ${order}stars DESC,m.updated_at DESC,m.id LIMIT 8 OFFSET ?`).bind(owner,...args,(page-1)*8).all();
  const count=await env.DB.prepare('SELECT COUNT(*) AS total FROM workshop_maps m'+where).bind(...args).first();
  return reply({maps:results.map(r=>({...r,starred:!!r.starred})),page,total:count.total,hasMore:page*8<count.total});
 }
 if(request.method==='POST'&&path==='/v1/workshop/validate') {
  const owner=await ownerOf(request),b=await bodyOf(request,1500000),r=b.replay;
  if(!validateLayout(b.layout)||!validateReplay(r)||!r.single||r.duel||r.checks.at(-1)[1]!==b.layout.level||r.world!==b.layout.world||r.startLevel!==b.layout.level||canonical(r.layouts[r.world+':'+r.startLevel])!==canonical(b.layout)) fail(400,'Termine cette version de la carte avant de la publier.');
  const quota=await env.DB.prepare('SELECT COUNT(*) AS total FROM workshop_validations WHERE owner=? AND created_at>?').bind(owner,Date.now()-3600000).first();
  if(quota.total>=30) fail(429,'Trop de validations. Réessaie plus tard.');
  const id=crypto.randomUUID();await env.DB.prepare('INSERT INTO workshop_validations VALUES(?,?,?,?)').bind(id,owner,await fingerprint(b.layout),Date.now()).run();return reply({id},201);
 }
 if(request.method==='POST'&&path==='/v1/workshop') {
  const owner=await ownerOf(request), b=await bodyOf(request,131072);
  const title=clean(b.title,60),author=clean(b.author,24);
  if(!title||!author||!validateLayout(b.layout)) fail(400,'Titre, auteur ou carte invalide.');
  const id=b.id||crypto.randomUUID();
  if(!/^[a-f0-9-]{36}$/.test(id)) fail(400,'Identifiant invalide.');
  const previous=await env.DB.prepare('SELECT owner FROM workshop_maps WHERE id=?').bind(id).first();
  if(previous&&previous.owner!==owner) fail(403,'Cette carte appartient à un autre créateur.');
  const proof=typeof b.proof==='string'&&await env.DB.prepare('SELECT layout_hash FROM workshop_validations WHERE id=? AND owner=? AND created_at>?').bind(b.proof,owner,Date.now()-86400000).first();
  if(!proof||proof.layout_hash!==await fingerprint(b.layout)) fail(403,'Termine cette version de la carte avant de la publier.');
  const now=Date.now();
  if(!previous) {
   const quota=await env.DB.prepare('SELECT COUNT(*) AS total,SUM(created_at>?) AS recent FROM workshop_maps WHERE owner=?').bind(now-3600000,owner).first();
   if(quota.total>=100||quota.recent>=20) fail(429,'Limite de publication atteinte. Réessaie plus tard.');
  }
  await env.DB.prepare(`INSERT INTO workshop_maps(id,owner,title,author,world,layout,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?)
    ON CONFLICT(id) DO UPDATE SET title=excluded.title,author=excluded.author,world=excluded.world,layout=excluded.layout,updated_at=excluded.updated_at WHERE workshop_maps.owner=excluded.owner`)
    .bind(id,owner,title,author,b.layout.world,JSON.stringify(b.layout),now,now).run();
  return reply({id,ok:true},previous?200:201);
 }
 const match=path.match(/^\/v1\/workshop\/([a-f0-9-]{36})(\/star)?$/);
 if(match) {
  if(request.method==='GET'&&!match[2]) {
   const row=await env.DB.prepare('SELECT id,title,author,world,layout FROM workshop_maps WHERE id=?').bind(match[1]).first();
   if(!row) fail(404,'Carte introuvable.');
   return reply({...row,layout:JSON.parse(row.layout)});
  }
  if(request.method==='POST'&&match[2]) {
   const owner=await ownerOf(request),b=await bodyOf(request);
   if(typeof b.starred!=='boolean') fail(400,'Vote invalide.');
   if(!await env.DB.prepare('SELECT id FROM workshop_maps WHERE id=?').bind(match[1]).first()) fail(404,'Carte introuvable.');
   if(b.starred) await env.DB.prepare('INSERT OR IGNORE INTO workshop_stars(map_id,owner,created_at) VALUES(?,?,?)').bind(match[1],owner,Date.now()).run();
   else await env.DB.prepare('DELETE FROM workshop_stars WHERE map_id=? AND owner=?').bind(match[1],owner).run();
   const row=await env.DB.prepare('SELECT COUNT(*) AS stars FROM workshop_stars WHERE map_id=?').bind(match[1]).first();
   return reply({stars:row.stars,starred:b.starred});
  }
 }
 return reply({error:'Route Workshop introuvable.'},404);
}
