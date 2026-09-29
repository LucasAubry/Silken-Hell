local T={}
local C=require 'mobs.bosses.abyss.pattern_cycle'
local function reset()
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
 Campaign.select(7);player.level=10;reset_level();App.state='playing';player.reset=false
 player.x=Arena.width-60;player.y=540;return Abyss
end
function T.run()
 io.stdout:setvbuf('no')
 local kill=Hazards.kill;Hazards.kill=function() end
 for round=1,2 do
  local b=reset();b.round=round;C.enter(b,'retreat');local start=b.swimHead.x;C.update(b,.05);assert(math.abs(b.swimHead.x-start)<5)
  C.enter(b,'traverse');assert(b.swimDir==(round==1 and 1 or -1));assert(b.bones[1].flip==(round==2))
  start=b.swimHead.x;C.update(b,.05);assert(math.abs(b.swimHead.x-start)<2)
  local previous,seen=nil,0
  for _=1,700 do
   C.update(b,1/120)
   if b.lastDropX and b.lastDropX~=previous then
    if previous then assert(math.abs(previous-b.lastDropX)>=205) end
    previous=b.lastDropX;seen=seen+1
   end
   for _,p in ipairs(b.debris) do assert(p.vx==0 and p.vy==760) end
   assert(#b.swimTrail<45)
  end
  assert(seen>=2 and b.bones[2].y~=b.bones[5].y)
  C.update(b,.2);assert(b.phase=='returnHead' and b.swimHead.x<35)
  C.update(b,1);assert(b.phase=='fire' and b.swimHead.x==35)
 end
 for round=1,3 do
  local b=reset();b.round=round;C.enter(b,'fire');assert(b.laserCount==(round==3 and 2 or 1))
  b.phaseTime=1.15;local first=C.laserAngles(b);b.phaseTime=8.1;local last=C.laserAngles(b)
  if round==1 then assert(first[1]<-1.4 and last[1]>1.4)
  elseif round==2 then assert(first[1]>1.4 and last[1]<-1.4)
  else assert(first[1]<-1.4 and first[2]>1.4 and math.abs(last[1])<.001 and math.abs(last[2])<.001) end
  for _,time in ipairs({0,.5,2.1,4.2,6.2}) do b.phaseTime=time;C.geometry(b);assert(#b.beams==0 and not C.dangerAt(b,500,300)) end
 end
 Hazards.kill=kill
 local b=reset();b.round=3;C.enter(b,'fire');b.phaseTime=5.6;C.geometry(b)
 local ray=b.beams[1];player.x=ray.x+math.cos(ray.angle)*450-15;player.y=ray.y+math.sin(ray.angle)*450-12
 b.visibleSince=nil;C.contact(b);assert(not player.reset);C.draw(b);b.visibleSince=b.phaseTime-.2;C.contact(b);assert(player.reset)
 b=reset();C.enter(b,'traverse');b.debris={{x=player.x+15,y=player.y+12,vx=0,vy=760,w=18,h=64}};C.contact(b);assert(player.reset)
 print('PASS swimming: both directions, smooth movement, wave, fast spaced bones, bounded trail, sweeping/converging lasers, safe blink intervals, lethal visible hazards')
 love.event.quit()
end
return T
