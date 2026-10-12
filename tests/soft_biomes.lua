local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 Profile.character=1;Graphics.quality=2;Graphics.effects=true;Graphics.showFPS=false
 Graphics.vsync=0;Graphics.limit=0
 local g=love.graphics;local draw=love.draw;local index,frames,pending=0,0,0
 local tasks={1,6,5,4,7,2,3,'gulls'}
 love.filesystem.createDirectory('soft-biomes')
 local function capture(name)
  pending=pending+1
  g.captureScreenshot(function(data)
   data:encode('png','soft-biomes/'..name..'.png');data:release();pending=pending-1
  end)
 end
 love.update=function()
  if index>0 and frames<3 then return end
  if index==#tasks then
   if pending>0 then return end
   print('PASS soft biomes: seven worlds rendered, four gull directions, unchanged gameplay RNG and walls')
   print('CAPTURES '..love.filesystem.getSaveDirectory()..'/soft-biomes')
   love.event.quit();return
  end
  index=index+1;frames=0
  if tasks[index]=='gulls' then App.state='bestiary';return end
  App.singleLevel=true;App.practice=tasks[index]==3 and 1 or tasks[index]==7 and 4 or 9;App.hardcore=false
  App.start(tasks[index]);App.practice=nil;player.reset=false;UI.clock=5.15;timer=12.48
  for _,m in ipairs(mobs) do if m.imgs then m.dir='down';m.img=m.imgs.down or m.imgs.up end end
 end
 love.draw=function()
  if index==0 then return end
  local rng=love.math.getRandomState();local walls=require('json').encode(Arena.walls)
  if tasks[index]=='gulls' then
   g.clear(.30,.43,.50);g.push('all');g.origin();g.setColor(1,1,1)
   local w,h=g.getDimensions()
   for i,dir in ipairs({'down','up','left','right'}) do
    Art.drawFacing('gull',dir,w*(i-.5)/4,h*.38,210)
    Art.drawFacing('gull',dir,w*(i-.5)/4,h*.76,75)
   end
   g.pop()
  else draw() end
  assert(love.math.getRandomState()==rng,'Rendering consumed gameplay randomness')
  assert(require('json').encode(Arena.walls)==walls,'Rendering changed collisions')
  frames=frames+1;if frames==2 then capture('biome-'..tasks[index]) end
 end
end
return T
