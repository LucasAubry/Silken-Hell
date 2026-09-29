local T={}
local function reset()
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
 Campaign.select(6);player.level=10;reset_level();App.state='playing';player.reset=false
 return Storm
end
function T.run()
 io.stdout:setvbuf('no')
 for _,right in ipairs({false,true}) do for _,bottom in ipairs({false,true}) do for mode=0,3 do
  local b=reset();player.x=right and Arena.width-53 or 23;player.y=bottom and 553 or 23
  b.round=1;b.pass=mode;b.setPhase('flightTell')
  if mode<2 then assert(b.startY==player.y+12) else assert(b.startX==player.x+15) end
  local _,_,_,_,w,h=b.previewPose();assert(w>=72 and h>=72,'Beak preview has room at every edge')
  b.setPhase('flight');for _=1,100 do b.update(.005);if player.reset then break end end
  assert(player.reset,'Stationary corner player must be hit by every charge direction')
 end end end
 local b=reset();b.x=Arena.width/2;b.y=40
 local H=require 'boss_hud';assert(H.stormOverlapsTop(love.graphics.getDimensions()))
 H.draw(b);assert(H.offsetY==580,'HUD moves away from upper bird')
 b.y=300;H.draw(b);assert(H.offsetY==0,'HUD returns when upper area clears')
 local unlocked=Profile.unlocked;Ending.previewCredits();assert(App.state=='credits' and Ending.preview)
 Ending.creditTime=Ending.creditDuration()-13;Ending.updateCredits(14)
 assert(App.state=='menu' and not Ending.preview and Profile.unlocked==unlocked,'Preview returns without campaign progress')
 Ending.previewCredits();love.keypressed('escape');assert(App.state=='menu')
 local R={speed=1,paused=true,data={startLevel=1,single=false,checks={{0,2}},frames=100}}
 R.play=function(data) R.data=data;R.playing=true;R.ghost=nil;player.level=1;return true end
 R.stop=function() R.playing=false end
 require('replay_tools').install(R)
 R.key(Profile.keys.ghost);assert(not R.ghost and not R.startGhost)
 R.seekLevel(2,true);assert(R.job and not R.ghost);player.level=2;R.afterFrame();assert(not R.job and R.paused and not R.ghost)
 R.changeSpeed(1);assert(R.speed==2)
 print('PASS sky visibility: 16 corner charges, extended beaks, adaptive HUD, credits preview/exit, spectator seek/pause/speed without ghost')
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1
  if frame==1 then b=reset();b.x=Arena.width/2;b.y=40;App.capture='sky-top-visible.png'
  elseif frame==3 then player.x=Arena.width/2-15;player.y=250;b.round=1;b.pass=2;b.setPhase('flightTell');App.capture='sky-beak-visible.png'
  elseif frame==5 then Ending.previewCredits();Ending.creditTime=Ending.creditDuration()-5;App.capture='credits-preview-button.png'
  elseif frame==7 then love.event.quit() end
 end
end
return T
