local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 local g=love.graphics;local C=require('ocean_current');local clock=love.timer.getTime
 Graphics.quality=3;Graphics.effects=true
 local layouts=require('json').decode(love.filesystem.read('custom_levels.json')).levels
 local function p95(v)table.sort(v);return v[math.ceil(#v*.95)]*1000 end
 local results={}
 for _,n in ipairs({1,2,3}) do
  App.practice=n;App.singleLevel=true;App.start(4);require('run_start').active=false
  LevelLayouts.apply(layouts['4:'..n]);player.x=30;player.y=30
  local canvas=g.newCanvas(Arena.width,600);local frames,updates={},{}
  local kill=Hazards.kill;Hazards.kill=function()end
  for frame=1,100 do
   local t=clock()
   for _,school in ipairs(Realms.schools) do school.age=2.5;school.angle=.4 end
   for _,m in ipairs(mobs) do if m.type=='fish' then MobBehaviors.fish.update(m,1/60) end end
   C.velocity(480,300,300,0,Realms.current)
   local update=clock()-t
   g.push('all');g.setCanvas(canvas);g.origin();g.clear();t=clock()
   for _,e in ipairs(Realms.current) do C.draw(e,frame/60) end
   g.flushBatch();local elapsed=clock()-t;g.pop()
   if frame>10 then frames[#frames+1]=elapsed;updates[#updates+1]=update end
  end
  Hazards.kill=kill;canvas:release()
  local row={level=n,currentCPU=p95(frames),chargeCPU=p95(updates)};results[#results+1]=row
  print(string.format('OCEAN_PERF level=%d current_cpu_p95=%.3fms charge_update_p95=%.3fms',n,row.currentCPU,row.chargeCPU))
 end
 love.filesystem.write('ocean-performance.json',require('json').encode(results))
 print('PASS Ocean performance: saved maps, charging fish and dense current paths');love.event.quit()
end
return T
