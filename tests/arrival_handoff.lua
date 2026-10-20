local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 Replay.disabled=true;Replay.playing=false;Replay.recording=false
 App.practice=nil;App.singleLevel=false;App.preview=false;App.sessionLayout=nil;Secret.duel=nil;App.hardcore=false
 Input.speedHeld=function()return false end
 Profile.completed={};Profile.levels={};Profile.transitionsSeen={}
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true;Profile.levels[w]=10 end
 local C=require('run_start');local g=love.graphics
 UI.draw=function()end;Input.draw=function()end;C.draw=function()end
 local function capture()
  local target=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  g.push('all');setCanvas(target);g.setCanvas=function(c,...)return setCanvas(c or target,...)end
  love.draw();g.setCanvas=setCanvas;setCanvas();g.pop()
  local image=target:newImageData();target:release();return image
 end
 for _,world in ipairs({6,5,4,7,2,3}) do
  App.start(world);assert(math.abs(C.arrivalDuration-6.7)<.00001,'Same full duration as Paradise to Sky')
  local scene=C.scene();local px,py=player.x,player.y;local rng=love.math.getRandomState()
  for i=1,133 do
   C.advance(.05)
   if world~=6 then
    local p=scene.pose(C.arrival)
    assert(p.mapAlpha==p.actorsAlpha,'One reveal for scenery and creatures')
    if C.arrival>6 then assert(p.mapAlpha==1,'Complete destination before handoff') end
   end
   if i==1 or i==65 or i==82 or i==98 or i==108 or i==132 then capture():encode('png','handoff-'..world..'-'..i..'.png') end
   assert(timer==0 and px==player.x and py==player.y and rng==love.math.getRandomState(),'Presentation does not simulate gameplay')
  end
  scene.advance(6.7);C.arrival=6.7
  local before=capture()
  if world==4 then
   local bubble=require('breathing_bubble');local draw=bubble.drawAt;local calls=0;local actual
   bubble.drawAt=function(bx,by,r,...)
    local gx,gy=g.transformPoint(bx,by);calls=calls+1;actual={gx,gy,r}
    return draw(bx,by,r,...)
   end
   capture();bubble.drawAt=draw
   local scale,x,y=App.viewport(g.getDimensions())
   local bx,by,r=bubble.headPosition(player.x+15,player.y+8,Characters.playerWidth,direction)
   assert(calls==1,'One bubble only during the Ocean arrival')
   assert(math.abs(actual[1]-(x+bx*scale))<.001 and math.abs(actual[2]-(y+by*scale))<.001 and math.abs(actual[3]-r*scale)<.001,'Cinematic bubble matches gameplay position and radius exactly')
  end
  C.arrival=nil;C.arrivalKind=nil
  local after=capture();local w,h=after:getDimensions();local scale,x,y=App.viewport(w,h)
  local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
  local sum,count=0,0
  for yy=50,h-50,8 do for xx=50,w-50,8 do
   if math.abs(xx-sx)>85*scale or math.abs(yy-sy)>85*scale then
    local r,gc,b=before:getPixel(xx,yy);local r2,g2,b2=after:getPixel(xx,yy)
    sum=sum+math.abs(r-r2)+math.abs(gc-g2)+math.abs(b-b2);count=count+3
   end
  end end
  assert(sum/count<.01,'No scenery cut at handoff: '..world..' '..sum/count)
  assert(C.active and C.advance(.1)==0,'Still waits for Space')
 end
 App.practice=1;App.singleLevel=true;App.start(5)
 assert(C.arrivalKind=='portal','First training entry has a portal')
 App.state='customVictory';App.restartCurrent()
 assert(not C.arrival and C.active and App.practice==1,'Training replay skips portal and waits for Space')
 assert(timer==0 and player.death==0 and C.press(Profile.keys.dash),'Fresh training attempt')
 print('PASS unified 6.7-second transitions, synchronized creatures, pixel handoffs and training replay')
 love.event.quit()
end
return T
