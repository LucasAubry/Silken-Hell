local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true;love.focus=function()end
 App.practice=10;App.singleLevel=true;App.start(6);require('boss_arrival').events={};player.reset=false
 local b=Storm
 b.shot=100;b.bolt=100
 b.hurt(true);b.hurt(true);assert(b.hp==8 and b.phase=='orbit' and b.pendingDashes==0)
 b.hurt(true);assert(b.hp==7 and b.phase=='leave' and b.nextDashHP==5)
 local function finishPass()
  player.x=80;player.y=288;b.setPhase('flightTell');local y=b.startY
  player.y=480;b.update(.01);assert(b.startY==y and b.endY==y,'Warning locks its announced path')
  b.setPhase('flight');b.update(b.flightDuration+.001)
  assert(b.phase=='return' and b.pass==1,'One crossing, then return')
  b.update(.66);assert(b.phase=='orbit' and b.pendingDashes==0,'No automatic repeat')
 end
 finishPass();b.hurt(true);assert(b.hp==6 and b.phase=='orbit')
 b.hurt(true);assert(b.hp==5 and b.phase=='leave' and b.nextDashHP==4);finishPass()
 for hp=4,1,-1 do b.hurt(true);assert(b.hp==hp and b.phase=='leave');finishPass() end
 b.hurt(true);assert(b.defeated and require('boss_liberation').busy(),'Final HP triggers liberation, not a dash')
 reset_level();require('boss_arrival').events={}
 b.hurt(true);b.hurt(true);b.hurt(true);b.hurt(true);assert(b.pendingDashes==0)
 b.hurt(true);assert(b.pendingDashes==1 and b.nextDashHP==4,'Only a crossed HP threshold queues a dash')
 local sides={{80,288,'right'},{Arena.width-110,288,'left'},{Arena.width/2-15,75,'down'},{Arena.width/2-15,490,'up'}}
 local g=love.graphics
 for _,p in ipairs(sides) do
  player.x=p[1];player.y=p[2];b.setPhase('flightTell');assert(b.dir==p[3],'Player position chooses entry edge')
  local cross=(player.x+15-b.startX)*(b.endY-b.startY)-(player.y+12-b.startY)*(b.endX-b.startX)
  assert(math.abs(cross)<.01)
  local oldLine=g.line;g.line=function()error('The player arrow must be absent')end;b.draw();g.line=oldLine
  require('boss_hud').draw(b);assert(require('boss_hud').offsetY==0,'Storm health bar stays at the top')
 end
 assert(require('boss_arrival').sizeScale<.5,'Boss entrances are less than half their previous size')
 print('PASS sky revision: 3/2/1 HP thresholds, one crossing, queued thresholds only, four player-relative directions, locked target, no arrow, fixed top HUD, reduced entrances')
 local draw=love.draw;local frame=0
 love.update=function()
  frame=frame+1
  if sides[frame] then local p=sides[frame];player.x=p[1];player.y=p[2];b.setPhase('flightTell') else love.event.quit()end
 end
 love.draw=function()
  draw();if sides[frame] then local path='/tmp/silken-storm-direction-'..sides[frame][3]..'.png'
   g.captureScreenshot(function(data)local file=assert(io.open(path,'wb'));file:write(data:encode('png'):getString());file:close()end)
  end
 end
end
return T
