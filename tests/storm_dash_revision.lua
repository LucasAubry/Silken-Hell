local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true;love.focus=function()end
 App.practice=10;App.singleLevel=true;App.start(6);player.reset=false
 local b=Storm
 local kill=Hazards.kill;Hazards.kill=function()end
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
 b.hurt(true);b.hurt(true);assert(b.hp==8 and b.phase=='orbit' and b.pendingDashes==0)
 b.hurt(true);assert(b.hp==7 and b.phase=='leave' and b.nextDashHP==5)
 local function finishPass()
  player.x=80;player.y=288;b.setPhase('flightTell');local y=b.startY
  player.y=480;b.update(.01);assert(b.startY==y and b.endY==y,'Warning locks its announced path')
  b.setPhase('flight');b.update(b.flightDuration+.001)
  assert(b.phase=='return' and b.pass==1,'One crossing, then return')
  b.update(.66);assert(b.phase=='orbit' and b.pendingDashes==0,'No automatic repeat')
 end
 finishPass();b.hurt(true);assert(b.hp==6 and b.phase=='orbit')
 b.hurt(true);assert(b.hp==5 and b.phase=='leave' and b.nextDashHP==4);finishPass()
 for hp=4,1,-1 do b.hurt(true);assert(b.hp==hp and b.phase=='leave');finishPass() end
 b.hurt(true);assert(b.defeated and require('boss_liberation').busy(),'Final HP triggers liberation, not a dash')
 reset_level();
 b.hurt(true);b.hurt(true);b.hurt(true);b.hurt(true);assert(b.pendingDashes==0)
 b.hurt(true);assert(b.pendingDashes==1 and b.nextDashHP==4,'Only a crossed HP threshold queues a dash')
 local sides={{80,288,'right'},{Arena.width-110,288,'left'},{Arena.width/2-15,75,'down'},{Arena.width/2-15,490,'up'}}
 local g=love.graphics
 for _,p in ipairs(sides) do
  player.x=p[1];player.y=p[2];b.setPhase('flightTell');assert(b.dir==p[3],'Player position chooses entry edge')
  local cross=(player.x+15-b.startX)*(b.endY-b.startY)-(player.y+12-b.startY)*(b.endX-b.startX)
  assert(math.abs(cross)<.01)
  local oldLine=g.line;g.line=function()error('The player arrow must be absent')end;b.draw();g.line=oldLine
  require('boss_hud').draw(b);assert(require('boss_hud').offsetY==0,'Storm health bar stays at the top')
 end
 print('PASS sky revision: independent smooth patrol, four flight directions, 60/120 FPS, fixed return, fewer lightning volleys, smaller body, 3/2/1 HP thresholds, one crossing, locked dash target, no arrow, fixed top HUD, immediate spawn')
 local draw=love.draw;local frame=0
 love.update=function()
  frame=frame+1
  if sides[frame] then local p=sides[frame];player.x=p[1];player.y=p[2];b.setPhase('flightTell') else love.event.quit()end
 end
 love.draw=function()
  draw();if sides[frame] then local path='/tmp/silken-storm-direction-'..sides[frame][3]..'.png'
   g.captureScreenshot(function(data)local file=assert(io.open(path,'wb'));file:write(data:encode('png'):getString());file:close()end)
  end
 end
end
return T
