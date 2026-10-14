local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true;love.focus=function()end
 App.practice=10;App.singleLevel=true;App.start(6);player.reset=false
 local b=Storm
 local kill=Hazards.kill;Hazards.kill=function()end
 local placeTarget=b.placeTarget;b.placeTarget=function()end
 local function patrol(movingPlayer,dt)
  b.reset(true);b.shot=1000;b.bolt=1000;b.rainClock=1000
  local samples={};local directions={};local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
  local px,py=b.x,b.y
  for i=1,math.floor(18/dt) do
   player.x=movingPlayer and 80+(i*23)%(Arena.width-160) or 80
   player.y=movingPlayer and 90+(i*17)%400 or 90
   b.update(dt)
   assert(math.sqrt((b.x-px)^2+(b.y-py)^2)<500*dt,'Patrol turns remain smooth')
   assert(b.x>90 and b.x<Arena.width-90 and b.y>90 and b.y<510,'Patrol stays inside the arena')
   px,py=b.x,b.y;directions[b.dir]=true
   minX=math.min(minX,b.x);maxX=math.max(maxX,b.x);minY=math.min(minY,b.y);maxY=math.max(maxY,b.y)
   if i%math.floor(.1/dt+.5)==0 then samples[#samples+1]={b.x,b.y} end
  end
  assert(maxX-minX>Arena.width*.5 and maxY-minY>260,'Patrol sweeps horizontally and vertically')
  assert(directions.left and directions.right and directions.up and directions.down,'The bird naturally turns in all four directions')
  return samples
 end
 local still=patrol(false,1/60);local moving=patrol(true,1/60);local faster=patrol(true,1/120)
 for i,p in ipairs(still) do
  assert(math.abs(p[1]-moving[i][1])+math.abs(p[2]-moving[i][2])<.001,'Moving the player never changes the patrol')
  assert(math.abs(p[1]-faster[i][1])+math.abs(p[2]-faster[i][2])<.01,'Flight is consistent at 60 and 120 FPS')
 end
 b.setPhase('return');local rx,ry=b.returnX,b.returnY
 player.x=Arena.width-90;player.y=510;b.setPhase('return')
 assert(b.returnX==rx and b.returnY==ry,'Return rejoins the patrol rather than chasing the player')
 b.reset(true);b.shot=1000;b.rainClock=1000
 local summon=b.summon;local volleys=0;b.summon=function()volleys=volleys+1 end
 for i=1,600 do b.update(.02)end
 assert(volleys==5,'Lightning volleys are spaced out over twelve seconds')
 b.summon=summon;Hazards.kill=kill
 b.reset(true);player.x=80;player.y=288
 local _,_,bw,bh=b.visibleBounds();assert(math.max(bw,bh)<160,'The boss silhouette is slightly smaller')
 b.shot=100;b.bolt=100
 local sides={{80,288,'right'},{Arena.width-110,288,'left'},{Arena.width/2-15,75,'down'},{Arena.width/2-15,490,'up'}}
 for i,p in ipairs(sides) do
  b.reset(true);b.shot=100;b.bolt=100;player.reset=false
  b.fallSide=i-1;player.x=p[1];player.y=p[2];b.setPhase('flightTell');assert(b.dir==p[3],'Fall side chooses entry edge')
  local sx,sy,ex,ey=b.startX,b.startY,b.endX,b.endY
  player.x=Arena.width/2;player.y=420;b.update(.01)
  assert(b.startX==sx and b.startY==sy and b.endX==ex and b.endY==ey,'Warning locks its announced path')
  b.setPhase('flight')
  if sy==ey then player.x=Arena.width/2;player.y=sy<300 and 480 or 100 else player.x=sx<Arena.width/2 and Arena.width-100 or 100;player.y=300 end
  b.update(b.flightDuration+.001)
  assert(b.phase=='return' and not player.reset,'One crossing, then return')
  b.update(.66);assert(b.phase=='orbit','No automatic repeat')
 end
 b.placeTarget=placeTarget
 print('PASS sky flight: independent smooth patrol, four directions, 60/120 FPS, fixed return, spaced lightning, smaller body, fall-side beak warning, one crossing and locked dash target')
 love.event.quit()
end
return T
