-- Regression coverage for the removal of the old PNG entrance sequences.
local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 App.hardcore=false;App.singleLevel=true;Graphics.effects=true;Graphics.showFPS=false
 assert(not love.filesystem.getInfo('boss_arrival.lua'),'Entrance controller has been removed')
 assert(not love.filesystem.getInfo('assets/effects/boss-arrivals'),'Entrance assets are absent')
 local cases={{1,Raven,'elapsed'},{2,Wasp,'elapsed'},{5,Hedgehog,'phaseTime'},{4,Octopus,'clock'},
  {6,Storm,'clock'},{7,Abyss,'clock'},{3,require('final_spider'),'clock'}}
 local g=love.graphics;local kill=Hazards.kill;Hazards.kill=function()end
 local function visible(b)
  local calls=0;local original=g.draw
  g.draw=function(...)calls=calls+1;return original(...)end
  local body=b.draw or b.drawBones;body(false);body(true)
  if b.drawGround then b.drawGround()end
  g.draw=original;assert(calls>0,'Boss must render on the first frame')
 end
 for _,c in ipairs(cases) do
  App.practice=c[1]==3 and 1 or 10;App.start(c[1]);player.reset=false
  local b=c[2];assert(b.active);visible(b)
  local before=b[c[3]];assert(before~=nil,c[3]);b.update(.05)
  assert(b[c[3]]~=before,'Boss AI must advance immediately')
  reset_level();player.reset=false;visible(b)
  love.draw()
 end
 App.practice=1;App.start(1)
 Bosses.load({{type='storm',x=220,y=180},{type='storm',x=650,y=180}},{},{})
 for _,item in ipairs(Bosses.items) do
  visible(item.boss);local before=item.boss.clock;item.boss.update(.01);assert(item.boss.clock>before)
 end
 Hazards.kill=kill
 print('PASS no boss entrances: seven bosses visible and active immediately, retries, independent editor copies, removed PNG assets')
 love.event.quit()
end
return T
