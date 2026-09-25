local T={}
local C=require 'mobs.bosses.abyss.laser_cycle'
local function level(n)
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false;Replay.data=nil
 App.hardcore=false;App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;Secret.duel=nil;LevelLayouts.disabled=true
 Campaign.select(7);player.level=n or 10;reset_level();App.state='playing';player.reset=false
end
local function grab(a)
 local x,y=C.tooth(a);player.x=x-15;player.y=y-12;player.dashing=true;C.contact(a)
end
function T.run()
 level();local a=Abyss;local move=Input.move
 assert(a.hp==6 and #a.lures==0 and #a.beams==0 and #mobs==0)
 grab(a);assert(not a.grab,'Closed mouth has no target')
 C.enter(a,'open');local x,y=C.tooth(a);player.x=x-15;player.y=y-12;player.dashing=false;C.contact(a);assert(not a.grab,'Must rush tooth')
 grab(a);assert(a.grab and C.lockPlayer(a));Input.move=function() return -1,0 end;a.update(.2);assert(a.grab.progress==0,'Pull outward only')
 Input.move=function() return 1,0 end
 local hp=a.hp;for i=1,8 do a.update(.1) end
 assert(a.hp==hp-1 and not a.grab and not player.reset and a.phase=='recoil','Extract one tooth and escape')
 local removed=a.toothIndex;C.contact(a);assert(a.hp==hp-1)
 C.enter(a,'open');assert(a.toothIndex~=removed,'Removed teeth cannot be targeted again')
 grab(a);a.phaseTime=a.duration-.01;a.update(.02);assert(player.reset and a.hp==hp-1 and not a.grab,'Closing kills before awarding extraction')
 level();a=Abyss;C.enter(a,'open');grab(a);a.grab.progress=.999;a.phaseTime=a.duration-.001;a.update(.01);assert(player.reset and a.hp==6,'No late extraction on closing frame')
 level();a=Abyss
 for i=1,6 do C.enter(a,'open');grab(a);for j=1,8 do a.update(.1) end;assert(a.hp==6-i) end
 assert(a.defeated and not C.lockPlayer(a));Aftermath.update(0);assert(objet.larme.x+15==Arena.width/2 and objet.larme.y+20==Arena.height/2)
 level();assert(not Abyss.grab and Abyss.hp==6);level(8);assert(not Abyss.boss and #Abyss.bones>0)
 Input.move=move
 print('PASS teeth: rush, outward pull, one HP per tooth, lethal deadline, no late damage, no repeat tooth, victory, reset, earlier levels');io.stdout:flush()
 local tick=0;love.focus=function() end
 love.update=function()
  tick=tick+1
  if tick==1 then level();a=Abyss;C.enter(a,'open');App.capture='abyss-tooth-open.png'
  elseif tick==3 then grab(a);a.grab.progress=.4;App.capture='abyss-tooth-pull.png'
  elseif tick==5 then a.phaseTime=a.duration-.3;App.capture='abyss-tooth-danger.png'
  elseif tick==7 then love.event.quit(0) end
 end
end
return T
