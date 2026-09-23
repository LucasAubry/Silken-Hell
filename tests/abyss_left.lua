local T={}
local function level(w,n)
 Replay.recording=false;Replay.playing=false;Replay.disabled=true;Replay.data=nil
 App.hardcore=false;App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;Secret.duel=nil;LevelLayouts.disabled=true
 Campaign.select(w);player.level=n;reset_level();App.state='playing';player.reset=false
end
function T.run()
 require('tests.earth_cages').run()
 level(7,10);local a=Abyss
 assert(#a.bones==1 and a.bones[1].angle==0,'Only a right-facing skull remains')
 assert(a.head.x-a.head.w/2<0 and a.head.y-a.head.h/2>0,'Head extends through left edge only')
 local mx,my=a.mouth();assert(mx>200 and mx<280 and my>300 and my<380,'Accessible right-facing mouth')
 assert(#a.lightSites==2 and #AbyssTerrain.parts==0 and a.ruptures==nil,'Only cages remain in the arena')
 a.hp=a.maxHp*.5;a.fireBlue();local red,blue=0,0
 for _,p in ipairs(a.threads) do if p.red then red=red+1 else blue=blue+1 end end
 assert(red==0 and blue==3,'Only blue charging bolts remain, including at half health')
 local Pressure=require('mobs.bosses.abyss.pressure')
 level(7,10);a=Abyss;player.x=485;player.y=388;Pressure.spawn(a)
 player.y=100;Pressure.update(a,.5);assert(not player.reset,'Pressure warning harmless')
 Pressure.update(a,1.7);assert(player.reset,'Crossing pressure front kills outside passage')
 level(7,10);a=Abyss;player.x=485;player.y=388;Pressure.spawn(a);local wide=a.pressure.halfGap
 Pressure.update(a,2.2);assert(not player.reset,'Safe passage protects the player')
 local drift=a.pressure.drift;a.hp=5;Pressure.spawn(a);assert(a.pressure.halfGap<wide and a.pressure.drift==-drift,'Waves alternate drifting passage and narrow at half health')
 a.open=true;Pressure.update(a,.1);assert(a.pressure==nil,'Suction clears pressure waves')
 a.lightSites[1].light=3;a.updateCages(.5)
 assert(a.lightSites[1].light<3 and #a.lightMotes>0,'Drained cage light travels toward mouth')
 a.lightSites[1].light=0;a.updateCages(.9);assert(#a.lightMotes==0,'Light particles expire on arrival')
 a.hurt(a.hp);assert(a.pressure==nil and #a.lightMotes==0,'Victory clears abilities')
 print('PASS left skull, blue-only bolts, pressure warning/collision/safe passage/escalation, visible light drain and cleanup')
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then level(5,1);App.capture='top-terre-rings.png'
  elseif tick==3 then level(7,10);a=Abyss;player.x=480;player.y=390;a.hp=5;a.charge(6);a.lightSites[1].light=2;a.lightSites[2].light=3;Pressure.spawn(a);Pressure.update(a,.6);a.fireBlue();App.capture='cage-pressure-warning.png'
  elseif tick==5 then Pressure.update(a,1.2);App.capture='cage-pressure-wave.png'
  elseif tick==7 then a.open=true;a.buildBones();Pressure.update(a,0);a.updateCages(.35);a.updateCages(.3);App.capture='cage-light-drain.png'
  elseif tick==9 then love.event.quit(0) end
 end
end
return T
