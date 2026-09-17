const worlds=[1,2,3,4,5,6,7];
const kinds=new Set(['magma_spawner','spawn','tear','wall','mob','boss','nest','light','lava','vent','hole','tunnel','tornado','current','rain']);
const mobs=new Set(['magma_larva','ange','snake','piege','scie','spinner','imp','crab','abyss_fish','light_jelly','lanternfish','waspling','larva','blackbird_chick','fish','mole','worm','gull','jelly']);
const bosses=new Set(['storm','merle','hellserpent','wasp','hedgehog','octopus','skeleton_fish']);
export function validateLayout(l) {
 if(!l || !worlds.includes(l.world) || !Number.isInteger(l.level) || l.level<1 || l.level>(l.world===3?6:10) || !Number.isFinite(l.width) || l.width<400 || l.width>4000 || l.height!==600 || !Array.isArray(l.entities) || l.entities.length>1000) return false;
 let spawn=0;
 for(const e of l.entities) {
  if(!e || !kinds.has(e.kind) || (e.kind==='mob'&&!mobs.has(e.type)) || (e.kind==='boss'&&!bosses.has(e.type))) return false;
  for(const k of ['x','y','speed','w','h','rx','ry','radius','phase','dx','rota','seed','schoolId']) if(e[k]!==undefined && (!Number.isFinite(e[k]) || Math.abs(e[k])>10000)) return false;
  if(!Number.isFinite(e.x)||!Number.isFinite(e.y)||e.x<0||e.x>l.width||e.y<0||e.y>600) return false;
  for(const k of ['w','h','rx','ry','radius']) if(e[k]!==undefined&&e[k]<1) return false;
  if(e.kind==='wall'&&(!e.w||!e.h)) return false;
  for(const k of ['electric','has_larme','elite']) if(e[k]!==undefined&&typeof e[k]!=='boolean') return false;
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
  const owner=await optionalOwner();
  const {results}=await env.DB.prepare(`SELECT m.id,m.title,m.author,m.world,m.updated_at,
   (SELECT COUNT(*) FROM workshop_stars s WHERE s.map_id=m.id) AS stars,
   EXISTS(SELECT 1 FROM workshop_stars s WHERE s.map_id=m.id AND s.owner=?) AS starred
   FROM workshop_maps m ORDER BY stars DESC,m.updated_at DESC,m.id LIMIT 8 OFFSET ?`).bind(owner,(page-1)*8).all();
  const count=await env.DB.prepare('SELECT COUNT(*) AS total FROM workshop_maps').bind().first();
  return reply({maps:results.map(r=>({...r,starred:!!r.starred})),page,total:count.total,hasMore:page*8<count.total});
 }
 if(request.method==='POST'&&path==='/v1/workshop') {
  const owner=await ownerOf(request), b=await bodyOf(request,131072);
  const title=clean(b.title,60),author=clean(b.author,24);
  if(!title||!author||!validateLayout(b.layout)) fail(400,'Titre, auteur ou carte invalide.');
  const id=b.id||crypto.randomUUID();
  if(!/^[a-f0-9-]{36}$/.test(id)) fail(400,'Identifiant invalide.');
  const previous=await env.DB.prepare('SELECT owner FROM workshop_maps WHERE id=?').bind(id).first();
  if(previous&&previous.owner!==owner) fail(403,'Cette carte appartient à un autre créateur.');
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
