local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;LevelLayouts.disabled=true;Campaign.select(4);player.level=10;reset_level();App.state='playing'
 local g=love.graphics;local canvas=g.newCanvas(1920,1200);local o=Octopus;o.enraged=true;player.x=60;player.y=500
 for i=1,4 do o.releaseCrabs() end
 for _,c in ipairs(o.crabs) do c.emerge=nil end
 local start=love.timer.getTime();local kill=Hazards.kill;Hazards.kill=function() end
 for i=1,180 do o.updateCrabs(1/60) end
 print(string.format('BENCH 32 crab simulation %.3f ms',(love.timer.getTime()-start)*1000/180));Hazards.kill=kill
 local function draw()
  g.push('all');g.setCanvas(canvas);g.origin();g.clear();g.scale(2);o.draw();g.setCanvas();g.pop()
  local pixels=canvas:newImageData();pixels:release()
 end
 draw();start=love.timer.getTime()
 for i=1,30 do o.angle=i*.02;draw() end
 print(string.format('BENCH octopus 1920px render with GPU readback %.3f ms',(love.timer.getTime()-start)*1000/30))
 canvas:release();io.stdout:flush();love.event.quit(0)
end
return T
