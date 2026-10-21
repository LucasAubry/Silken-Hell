local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 App.practice=1;App.start(6);require('run_start').active=false
 local D=require('mob_start_direction');local json=require('json')
 for _,kind in ipairs({'ange','snake','waspling','larva','magma_larva','lava_scorpion','mole','worm','dragonfly','abyss_fish','lanternfish','crab','piege','scie'}) do
  assert(not D.supported({kind='mob',type=kind}),kind..' must not offer an autonomous departure')
 end
 local count=0
 for _,kind in ipairs({'blackbird_chick','spinner','jelly','light_jelly','fish','cloud_beast','cloud_snail','mist_moth','wind_bat'}) do
  for _,dir in ipairs({'up','down','left','right'}) do
   local e={kind='mob',type=kind,x=480,y=300,speed=90,startDirection=dir}
   assert(D.supported(e))
   mobs={};Arena.walls={};Realms.holes={};Realms.schools={};LevelLayouts.schools={};require('sky_weather').reset()
   player.x=800;player.y=500;player.reset=false;Storm.active=false;Bosses.items={}
   LevelLayouts.spawn(e);local m=mobs[1];local x,y=m.x,m.y
   local saved=false;for _,entity in ipairs(LevelLayouts.snapshot().entities) do if entity.kind=='mob' and entity.type==kind then saved=entity.startDirection==dir end end;assert(saved,'Snapshot keeps departure: '..kind)
   assert(m.startDirection==dir and m.dir==dir,'Spawn facing: '..kind)
   MobBehaviors[kind].update(m,1/60)
   local v=D.vectors[dir];assert((m.x-x)*v[1]+(m.y-y)*v[2]>0,'First movement: '..kind..' '..dir)
   assert(math.abs((m.x-x)*v[2]-(m.y-y)*v[1])<.05,'No unwanted sideways start: '..kind)
   local plain={type=kind,x=100,y=200,vx=.42,vy=.31,phase=3}
   local before=json.encode(plain);D.apply(plain,{kind='mob',type=kind});assert(json.encode(plain)==before,'Existing defaults unchanged')
   count=count+1
  end
 end
 local l={world=6,level=1,width=960,height=600,entities={{kind='spawn',x=100,y=100},{kind='mob',type='cloud_beast',x=400,y=300,startDirection='left'}}}
 assert(require('layout_schema').validate(l));l.entities[2].startDirection='invalid';assert(not require('layout_schema').validate(l))
 print('PASS '..count..' authored departures, unchanged defaults, follower exclusions and validation');love.event.quit()
end
return T
