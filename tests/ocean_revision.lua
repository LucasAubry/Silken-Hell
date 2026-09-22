local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;LevelLayouts.disabled=false
 local layout={world=4,level=10,width=960,height=600,entities={{kind='spawn',x=100,y=500},{kind='tear',x=480,y=300},{kind='boss',type='octopus',x=480,y=300}}}
 Workshop.playLayout(layout);local boss=Bosses.items[1].boss;boss.enraged=true
 for i=1,4 do boss.releaseCrabs() end
 local kill=Hazards.kill;Hazards.kill=function() end
 local start=love.timer.getTime()
 for frame=1,180 do boss.update(1/60) end
 print(string.format('PERF custom octopus, %d crabs, update %.3f ms',#boss.crabs,(love.timer.getTime()-start)*1000/180))
 local g=love.graphics;local canvas=g.newCanvas(1920,1080)
 local function floorBench(raw)
  local start=love.timer.getTime()
  for i=1,15 do g.push('all');g.setCanvas(canvas);g.origin();if raw then BiomeFloor.shader:send('biome',4);BiomeFloor.shader:send('clock',i/30);BiomeFloor.shader:send('dimensions',{1920,1080});g.setShader(BiomeFloor.shader);g.rectangle('fill',0,0,1920,1080);g.setShader() else BiomeFloor.draw(4,1920,1080,i/30) end;g.setCanvas();g.pop();local pixels=canvas:newImageData();pixels:release() end
  return (love.timer.getTime()-start)*1000/15
 end
 floorBench();floorBench(true) -- warm shader compilation and GPU allocations
 print(string.format('PERF ocean background 1080p, raw %.3f ms vs cached %.3f ms (GPU readback included)',floorBench(true),floorBench()))
 g.setCanvas(canvas);g.origin();g.clear();boss.draw();g.flushBatch();g.setCanvas();local pixels=canvas:newImageData();pixels:release();g.setCanvas(canvas)
 start=love.timer.getTime()
 for i=1,30 do boss.rider={arm=1};player.x=50+i*5;player.y=480;boss.updateTether(1/60);boss.draw();g.flushBatch() end
 print(string.format('PERF pulling tentacle + crabs draw submission %.3f ms',(love.timer.getTime()-start)*1000/30))
 g.setCanvas();canvas:release();Hazards.kill=kill
 io.stdout:flush()
 local eggLayout=require('json').decode(love.filesystem.read('tests/egg_layout.json'))
 Workshop.playLayout(eggLayout)
 assert(not Raven.active and #Bosses.items==1 and #Bosses.items[1].boss.nests==6,'Saved map must contain six active nests')
 local drawArt=Art.draw;local nests=0
 Art.draw=function(key,...) if key=='nest' then nests=nests+1 end;return drawArt(key,...) end
 Raven.drawGround();Bosses.drawGround();Art.draw=drawArt
 assert(nests==6,'No ghost nests from disabled campaign boss')
 print('PASS real saved first-boss map: exactly six nests rendered, no inactive duplicates');io.stdout:flush()
 local tick=0
 love.update=function(dt)
  tick=tick+1;UI.clock=UI.clock+dt
  if tick==2 then App.capture='ocean-revision-six-nests.png' end
  if tick==5 then Workshop.playLayout(layout);App.capture='ocean-revision-light.png' end
  if tick==8 then local b=Bosses.items[1].boss;b.enraged=true;for i=1,4 do b.releaseCrabs() end;for _,c in ipairs(b.crabs) do c.emerge=nil;c.x=c.tx;c.y=c.ty end;App.capture='ocean-revision-crabs.png' end
  if tick==11 then love.event.quit(0) end
 end
end
return T
