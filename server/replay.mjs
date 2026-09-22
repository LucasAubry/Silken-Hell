import {validateLayout} from './workshop.mjs';
export function canonical(v) {
 if(v===null||typeof v!=='object') return JSON.stringify(v);
 if(Array.isArray(v)) return '['+v.map(canonical).join(',')+']';
 return '{'+Object.keys(v).sort().map(k=>JSON.stringify(k)+':'+canonical(v[k])).join(',')+'}';
}
export async function fingerprint(v) {return [...new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(canonical(v))))].map(b=>b.toString(16).padStart(2,'0')).join('');}
export function validateReplay(r) {
 if(!r||r.version!==1||!r.completed||typeof r.build!=='string'||!/^[a-f0-9]{64}$/.test(r.build)||![1,2,3,4,5,6,7,9,10,11,12,13,14].includes(r.world)||!Number.isInteger(r.seed)||r.seed<1||r.seed>2147483646||!Number.isInteger(r.skin)||r.skin<1||r.skin>14||!Number.isFinite(r.width)||r.width<400||r.width>4000||r.height!==600||!Number.isInteger(r.startLevel)||r.startLevel<1||r.startLevel>10||typeof r.single!=='boolean') return false;
 if(!Number.isFinite(r.time)||r.time<0||r.time>86400||!Number.isInteger(r.deaths)||r.deaths<0||r.deaths>100000||!Number.isInteger(r.frames)||r.frames<1||r.frames>5184000||r.time>r.frames/60+.1) return false;
 if(!Array.isArray(r.inputs)||r.inputs.length>100000||!Array.isArray(r.checks)||!r.checks.length||r.checks.length>25000||!r.layouts||typeof r.layouts!=='object'||Object.keys(r.layouts).length>100) return false;
 let frames=0;
 for(const e of r.inputs) {if(!Array.isArray(e)||e.length!==4||!Number.isInteger(e[0])||e[0]<1||!Number.isFinite(e[1])||!Number.isFinite(e[2])||Math.abs(e[1])>1||Math.abs(e[2])>1||![0,1].includes(e[3])) return false;frames+=e[0];}
 if(frames!==r.frames) return false;
 let last=0;
 for(const c of r.checks) {if(!Array.isArray(c)||c.length!==6||!c.slice(0,5).every(Number.isSafeInteger)||c[0]<=last||c[0]>frames||c[1]<1||c[1]>10||c[4]<0||typeof c[5]!=='boolean') return false;last=c[0];}
 const end=r.checks.at(-1);if(end[0]!==frames||end[4]!==r.deaths||end[5]!==true) return false;
 for(const [key,layout] of Object.entries(r.layouts)) if(!validateLayout(layout)||key!==layout.world+':'+layout.level) return false;
 return true;
}
export async function replays(request,env,{reply,fail,ownerOf,bodyOf}) {
 const path=new URL(request.url).pathname;
 const read=path.match(/^\/v1\/replays\/([a-f0-9-]{36})$/);
 if(read&&request.method==='GET') {const row=await env.DB.prepare('SELECT payload FROM run_replays WHERE run_id=?').bind(read[1]).first();if(!row) fail(404,'Replay introuvable.');return reply({replay:JSON.parse(row.payload)});}
 const upload=path.match(/^\/v1\/runs\/([a-f0-9-]{36})\/replay$/);
 if(upload&&request.method==='POST') {
  const owner=await ownerOf(request),b=await bodyOf(request,1500000),r=b.replay;
  const score=await env.DB.prepare('SELECT * FROM scores WHERE run_id=? AND owner=?').bind(upload[1],owner).first();
  if(!score) fail(404,'Partie terminée introuvable.');
  if(!validateReplay(r)||r.single||r.startLevel!==1||r.checks.at(-1)[1]!==(r.world>=9?1:r.world===3?6:10)||r.world!==score.world||r.skin!==score.skin||r.deaths!==score.deaths||Math.abs(r.time*1000-score.elapsed_ms)>2) fail(400,'Replay incohérent avec le score.');
  await env.DB.prepare('INSERT INTO run_replays(run_id,owner,payload,created_at) VALUES(?,?,?,?) ON CONFLICT(run_id) DO NOTHING').bind(upload[1],owner,JSON.stringify(r),Date.now()).run();return reply({ok:true},201);
 }
 return null;
}
