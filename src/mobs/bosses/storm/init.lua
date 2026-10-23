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
local function pose()
 local flap=1+math.sin(S.clock*14)*.025
 return flap,math.cos(S.angle)<0 and -1 or 1
end
function S.anchor()
 -- The same transform as the sprite, at the tip of its lower tail feathers.
 local flap,flip=pose();local x,y=-60*flap,58*flip/flap
 local c,s=math.cos(S.angle),math.sin(S.angle)
 return S.x+x*c-y*s,S.y+x*s+y*c
end
function S.spawnSnails()
 S.snails={};local ax,ay=S.anchor();S.snailAnchorX,S.snailAnchorY=ax,ay;local nx,ny=-math.sin(S.angle),math.cos(S.angle)
 for i=1,S.wave do
  local slot=i-(S.wave+1)/2;local rope=110+math.abs(slot)*14;local spread=slot*52
  S.snails[i]={id=i,x=ax-math.cos(S.angle)*rope+nx*spread,y=ay-math.sin(S.angle)*rope+ny*spread,
   vx=S.vx*.6,vy=S.vy*.6,rope=rope,phase='tethered',age=0,angle=S.angle,lift=0}
 end
end
function S.setPhase(phase)
 S.phase=phase;S.phaseAge=0
 if phase=='tell' then
  local side=S.wave%2==1 and 1 or -1
  S.x=side==1 and -100 or Arena.width+100
  S.y=155
  local dx,dy=side,0;local d=1
  S.angle=math.atan2(dy,dx);S.vx=dx/d*650;S.vy=dy/d*650
  S.fogHits=0;S.fogAmount=0;S.fogTarget=0;S.smoke={};S.fogRows=0;S.cleanStage=nil
  S.phaseTime=setting('hidden',.9);S.dir=side==1 and 'right' or 'left';S.spawnSnails()
 elseif phase=='charge' then
  S.phaseTime=(Arena.width*.5+100)/650
 elseif phase=='hunt' then
  S.turnClock=0;S.phaseTime=setting('huntDuration',18);S.turnSign=S.wave%2==1 and 1 or -1;S.flightSpeed=length(S.vx,S.vy)
 elseif phase=='clean' then
  S.phaseTime=999;S.groundRevision=S.groundRevision+1
  require('mobs.bosses.storm.sweep').begin(S)
 elseif phase=='leave' then
  S.exitX=S.x<Arena.width/2 and -220 or Arena.width+220;S.phaseTime=2
 elseif phase=='return' then
  S.phaseTime=setting('returnDelay',.7)
 end
end
function S.reset(active)
 S.active=active;S.name='Merle noir';S.hp=10;S.maxHp=10;S.defeated=false;S.hidden=false
 S.wave=1;S.clock=0;S.flightSpeed=0;S.flash=0;S.contactGrace=0;S.vx=0;S.vy=0;S.angle=0
 S.playerX=player.x+15;S.playerY=player.y+12
 S.snails={};S.holes={};S.bursts={};S.projectiles={};S.groundRevision=0;S.trailKeys={}
 S.nest={x=Arena.width-105,y=115};S.setPhase('tell')
end
function S.holeAt(x,y)
 if not S.active or S.defeated or S.phase=='clean' then return false end
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
 S.holes={};S.snails={};S.fogAmount=0
 require('boss_liberation').start(S,'storm',function()
  S.defeated=true;objet.larme.taken=false
  objet.larme.x,objet.larme.y=Arena.clearSpot(clamp(S.x,70,Arena.width-70)-15,clamp(S.y,85,515)-20,30,40)
 end)
end
function S.contact()
 if not S.active or S.defeated or player.reset or S.phase=='tell' or S.phase=='return' or S.phase=='clean' then return end
 local px,py=player.x+15,player.y+12;local ax,ay=S.anchor()
 if require('collision_shapes').touchCircle('storm_body',S.x,S.y,47) then Hazards.kill('storm');return end
 local moving=(px-(S.playerX or px))^2+(py-(S.playerY or py))^2>.01
 S.playerX,S.playerY=px,py
 -- Bodies are lethal, while the open length of silk can be crossed on foot.
 for _,p in ipairs(S.snails)do if p.phase=='tethered' and (p.lift or 0)<8 then
  if require('collision_shapes').touchRect('storm_snail',p.x-16,p.y-14,32,28) then Hazards.kill('cloud_snail');return end
 end end
 if S.phase=='charge' or S.phase=='hunt' then
  for _,p in ipairs(S.snails)do if p.phase=='tethered' then
   local distance,t=segmentDistance(px,py,ax,ay,p.x,p.y)
   if moving and distance<12 and t>.12 and t<.87 then S.cut(p)end
  end end
 end
 if S.holeAt(px,py) and not airborne() then Hazards.kill('storm');if player.reset then player.falling=true end;return end

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
 S.snailAnchorX,S.snailAnchorY=ax,ay
 local forwardX,forwardY=math.cos(S.angle),math.sin(S.angle)
 local baseX,baseY=ax-forwardX*110,ay-forwardY*110
 -- Keep the fan reachable during the hunt instead of throwing captives offscreen.
 if S.phase=='hunt' then baseX=clamp(baseX,125,Arena.width-125);baseY=clamp(baseY,135,465) end
 for _,p in ipairs(S.snails)do
  p.age=p.age+dt
  if p.phase=='tethered' then
   pending=pending+1
   local slot=p.id-(S.wave+1)/2
   local tx=baseX-forwardX*math.abs(slot)*14-forwardY*slot*52
   local ty=baseY-forwardY*math.abs(slot)*14+forwardX*slot*52
   local dx,dy=tx-p.x,ty-p.y;local d=math.max(.001,length(dx,dy))
   local move=math.min(d*(1-math.exp(-7*dt)),650*dt)
   local mx,my=dx/d*move,dy/d*move
   p.x,p.y=p.x+mx,p.y+my;p.vx,p.vy=mx/math.max(dt,.0001),my/math.max(dt,.0001)
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
    require('mobs.bosses.storm.fog').impact(S)
   else p.x=p.x+dx/d*move;p.y=p.y+dy/d*move end
  end
 end
 if pending==0 and (S.phase=='charge' or S.phase=='hunt') then S.advanceWave=true;S.setPhase('clean')end
end
local function moveToward(x,y,speed,dt)
 local dx,dy=x-S.x,y-S.y;local d=math.max(.001,length(dx,dy))
 local desired=math.min(speed,math.sqrt(2*1400*d))
 local dvx,dvy=dx/d*desired-S.vx,dy/d*desired-S.vy
 local change=length(dvx,dvy);local blend=math.min(1,1800*dt/math.max(.001,change))
 S.vx,S.vy=S.vx+dvx*blend,S.vy+dvy*blend
 S.x,S.y=S.x+S.vx*dt,S.y+S.vy*dt
 if length(S.vx,S.vy)>1 then
  local delta=(math.atan2(S.vy,S.vx)-S.angle+math.pi)%(2*math.pi)-math.pi
  S.angle=S.angle+clamp(delta,-3.4*dt,3.4*dt)
 end
 return d<5
end
local function clean(dt)
 if require('mobs.bosses.storm.sweep').update(S,dt,moveToward) then
  if S.hp==0 then S.finish() else S.setPhase('leave') end
 end
end
function S.update(dt)
 if not S.active or S.defeated or player.reset then return end
 local steps=math.max(1,math.ceil(dt/(1/120)));local step=dt/steps
 for _=1,steps do
  require('mobs.bosses.storm.fog').update(S,step)
  S.clock=S.clock+step;S.phaseAge=S.phaseAge+step;S.phaseTime=S.phaseTime-step
  S.flash=math.max(0,S.flash-step);S.contactGrace=math.max(0,S.contactGrace-step)
  for i=#S.bursts,1,-1 do local b=S.bursts[i];b.age=b.age+step;if b.age>.75 then table.remove(S.bursts,i)end end
  if S.phase=='tell' then if S.phaseTime<=0 then S.setPhase('charge')end
  elseif S.phase=='charge' then
   S.x=S.x+S.vx*step;S.y=S.y+S.vy*step
   if S.phaseTime<=0 then S.setPhase('hunt')end
  elseif S.phase=='hunt' then
   S.turnClock=S.turnClock+step
   -- A continuous elliptical flow field: no player tracking or border flip.
   local rx,ry=math.max(150,Arena.width*.30),145
   local ux,uy=(S.x-Arena.width/2)/rx,(S.y-300)/ry
   local radius=math.max(.05,length(ux,uy))
   local tx=-uy*rx*S.turnSign-(radius-1)*ux*rx*3
   local ty=ux*ry*S.turnSign-(radius-1)*uy*ry*3
   local target=length(tx,ty)>.01 and math.atan2(ty,tx) or S.angle
   local delta=(target-S.angle+math.pi)%(2*math.pi)-math.pi
   local turnRate=2.4*2.1*(S.attackRate or 1)/setting('turnInterval',2.1)
   S.angle=S.angle+clamp(delta,-step*turnRate,step*turnRate)
   local desired=(260+S.wave*14)*(S.movementRate or 1)
   S.flightSpeed=S.flightSpeed+clamp(desired-S.flightSpeed,-420*step,420*step)
   S.vx,S.vy=math.cos(S.angle)*S.flightSpeed,math.sin(S.angle)*S.flightSpeed
   S.x=S.x+S.vx*step;S.y=S.y+S.vy*step
   if S.phaseTime<=0 then S.phaseTime=setting('huntDuration',18) end
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
 if S.fogFront then S.fogFront=S.fogFront*r end
 if S.snailAnchorX then S.snailAnchorX=S.snailAnchorX*r end
 S.x=S.x*r;if S.exitX then S.exitX=S.exitX*r end
 for _,p in ipairs(S.smoke or {}) do p.x=p.x*r end
 S.nest.x=S.nest.x*r
 for _,p in ipairs(S.snails)do p.x=p.x*r;if p.tx then p.tx=p.tx*r end end
 for _,p in ipairs(S.holes)do p.x=p.x*r;p.tx=p.tx*r end
 S.groundRevision=S.groundRevision+1
end
function S.visibleBounds()return S.x-80,S.y-80,160,160 end
function S.drawFog()require('mobs.bosses.storm.fog').draw(S)end
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
  if S.cleanStage=='dash' then
   for i=1,16 do
    local x=S.x-S.sweepDir*(20+i*9);local y=S.y+math.sin(i*2.399+S.clock*3)*48
    g.setColor(.8,.94,1,.3);g.setLineWidth(1+i%2)
    g.line(x,y,x-S.sweepDir*(35+i%4*16),y+math.sin(S.clock*9+i)*3)
   end
  end
  local key='merle_flight';local a=Art.images[key]
  local scale=150/math.max(a.w,a.h);local flap,flip=pose()
  g.setColor(1,1-S.flash*.4,1-S.flash*.4)
  Art.draw(key,S.x,S.y,a.w*scale*flap,S.angle,a.h*scale*flip/flap)
 end
 for _,b in ipairs(S.bursts)do
  local t=b.age/.75;local radius=b.kind=='impact' and 75 or 28
  g.setColor(.6,.9,1,(1-t)*.65);g.setLineWidth(2);g.circle('line',b.x,b.y,4+t*radius)
  for i=1,14 do local a=i*2.399;local r=t*radius;g.setColor(1,.9,.5,1-t);g.circle('fill',b.x+math.cos(a)*r,b.y+math.sin(a)*r,2.5*(1-t))end
 end
 g.pop()
end
return S
