local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 App.sessionLayout=nil;App.workshopMap=nil;App.preview=false;App.singleLevel=false;App.practice=nil;App.hardcore=false;Secret.duel=nil
 local E=Ending;local M=require('reunion_motion');local Walk=require('brown_walk')
 local function reset()
  Campaign.select(3);player.level=2;reset_level();App.state='playing';player.reset=false
  player.x=75;player.y=450
 end
 local dt=1/120
 for _,clock in ipairs({0,12,29}) do
  reset();E.clock=clock;E.partner.x=Arena.width*.5;E.partner.y=300
  local x,y=E.partner.x,E.partner.y;E.update(dt)
  local distance=math.sqrt((E.partner.x-x)^2+(E.partner.y-y)^2)
  assert(math.abs(distance/dt-440)<.001,'The reunion spider never slows with elapsed time')
  local gait={};Walk.advance(gait,distance,dt)
  assert(E.partner.walkMoving and math.abs(E.partner.walkPhase-gait.walkPhase)<.00001,'The partner shares the player stride cadence')
 end
 for _,width in ipairs({600,960,1440}) do
  for _,start in ipairs({{70,70},{width-70,70},{70,530},{width-70,530},{70,300},{width-70,300},{width/2,70},{width/2,530}}) do
   local p={x=start[1],y=start[2]};local facing,switches=nil,0
   for frame=1,240 do
    local x,y=p.x,p.y;local vx,vy=p.vx,p.vy
    M.advance(p,width/2,300,width,600,dt)
    assert(p.x>=M.margin and p.x<=width-M.margin and p.y>=M.margin and p.y<=600-M.margin,'Escape stays inside the arena')
    assert(math.abs(math.sqrt((p.x-x)^2+(p.y-y)^2)/dt-M.speed)<.001,'Turning along a wall retains full speed')
    if vx then assert(vx*p.vx+vy*p.vy>0,'No abrupt reversal at walls or corners') end
    if facing and p.facing~=facing then switches=switches+1 end;facing=p.facing
   end
   assert((p.x-start[1])^2+(p.y-start[2])^2>100^2,'Escape leaves the corner instead of shuttling in place')
   assert(switches<8,'Direction poses stay stable through turns')
  end
 end
 local a,b={x=480,y=300},{x=480,y=300}
 M.advance(a,200,300,960,600,dt);M.advance(b,760,300,960,600,dt)
 assert(a.x>480 and b.x<480,'Escape direction responds to the player')
 local copy={x=a.x,y=a.y,heading=a.heading,escapeSide=a.escapeSide,facing=a.facing}
 for i=1,240 do
  local px,py=480+math.sin(i*.04)*180,300+math.cos(i*.04)*100
  M.advance(a,px,py,960,600,dt);M.advance(copy,px,py,960,600,dt)
  assert(a.x==copy.x and a.y==copy.y,'Identical input produces identical escape movement')
 end
 for _,fps in ipairs({30,60,120}) do
  local p={x=850,y=280};local px,py=90,312
  for frame=1,fps*5 do
   local dx,dy=p.x-px,p.y-py;local distance=math.sqrt(dx*dx+dy*dy)
   if distance<43 then break end
   px=px+dx/distance*540/fps;py=py+dy/distance*540/fps
   local heading=p.heading
   M.advance(p,px,py,960,600,1/fps)
   if heading then
    local turn=math.abs(math.atan2(math.sin(p.heading-heading),math.cos(p.heading-heading)))
    assert(turn<=M.turnRate/fps+.00001,'A pursuing player cannot force an abrupt turn at a wall')
   end
  end
 end
 reset();E.phase='depart';local y=E.partner.y;E.update(.05)
 assert(math.abs(y-E.partner.y-M.speed*.05)<.001 and E.partner.walkMoving,'Departure keeps full speed and walking animation')
 local complete,award=E.complete,Achievements.award;local caught,reward=0,0
 E.complete=function()caught=caught+1 end;Achievements.award=function(id)assert(id=='heartbreak');reward=reward+1 end
 reset();E.clock=29.99;player.x=E.partner.x-15;player.y=E.partner.y-12;E.update(.02)
 assert(caught==1 and reward==0,'Contact still wins at the thirty-second deadline')
 reset();E.clock=29.99;E.update(.02)
 assert(E.phase=='depart' and reward==1,'The thirty-second departure and reward remain available')
 E.complete,Achievements.award=complete,award
 reset()
 -- Exercise the real player rig on every partner pose, and compare two strides.
 local g=love.graphics;local canvas=g.newCanvas(512,256)
 g.push('all');g.setCanvas(canvas);g.clear(.09,.11,.12,1)
 for row=1,2 do for i,angle in ipairs({0,math.pi/2,math.pi,-math.pi/2}) do
  E.partner.angle=angle;E.partner.walkMoving=true;E.partner.walkPhase=(row-1)*math.pi/2
  E.partner.x=i*128-64;E.partner.y=row*128-64;E.drawFamily()
 end end
 g.pop()
 local data=canvas:newImageData();local changed=0
 for y=20,107 do for x=20,107 do
  local r1,g1,b1=data:getPixel(x,y);local r2,g2,b2=data:getPixel(x,y+128)
  if math.abs(r1-r2)+math.abs(g1-g2)+math.abs(b1-b2)>.08 then changed=changed+1 end
 end end
 assert(changed>50,'Partner legs visibly animate between strides')
 local file=assert(io.open('/tmp/silken-reunion-walk.png','wb'));file:write(data:encode('png'):getString());file:close()
 data:release();canvas:release()
 print('PASS reunion: constant speed, smooth corner escape, player-driven steering, deterministic replay, shared visible walking rig and thirty-second endings')
 love.event.quit()
end
return T
