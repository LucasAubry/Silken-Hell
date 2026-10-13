-- Exercise real updates, replay recording, respawns and rendering together.
local T={}
function T.run()
 Online.enabled=false;LevelLayouts.disabled=true;Replay.disabled=false;Replay.playing=false;Replay.ghost=false
 love.focus=function()end
 Profile.character=1;Profile.achievements={};Profile.skinEffects={};Profile.skinGrants={};Profile.scores={};Profile.completed={};Profile.storyTexts={};Profile.topRecords={}
 Hardcore.completed={};require('achievement_notice').init();require('skin_unlock').init()
 Graphics.quality=3;Graphics.limit=0;Graphics.vsync=0;love.window.setVSync(0)
 local g=love.graphics;local clock=love.timer.getTime
 local scene;local material=require('prism_material');local begin=material.beginScene
 material.beginScene=function(canvas)scene=canvas;return begin(canvas)end
 local frame=0
 Input.move=function()if Replay.input then return Replay.input[1],Replay.input[2]end;return math.floor(frame/40)%2==0 and 1 or -1,0 end
 Input.slow=function()return true end
 local audioTime,resetTime=0,0
 local audio=Audio.update;Audio.update=function(...)local t=clock();audio(...);audioTime=audioTime+clock()-t end
 local reset=reset_level;reset_level=function(...)local t=clock();reset(...);resetTime=resetTime+clock()-t end
 local function percentile(v,p)table.sort(v);return v[math.ceil(#v*p)]*1000 end
 for _,task in ipairs({{1,9},{6,9},{5,9},{4,9},{2,9},{4,10},{7,10}}) do
  App.hardcore=false;App.singleLevel=true;App.practice=task[2];App.start(task[1]);Audio.focus(true)
  local updates,draws={},{};audioTime=0;resetTime=0
  for i=1,240 do
   frame=i
   if i%60==0 then player.reset=true end
   local t=clock();love.update(1/60);updates[i]=clock()-t
   t=clock();love.draw();g.flushBatch()
   local pixels=scene:newImageData(1,1,0,0,1,1);pixels:release();draws[i]=clock()-t
  end
  print(string.format('GAMEPLAY_PERF world%d-level%d update_p95=%.3fms update_max=%.3fms render_p95=%.3fms render_max=%.3fms audio_total=%.3fms reset_total=%.3fms deaths=%d',task[1],task[2],percentile(updates,.95),percentile(updates,1),percentile(draws,.95),percentile(draws,1),audioTime*1000,resetTime*1000,player.death))
 end
 print('PASS gameplay performance: moving player, recording, forced respawns and full rendering across seven encounters')
 io.stdout:flush();love.event.quit()
end
return T
