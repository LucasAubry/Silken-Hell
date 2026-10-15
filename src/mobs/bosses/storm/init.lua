local FX=require 'mobs.bosses.encounter_fx'
local S={active=false,playerFeatherRadius=17}
local Rain=require 'storm_rain'
local Conductors=require 'mobs.bosses.storm.conductors'
local STRIKE_RADIUS=22
local BODY_SIZE=150
local BODY_RADIUS=34
local STRIKE_WARNING=.85
local function distance(x,y,tx,ty) return math.sqrt((tx-x)^2+(ty-y)^2) end
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function S.speed() return (3000+2200*(1-S.hp/S.maxHp))*(S.movementRate or 1) end
function S.reset(active)
 if player.skyWhirl and player.skyWhirl.boss==S then player.skyWhirl=nil end
 if player.skyThrow and player.skyThrow.boss==S then player.skyThrow=nil end
 S.active=active;S.name='Merle noir';S.hp=10;S.maxHp=10;S.defeated=false;S.electric=false
 S.x=Arena.width*.5;S.y=150;S.dir='down';S.clock=0;S.flash=0;S.hitGrace=0;S.chargeTime=0;S.charges=0
 S.projectiles={};S.strikes={};S.trails={};S.holes={};S.rain={};S.rainClock=1.4;S.rainWave=0;S.tornado=nil;S.pattern=0;S.pass=0;S.round=0;S.featherSalvos=0
 S.vx=0;S.vy=0;S.patrolClock=0;S.poseAge=1;S.boltsRemaining=0;S.volleyClock=0;S.fallSide=nil
 Conductors.reset(S)
 S.nest={x=Arena.width-105,y=115};S.setPhase('orbit')
end
function S.setPhase(phase)
 S.phase=phase;S.phaseAge=0;S.hidden=false
 if phase=='orbit' or phase=='lightning' then
  S.phase='orbit';S.phaseTime=math.huge;S.shot=.7;S.bolt=.65;S.burst=0;S.salvos=0;S.round=S.round+1;S.boltsRemaining=0;S.fallSide=nil
 elseif phase=='leave' then S.phaseTime=.22;S.fromX=S.x;S.fromY=S.y;S.pass=0;S.vx=0;S.vy=0
 elseif phase=='flightTell' then
  S.phaseTime=.60-.16*(1-S.hp/S.maxHp);S.hidden=true;S.pass=S.pass+1
  local px,py=clamp(player.x+15,38,Arena.width-38),clamp(player.y+12,35,565)
  -- Retaliate from the grounded rod's edge; lock the lane during the beak warning.
  local dx=(px-Arena.width*.5)/(Arena.width*.5-38);local dy=(py-300)/265
  local mode=S.fallSide or (math.abs(dx)>math.abs(dy) and (dx<0 and 0 or 1) or (dy<=0 and 2 or 3))
  if mode==0 then S.startX=-110;S.endX=Arena.width+110;S.startY=py;S.endY=py;S.dir='right'
  elseif mode==1 then S.startX=Arena.width+110;S.endX=-110;S.startY=py;S.endY=py;S.dir='left'
  elseif mode==2 then S.startX=px;S.endX=px;S.startY=-100;S.endY=700;S.dir='down'
  else S.startX=px;S.endX=px;S.startY=700;S.endY=-100;S.dir='up' end
  S.x=S.startX;S.y=S.startY
 elseif phase=='flight' then
  S.flightDuration=distance(S.startX,S.startY,S.endX,S.endY)/S.speed();S.phaseTime=S.flightDuration
 elseif phase=='return' then
  S.phaseTime=.65;S.fromX=S.x;S.fromY=S.y
  S.returnX,S.returnY=S.patrolPosition()
 end
end
function S.patrolPosition()
 -- Two independent sweeps bend naturally through their turns across the arena.
 local t=S.patrolClock
 return Arena.width*.5+math.sin(t)*math.max(0,Arena.width*.5-135),300+math.sin(t*1.35-math.pi*.5)*160
end
function S.fire()
 local aim=math.atan2(player.y+12-S.y,player.x+15-S.x)
 -- Sparse opening salvos grow denser and faster as the silk tightens.
 local count=S.hp>S.maxHp*.5 and 3 or 5
 local middle=math.floor(count/2)
 local offset=(S.burst-middle)*.16
 local rage=1-S.hp/S.maxHp
 local a=aim+offset;local speed=(255+110*rage)*1.3*(1+S.charges*.12)
 S.projectiles[#S.projectiles+1]={x=S.x+math.cos(a)*45,y=S.y+math.sin(a)*45,vx=math.cos(a)*speed,vy=math.sin(a)*speed,life=4.5,age=0}
 S.burst=S.burst+1
 if S.burst>=count then S.burst=0;S.salvos=S.salvos+1;S.featherSalvos=S.featherSalvos+1;S.shot=.95-.60*rage else S.shot=.26-.17*rage end
end
function S.lightningAt(x,y)
 for _,strike in ipairs(S.strikes) do
  if strike.age>=.85 and strike.age<1.33 then
   strike.boltPoints=strike.boltPoints or FX.boltPoints(strike.x,strike.y,strike.seed,.55)
   if FX.boltTouches(strike.x,strike.y,strike.seed,.55,x,y,8,strike.boltPoints) then return strike end
  end
 end
end
function S.splitFeather(p)
 if p.split then return false end
 local angle=math.atan2(p.vy,p.vx)+math.pi
 local speed=distance(0,0,p.vx,p.vy)*1.2
 for i=0,2 do
  local a=angle+i*math.pi*2/3
  S.projectiles[#S.projectiles+1]={x=p.x,y=p.y,vx=math.cos(a)*speed,vy=math.sin(a)*speed,
   life=p.life,age=0,split=true}
 end
 BossFX.burst(p.x,p.y,{.65,.85,1},.5)
 return true
end
function S.strikeCount()
 return S.hp>S.maxHp*2/3 and 1 or S.hp>S.maxHp/3 and 2 or 3
end
function S.targetLightning()
 -- Each warning locks the current player position; subsequent bolts can be baited elsewhere.
 S.strikes[#S.strikes+1]={x=player.x+15,y=player.y+12,age=0,seed=S.pattern}
 S.pattern=S.pattern+1
end
function S.summon()
 S.targetLightning();S.boltsRemaining=S.strikeCount()-1;S.volleyClock=.42
end
function S.targetSafe(x,y)
 if Arena.blocked(x-24,y-24,48,48) then return false end
 for _,offset in ipairs({{0,0},{-24,-24},{24,-24},{-24,24},{24,24}}) do
  if Realms.fallAt(x+offset[1],y+offset[2]) then return false end
 end
 return true
end
function S.finish()
 require('boss_liberation').start(S,'storm',function()
  S.defeated=true;S.projectiles={};S.strikes={};S.trails={};S.holes={};S.rain={}
  objet.larme.taken=false;objet.larme.x,objet.larme.y=Arena.clearSpot(clamp(S.x,70,Arena.width-70)-15,clamp(S.y,85,515)-20,30,40)
 end)
end
function S.holeAt(x,y)
 if not S.active or S.defeated then return false end
 for _,p in ipairs(S.holes) do if p.r>7 and ((x-p.x)/(p.r-5))^2+((y-p.y)/(p.r*.78-5))^2<1 then return true end end
 return false
end
function S.contact()

 if not S.active or S.defeated or player.reset or player.abyssHeld then return end
 if S.holeAt(player.x+15,player.y+12) then Hazards.kill('storm');if player.reset then player.falling=true end;return end
 Conductors.contact(S)
 if not S.defeated and not S.hidden and S.phase~='leave' and S.phase~='return'
  and require('collision_shapes').touchCircle('storm',S.x,S.y,BODY_RADIUS) then Hazards.kill('storm') end
end
function S.updateTornado() end
function S.update(dt)

 if not S.active or S.defeated or player.reset then return end
 Conductors.update(S,dt)
 if player.reset or S.defeated then return end
 S.clock=S.clock+dt;S.flash=math.max(0,S.flash-dt);S.hitGrace=math.max(0,S.hitGrace-dt)
 local oldDir=S.dir
 S.poseAge=(S.poseAge or 1)+dt
 S.phaseAge=S.phaseAge+dt;S.phaseTime=S.phaseTime-dt
 if S.phaseTime<=0 and S.phase~='flight' then
  local nextPhase={orbit='leave',leave='flightTell',flightTell='flight',['return']='orbit'}
  S.setPhase(nextPhase[S.phase] or 'orbit')
 end
 if S.phase=='flight' then
  local t=math.min(1,S.phaseAge/S.flightDuration);local tx=S.startX+(S.endX-S.startX)*t;local ty=S.startY+(S.endY-S.startY)*t
  local ox,oy=S.x,S.y;local steps=math.max(1,math.ceil(distance(ox,oy,tx,ty)/6))
  for i=1,steps do S.x=ox+(tx-ox)*i/steps;S.y=oy+(ty-oy)*i/steps;S.contact();if player.reset or S.defeated then return end end
  S.trails[#S.trails+1]={x=S.x,y=S.y,life=.13,dir=S.dir}
  if S.phaseTime<=0 then S.setPhase('return') end
 elseif S.phase=='leave' then
  local t=math.min(1,S.phaseAge/.22)
  S.x=S.fromX;S.y=S.fromY+(-120-S.fromY)*t;S.dir='up'
 elseif S.phase=='return' then
  local t=math.min(1,S.phaseAge/.65);t=t*t*(3-2*t)
  S.x=S.fromX+(S.returnX-S.fromX)*t;S.y=S.fromY+(S.returnY-S.fromY)*t
  S.dir=Art.direction(S.returnX-S.fromX,S.returnY-S.fromY,S.dir)
  S.vx=0;S.vy=0
 elseif S.phase=='orbit' then
  -- Patrol time never reads the player's position; dash targeting stays separate.
  local steps=math.max(1,math.ceil(dt*120));local step=dt/steps
  for _=1,steps do
   S.patrolClock=S.patrolClock+step*(.62+.1*(1-S.hp/S.maxHp))*(S.movementRate or 1)
   local tx,ty=S.patrolPosition()
   S.vx=S.vx+((tx-S.x)*12-S.vx*6)*step
   S.vy=S.vy+((ty-S.y)*12-S.vy*6)*step
   S.x=S.x+S.vx*step;S.y=S.y+S.vy*step
  end
  local horizontal=S.dir=='left' or S.dir=='right'
  if math.abs(S.vx)>math.abs(S.vy)*(horizontal and .7 or 1.4) then S.dir=S.vx<0 and 'left' or 'right'
  elseif math.abs(S.vy)>math.abs(S.vx)*(horizontal and 1.4 or .7) then S.dir=S.vy<0 and 'up' or 'down' end
  S.shot=S.shot-dt*(S.attackRate or 1);S.bolt=S.bolt-dt*(S.attackRate or 1)*(1+S.charges*.45)
  if S.shot<=0 then S.fire() end
  if S.boltsRemaining>0 then
   S.volleyClock=S.volleyClock-dt*(S.attackRate or 1)
   if S.volleyClock<=0 then S.targetLightning();S.boltsRemaining=S.boltsRemaining-1;S.volleyClock=S.volleyClock+.42 end
  elseif S.bolt<=0 then S.summon();S.bolt=2.4 end
 end
 if S.dir~=oldDir then S.previousDir=oldDir;S.poseAge=0 end
 for i=#S.strikes,1,-1 do local p=S.strikes[i];local previous=p.age;p.age=p.age+dt
  if p.age>=STRIKE_WARNING and not p.struck then
   p.struck=true
   if Campaign.biome==6 then require('storm_lightning').trigger(p.x,p.y,p.seed) else BossFX.burst(p.x,p.y,{.65,.8,1},1) end
   S.holes[#S.holes+1]={x=p.x,y=p.y,age=0,r=STRIKE_RADIUS,seed=p.seed}
  end
  if p.age>=STRIKE_WARNING and previous<1.2 then
   Rain.electrify(p.x,p.y,STRIKE_RADIUS)
   if require('collision_shapes').touchCircle('lightning',p.x,p.y,STRIKE_RADIUS) then Hazards.kill('lightning') end
  end
  if p.age>1.4 then table.remove(S.strikes,i) end
 end
 for i=#S.holes,1,-1 do local p=S.holes[i];p.age=p.age+dt;p.r=STRIKE_RADIUS*math.max(0,1-p.age/6.5)^.7;if p.age>=6.5 then table.remove(S.holes,i) end end
 for i=#S.trails,1,-1 do local p=S.trails[i];p.life=p.life-dt;if p.life<=0 then table.remove(S.trails,i) end end
 for i=#S.projectiles,1,-1 do
  local p=S.projectiles[i];p.age=p.age+dt;local dead=false
  p.life=p.life-dt;dead=p.life<=0
  local speed=distance(0,0,p.vx,p.vy);local steps=math.max(1,math.ceil(speed*dt/6))
  for _=1,steps do
   if dead then break end
   p.x=p.x+p.vx*dt/steps;p.y=p.y+p.vy*dt/steps
   if p.x<20 or p.x>Arena.width-20 or p.y<35 or p.y>565 or Arena.blocked(p.x-3,p.y-3,6,6) then dead=true
   elseif not p.split and S.lightningAt(p.x,p.y) then dead=S.splitFeather(p)
   elseif require('collision_shapes').featherTouches(p.x,p.y,S.playerFeatherRadius) then Hazards.kill('storm');dead=true end
  end
  if dead then table.remove(S.projectiles,i) end
 end
 S.contact()
end
function S.resize(r)
 for _,key in ipairs({'x','fromX','returnX','startX','endX','vx'}) do if S[key] then S[key]=S[key]*r end end
 S.nest.x=S.nest.x*r
 if S.discharge then S.discharge.x=S.discharge.x*r;S.discharge.tx=S.discharge.tx*r end
 for _,list in ipairs({S.projectiles,S.strikes,S.trails,S.holes,S.rain,S.pickups,S.rods}) do for _,p in ipairs(list) do p.x=p.x*r;p.boltPoints=nil end end
end
local function sprite(dir)
 local key='merle_flight_'..dir
 if dir=='right' then key='merle_flight' end
 return Art.images[key] and key or 'merle_'..dir
end
local function bird(dir,x,y)
 local key=sprite(dir);local a=Art.images[key];local scale=BODY_SIZE/math.max(a.w,a.h)
 local flap=math.sin(S.clock*14)*.025
 Art.draw(key,x,y,a.w*scale*(1+flap),0,a.h*scale*(1-flap))
end
function S.drawGround()

 if not S.active or S.defeated then return end
 local g=love.graphics;g.push('all')
 Conductors.draw(S)
 for _,p in ipairs(S.strikes) do if p.age>=0 then
  if Campaign.biome==6 then
   local light=require('storm_lightning')
   if p.age<.85 then light.warning(p.x,p.y,p.age/.85,STRIKE_RADIUS,STRIKE_RADIUS)
   end
  elseif p.age<.85 then
   local charge=math.min(1,p.age/.85)
   FX.rune(p.x,p.y,STRIKE_RADIUS,S.clock,{1,.76,.20},.08+charge*.10)
   g.setColor(1,.87,.38,.9);g.setLineWidth(2)
   g.arc('line','open',p.x,p.y,17,-math.pi/2,-math.pi/2+math.max(.01,charge)*math.pi*2)
   -- Angular gold lightning seal, matching the game's carved menu ornaments.
   g.setColor(1,.91,.53,.65+charge*.35)
   g.polygon('fill',p.x+2,p.y-14,p.x-8,p.y+2,p.x-1,p.y+2,p.x-3,p.y+14,p.x+9,p.y-3,p.x+2,p.y-3)
   for i=0,3 do local a=i*math.pi/2;local x,y=p.x+math.cos(a)*27,p.y+math.sin(a)*27
    g.polygon('fill',x,y-3,x+2,y,x,y+3,x-2,y)
   end
  else
   FX.bolt(p.x,p.y,p.seed,p.age-.85,.55)
  end
 end end
 for _,p in ipairs(S.holes) do
  local points={}
  for i=0,31 do local a=i*math.pi/16;local r=p.r*(1+.07*math.sin(i*2.7+p.seed));points[#points+1]=p.x+math.cos(a)*r;points[#points+1]=p.y+math.sin(a)*r*.78 end
  g.setColor(.02,.04,.09,.98);g.polygon('fill',points)
  g.setColor(.91,.95,.96,.65);g.setLineWidth(3);g.polygon('line',points)
  g.setColor(.28,.40,.49,.22);g.ellipse('line',p.x,p.y,p.r*.7,p.r*.48)
 end
 g.pop()
end
function S.previewPose()
 local a=Art.images[sprite(S.dir)];local scale=BODY_SIZE/math.max(a.w,a.h);local w,h=a.w*scale,a.h*scale
 local x,y=S.x,S.y;local cx,cy,cw,ch
 if S.dir=='right' then x=52-w/2;y=y-h*.27;cx,cy,cw,ch=22,S.y-24,32,48
 elseif S.dir=='left' then x=Arena.width-52+w/2;y=y-h*.27;cx,cy,cw,ch=Arena.width-54,S.y-24,32,48
 elseif S.dir=='down' then y=52-h/2;cx,cy,cw,ch=x-24,22,48,32
 else y=548+h/2;cx,cy,cw,ch=x-24,546,48,32 end
 return x,y,cx,cy,cw,ch
end
function S.visibleBounds()
 if not S.active or S.defeated then return end
 if S.phase=='flightTell' then local _,_,x,y,w,h=S.previewPose();return x,y,w,h end
 if S.hidden then return end
 local a=Art.images[sprite(S.dir)];local scale=(BODY_SIZE+5)/math.max(a.w,a.h)
 return S.x-a.w*scale/2,S.y-a.h*scale/2,a.w*scale,a.h*scale
end
function S.draw()

 if not S.active or (S.defeated and not S.liberating) then return end
 local g=love.graphics;g.push('all')
 for _,p in ipairs(S.trails) do g.setColor(.45,.7,1,p.life*.9);bird(p.dir,p.x,p.y) end
 if S.phase=='flightTell' then
  -- Only the tip of the beak protrudes; the body stays beyond the arena edge.
  local x,y,cx,cy,cw,ch=S.previewPose()
  local sx,sy=g.transformPoint(cx,cy);local ex,ey=g.transformPoint(cx+cw,cy+ch)
  local oldX,oldY,oldW,oldH=g.getScissor()
  g.intersectScissor(sx,sy,ex-sx,ey-sy);g.setColor(1,1,1);bird(S.dir,x,y)
  if oldX then g.setScissor(oldX,oldY,oldW,oldH) else g.setScissor() end
 elseif not S.hidden then
  require('monster_fx').halo(S.x,S.y,88)
  local blend=math.min(1,S.poseAge/.13)
  if S.previousDir and blend<1 and S.phase=='orbit' then g.setColor(1,1,1,1-blend);bird(S.previousDir,S.x,S.y) else blend=1 end
  g.setColor(1,1-S.flash*.5,1-S.flash,blend);bird(S.dir,S.x,S.y)
 end
 for _,p in ipairs(S.projectiles) do
  local angle=math.atan2(p.vy,p.vx);local dx,dy=math.cos(angle),math.sin(angle)
  g.setColor(.3,.65,1,.18);g.setLineWidth(2);g.line(p.x-dx*24,p.y-dy*24,p.x,p.y)
  g.setColor(1,1,1);Art.draw('black_feather',p.x,p.y,32,angle)
 end
 g.pop()
end
return S
