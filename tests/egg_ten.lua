local T={}
local function hit(b)
 player.dashing=true;player.x=35;player.y=540;b.contact()
 player.x=b.x-15;player.y=b.y-12;b.contact();player.dashing=false
end
local function reset()
 Replay.recording=false;Replay.playing=false;Replay.data=nil;App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true;Campaign.select(1);player.level=10;reset_level();App.state='playing';player.reset=false
end
local function clearBoss(b)
 assert(b.hp==10 and b.maxHp==10)
 for i=1,9 do hit(b);assert(b.hp==10-i and not b.broken) end
 b.projectiles={{x=50,y=50,vx=1,vy=1,life=3}}
 hit(b);assert(b.hp==0 and b.broken and b.defeated and b.liberating and #b.freedChicks==6)
 local L=require('boss_liberation')
 assert(#b.projectiles==0 and objet.larme.taken and not Campaign.canCollect())
 assert(#L.events==1 and #L.events[1].threads>=7,'Egg and every surviving bird receive a silk thread')
 local m=b.freedChicks[1];local x,y=m.x,m.y
 player.x=x-15;player.y=y-12;player.dashing=false;b.contact();b.update(.1)
 assert(#b.freedChicks==6 and m.x==x and m.y==y and not player.reset,'Survivors wait safely during liberation')
 b.breakEgg();assert(#L.events==1,'Breaking the egg again cannot restart liberation')
 Aftermath.update(.01);assert(not Aftermath.cleared,'Reward waits for the threads to break')
 L.update(1.8);assert(objet.larme.taken and not Campaign.canCollect())
 L.update(.2)
 assert(b.defeated and not b.liberating and #b.chicks==0 and #b.freedChicks==0)
 assert(Campaign.canCollect() and not objet.larme.taken,'Tear follows the silk animation with no bird contacts')

end
function T.run()
 Online.enabled=false;Replay.disabled=true;reset()
 local kill=Hazards.kill;Hazards.kill=function() end
 local b=Raven
 local artDraw=Art.draw;local nests=0
 Art.draw=function(key,x,y,w,angle,h)
  assert(key=='nest' and w==80 and h==60,'All nests have identical art and dimensions')
  nests=nests+1
 end
 b.drawGround();Art.draw=artDraw;assert(nests==#b.nests)
 for i=1,3 do hit(b) end
 b.shotClock=100;b.projectiles={};player.x=35;player.y=540
 local chasing=b.chicks[#b.chicks]
 local function distance(m) return math.sqrt((m.x-player.x-15)^2+(m.y-player.y-12)^2) end
 local before=distance(chasing);b.update(.1)
 assert(distance(chasing)<before and chasing.phase=='chase','Non-shooters pursue the player')
 player.x=Arena.width-60;player.y=100;before=distance(chasing);b.update(.1)
 assert(distance(chasing)<before,'Pursuers change direction when player moves')
 b.hp=10;local slow=b.chaseSpeed();b.hp=1;assert(b.chaseSpeed()>slow,'Pursuit accelerates as egg weakens')
 reset();b=Raven
 local slots={};local fire=b.fire;b.fire=function(m) slots[#slots+1]=m.slot;fire(m) end
 player.x=35;player.y=540
 for i=1,180 do b.update(1/60) end
 assert(#slots>=6,'Faster continuous shooting cadence')
 for i,slot in ipairs(slots) do assert(slot==({1,3,5})[(i-1)%3+1]) end
 b.fire=fire;Hazards.kill=kill
 reset();b=Raven
 for i=1,9 do
  local previous={};for _,m in ipairs(b.chicks) do previous[m]=true end
  hit(b);assert(#b.chicks==3+math.min(math.floor(i/2),3),'Every two lost HP summon a pursuer, up to three living birds')
  for _,m in ipairs(b.chicks) do previous[m]=nil end
  assert(next(previous)==nil,'Existing birds remain after every invocation')
  for _,m in ipairs(b.chicks) do assert(m.kind~='corner') end
 end
 reset();b=Raven;Hazards.kill=function() end
 local anchors={};for _,m in ipairs(b.chicks) do if m.kind=='shooter' then anchors[m]={m.x,m.y} end end
 for i=1,180 do player.x=35+i;player.y=500;b.update(1/60) end
 for m,p in pairs(anchors) do assert(m.x==p[1] and m.y==p[2],'Shooters remain in their nests') end
 assert(b.featherSpeed==440 and b.interval()<=.32,'Faster feathers and firing cadence')
 reset();b=Raven;assert(#b.chicks==3,'Only shooters are present initially')
 for i=1,6 do hit(b) end
 local target=b.chicks[#b.chicks]
 target.age=1;target.x=b.x+140;target.y=b.y;b.movementRate=0;b.shotClock=100
 player.x=35;player.y=540
 b.projectiles={{x=b.x+95,y=b.y,vx=440,vy=0,life=3}}
 b.update(.12)
 assert(#b.chicks==5 and #b.corpses==1 and #b.projectiles==0,'Feather kills pursuing bird and is consumed without tunnelling')
 b.update(0);assert(#b.chicks==5,'A death alone does not summon a replacement')
 hit(b);assert(#b.chicks==5,'One lost HP does not replace a dead pursuer')
 hit(b);assert(#b.chicks==6,'Two lost HP replace a dead pursuer')
 hit(b);assert(#b.chicks==6,'Only one replacement may spawn per death')
 local corpse=b.corpses[1];local x,y=corpse.x,corpse.y
 for i=1,60 do b.update(1/60) end
 assert(corpse.x==x and corpse.y==y and corpse.fall==1,'Corpse settles and stays on the floor')
 local hurt=false;Hazards.kill=function() hurt=true end
 player.x=x-15;player.y=y-12;b.update(.01);assert(not hurt,'Dead bird is harmless')
 local shooter=b.chicks[1];b.projectiles={{x=shooter.x,y=shooter.y,vx=0,vy=0,life=3}}
 b.update(.01);assert(#b.chicks==6 and #b.corpses==1,'Feathers do not kill nesting shooters')
 b.hp=1;hit(b);assert(b.broken and b.liberating and #b.freedChicks==6 and #b.corpses==1,'Living birds are freed immediately')
 require('boss_liberation').update(2)
 player.dashing=false;assert(b.defeated and #b.corpses==1,'Corpses remain after victory and do not block it')
 Hazards.kill=kill
 print('PASS stationary nest shooters, faster fire, feather friendly fire, persistent harmless corpses, victory with dead birds')
 reset();clearBoss(Raven)
 local layout=require('json').decode(love.filesystem.read('tests/egg_layout.json'))
 LevelLayouts.disabled=false;Workshop.playLayout(layout);clearBoss(Bosses.items[1].boss)
 print('PASS ten egg HP, faster alternating fire, accelerating pursuit, automatic silk liberation, delayed tear without bird contacts (native and saved map)')
 reset();local tick=0
 love.update=function(dt)
  tick=tick+1;UI.clock=UI.clock+dt
  if tick==1 then App.capture='egg-ten-full.png'
  elseif tick==3 then
   for i=1,5 do hit(Raven) end
   player.x=35;player.y=540;local k=Hazards.kill;Hazards.kill=function() end;for i=1,60 do Raven.update(1/60) end;Hazards.kill=k
   App.capture='egg-nest-fire.png'
  elseif tick==5 then
   local m;for _,v in ipairs(Raven.chicks) do if v.kind=='charger' then m=v;break end end
   if m then Raven.projectiles={{x=m.x,y=m.y,vx=0,vy=0,life=3}};Raven.update(0);Raven.update(.3) end
   App.capture='egg-fallen-bird.png'
  elseif tick==7 then reset();for i=1,10 do hit(Raven) end;App.capture='egg-no-ground-triangles.png'
  elseif tick==9 then io.stdout:flush();love.event.quit(0) end
 end
end
return T
