local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 App.singleLevel=true
 local configure=Arena.configure
 for _,width in ipairs({600,960,1440}) do
  -- Simulate logical arena sizes independently of the OS minimum window size.
  Arena.configure=function()Arena.width=width;Arena.height=600 end
  for level=1,9 do
   App.practice=level;App.start(4);player.reset=false
   assert(Arena.width==width,'Requested arena aspect ratio is active')
   assert(#Arena.interior>=2,'Coral obstacles in ocean level '..level..' width '..width)
   assert(not Arena.blocked(player.x,player.y,30,24),'Clear spawn')
   for _,wall in ipairs(Arena.interior) do assert(Arena.blocked(wall.x,wall.y,1,1),'Solid coral collision') end
   for _,tear in ipairs(levels[player.level].larme_position) do
    assert(not Arena.blocked(tear.x,tear.y,30,24),'Tear not trapped in coral')
    local route=Arena.route(player,tear.x,tear.y)
    assert(#route>0,'Reachable tear around coral, level '..level..' width '..width)
   end
   local random=love.math.getRandomState()
   Arena.drawWalls(false);assert(random==love.math.getRandomState(),'Coral drawing leaves gameplay RNG intact')
  end
  App.practice=10;App.start(4);assert(#Arena.interior==0,'Boss arena remains open')
 end
 Arena.configure=configure
 Arena.configure(love.graphics.getDimensions());App.practice=7;App.start(4);player.reset=false
 local draw=love.draw;local tick=0
 love.update=function()tick=tick+1;UI.clock=3 end
 love.draw=function()
  draw()
  if tick==1 then love.graphics.captureScreenshot(function(data)
   local f=assert(io.open('/tmp/silken-ocean-coral.png','wb'));f:write(data:encode('png'):getString());f:close()
  end) end
  if tick>=3 then print('PASS coral walls: all 9 ocean levels at 3 arena widths, solid collisions, clear spawns, reachable tears, open boss arena, RNG isolation');love.event.quit() end
 end
end
return T
