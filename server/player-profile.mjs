const worlds=[1,6,5,4,7,2,3];
const achievementIds=new Set(['heartbreak','worlds_all','story_all','gillou','maxance','flawless_all','hardcore_all','hardcore','top1','workshop_publish','workshop_test',...worlds.map(w=>'world'+w)]);
export function validateProfile(b,fail) {
 const name=typeof b.name==='string'?b.name.normalize('NFC').trim():'';
 if(!name||[...name].length>16||/[\p{C}]/u.test(name)) fail(400,'Pseudo invalide.');
 if(!Number.isInteger(b.skin)||b.skin<1||b.skin>27) fail(400,'Apparence invalide.');
 const count=n=>{if(!Number.isSafeInteger(n)||n<0||n>1e9) fail(400,'Statistiques invalides.');return n;};
 if(!b.stats||!Array.isArray(b.worlds)||b.worlds.length!==7||!Array.isArray(b.achievements)||b.achievements.length>achievementIds.size) fail(400,'Profil invalide.');
 const stats=Object.fromEntries(['tears','eggs','deaths','attempts'].map(k=>[k,count(b.stats[k]??0)]));
 const seen=new Set();
 const rows=b.worlds.map(r=>{
  if(!r||!worlds.includes(r.world)||seen.has(r.world)) fail(400,'Monde invalide.');seen.add(r.world);
  for(const k of ['completed','hardcore','flawless']) if(typeof r[k]!=='boolean') fail(400,'Progression invalide.');
  return {world:r.world,completed:r.completed,hardcore:r.hardcore,flawless:r.flawless,...Object.fromEntries(['tears','deaths','attempts','bosses'].map(k=>[k,count(r[k]??0)]))};
 });
 if(b.achievements.some(id=>!achievementIds.has(id))) fail(400,'Succès invalide.');
 stats.bosses=rows.reduce((n,r)=>n+r.bosses,0);
 return {name,skin:b.skin,stats,worlds:rows,achievements:[...new Set(b.achievements)]};
}
export async function playerProfiles(request,env,{reply,fail,ownerOf,bodyOf}) {
 const path=new URL(request.url).pathname;
 if(request.method==='POST'&&path==='/v1/profile') {
  const owner=await ownerOf(request),data=validateProfile(await bodyOf(request,8192),fail);
  await env.DB.prepare('INSERT INTO player_profiles(owner,payload,updated_at) VALUES(?,?,?) ON CONFLICT(owner) DO UPDATE SET payload=excluded.payload,updated_at=excluded.updated_at').bind(owner,JSON.stringify(data),Date.now()).run();
  return reply({ok:true});
 }
 const match=path.match(/^\/v1\/players\/by-run\/([a-f0-9-]{36})$/);
 if(request.method!=='GET'||!match) return;
 // Resolve the owner internally: never expose the authentication identity or match by nickname.
 const score=await env.DB.prepare('SELECT owner,name,skin FROM scores WHERE run_id=?').bind(match[1]).first();
 if(!score) fail(404,'Joueur introuvable.');
 const saved=await env.DB.prepare('SELECT payload,updated_at FROM player_profiles WHERE owner=?').bind(score.owner).first();
 if(saved) return reply({...JSON.parse(saved.payload),source:'profile',updatedAt:saved.updated_at});
 // Older clients have no snapshot. Show only facts recorded by completed ranked runs.
 const {results}=await env.DB.prepare('SELECT world,hardcore,deaths,elapsed_ms FROM scores WHERE owner=?').bind(score.owner).all();
 const records=await env.DB.prepare('SELECT COUNT(*) AS n FROM top_one_history WHERE owner=?').bind(score.owner).first();
 const rows=worlds.map(world=>{const runs=results.filter(s=>s.world===world);return {world,completed:runs.some(s=>!s.hardcore),hardcore:runs.some(s=>s.hardcore===1),flawless:runs.some(s=>s.deaths===0)};});
 const achievements=rows.filter(r=>r.completed).map(r=>'world'+r.world);
 if(rows.every(r=>r.completed)) achievements.push('worlds_all');
 if(rows.every(r=>r.hardcore)) achievements.push('hardcore_all');
 if(rows.every(r=>r.flawless)) achievements.push('flawless_all');
 if(rows.some(r=>r.hardcore)) achievements.push('hardcore');
 if(results.some(r=>r.world===1&&r.deaths>=95)) achievements.push('maxance');
 if(records.n>0) achievements.push('top1');
 return reply({name:score.name,skin:score.skin,source:'scores',worlds:rows,achievements,stats:{runs:results.length,deaths:results.reduce((n,s)=>n+s.deaths,0),time:results.reduce((n,s)=>n+s.elapsed_ms/1000,0)}});
}
