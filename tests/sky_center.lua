local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false;LevelLayouts.disabled=true
 App.hardcore=false;App.singleLevel=true;App.preview=false;Profile.language='fr'
 local kill=Hazards.kill;local hits=0;Hazards.kill=function()hits=hits+1 end
 for level=1,9 do
  App.practice=level;App.start(6)
  mobs={};Realms.lightningClock=0;Realms.rainClock=0;Realms.rainSites={{x=player.x+15,y=player.y+12,phase=1}}
  Realms.update(.01)
  assert(#Realms.lightning==0 and #Realms.rain==0,'No ground/player strikes in ordinary Sky level '..level)
  local gull={type='gull',x=100,y=100};mobs={gull,{type='gull',x=300,y=100,dead=true}}
  Realms.lightningClock=0;Realms.updateLightning(.01)
  assert(#Realms.lightning==1 and Realms.lightning[1].target==gull,'Only a live gull is targeted')
  gull.x=180;Realms.updateLightning(.3)
  assert(Realms.lightning[1].x==180,'Warning follows the gull')
  Realms.updateLightning(.5)
  assert(gull.electric,'Gull still electrifies on impact')
 end
 assert(hits==0,'Removed environmental bolts cannot damage the player')
 App.practice=10;App.start(6);Storm.summon();Storm.summonRain()
 assert(#Storm.strikes>0 and #Storm.rain>0,'Blackbird boss keeps both lightning patterns')
 Hazards.kill=kill
 local defaults=require('json').decode(love.filesystem.read('designer/default_levels.json'))
 for _,width in ipairs({800,960,1440}) do
  Arena.width=width;Campaign.select(1)
  for n=1,9 do
   player.level=n;reset_level()
   assert(math.abs(player.x+15-width/2)<.001 and player.y+12==300,'Fallback Paradise spawn centered')
   LevelLayouts.apply(defaults.levels['1:'..n])
   assert(math.abs(player.x+15-width/2)<.001 and player.y+12==300,'Editor default spawn centered')
  end
 end
 print('PASS Sky: only gull strikes in levels 1–9, electrification intact, boss lightning retained; Paradise centered at three aspect ratios')
 local C=require('run_start');local tick=0
 love.update=function()
  tick=tick+1;UI.clock=25+tick*.2
  if tick==1 then App.singleLevel=false;App.practice=nil;App.start(1);C.elapsed=.25;App.capture='sky-center-countdown.png'
  elseif tick==2 then App.singleLevel=true;App.practice=6;App.start(6);Realms.lightningClock=0;Realms.updateLightning(.01);App.capture='sky-gulls-only.png'
  elseif tick==3 then print('PASS Sky and centered countdown captures');love.event.quit()end
 end
end
return T
