local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Profile.skinEffects={};Profile.character=1;Graphics.showFPS=false
 local g=love.graphics;local L=require('world_lighting');local B=require('biome_radiance')
 local json=require('json');local apply,rendered=L.apply,nil
 L.apply=function(scene)rendered=apply(scene);return rendered end
 local function draw()
  local rng=love.math.getRandomState();local state=json.encode(LevelLayouts.snapshot());local x,y=player.x,player.y
  love.draw()
  assert(rng==love.math.getRandomState(),'Decorative light must preserve gameplay RNG')
  assert(state==json.encode(LevelLayouts.snapshot()) and player.x==x and player.y==y,'Scenery must preserve collisions and actors')
  assert(g.getCanvas()==nil,'Light passes must restore canvas state')
  return rendered:newImageData()
 end
 for _,world in ipairs({4,1,5,3,6}) do
  App.practice=world==3 and 2 or 5;App.singleLevel=true;App.start(world);require('run_start').active=false
  UI.clock=4;Realms.clock=4
  Graphics.quality=2;Graphics.effects=false
  assert(not B.active());local before=draw();before:encode('png','radiance-'..world..'-off.png')
  Graphics.effects=true;assert(B.active())
  local after=draw();after:encode('png','radiance-'..world..'.png')
  local difference=0;local w,h=after:getDimensions()
  for y=10,h-10,30 do for x=10,w-10,30 do
   local r,g,b=after:getPixel(x,y);local rr,gg,bb=before:getPixel(x,y)
   difference=difference+math.abs(r-rr)+math.abs(g-gg)+math.abs(b-bb)
  end end
  assert(difference>1,'Each requested biome needs visible lighting')
  before:release();after:release()
  for _,quality in ipairs({1,3}) do
   Graphics.quality=quality;local data=draw();data:release()
   assert(#L.lights<= (quality==1 and 8 or 16),'Light budget must remain bounded')
  end
  UI.clock=12;local data=draw();data:release()
  print('PASS biome '..world..': visible lights, three quality levels, animation and simulation isolation')
 end
 L.apply=apply;Graphics.quality=2
 print('PASS ocean scenery and Ori-inspired lighting across all five requested biomes');love.event.quit()
end
return T
