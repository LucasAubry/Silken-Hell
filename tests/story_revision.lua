local T={}
local function reset(world,n)
 App.practice=n or 10;App.singleLevel=true;App.sessionLayout=nil;App.preview=false;App.start(world)
 require('boss_arrival').events={};player.reset=false
end
function T.run()
 io.stdout:setvbuf('no')
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end;Graphics.showFPS=false
 local S=Storm
 reset(6)
 local function salvo(hp)
  S.reset(true);S.hp=hp;local elapsed=0;local count=0
  repeat S.fire();elapsed=elapsed+S.shot;count=count+1 until S.burst==0
  return elapsed,count
 end
 local early,n1=salvo(10);local late,n2=salvo(1)
 assert(n1==3 and n2==5 and late<early,'Fewer opening feathers and faster late salvos')
 reset(6);player.x=350;player.y=350
 S.shot=100;S.bolt=100;S.update(6);assert(S.phase=='orbit','No dash until a hit')
 S.hurt(true);S.hurt(true);assert(S.phase=='orbit','Opening requires three HP')
 S.hurt(true);assert(S.hp==7 and S.phase=='leave','Third lost HP starts an escape')
 S.update(.11);assert(S.y<100,'Escape is fast');S.update(.12);assert(S.phase=='flightTell' and S.hidden)
 local sx,sy,ex,ey=S.startX,S.startY,S.endX,S.endY
 assert(sy==player.y+12 and ey==sy,'First pass targets player position')
 player.y=440;S.update(.05);assert(S.startY==sy,'Announced path locks so player can evade')
 S.hurt(true);assert(S.pendingDashes==0,'Next threshold requires two HP')
 S.hurt(true);assert(S.pendingDashes==1,'Crossed threshold queues another reaction')
 for _,pos in ipairs({{65,288},{Arena.width-95,288},{Arena.width/2-15,70},{Arena.width/2-15,495}}) do
  player.x=pos[1];player.y=pos[2];S.setPhase('flightTell')
  local _,_,x,y,w,h=S.previewPose();assert(x>=20 and y>=20 and x+w<=Arena.width-20 and y+h<=580,'Beak visible inside arena')
  local cross=(player.x+15-S.startX)*(S.endY-S.startY)-(player.y+12-S.startY)*(S.endX-S.startX)
  assert(math.abs(cross)<.01,'All four passes aim through the player')
 end
 S.hp=1;S.hurt(true);assert(S.defeated and S.hp==0,'Final hit finishes the boss')
 local counts={}
 for _,a in ipairs(Achievements.list) do assert(a.category);counts[a.category]=(counts[a.category] or 0)+1 end
 assert(counts.secrets==2 and counts.worlds==7 and counts.mastery>=8)
 reset(1,10);Raven.defeated=true;Achievements.finishLevel();assert(Profile.achievements.bossflawless1)
 Profile.achievements.bossflawless1=nil;player.death=player.death+1;reset_level();Raven.defeated=true
 Achievements.finishLevel();assert(not Profile.achievements.bossflawless1,'Death and retry cannot erase the boss challenge failure')
 for _,e in ipairs(Bestiary.entries) do assert(#e.text<420,'Short bestiary description: '..e.id) end
 local servants=require('servant_art');assert(servants.amount(1,1)<servants.amount(6,10) and servants.amount(6,10)<servants.amount(2,10))
 for _,key in ipairs({'mole_up','mole_down','mole_left','mole_right','merle_up','merle_down','merle_left','merle_right','crab_open','crab_closed','magma_larva'}) do assert(servants.frames[key],key) end
 reset(5);assert(mobs[1].bossServant,'Boss moles use authored skin')
 reset(2);local larva=Wasp.fireLarva(Wasp.bees[1]);assert(larva.bossServant)
 local anchor=require('silk_art').anchors;for i=1,14 do assert(anchor[i] and anchor[i]<0,'Thread attaches to skin '..i) end
 App.state='menu';UI.buttons={};local clicks=0
 UI.button('Test',10,10,100,35,function()clicks=clicks+1 end)
 UI.click(20,20);assert(UI.pressed and clicks==0);UI.updatePress(.06);assert(clicks==0);UI.updatePress(.06);assert(clicks==1 and not UI.pressed)
 print('PASS story revision: sky attack ramp, damage dashes, locked telegraphs at all edges, queued hits, victory, achievement categories/challenge, short lore, progressive silk, preloaded servant skins, attached thread, button press')
 local shots={
  {'menu-paradis',function()App.state='menu';App.selectedWorld=1 end},
  {'menu-renaissance',function()App.state='menu';App.selectedWorld=3 end},
  {'menu-sanctuaire',function()App.state='menu';App.selectedWorld=8 end},
  {'succes-mondes',function()App.state='achievements';UI.achievementCategory='worlds';UI.achievementPage=1 end},
  {'succes-maitrise',function()App.state='achievements';UI.achievementCategory='mastery';UI.achievementPage=1 end},
  {'succes-secrets',function()App.state='achievements';UI.achievementCategory='secrets';UI.achievementPage=1 end},
  {'serviteurs-paradis',function()reset(1);Raven.hp=8;Raven.hatch() end},
  {'serviteurs-terre',function()reset(5);for _,m in ipairs(mobs) do m.age=3;m.x=Arena.width*.3;m.y=320 end end},
  {'serviteurs-ocean',function()reset(4);Octopus.releaseCrabs();for _,c in ipairs(Octopus.crabs) do c.emerge=nil end end},
  {'serviteurs-enfer',function()reset(2);Wasp.fireLarva({x=Arena.width*.5,y=380}) end},
  {'ciel-annonce',function()reset(6);player.x=Arena.width*.5;player.y=340;Storm.round=1;Storm.pass=0;Storm.setPhase('flightTell') end},
  {'ciel-annonce-gauche',function()Storm.pass=1;Storm.setPhase('flightTell') end},
  {'ciel-annonce-bas',function()Storm.pass=2;Storm.setPhase('flightTell') end},
  {'ciel-annonce-haut',function()Storm.pass=3;Storm.setPhase('flightTell') end},
  {'sanctuaire',function()Profile.completed={};for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end;Secret.open(false) end},
  {'bestiary-histoire',function()App.state='bestiary';Bestiary.discover('crab');Bestiary.open('crab') end},
  {'chargement',function()require('texture_preload').begin() end},
 }
 local tick=0;local draw=love.draw
 love.update=function()
  tick=tick+1
  if shots[tick] then shots[tick][2]() else love.event.quit() end
 end
 love.draw=function()
  if shots[tick] and shots[tick][1]=='chargement' then require('texture_preload').draw() else draw() end
  if shots[tick] then
   local path='/tmp/silken-story-'..shots[tick][1]..'.png'
   love.graphics.captureScreenshot(function(data)local f=assert(io.open(path,'wb'));f:write(data:encode('png'):getString());f:close()end)
  end
 end
end
return T
