-- End-to-end draw benchmark: the regular scene, materials, atmosphere, final
-- postprocess and HUD stay enabled. Physics is a frozen reproducible snapshot.
local T={}
local g=love.graphics
local json=require('json')

local function physicalState()
 local state={world=Campaign.world,level=player.level,timer=timer,walls=Arena.walls,
  player={player.x,player.y,player.hitBox_width,player.hitBox_height},mobs={}}
 for i,m in ipairs(mobs) do
  state.mobs[i]={type=m.type,x=m.x,y=m.y,w=m.hitBox_width,h=m.hitBox_height,
   ox=m.hitBox_offset_x,oy=m.hitBox_offset_y,rotation=m.rotation,active=m.active}
 end
 return json.encode(state)
end

local function percentile(values,q)
 table.sort(values)
 return values[math.max(1,math.ceil(#values*q))]
end

local function prepareAbyss(update)
 local arrival=require('mobs.bosses.abyss.arrival')
 local boss=assert(arrival.current)
 local move=Input.move
 local swimming=0
 Input.move=function()
  if not arrival.current and swimming<.55 then return math.sqrt(.5),math.sqrt(.5) end
  return 0,0
 end
 for _=1,240 do if not arrival.current then break end;update(1/60) end
 assert(not arrival.current,'The Abyss arrival must complete before benchmarking')
 while boss.swimHead.x<Arena.width*.37 and swimming<3 and player.death==0 do
  update(1/60);swimming=swimming+1/60
 end
 Input.move=move
 assert(player.death==0 and App.state=='playing','The Abyss benchmark must show a live encounter')
end

function T.run()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false
 LevelLayouts.disabled=true;Profile.save=function()end;Bestiary.save=function()end
 love.focus=function()end;Input.move=function()return 0,0 end;Input.slow=function()return true end
 Profile.character=1;Profile.unlocked=7;Profile.language='fr'
 -- Other isolated tests may have saved reward cosmetics. Hold those constant
 -- too, so before/after captures do not add or remove a cosmetic effect.
 Profile.achievements={};Profile.completed={};Profile.scores={};Profile.skinGrants={}
 Profile.skinEffects={};Profile.tearExtension=false;Profile.topRecords={};Profile.storyTexts={}
 Hardcore.completed={}
 require('achievement_notice').init();require('skin_unlock').init()
 Graphics.quality=2;Graphics.effects=true;Graphics.psychedelic=2;Graphics.showFPS=false;Graphics.vsync=0;Graphics.limit=0
 love.window.setMode(1920,1200,{resizable=true,fullscreen=false,vsync=0})
 local Material=require('prism_material');Material.enabled=true
 local originalBegin=Material.beginScene
 local sceneCanvas
 Material.beginScene=function(canvas)sceneCanvas=canvas;return originalBegin(canvas)end
 local update,draw=love.update,love.draw
 local realTime=love.timer.getTime
 local drawTime=0
 local function animationTime()return drawTime end
 local renderer,version,vendor,device=g.getRendererInfo()
 local w,h=g.getDimensions();local pw,ph=g.getPixelDimensions()
 print(string.format('FRAME_PERF renderer=%s version=%s vendor=%s device=%s logical=%dx%d physical=%dx%d windowDPI=%.3f quality=2 effects=true psychedelic=2 material=true samples=36 warmup=12',
  renderer,version,vendor,device,w,h,pw,ph,love.window.getDPIScale()))
 local tasks={{world=1,level=9},{world=6,level=9},{world=5,level=9},{world=4,level=9},
  {world=2,level=9},{world=4,level=10},{world=7,level=10},{world=1,level=9,pickup=true}}
 local fenceMode
 local function fence()
  g.flushBatch()
  if not fenceMode then
   local ok,pixels=pcall(sceneCanvas.newImageData,sceneCanvas,1,1,0,0,1,1)
   if ok then
    assert(pixels:getWidth()==1 and pixels:getHeight()==1)
    pixels:release();fenceMode='1px GPU readback included'
   else fenceMode='whole scene GPU readback included' end
   print('FRAME_PERF sync='..fenceMode)
  end
  local pixels
  if fenceMode=='1px GPU readback included' then pixels=sceneCanvas:newImageData(1,1,0,0,1,1)
  else pixels=sceneCanvas:newImageData() end
  pixels:release()
 end
 local started=love.timer.getTime()
 for _,task in ipairs(tasks) do
  love.math.setRandomSeed(73129+task.world*100+task.level)
  App.hardcore=false;App.singleLevel=true;App.practice=task.level;App.start(task.world)
  if task.world==7 then prepareAbyss(update) else update(1/60) end
  if task.world==4 and task.level==10 then
   Octopus.enraged=true;Octopus.releaseCrabs();Octopus.releaseCrabs()
   for _,crab in ipairs(Octopus.crabs) do crab.emerge=nil end
  end
  for _,m in ipairs(mobs) do if m.imgs then m.dir='down';m.img=m.imgs.down or m.imgs.up end end
  local psyche=require('psychedelic_fx')
  psyche.reset()
  if task.pickup then psyche.collect(player.x+15,player.y+12);psyche.update(.12) end
  local physics=physicalState();local rng=love.math.getRandomState()
  local cpu,total,calls,switches={},{},{},{}
  for frame=1,48 do
   UI.clock=10+frame/60
   drawTime=UI.clock
   local statsBefore=g.getStats()
   local t0=love.timer.getTime()
   -- Legacy creature glows use wall time. Freeze only their clock while drawing;
   -- measurements and the GPU fence still use the real monotonic timer.
   love.timer.getTime=animationTime
   draw()
   love.timer.getTime=realTime
   g.flushBatch()
   local t1=love.timer.getTime()
   local statsAfter=g.getStats()
   fence()
   local t2=love.timer.getTime()
   assert(love.math.getRandomState()==rng,'Measured drawing must not consume gameplay RNG')
   assert(physicalState()==physics,'Measured drawing must not alter physics or collision state')
   if frame>12 then
    cpu[#cpu+1]=(t1-t0)*1000;total[#total+1]=(t2-t0)*1000
    calls[#calls+1]=(statsAfter.drawcalls or 0)-(statsBefore.drawcalls or 0)
    switches[#switches+1]=(statsAfter.shaderswitches or 0)-(statsBefore.shaderswitches or 0)
   end
  end
  local label=string.format('world%d-level%d%s',task.world,task.level,task.pickup and '-pickup' or '')
  print(string.format('FRAME_PERF %s scene=%dx%d density=%.3f mobs=%d crabs=%d CPU_median=%.3fms CPU_p95=%.3fms SYNC_median=%.3fms SYNC_p95=%.3fms drawcalls_median=%.0f shaderswitches_median=%.0f (%s)',
   label,sceneCanvas:getPixelWidth(),sceneCanvas:getPixelHeight(),sceneCanvas:getDPIScale(),#mobs,
   Octopus.active and #Octopus.crabs or 0,percentile(cpu,.5),percentile(cpu,.95),
   percentile(total,.5),percentile(total,.95),percentile(calls,.5),percentile(switches,.5),fenceMode))
  if (task.world==1 and not task.pickup) or (task.world==4 and task.level==10) then
   -- Capture the native-density arena after timings. Both runs use this exact
   -- clock and the same seeded frozen actors for visual A/B comparison.
   assert(UI.clock==10+48/60)
   assert(love.filesystem.createDirectory('frame-perf'))
   local path='frame-perf/'..label..'.png'
   local pixels=sceneCanvas:newImageData()
   local encoded=pixels:encode('png',path);encoded:release();pixels:release()
   print('CAPTURE '..love.filesystem.getSaveDirectory()..'/'..path)
  end
  assert(love.timer.getTime()-started<140,'The frame benchmark must remain bounded')
 end
 Material.beginScene=originalBegin
 print('PASS frame performance: eight full-render snapshots; native scene DPI; animated backgrounds; real materials, atmosphere, postprocess and HUD; drawing preserves RNG and physics; sync timings include GPU readback')
 io.stdout:flush();love.event.quit()
end

return T
