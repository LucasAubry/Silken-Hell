"""Archive trusted historical simulation sources, deduplicated by content.
No player recordings or profile data are included. Re-run before deleting history.
"""
import base64,hashlib,json,re,subprocess,zlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/replay_engines'
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT)
def fingerprint(files):
 prefix='src/' if 'src/replay.lua' in files else ''
 source=files.get(prefix+'replay.lua',b'').decode()
 if not source:return None
 build=source[source.find('function R.build()'):source.find('function R.enter()')]
 if "sourceTree('src')" in build:
  paths=sorted((k for k in files if k.startswith('src/') and k.endswith('.lua')),key=lambda p:p.split('/'))
  return hashlib.sha256(b''.join(p.encode()+files[p] for p in paths)).hexdigest()
 groups=re.findall(r'ipairs\(\{([^}]+)\}\)',build)
 if len(groups)<2:return None
 names=lambda s:re.findall(r"'([^']+)'",s)
 paths=[prefix+n+'.lua' for n in names(groups[0])]
 paths+=sorted((k for k in files if k.startswith(prefix+'mobs/') and k.endswith('.lua')),key=lambda p:p.split('/'))
 paths+=[prefix+'levels/level_'+str(i)+'.lua' for i in range(1,11)]
 paths+=[prefix+n+'.lua' for n in names(groups[-1])]
 try:return hashlib.sha256(b''.join(files[p] for p in paths)).hexdigest()
 except KeyError:return None

def main():
 OUT.mkdir(exist_ok=True)
 bank={};images={};engines=[];seen=set();cache={}
 aliases=dict(re.findall(r'\["([^"]+)"\]="([^"]+)"',(ROOT/'src/asset_paths.lua').read_text()))
 proc=subprocess.Popen(['git','cat-file','--batch'],cwd=ROOT,stdin=subprocess.PIPE,stdout=subprocess.PIPE)
 def blob(oid):
  if oid not in cache:
   proc.stdin.write((oid+'\n').encode());proc.stdin.flush()
   meta=proc.stdout.readline().split();cache[oid]=proc.stdout.read(int(meta[2]));proc.stdout.read(1)
  return cache[oid]
 for rev in git('rev-list','HEAD').decode().splitlines():
  files={};image_refs={}
  for entry in git('ls-tree','-rz',rev).split(b'\0'):
   if not entry:continue
   meta,path=entry.split(b'\t');path=path.decode();oid=meta.split()[2].decode()
   if path.endswith('.lua') and (path.startswith(('src/','mobs/','levels/')) or '/' not in path) or path.endswith('.glsl') or path.startswith('assets/') and path.endswith('.json') or path=='art-metadata.json':
    files[path]=blob(oid)
   elif path.endswith('.png') and path.startswith(('assets/','texture/')) and not (ROOT/aliases.get(path,path)).is_file():
    data=blob(oid);image_refs[path]=oid;images[oid]=base64.b64encode(data).decode()
  key=fingerprint(files)
  if not key or key in seen:continue
  seen.add(key);mapping={}
  for path,data in files.items():
   oid=hashlib.sha256(data).hexdigest();bank[oid]=data.decode();mapping[path]=oid
  stamp=int(git('show','-s','--format=%ct',rev))
  engines.append({'build':key,'revision':rev[:12],'time':stamp,'files':mapping,'images':image_refs,'entry':'game' if 'src/game.lua' in files else 'main'})
 # Early recordings predate the first replay commit. That commit replaced the
 # bosses while keeping the level simulation. Retain the earlier boss families
 # as candidate engines; the player must pass every recorded checkpoint before
 # any such reconstruction is displayed.
 base=next(e for e in engines if e['revision'].startswith('c7f9ba9'))
 boss_paths={'raven':'mobs/bosses/raven/init.lua','wasp':'mobs/bosses/wasp/init.lua','storm':'mobs/bosses/storm/init.lua','hedgehog':'mobs/bosses/hedgehog/init.lua','octopus':'mobs/bosses/octopus/init.lua','abyss':'mobs/bosses/abyss/init.lua','boss_instances':'mobs/bosses/instances.lua'}
 for rev in ('95cab70','e55ea7e','e181c3b'):
  for family in ('raven','all'):
   mapping=dict(base['files'])
   names=['raven','boss_instances'] if family=='raven' else list(boss_paths)
   for name in names:
    data=git('show',rev+':'+name+'.lua').decode()
    if name=='boss_instances':
     for old,new in boss_paths.items():data=data.replace("='"+old+"'", "='"+new[:-4]+"'")
    oid=hashlib.sha256(data.encode()).hexdigest();bank[oid]=data;mapping[boss_paths[name]]=oid
   key=hashlib.sha256(json.dumps(mapping,sort_keys=True).encode()).hexdigest()
   engines.append({**base,'build':key,'revision':base['revision']+'+'+rev+'-'+family,'time':base['time'],'files':mapping,'reconstructed':True})
 proc.stdin.close();proc.wait()
 used={key for e in engines for key in e['images'].values()}
 images={key:value for key,value in images.items() if key in used}
 image_dir=OUT/'images';image_dir.mkdir(exist_ok=True)
 for key,value in images.items():
  path=image_dir/(key+'.png')
  if not path.exists():path.write_bytes(base64.b64decode(value))
 for path in image_dir.glob('*.png'):
  if path.stem not in images:path.unlink()
 payload=json.dumps({'engines':engines,'blobs':bank},separators=(',',':'),ensure_ascii=False).encode()
 (OUT/'history.dat').write_bytes(zlib.compress(payload,9))
 print(f'{len(engines)} engines, {len(bank)} unique source files, {len(payload)//1024} KiB before compression')
if __name__=='__main__':main()
