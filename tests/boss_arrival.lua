local T={}
function T.run()
 local F=require 'boss_arrival';local g=love.graphics
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 App.hardcore=false;App.singleLevel=true;Graphics.effects=true;Graphics.showFPS=false
 local worlds={1,2,5,4,6,7,3};local kinds={'merle','wasp','hedgehog','octopus','storm','skeleton_fish','final_spider'}
 for _,kind in ipairs(kinds) do
  local sheet=assert(F.sheets[kind],'PNG must be loaded before gameplay');assert(#sheet.frames==16)
  local data=love.image.newImageData('assets/effects/boss-arrivals/'..kind..'.png')
  local _,_,_,alpha=data:getPixel(0,0);assert(alpha==0,'Atlas background must be transparent');data:release()
 end
 local tasks={};for i,w in ipairs(worlds) do tasks[#tasks+1]={w=w,kind=kinds[i]} end
 local index=0;local drawn=true;local draw=love.draw
 love.update=function()
  if not drawn then return end;drawn=false;index=index+1
  local task=tasks[index]
  if not task then
   -- Independent copies of bosses must each receive an entrance, exactly once.
   App.practice=1;App.start(1);F.reset()
   local a={active=true,x=100,y=100,hp=5,name='A'};local b={active=true,x=300,y=100,hp=5,name='B'}
   F.observe('merle',a,'a');F.observe('merle',b,'b');F.observe('merle',a,'a');assert(#F.events==2)
   local e=F.events[1];Replay.ghost=true;F.reset();F.update(2);assert(F.events[1]==e);Replay.ghost=false
   local drawImage=g.draw;Graphics.effects=false;g.draw=function()error('Disabled entrances must not draw')end;F.draw(false);F.draw(true);g.draw=drawImage;Graphics.effects=true
   F.update(2);assert(#F.events==0,'Entrance must expire without re-triggering')
   print('PASS PNG boss arrivals: seven preloaded transparent atlases, all 112 frames in order at every quality, seven bosses, bosses hidden and inert until the final frame, including passive queen, shortened retries, independent duplicates, ghost isolation, settings, expiration, no RNG/HP/position changes or runtime GPU allocations')
   love.event.quit();return
  end
  App.practice=task.w==3 and 1 or 10;App.start(task.w)
  assert(#F.events==1 and F.events[1].kind==task.kind,'Missing arrival: '..task.kind)
  local e=F.events[1];assert(not e.retry)
  assert(F.waiting(e.boss),'Boss must wait for its arrival to finish')
  local px,py=player.x,player.y;local before=player.death
  player.x=(e.boss.x or e.x)-15;player.y=(e.boss.y or e.y)-12
  local actorState={e.boss.hp,e.boss.x,e.boss.y,e.boss.clock,e.boss.elapsed,e.boss.phaseTime}
  e.boss.update(.4);if e.boss.contact then e.boss.contact() end
  assert(not player.reset and player.death==before,'Invisible boss cannot injure the player')
  local after={e.boss.hp,e.boss.x,e.boss.y,e.boss.clock,e.boss.elapsed,e.boss.phaseTime}
  for i=1,6 do assert(actorState[i]==after[i],'Boss AI cannot advance during entrance') end
  player.x,player.y=px,py
  local body=e.boss.draw or e.boss.drawBones;local rawDraw=g.draw
  g.draw=function()error('Boss sprite appeared before the end of the PNG sequence')end
  body(false);body(true)
  if e.boss.drawGround then e.boss.drawGround() end
  g.draw=rawDraw

  local state=love.math.getRandomState();local hp,x,y=e.boss.hp,e.boss.x,e.boss.y
  local image,shader,canvas=g.newImage,g.newShader,g.newCanvas
  local function forbidden()error('Entrances cannot allocate GPU resources')end
  g.newImage=forbidden;g.newShader=forbidden;g.newCanvas=forbidden
  F.load() -- Repeated preloading must reuse all textures and quads.
  for q=1,3 do Graphics.quality=q
   for frame=1,16 do
    e.age=(frame-.5)/16*e.duration;assert(F.frame(e)==frame,'Every painted frame must play in order')
    F.draw(false);F.draw(true)
   end
  end
  g.newImage=image;g.newShader=shader;g.newCanvas=canvas
  assert(love.math.getRandomState()==state and hp==e.boss.hp and x==e.boss.x and y==e.boss.y)
  F.update(e.duration-e.age+.001);assert(not F.waiting(e.boss),'Boss must unlock after the final frame')
  local draws=0;local originalDraw=g.draw;g.draw=function(...)draws=draws+1;return originalDraw(...)end
  body(false);body(true);g.draw=originalDraw;assert(draws>0,'Boss must actually render after the sequence')
  F.reset();F.scan();assert(#F.events==1 and F.events[1].retry and F.events[1].duration==.55,'Retries must be shorter')
  F.events[1].retry=false;F.events[1].duration=1.55;F.events[1].age=.48
 end
 love.draw=function()
  if not tasks[index] then drawn=true;return end
  draw()
  local dir=os.getenv('SILKEN_STYLE_CAPTURE_DIR')
  if dir then local name=tasks[index].kind
   g.captureScreenshot(function(data)
    local bytes=data:encode('png');local file=assert(io.open(dir..'/'..name..'.png','wb'))
    file:write(bytes:getString());file:close();bytes:release();data:release()
   end)
  end
  drawn=true
 end
end
return T
