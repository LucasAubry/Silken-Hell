local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;LevelLayouts.disabled=true
 Campaign.select(1);player.level=10;reset_level();App.state='playing'
 assert(#Raven.nests==6 and #Raven.chicks==3)
 for i,n in ipairs(Raven.nests) do
  assert(math.abs(((n.x-Raven.x)/math.min(320,Arena.width/2-65))^2+((n.y-Raven.y)/240)^2-1)<.001)
  assert(n.shooter==(i%2==1))
 end
 assert(math.abs(player.x+15-Raven.x)<.001 and math.abs(player.y+12-(Raven.nests[4].y-65))<.001)
 player.x=Raven.x-15;player.y=Raven.y-12;player.dashing=true;Raven.contact()
 assert(#Raven.chicks==3,'First hit does not summon a bird')
 player.x=35;player.y=540;Raven.contact()
 player.x=Raven.x-15;player.y=Raven.y-12;Raven.contact()
 assert(#Raven.chicks==4 and #Raven.projectiles==0);Raven.fireNext();assert(#Raven.projectiles==1)
 for _,p in ipairs(Raven.projectiles) do
  local bird=false;for _,m in ipairs(Raven.chicks) do if m.kind=='shooter' and m.x==p.x and m.y==p.y then bird=true end end
  assert(bird,'Feathers originate at an actual bird')
 end
 player.dashing=false;player.x=Raven.x+150;player.y=Raven.y-17
 local bird=Raven.chicks[#Raven.chicks];bird.age=1;local before=(bird.x-player.x-15)^2+(bird.y-player.y-12)^2
 Raven.projectiles={{x=Raven.x-80,y=Raven.y-5,vx=320,vy=0,life=3}}
 Raven.shotClock=10;Raven.update(.25)
 assert(#Raven.projectiles==1,'Feathers fly over the egg')
 assert((bird.x-player.x-15)^2+(bird.y-player.y-12)^2<before and bird.phase=='chase','Non-shooters pursue the player')
 Raven.setupNests();local shooter=Raven.chicks[1];local previousX,previousY=shooter.x,shooter.y
 player.x=50;player.y=450;Raven.update(.1)
 assert(shooter.x==previousX and shooter.y==previousY,'Ranged birds stay in their nest')
 Campaign.select(4);player.level=10;reset_level()
 for _,p in ipairs({{Arena.width/2,500},{50,50},{Arena.width-50,550},{Arena.width/2,300}}) do
  Octopus.crabs={};player.x=p[1]-15;player.y=p[2]-12;Octopus.releaseCrabs()
  assert(#Octopus.crabs>0 and #Octopus.crabs<=6)
  for _,c in ipairs(Octopus.crabs) do
   assert((c.x-p[1])^2+(c.y-p[2])^2>=115^2,'Crab emergence clearance')
   assert(c.emerge and not c.launch and c.x==c.tx and c.y==c.ty,'Spawn directly in seabed')
  end
  local first=Octopus.crabs[1];local x,y=first.x,first.y
  Octopus.updateCrabs(.4);assert(first.x==x and first.y==y and first.emerge,'No airborne movement')
  local px,py=player.x,player.y;player.x=x-15;player.y=y-12;Octopus.crabContact(first);assert(not player.reset,'Buried crabs cannot hurt player');player.x,player.y=px,py
  Octopus.updateCrabs(.7);assert(not first.emerge,'Crab becomes active after emerging')
 end
 -- Crab detouring now keeps the complete resting boss clear.
 Octopus.reset(true);player.reset=false
 assert(not Octopus.crabPathClear(Octopus.x+170,Octopus.y),'Crabs avoid the boss, including gaps near its head')
 print('PASS crab avoidance around resting boss')
 print('PASS six circular nests, bottom spawn, three resident shooters, flight over egg, seabed emergence')
 local layout=require('json').decode(love.filesystem.read('tests/egg_layout.json'))
 LevelLayouts.disabled=false;Workshop.playLayout(layout)
 local boss=Bosses.items[1].boss
 assert(#boss.nests==6 and #boss.chicks==3)
 local followers=0;for _,m in ipairs(boss.chicks) do if m.kind=='charger' then followers=followers+1 end end
 assert(followers==0,'Saved encounters summon pursuers only on damage')
 App.capture='nest-revision.png';local ticks=0
 love.update=function() ticks=ticks+1;if ticks==3 then
   Campaign.select(4);player.level=10;App.sessionLayout=nil;LevelLayouts.disabled=true;reset_level();Octopus.releaseCrabs();Octopus.updateCrabs(.6);App.capture='crab-emergence.png'
  elseif ticks==6 then io.stdout:flush();love.event.quit(0) end end
end
return T
