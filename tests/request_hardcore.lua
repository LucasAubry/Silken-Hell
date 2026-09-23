local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Profile.completed[Worlds.order[3]]=true;Profile.completed[1]=true
 local function level(w,n)
  App.hardcore=false;App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;Secret.duel=nil
  Hardcore.notice=nil;LevelLayouts.disabled=true;Campaign.select(w);player.level=n;reset_level();App.state='playing';player.reset=false
 end
 for n=1,Worlds.levelCount(3) do
  level(3,n);assert(Campaign.biome==3 and #mobs==0 and #Arena.interior==0 and not Bosses.any() and not Raven.active and not Wasp.active and not Octopus.active and not Abyss.active,'Renaissance must be empty at '..n)
  assert(Campaign.canCollect(),'Empty levels retain an exit')
 end
 level(3,4);RunDetails.reset();App.hardcore=true;player.death=1;player.reset=true
 App.resolveDeath();assert(player.level==3 and not player.reset and RunDetails.rows[4].deaths==1)
 player.level=1;player.reset=true;App.resolveDeath();assert(player.level==1)
 player.level=4;reset_level();player.x=objet.larme.x;player.y=objet.larme.y;App.simulate(0)
 assert(player.level==5 and Hardcore.notice.text:find('5'),'Hardcore advances')
 player.reset=true;player.falling=true;player.fallTimer=0;App.resolveDeath();assert(player.level==4);App.simulate(.32);assert(player.level==4 and not player.reset,'Falling death drops exactly once')
 local kill=Hazards.kill;Hazards.kill=function() end
 for alive=1,3 do
  level(2,10);for i=alive+1,3 do Wasp.bees[i].hp=0 end
  Wasp.beginRound();local b=Wasp.bees[1];assert(b.dashesLeft==4-alive)
  for _,other in ipairs(Wasp.bees) do other.phase='cooldown' end
  b.x=Arena.width-47;b.y=100;b.vx=1;b.vy=0;b.attack=1;b.phase='charge'
  for j=1,4-alive do
   Wasp.updateBees(.01)
   if j<4-alive then assert(b.phase=='aim' and b.vy==0,'Repeated dash retains axis');b.phase='charge';b.x=b.vx>0 and Arena.width-47 or 47
   else assert(b.phase=='fatigued','Fatigue only after whole combo') end
  end
 end
 level(4,10);Octopus.releaseCrabs();assert(#Octopus.crabs==6,'Original six-crab wave')
 local c=Octopus.crabs[1];c.emerge=nil;c.x=10;c.y=100
 Octopus.walkCrab(c,.016,function() Octopus.crabContact(c) end)
 assert(c.dead or not Arena.blocked(c.x-14,c.y-12,28,24),'Crab recovered from wall')
 local c={x=80,y=400,speed=195,age=0,hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
 player.x=140;player.y=500
 local before=(c.x-player.x-15)^2+(c.y-player.y-12)^2
 Octopus.walkCrab(c,.1,function() end)
 assert((c.x-player.x-15)^2+(c.y-player.y-12)^2<before,'Ordinary crab follows player again')
 c.inked=true;c.frenzy=true;c.wave=1;local previous;local changed=false
 for i=1,12 do
  c.x=100;c.y=300;c.age=c.age+.23
  Octopus.walkCrab(c,.23,function() end)
  local angle=math.atan2(c.vy,c.vx);if previous and math.abs(angle-previous)>.5 then changed=true end;previous=angle
 end
 assert(changed,'Inked crab wanders freely again')
 local function blackCrab()
  return {x=Octopus.x+205,y=Octopus.y,speed=195,age=1,inked=true,frenzy=true,wave=1,hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
 end
 local left,right=blackCrab(),blackCrab()
 player.x=60;player.y=100;Octopus.walkCrab(left,.016,function() end)
 player.x=Arena.width-70;player.y=500;Octopus.walkCrab(right,.016,function() end)
 assert(left.x==right.x and left.y==right.y and left.vx==right.vx and left.vy==right.vy,'Black frenzy never orbits toward player')
 assert(left.frenzyTurn>=.1 and left.frenzyTurn<=.26,'Rapid irregular direction changes')

 Octopus.crabs={};Octopus.enraged=true;Octopus.releaseCrabs();assert(#Octopus.crabs==8,'Original enraged eight-crab wave')
 Hazards.kill=kill
 -- Run a complete hardcore campaign and replay it using real movement.
 local json=require 'json';local maps={}
 for n=1,10 do maps['1:'..n]={world=1,level=n,width=960,height=600,entities={{kind='spawn',x=80,y=300},{kind='tear',x=240,y=300}}} end
 local read=LevelLayouts.read;local move,slow=Input.move,Input.slow
 LevelLayouts.read=function() return maps end;LevelLayouts.disabled=false
 Input.move=function() if Replay.input then return Replay.input[1],Replay.input[2] end;return 1,0 end
 Input.slow=function() return false end
 local scoreCount=#Profile.scores;local reached=(Profile.levels or {})[1]
 local start,checkpoint=Online.start,Online.checkpoint
 Online.start=function() error('Hardcore must not start a normal leaderboard run') end
 Online.checkpoint=function() error('Hardcore must not send normal checkpoints') end
 App.hardcore=true;App.practice=nil;App.singleLevel=false;Replay.disabled=false;App.start(1)
 LevelLayouts.read=read
 for i=1,2000 do if App.state~='playing' then break end;Replay.update(1/60,App.simulate) end
 assert(App.state=='victory' and player.level==10 and Hardcore.completed['1'])
 assert(#Profile.scores==scoreCount and Profile.levels[1]==reached,'Separate normal progression')
 local data=json.decode(json.encode(Replay.last));assert(data.hardcore and data.completed)
 assert(Replay.play(data))
 for i=1,2000 do if not Replay.playing then break end;Replay.update(1/43,App.simulate) end
 assert(Replay.status=='Lecture terminée.','Hardcore replay: '..Replay.status)
 Hardcore.completed={};Hardcore.load();assert(Hardcore.completed['1'],'Hardcore completion persists')
 Input.move,Input.slow=move,slow;Online.start,Online.checkpoint=start,checkpoint;Replay.disabled=true
 print('PASS full hardcore campaign, isolated scores, saved completion and deterministic replay')
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 print('PASS empty Renaissance, hardcore progression/fall death, bee combos, restored crab waves, pursuit, ink wandering and wall recovery')
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then App.selectedWorld=5;WorldMap.open();App.capture='request-map.png'
  elseif tick==3 then WorldMap.branch(true);WorldMap.update(2);App.capture='request-hardcore.png'
  elseif tick==5 then level(1,10);App.capture='request-egg.png'
  elseif tick==7 then level(5,1);App.capture='request-earth.png'
  elseif tick==9 then level(3,Worlds.levelCount(3));App.capture='request-empty.png'
  elseif tick==11 then App.hardcore=true;Hardcore.notify('Niveau 4 : retour au niveau 3',true);App.capture='request-notice.png'
  elseif tick==13 then App.state='victory';App.capture='request-victory.png'
  elseif tick==15 then io.stdout:flush();love.event.quit(0) end
 end
end
return T
