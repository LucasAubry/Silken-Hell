-- The Merle swings captive snails on silk. Only freed snails damage him.
local Timing=require('boss_attack_timing')
local S={active=false}
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function length(x,y)return math.sqrt(x*x+y*y)end
local function airborne()return player.throw or player.whirl or player.skyThrow or player.skyWhirl end
local function setting(k,v)return Timing.get(S,k,v)end
local function segmentDistance(x,y,ax,ay,bx,by)
 local dx,dy=bx-ax,by-ay;local d=dx*dx+dy*dy
 local t=d>0 and clamp(((x-ax)*dx+(y-ay)*dy)/d,0,1) or 0
 return length(x-ax-t*dx,y-ay-t*dy),t
end
function S.anchor()
 return S.x-math.cos(S.angle)*42,S.y-math.sin(S.angle)*32
end
function S.spawnSnails()
 S.snails={};local ax,ay=S.anchor();local nx,ny=-math.sin(S.angle),math.cos(S.angle)
 for i=1,S.wave do
  local rope=145+(i-1)*28;local spread=(i-(S.wave+1)/2)*25
  S.snails[i]={id=i,x=ax-math.cos(S.angle)*rope+nx*spread,y=ay-math.sin(S.angle)*rope+ny*spread,
   vx=S.vx*.6,vy=S.vy*.6,rope=rope,phase='tethered',age=0,angle=S.angle,lift=0}
 end
end
function S.setPhase(phase)
 S.phase=phase;S.phaseAge=0
 if phase=='tell' then
  local side=S.wave%2==1 and 1 or -1
  S.x=side==1 and -100 or Arena.width+100
  S.y=clamp(math.floor((player.y+12)*1000+.5)/1000+(S.wave%2==1 and -120 or 120),90,510)
  local dx,dy=player.x+15-S.x,player.y+12-S.y;local d=math.max(1,length(dx,dy))
  S.angle=math.atan2(dy,dx);S.vx=dx/d*650;S.vy=dy/d*650
  S.phaseTime=setting('hidden',.9);S.dir=side==1 and 'right' or 'left';S.spawnSnails()
 elseif phase=='charge' then
  S.phaseTime=(Arena.width+220)/650
 elseif phase=='hunt' then
  S.turnClock=0;S.phaseTime=setting('huntDuration',18);S.turnSign=S.wave%2==1 and 1 or -1
 elseif phase=='clean' then
  S.cleanIndex=#S.holes;S.phaseTime=999;S.groundRevision=S.groundRevision+1
 elseif phase=='leave' then
  S.exitX=S.x<Arena.width/2 and -220 or Arena.width+220;S.phaseTime=2
 elseif phase=='return' then
  S.phaseTime=setting('returnDelay',.7)
 end
end
function S.reset(active)
 S.active=active;S.name='Merle noir';S.hp=10;S.maxHp=10;S.defeated=false;S.hidden=false
 S.wave=1;S.clock=0;S.flash=0;S.contactGrace=0;S.vx=0;S.vy=0;S.angle=0
 S.playerX=player.x+15;S.playerY=player.y+12
 S.snails={};S.holes={};S.bursts={};S.projectiles={};S.groundRevision=0;S.trailKeys={}
 S.nest={x=Arena.width-105,y=115};S.setPhase('tell')
end
function S.holeAt(x,y)
 if not S.active or S.defeated then return false end
 for _,p in ipairs(S.holes)do
  if p.radius>0 and x>=math.min(p.x,p.tx)-p.radius and x<=math.max(p.x,p.tx)+p.radius
   and y>=math.min(p.y,p.ty)-p.radius and y<=math.max(p.y,p.ty)+p.radius
   and segmentDistance(x,y,p.x,p.y,p.tx,p.ty)<p.radius then return true end
 end
 return false
end
function S.cut(p)
 if p.phase~='tethered' then return end
 p.phase='rise';p.age=0;p.vx=p.vx*.15;p.vy=p.vy*.15;p.lift=0
 S.bursts[#S.bursts+1]={x=p.x,y=p.y,age=0,kind='cut'}
end
function S.finish()
 S.holes={};S.snails={}
 require('boss_liberation').start(S,'storm',function()
  S.defeated=true;objet.larme.taken=false
  objet.larme.x,objet.larme.y=Arena.clearSpot(clamp(S.x,70,Arena.width-70)-15,clamp(S.y,85,515)-20,30,40)
 end)
end
function S.contact()
 if not S.active or S.defeated or player.reset or S.phase=='tell' or S.phase=='return' then return end
 local px,py=player.x+15,player.y+12;local ax,ay=S.anchor()
 local moving=(px-(S.playerX or px))^2+(py-(S.playerY or py))^2>.01
 S.playerX,S.playerY=px,py
 -- Bodies are lethal, while the open length of silk can be crossed on foot.
 for _,p in ipairs(S.snails)do if p.phase=='tethered' and (p.lift or 0)<8 then
  if require('collision_shapes').touchRect('storm_snail',p.x-12,p.y-11,24,22) then Hazards.kill('cloud_snail');return end
 end end
 if S.phase=='charge' or S.phase=='hunt' then
  for _,p in ipairs(S.snails)do if p.phase=='tethered' then
   local distance,t=segmentDistance(px,py,ax,ay,p.x,p.y)
   if moving and distance<12 and t>.12 and t<.87 then S.cut(p)end
  end end
 end
 if S.holeAt(px,py) and not airborne() then Hazards.kill('storm');if player.reset then player.falling=true end;return end
 if S.phase~='clean' and S.phase~='leave' and length(px-S.x,py-S.y)<47 and S.contactGrace<=0 then
  S.contactGrace=.45;local dx,dy=math.cos(S.angle),math.sin(S.angle)
  for i=1,10 do Arena.move(player,dx*4,dy*4)end
 end
end
local function trail(p)
 if p.x<25 or p.x>Arena.width-25 or p.y<25 or p.y>575 then p.tx=nil;return end
 local speed=length(p.vx,p.vy);if speed<10 then return end
 local x,y=p.x-p.vx/speed*18,p.y-p.vy/speed*18
 if not p.tx then p.tx,p.ty=x,y;return end
 if length(x-p.tx,y-p.ty)<10 then return end
 local function key(a,b)return math.floor(a/8+.5)..':'..math.floor(b/8+.5)end
 local a,b=key(p.tx,p.ty),key(x,y);if a>b then a,b=b,a end
 local k=a..'/'..b
 if not S.trailKeys[k] then
  S.trailKeys[k]=true;S.holes[#S.holes+1]={x=p.tx,y=p.ty,tx=x,ty=y,radius=(require('cloud_snail').width+require('cloud_snail').mergeMargin)/2,owner=p.id}
 end
 p.tx,p.ty=x,y
end
function S.updateSnails(dt)
 local ax,ay=S.anchor();local pending=0
 for _,p in ipairs(S.snails)do
  p.age=p.age+dt
  if p.phase=='tethered' then
   pending=pending+1
   local dx,dy=ax-p.x,ay-p.y;local d=math.max(.001,length(dx,dy));local nx,ny=dx/d,dy/d
   -- Slack rope exerts no force. A taut rope pulls without removing tangential inertia.
   if d>p.rope then
    local radial=(p.vx-S.vx)*nx+(p.vy-S.vy)*ny
    local force=math.max(0,(d-p.rope)*65-radial*7)
    p.vx=p.vx+nx*force*dt;p.vy=p.vy+ny*force*dt
   end
   local friction=math.exp(-.85*dt);p.vx=p.vx*friction;p.vy=p.vy*friction
   local speed=length(p.vx,p.vy);if speed>1000 then p.vx=p.vx/speed*1000;p.vy=p.vy/speed*1000 end
   p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt
   dx,dy=p.x-ax,p.y-ay;d=math.max(.001,length(dx,dy))
   if d>p.rope*1.12 then
    p.x=ax+dx/d*p.rope*1.12;p.y=ay+dy/d*p.rope*1.12
    local outward=(p.vx-S.vx)*dx/d+(p.vy-S.vy)*dy/d
    if outward>0 then p.vx=p.vx-dx/d*outward;p.vy=p.vy-dy/d*outward end
   end
   if length(p.vx,p.vy)>1 then p.angle=math.atan2(p.vy,p.vx)end
   if S.phase=='hunt' or S.phase=='charge' then p.lift=math.max(0,p.lift-dt*60);trail(p)
   else p.lift=math.min(22,p.lift+dt*65)end
  elseif p.phase=='rise' then
   pending=pending+1;p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt
   local duration=setting('riseDuration',.65);local t=math.min(1,p.age/duration)
   p.lift=75*t*t*(3-2*t);p.angle=p.angle+dt*3
   if t>=1 then p.y=p.y-p.lift;p.lift=0;p.phase='strike';p.age=0 end
  elseif p.phase=='strike' then
   pending=pending+1;local dx,dy=S.x-p.x,S.y-p.y;local d=math.max(.001,length(dx,dy));local move=(850+p.age*650)*dt
   p.angle=math.atan2(dy,dx)
   if d<move+25 then
    p.phase='spent';S.hp=math.max(0,S.hp-1);S.flash=.5
    S.bursts[#S.bursts+1]={x=S.x,y=S.y,age=0,kind='impact'}
    if S.hp==0 then S.finish();return end
   else p.x=p.x+dx/d*move;p.y=p.y+dy/d*move end
  end
 end
 if pending==0 and (S.phase=='charge' or S.phase=='hunt') then S.advanceWave=true;S.setPhase('clean')end
end
local function moveToward(x,y,speed,dt)
 local dx,dy=x-S.x,y-S.y;local d=math.max(.001,length(dx,dy));local step=math.min(d,speed*dt)
 S.vx=dx/d*speed;S.vy=dy/d*speed;S.x=S.x+dx/d*step;S.y=S.y+dy/d*step;S.angle=math.atan2(dy,dx)
 return d<=step+1
end
local function clean(dt)
 -- Only the Merle's actual swept footprint seals a scar; remote holes remain open.
 for _,p in ipairs(S.holes)do
  if p.radius>0 and segmentDistance(S.x,S.y,p.x,p.y,p.tx,p.ty)<48 then p.closing=true end
  if p.closing and p.radius>0 then p.radius=math.max(0,p.radius-32*dt);S.groundRevision=S.groundRevision+1 end
 end
 if not S.holes[S.cleanIndex] or S.holes[S.cleanIndex].closing then
  local best=math.huge;S.cleanIndex=0
  for i,p in ipairs(S.holes)do if not p.closing then
   local d=(S.x-(p.x+p.tx)/2)^2+(S.y-(p.y+p.ty)/2)^2
   if d<best then best=d;S.cleanIndex=i end
  end end
 end
 if S.cleanIndex>0 then local p=S.holes[S.cleanIndex];moveToward((p.x+p.tx)/2,(p.y+p.ty)/2,850,dt)
 else
  local open=false;for _,p in ipairs(S.holes)do if p.radius>0 then open=true;break end end
  if not open then S.holes={};S.trailKeys={};S.setPhase('leave')end
 end
end
function S.update(dt)
 if not S.active or S.defeated or player.reset then return end
 local steps=math.max(1,math.ceil(dt/(1/120)));local step=dt/steps
 for _=1,steps do
  S.clock=S.clock+step;S.phaseAge=S.phaseAge+step;S.phaseTime=S.phaseTime-step
  S.flash=math.max(0,S.flash-step);S.contactGrace=math.max(0,S.contactGrace-step)
  for i=#S.bursts,1,-1 do local b=S.bursts[i];b.age=b.age+step;if b.age>.75 then table.remove(S.bursts,i)end end
  if S.phase=='tell' then if S.phaseTime<=0 then S.setPhase('charge')end
  elseif S.phase=='charge' then
   S.x=S.x+S.vx*step;S.y=S.y+S.vy*step
   if S.phaseAge>.65 and (S.x<210 or S.x>Arena.width-210 or S.y<150 or S.y>450) or S.phaseTime<=0 then S.setPhase('hunt')end
  elseif S.phase=='hunt' then
   S.turnClock=S.turnClock+step
   -- Aim past the player, then reverse the turn to swing the sliding cargo across them.
   local cycle=setting('turnInterval',2.1)/(S.attackRate or 1)
   local turn=math.floor(S.turnClock/cycle)%2==0 and S.turnSign or -S.turnSign
   local target=math.atan2(player.y+12-S.y,player.x+15-S.x)+turn*.85
   local border=S.x<180 or S.x>Arena.width-180 or S.y<160 or S.y>440
   if border then target=math.atan2(300-S.y,Arena.width/2-S.x) end
   local delta=(target-S.angle+math.pi)%(2*math.pi)-math.pi
   local turnRate=border and 4.2 or 2.5
   S.angle=S.angle+clamp(delta,-step*turnRate,step*turnRate)
   local speed=(border and 180 or 300+S.wave*18)*(S.movementRate or 1)
   S.vx,S.vy=math.cos(S.angle)*speed,math.sin(S.angle)*speed
   S.x=S.x+S.vx*step;S.y=S.y+S.vy*step
   if S.phaseTime<=0 then S.advanceWave=false;S.setPhase('clean')end
  elseif S.phase=='clean' then clean(step)
  elseif S.phase=='leave' then
   if moveToward(S.exitX,clamp(S.y,100,500),650,step) then S.setPhase('return')end
  elseif S.phase=='return' and S.phaseTime<=0 then
   if S.advanceWave then S.wave=S.wave+1 end
   S.setPhase('tell')
  end
  S.dir=Art.direction(math.cos(S.angle),math.sin(S.angle),S.dir)
  if S.phase~='tell' and S.phase~='return' then S.updateSnails(step)end
  S.contact()
  if player.reset or S.defeated then break end
 end
end
function S.resize(r)
 S.x=S.x*r;if S.exitX then S.exitX=S.exitX*r end
 S.nest.x=S.nest.x*r
 for _,p in ipairs(S.snails)do p.x=p.x*r;if p.tx then p.tx=p.tx*r end end
 for _,p in ipairs(S.holes)do p.x=p.x*r;p.tx=p.tx*r end
 S.groundRevision=S.groundRevision+1
end
function S.visibleBounds()return S.x-80,S.y-80,160,160 end
function S.drawGround()if S.active and not S.defeated then require('mobs.bosses.storm.ground').draw(S)end end
function S.draw()
 if not S.active or S.defeated and not S.liberating then return end
 local g=love.graphics;g.push('all')
 if S.phase=='tell' then
  local x=S.x<0 and 0 or Arena.width;local dir=S.x<0 and 1 or -1
  g.setColor(.95,.7,.15);g.polygon('fill',x,S.y-7,x+dir*(12+10*math.min(1,S.phaseAge/.3)),S.y,x,S.y+6)
 elseif S.phase~='return' then
  local ax,ay=S.anchor()
  for _,p in ipairs(S.snails)do if p.phase=='tethered' then
   local dy=p.y-(p.lift or 0);g.setLineWidth(3);g.setColor(.08,.16,.2,.65);g.line(ax,ay,p.x,dy)
   g.setLineWidth(1.3);g.setColor(.9,.97,1,.95);g.line(ax,ay,p.x,dy)
  end end
  for _,p in ipairs(S.snails)do if p.phase~='spent' then
   if p.phase=='tethered' then Art.contactShadow(p.x,p.y+7,12,4,.25)end
   require('mobs.bosses.storm.snail_art').draw(p,S.clock)
  end end
  local key=S.dir=='right' and 'merle_flight' or 'merle_flight_'..S.dir
  if not Art.images[key] then key='merle_'..S.dir end
  local a=Art.images[key];local scale=150/math.max(a.w,a.h);local flap=1+math.sin(S.clock*14)*.025
  g.setColor(1,1-S.flash*.4,1-S.flash*.4);Art.draw(key,S.x,S.y,a.w*scale*flap,0,a.h*scale/flap)
 end
 for _,b in ipairs(S.bursts)do
  local t=b.age/.75;local radius=b.kind=='impact' and 75 or 28
  g.setColor(.6,.9,1,(1-t)*.65);g.setLineWidth(2);g.circle('line',b.x,b.y,4+t*radius)
  for i=1,14 do local a=i*2.399;local r=t*radius;g.setColor(1,.9,.5,1-t);g.circle('fill',b.x+math.cos(a)*r,b.y+math.sin(a)*r,2.5*(1-t))end
 end
 g.pop()
end
return S
