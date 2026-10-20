local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=false;Replay.playing=false
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Graphics.effects=true;Graphics.quality=3;Graphics.limit=0;Graphics.vsync=0;love.window.setVSync(0)
 local dimensions=love.graphics.getPixelDimensions
 love.graphics.getPixelDimensions=function()local w,h=dimensions();return w*2,h*2 end
 local json=require('json');local clock=love.timer.getTime;local g=love.graphics
 local layouts=json.decode(love.filesystem.read('sky-live-layouts.json') or '{}')
 local surface=require('terrain_surface');local draw=surface.draw;local spent=0
 surface.draw=function(zones,kind,...)
  local t=clock();draw(zones,kind,...);spent=spent+clock()-t
 end
 local scene;local material=require('prism_material');local begin=material.beginScene
 material.beginScene=function(canvas)scene=canvas;return begin(canvas)end
 Input.move=function()return .7,.4 end;Input.slow=function()return true end
 local function p95(v)table.sort(v);return v[math.ceil(#v*.95)]*1000 end
 local results={}
 for _,n in ipairs({1,2,3,4,5,6,7,8,9,10}) do
  App.sessionLayout=layouts['6:'..n];App.singleLevel=true;App.practice=n;App.hardcore=false
  LevelLayouts.disabled=App.sessionLayout==nil;App.start(6);require('run_start').active=false
  local updates,renders={},{};spent=0;local builds=surface.builds
  for frame=1,120 do
   local t=clock();love.update(1/60);local update=clock()-t
   t=clock();love.draw();g.flushBatch()
   local data=scene:newImageData(1,1,0,0,1,1);data:release()
   if frame>20 then updates[#updates+1]=update;renders[#renders+1]=clock()-t end
  end
  local row={level=n,update=p95(updates),render=p95(renders),terrain=spent*1000/120,misses=surface.builds-builds,holes=#Realms.holes,mobs=#mobs}
  assert(row.misses<=1,'Lightning must not rebuild painted terrain each frame')
  results[#results+1]=row
  print(string.format('SKY_PERF level=%d holes=%d mobs=%d update_p95=%.2fms render_p95=%.2fms terrain_cpu_mean=%.2fms field_changes=%d',n,row.holes,row.mobs,row.update,row.render,row.terrain,row.misses))
 end
 love.filesystem.write('sky-perf-results.json',json.encode(results))
 material.beginScene=begin;surface.draw=draw;g.getPixelDimensions=dimensions
 print('PASS Sky performance: live saved levels, moving player, replay recording, respawns and GPU-synchronized frames')
 love.event.quit()
end
return T
