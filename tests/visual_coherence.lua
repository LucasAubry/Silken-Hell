local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Graphics.showFPS=false;App.singleLevel=true;App.practice=7;App.start(1)
 local g=love.graphics;local M=require('prism_material')
 local function sample(key,enabled,clock)
  UI.clock=clock;M.enabled=enabled
  local c=g.newCanvas(160,160,{dpiscale=1})
  g.push('all');g.setCanvas(c);g.origin();g.clear(0,0,0,0);g.setColor(1,1,1,.7)
  M.beginScene(c)
  local a=Art.images[key];local scale=140/math.max(a.w,a.h)
  g.draw(a.image,a.quad,80,80,0,scale,scale,a.w/2,a.h/2)
  M.endScene();g.pop()
  local data=c:newImageData();c:release();return data
 end
 for _,key in ipairs({'crab_open','hedgehog_down','mole_down','octopus_mantle','skeleton_head','magma_larva','original_down','final_queen','wheel'}) do
  local before,after,later=sample(key,false,0),sample(key,true,0),sample(key,true,100)
  assert(after:getString()==later:getString(),'Material must not shimmer with time: '..key)
  for y=0,159 do for x=0,159 do
   local r,green,b,a=before:getPixel(x,y);local nr,ng,nb,na=after:getPixel(x,y)
   assert(a==na,'Exact silhouette/alpha: '..key)
   if a>.2 and r+green+b>.1 then
    local gain=(nr+ng+nb)/(r+green+b)
    assert(math.abs(nr-r*gain)<3/255 and math.abs(ng-green*gain)<3/255 and math.abs(nb-b*gain)<3/255,'Authored hue: '..key)
   end
  end end
  before:release();after:release();later:release()
 end
 M.enabled=true
 local tasks={};for _,w in ipairs(Worlds.order) do tasks[#tasks+1]={world=w,level=w==3 and 1 or 7} end
 local draw=love.draw;local tick=0;local task
 love.update=function()
  tick=tick+1;task=tasks[tick]
  if not task then print('PASS visual coherence: exact silhouettes and hues, stable materials, seven biomes, unchanged RNG and collisions');love.event.quit();return end
  App.practice=task.level;App.start(task.world);UI.clock=2
  local start=require('run_start');start.active=false;start.arrival=nil;start.arrivalKind=nil
  App.state='playing'
 end
 love.draw=function()
  if not task then return end
  local state=love.math.getRandomState();local walls=require('json').encode(Arena.walls);draw()
  assert(love.math.getRandomState()==state and walls==require('json').encode(Arena.walls),'Render must not change simulation')
  local name='/tmp/silken-coherence-'..task.world..'.png'
  g.captureScreenshot(function(data)
   local visible=0;local w,h=data:getDimensions()
   for y=0,h-1,8 do for x=0,w-1,8 do local r,b,c=data:getPixel(x,y);if math.max(r,b,c)>.08 then visible=visible+1 end end end
   assert(visible>200,'Capture must show the arena, not the arrival fade')
   local f=assert(io.open(name,'wb'));f:write(data:encode('png'):getString());f:close()
  end)
 end
end
return T
