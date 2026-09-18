const DEATH_PENALTY_MS=1000/3;
import {workshop} from './workshop.mjs';
const reply=(data,status=200)=>Response.json(data,{status,headers:{'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'}});
const fail=(status,error)=>{throw Object.assign(new Error(error),{status});};
export function countryOf(request) {
  const country=request.cf?.country;
  return typeof country==='string' && /^[A-Z]{2}$/.test(country) && !['XX','T1'].includes(country) ? country : 'ZZ';
}
async function ownerOf(request) {
  const token=request.headers.get('Authorization')?.match(/^Bearer ([a-f0-9]{64})$/)?.[1];
  if(!token) fail(401,'Identité de jeu manquante.');
  const digest=await crypto.subtle.digest('SHA-256',new TextEncoder().encode(token));
  return Array.from(new Uint8Array(digest),b=>b.toString(16).padStart(2,'0')).join('');
}
async function bodyOf(request,limit=2048) {
  if(Number(request.headers.get('Content-Length'))>limit) fail(413,'Requête trop grande.');
  const reader=request.body?.getReader();
  if(!reader) fail(400,'Requête vide.');
  let length=0; const chunks=[];
  while(true) {
    const {done,value}=await reader.read(); if(done) break;
    length+=value.length; if(length>limit) {await reader.cancel(); fail(413,'Requête trop grande.');}
    chunks.push(value);
  }
  const bytes=new Uint8Array(length); let offset=0;
  for(const chunk of chunks) {bytes.set(chunk,offset); offset+=chunk.length;}
  try {const b=JSON.parse(new TextDecoder().decode(bytes)); if(!b || Array.isArray(b) || typeof b!=='object') throw 0; return b;}
  catch {fail(400,'JSON invalide.');}
}
export default {
  async fetch(request,env) {
    try {
      const url=new URL(request.url); const path=url.pathname;
      if(request.method==='GET' && path==='/health') return reply({ok:true,service:'silken-hell-api'});
      if(env.API_LIMITER) {
        const {success}=await env.API_LIMITER.limit({key:request.headers.get('CF-Connecting-IP') || 'unknown'});
        if(!success) return reply({error:'Trop de requêtes. Réessaie dans une minute.'},429);
      }
      const community=await workshop(request,env,{reply,fail,ownerOf,bodyOf}); if(community) return community;
      if(request.method==='GET' && path==='/v1/location') return reply({country:countryOf(request)});
      if(request.method==='GET' && path==='/v1/leaderboard') {
        const world=Number(url.searchParams.get('world'));
        if(![1,2,3,4,5,6,7,9,10,11,12,13,14].includes(world)) fail(400,'Monde invalide.');
        const country=countryOf(request), local=url.searchParams.get('scope')==='country';
        const page=Number(url.searchParams.get('page') || 1);
        if(!Number.isSafeInteger(page) || page<1) fail(400,'Page invalide.');
        if(local && country==='ZZ') return reply({world,country,scores:[],page,total:0,hasMore:false});
        // Every completed run is retained, including repeat runs by the same player.
        const ranked=`SELECT * FROM scores WHERE world=? ${local?'AND country=?':''}`;
        const args=local?[world,country]:[world];
        const [{results},count]=await Promise.all([
          env.DB.prepare(`SELECT name,country,elapsed_ms,deaths,skin FROM (${ranked}) ORDER BY (elapsed_ms+deaths*${DEATH_PENALTY_MS}),deaths,completed_at,run_id LIMIT 10 OFFSET ?`).bind(...args,(page-1)*10).all(),
          env.DB.prepare(`SELECT COUNT(*) AS total FROM (${ranked})`).bind(...args).first()
        ]);
        return reply({world,country,page,total:count.total,hasMore:page*10<count.total,scores:results.map(s=>({name:s.name,country:s.country,time:(s.elapsed_ms+s.deaths*DEATH_PENALTY_MS)/1000,rawTime:s.elapsed_ms/1000,penalty:s.deaths*DEATH_PENALTY_MS/1000,deaths:s.deaths,skin:s.skin}))});
      }
      if(request.method==='POST' && path==='/v1/runs') {
        const owner=await ownerOf(request), b=await bodyOf(request);
        const name=typeof b.name==='string'?b.name.normalize('NFC').trim():'';
        if(!name || [...name].length>16 || /[\p{C}]/u.test(name)) fail(400,'Pseudo invalide (1 à 16 caractères).');
        if(![1,2,3,4,5,6,7,9,10,11,12,13,14].includes(b.world)) fail(400,'Monde indisponible.');
        const skin=b.skin===undefined?1:b.skin;
        if(!Number.isInteger(skin)||skin<1||skin>5) fail(400,'Apparence invalide.');
        const now=Date.now();
        const startedAt=b.startedAtMs===undefined?now:b.startedAtMs;
        if(!Number.isSafeInteger(startedAt)||startedAt>now+2500||startedAt<now-86400000) fail(400,'Date de départ invalide.');
        const recent=await env.DB.prepare('SELECT COUNT(*) AS count FROM runs WHERE owner=? AND started_at>?').bind(owner,now-60000).first();
        if(recent.count>=12) fail(429,'Trop de nouvelles parties.');
        const id=crypto.randomUUID();
        await env.DB.prepare('INSERT INTO runs(id,owner,world,name,country,started_at,skin) VALUES(?,?,?,?,?,?,?)').bind(id,owner,b.world,name,countryOf(request),startedAt,skin).run();
        return reply({id,country:countryOf(request)},201);
      }
      const match=path.match(/^\/v1\/runs\/([a-f0-9-]{36})\/checkpoint$/);
      if(request.method==='POST' && match) {
        const owner=await ownerOf(request), b=await bodyOf(request);
        const run=await env.DB.prepare('SELECT * FROM runs WHERE id=? AND owner=?').bind(match[1],owner).first();
        if(!run) fail(404,'Partie introuvable.');
        const {level,elapsedMs,deaths}=b;
        const lastLevel=run.world>=9?1:run.world===3?6:10;
        if(!Number.isInteger(level)||level<1||level>lastLevel||!Number.isInteger(elapsedMs)||!Number.isInteger(deaths)||deaths<0||deaths>100000) fail(400,'Score invalide.');
        if(level===run.level && elapsedMs===run.elapsed_ms && deaths===run.deaths) return reply({ok:true,completed:level===lastLevel});
        if(run.level===lastLevel) fail(409,'Partie déjà terminée.');
        if(level!==run.level+1) fail(409,'Niveaux à terminer dans l’ordre.');
        const now=Date.now();
        if(now-run.started_at>86400000) fail(410,'Partie expirée.');
        if(elapsedMs<run.elapsed_ms+100||elapsedMs>now-run.started_at+2500||elapsedMs>86400000||deaths<run.deaths) fail(400,'Chronomètre ou compteur incohérent.');
        const writes=[env.DB.prepare('UPDATE runs SET level=?,elapsed_ms=?,deaths=? WHERE id=? AND owner=? AND level=?').bind(level,elapsedMs,deaths,run.id,owner,run.level)];
        if(level===lastLevel) writes.push(env.DB.prepare(`INSERT OR IGNORE INTO scores(run_id,owner,world,name,country,elapsed_ms,deaths,completed_at,skin)
          SELECT id,owner,world,name,country,elapsed_ms,deaths,?,skin FROM runs WHERE id=? AND owner=? AND level=?`).bind(now,run.id,owner,lastLevel));
        await env.DB.batch(writes);
        return reply({ok:true,completed:level===lastLevel});
      }
      return reply({error:'Route introuvable.'},404);
    } catch(e) {
      return reply({error:e.status?e.message:'Service temporairement indisponible.'},e.status||500);
    }
  },
  async scheduled(_event,env) {
    // Scores persist; abandoned run metadata is removed after two days.
    await env.DB.prepare('DELETE FROM runs WHERE started_at<?').bind(Date.now()-172800000).run();
  }
};
