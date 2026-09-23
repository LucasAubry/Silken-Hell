local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;LevelLayouts.disabled=true
 local g=love.graphics
 local canvas=g.newCanvas(1920,1080)
 local function bench(world,raw)
  local start=love.timer.getTime()
  for frame=1,20 do
   g.push('all');g.setCanvas(canvas);g.origin();g.setColor(1,1,1)
   if raw then
    BiomeFloor.shader:send('biome',world);BiomeFloor.shader:send('clock',frame/30);BiomeFloor.shader:send('dimensions',{1920,1080})
    g.setShader(BiomeFloor.shader);g.rectangle('fill',0,0,1920,1080)
   else BiomeFloor.draw(world,1920,1080,frame/30) end
   g.setCanvas();g.pop()
   local pixels=canvas:newImageData();pixels:release()
  end
  return (love.timer.getTime()-start)*1000/20
 end
 for _,world in ipairs({1,2,3,4,5,7,8}) do
  bench(world,false);bench(world,true)
  print(string.format('PERF world %d background 1080p: raw %.3f ms, cached %.3f ms (GPU readback included)',world,bench(world,true),bench(world,false)))
 end
 canvas:release()
 -- All original spawners must reuse textures across deaths and wave spawns.
 local spawns={spawn_boss,spawn_snake,spawn_scie,spawn_piege,spawn_ange}
 for _,spawn in ipairs(spawns) do spawn(100,100,1) end
 local original=g.newImage;local uploads=0
 g.newImage=function(...) uploads=uploads+1;return original(...) end
 local start=love.timer.getTime()
 for i=1,100 do load_mob();for _,spawn in ipairs(spawns) do spawn(100,100,1) end end
 g.newImage=original
 assert(uploads==0,'Repeated spawns must not decode/upload images')
 print(string.format('PASS 500 monster spawns: zero texture uploads, %.3f ms total',(love.timer.getTime()-start)*1000))
 -- Cache invalidation, graphics-state preservation and static cave reuse.
 BiomeFloor.draw(5,960,600,1);local cached=BiomeFloor.cache;local tick=cached.tick
 BiomeFloor.draw(5,960,600,50);assert(BiomeFloor.cache==cached and cached.tick==tick)
 BiomeFloor.draw(4,1200,600,50);assert(BiomeFloor.cache.world==4 and BiomeFloor.cache.w==Graphics.floorHeight()*2)
 -- Custom maps and fullscreen backdrops often have different aspect ratios.
 BiomeFloor.draw(4,960,600,51);BiomeFloor.draw(4,1200,600,51)
 local newCanvas=g.newCanvas;local allocations=0
 g.newCanvas=function(...) allocations=allocations+1;return newCanvas(...) end
 for frame=1,60 do BiomeFloor.draw(4,960,600,frame/30);BiomeFloor.draw(4,1200,600,frame/30) end
 g.newCanvas=newCanvas
 assert(allocations==0 and #BiomeFloor.surfaces==2,'Letterbox rendering must reuse both bounded surfaces')
 print('PASS custom map + desktop: zero canvas allocations over 60 frames')
 local captures={1,2,3,4,5,7};local i=0
 love.update=function(dt)
  i=i+1;UI.clock=UI.clock+dt
  if i<=#captures then Campaign.select(captures[i]);player.level=10;reset_level();App.state='playing';App.capture='performance-world-'..captures[i]..'.png'
  else print('PASS performance regression checks');io.stdout:flush();love.event.quit(0) end
 end
 io.stdout:flush()
end
return T
