local FX=require 'mobs.bosses.encounter_fx'
local S={active=false}
local Rain=require 'sky_rain'
local STRIKE_RADIUS=22
local BODY_SIZE=150
local BODY_RADIUS=34
local GOLDEN_PICKUP_RADIUS=24
local RETURN_SPEED=2200
local function distance(x,y,tx,ty) return math.sqrt((tx-x)^2+(ty-y)^2) end
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function S.speed() return (3000+2200*(1-S.hp/S.maxHp))*(S.movementRate or 1) end
function S.reset(active)
 if player.skyWhirl and player.skyWhirl.boss==S then player.skyWhirl=nil end
 if player.skyThrow and player.skyThrow.boss==S then player.skyThrow=nil end
 S.active=active;S.name='Merle noir';S.hp=10;S.maxHp=10;S.defeated=false;S.electric=false
 S.x=Arena.width*.5;S.y=150;S.dir='down';S.clock=0;S.flash=0;S.hitGrace=0;S.chargeTime=0;S.charges=0
 S.projectiles={};S.strikes={};S.trails={};S.holes={};S.rain={};S.rainClock=1.4;S.rainWave=0;S.tornado=nil;S.pattern=0;S.pass=0;S.round=0;S.featherSalvos=0
 S.pendingDashes=0;S.nextDashHP=7;S.vx=0;S.vy=0;S.patrolClock=0;S.poseAge=1
 S.nest={x=Arena.width-105,y=115};S.setPhase('orbit')
end
function S.setPhase(phase)
 S.phase=phase;S.phaseAge=0;S.hidden=false
 if phase=='orbit' or phase=='lightning' then
  S.phase='orbit';S.phaseTime=math.huge;S.shot=.7;S.bolt=1;S.burst=0;S.salvos=0;S.round=S.round+1
 elseif phase=='leave' then S.phaseTime=.22;S.fromX=S.x;S.fromY=S.y;S.pass=0;S.vx=0;S.vy=0
 elseif phase=='flightTell' then
  S.phaseTime=.60-.16*(1-S.hp/S.maxHp);S.hidden=true;S.pass=S.pass+1
  local px,py=clamp(player.x+15,38,Arena.width-38),clamp(player.y+12,35,565)
  -- Choose the player's closest side in normalized arena space, then lock it.
  local dx=(px-Arena.width*.5)/(Arena.width*.5-38);local dy=(py-300)/265
  local mode=math.abs(dx)>math.abs(dy) and (dx<0 and 0 or 1) or (dy<=0 and 2 or 3)
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
function S.goldenInterval()
 if S.hp>=9 then return 1 elseif S.hp>=6 then return 1.6 elseif S.hp>=3 then return 2.4 else return 3.2 end
end
function S.fire()
 local aim=math.atan2(player.y+12-S.y,player.x+15-S.x)
 -- Sparse opening salvos grow denser and faster as the silk tightens.
 local count=S.hp>S.maxHp*.5 and 3 or 5
 local middle=math.floor(count/2)
 -- Fractional intervals spread the extra gold evenly without adding larger salvos.
 local interval=S.goldenInterval()
 local golden=S.burst==middle and math.floor(S.featherSalvos/interval)>math.floor((S.featherSalvos-1)/interval)
 local offset=golden and (S.featherSalvos%2==0 and .38 or -.38) or (S.burst-middle)*.13
 local rage=1-S.hp/S.maxHp
 local a=aim+offset;local speed=(255+110*rage)*1.3
 S.projectiles[#S.projectiles+1]={x=S.x+math.cos(a)*45,y=S.y+math.sin(a)*45,vx=math.cos(a)*speed,vy=math.sin(a)*speed,life=4.5,age=0,golden=golden}
 S.burst=S.burst+1
 if S.burst>=count then S.burst=0;S.salvos=S.salvos+1;S.featherSalvos=S.featherSalvos+1;S.shot=.95-.60*rage else S.shot=.26-.17*rage end
end
function S.summon()
 local cx,cy=player.x+15,player.y+12;local chosen={}
 for j=0,2 do
  for attempt=0,47 do
   local a=(S.pattern*3+j)*math.pi/4+attempt*math.pi/8;local r=110+math.floor(attempt/16)*40
   local x,y=cx+math.cos(a)*r,cy+math.sin(a)*r;local separated=true
   for _,p in ipairs(chosen) do if distance(x,y,p.x,p.y)<55 then separated=false end end
   if separated and x>40 and x<Arena.width-40 and y>75 and y<520 and not Arena.blocked(x-18,y-18,36,36) then
    local p={x=x,y=y,age=-j*.13,seed=S.pattern*3+j};S.strikes[#S.strikes+1]=p;chosen[#chosen+1]=p;break
   end
  end
 end
 S.pattern=S.pattern+1
end
function S.rainSettings()
 local rage=clamp(1-S.hp/S.maxHp,0,1)
 return 1+math.floor(rage*3.4),2.2-rage*1.1
end
function S.summonRain()
 local count,interval=S.rainSettings();local chosen={}
 local sites=Realms.rainSites
 S.rainWave=S.rainWave+1
 for j=1,count do
  for attempt=0,math.max(15,#sites-1) do
   local angle=S.rainWave*2.4+j*2.1+attempt*.7
   local radius=(j==1 and attempt==0) and 0 or 70+j*35+attempt*7
   local x=clamp(player.x+15+math.cos(angle)*radius,65,Arena.width-65)
   local y=clamp(player.y+12+math.sin(angle)*radius,85,515)
   -- Authored landing sites keep their positions, but follow the boss's intensity.
   if #sites>0 then
    local site=sites[((S.rainWave-1)*7+(j-1)*5+attempt)%#sites+1];x,y=site.x,site.y
   end
   local free=not Arena.blocked(x-Rain.rx,y-Rain.ry,Rain.rx*2,Rain.ry*2)
   for _,p in ipairs(chosen) do if distance(x,y,p.x,p.y)<64 then free=false end end
   if free then local p={x=x,y=y,age=0};S.rain[#S.rain+1]=p;chosen[#chosen+1]=p;break end
  end
 end
 S.rainClock=interval
end
function S.finish()
 require('boss_liberation').start(S,'storm',function()
  S.defeated=true;S.projectiles={};S.strikes={};S.trails={};S.holes={};S.rain={}
  objet.larme.taken=false;objet.larme.x,objet.larme.y=Arena.clearSpot(clamp(S.x,70,Arena.width-70)-15,clamp(S.y,85,515)-20,30,40)
 end)
end
function S.hurt(fromFeather)
 if S.defeated or (S.hitGrace>0 and not fromFeather) then return false end
 S.hp=math.max(0,S.hp-1);S.flash=.3;S.hitGrace=.24;S.electric=S.hp<=S.maxHp*.5
 BossFX.burst(S.x,S.y,{.65,.9,1},3)
 if S.hp==0 then S.finish()
 elseif S.hp<=S.nextDashHP then
  S.nextDashHP=S.nextDashHP==7 and 5 or S.nextDashHP-1
  if S.phase=='orbit' then S.setPhase('leave')
  else S.pendingDashes=S.pendingDashes+1 end
 end
 return true
end
function S.canReflect(p)
 return p.golden==true and not p.returned
end
function S.reflect(p)
 if p.returned or not p.golden then return end
 p.returned=true;p.age=0
 local d=math.max(1,distance(p.x,p.y,S.x,S.y))
 p.vx=(S.x-p.x)/d*RETURN_SPEED;p.vy=(S.y-p.y)/d*RETURN_SPEED
 BossFX.burst(p.x,p.y,{1,.8,.25},.6)
end
function S.featherHit(p)
 if p.returned and not p.spent and distance(p.x,p.y,S.x,S.y)<40 then
  p.spent=true
  return S.hurt(true) -- Each collected feather owns exactly one hit, even in a group.
 end
 return false
end
function S.holeAt(x,y)
 if not S.active or S.defeated then return false end
 for _,p in ipairs(S.holes) do if p.r>7 and ((x-p.x)/(p.r-5))^2+((y-p.y)/(p.r*.78-5))^2<1 then return true end end
 return false
end
function S.contact()

 if not S.active or S.defeated or player.reset or player.abyssHeld then return end
 if S.holeAt(player.x+15,player.y+12) then Hazards.kill('storm');if player.reset then player.falling=true end;return end
 for i=#S.projectiles,1,-1 do
  local p=S.projectiles[i]
  if S.canReflect(p) and distance(p.x,p.y,player.x+15,player.y+12)<GOLDEN_PICKUP_RADIUS then S.reflect(p) end
  if p.returned then
   if S.featherHit(p) then if S.defeated then return end;table.remove(S.projectiles,i) end
  end
 end
 if not S.hidden and S.phase~='leave' and S.phase~='return' and distance(S.x,S.y,player.x+15,player.y+12)<BODY_RADIUS then Hazards.kill('storm') end
end
function S.updateTornado() end
function S.update(dt)

 if not S.active or S.defeated or player.reset then return end
 Rain.update(S.rain,dt);if player.reset then return end
 if S.phase=='orbit' then
  S.rainClock=S.rainClock-dt*(S.attackRate or 1)
  if S.rainClock<=0 then S.summonRain() end
 end
 S.clock=S.clock+dt;S.flash=math.max(0,S.flash-dt);S.hitGrace=math.max(0,S.hitGrace-dt)
 local oldDir=S.dir
 S.poseAge=(S.poseAge or 1)+dt
 S.phaseAge=S.phaseAge+dt;S.phaseTime=S.phaseTime-dt
 if S.phaseTime<=0 and S.phase~='flight' then
  local nextPhase={orbit='leave',leave='flightTell',flightTell='flight',['return']='orbit'}
  if S.phase=='return' and S.pendingDashes>0 then
   S.pendingDashes=S.pendingDashes-1;S.setPhase('leave')
  else S.setPhase(nextPhase[S.phase] or 'orbit') end
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
  S.shot=S.shot-dt*(S.attackRate or 1);S.bolt=S.bolt-dt
  if S.shot<=0 then S.fire() end
  if S.bolt<=0 then S.summon();S.bolt=2.4 end
 end
 if S.dir~=oldDir then S.previousDir=oldDir;S.poseAge=0 end
 for i=#S.strikes,1,-1 do local p=S.strikes[i];p.age=p.age+dt
  if p.age>=.85 and not p.struck then
   p.struck=true;S.holes[#S.holes+1]={x=p.x,y=p.y,age=0,r=STRIKE_RADIUS,seed=p.seed};BossFX.burst(p.x,p.y,{.65,.8,1},1)
  end
  if p.age>1.4 then table.remove(S.strikes,i) end
 end
 for i=#S.holes,1,-1 do local p=S.holes[i];p.age=p.age+dt;p.r=STRIKE_RADIUS*math.max(0,1-p.age/6.5)^.7;if p.age>=6.5 then table.remove(S.holes,i) end end
 for i=#S.trails,1,-1 do local p=S.trails[i];p.life=p.life-dt;if p.life<=0 then table.remove(S.trails,i) end end
 for i=#S.projectiles,1,-1 do
  local p=S.projectiles[i];p.age=p.age+dt;local dead=false
  if p.returned then
   -- Home independently of the player, including while the bird leaves the screen.
   local steps=math.max(1,math.ceil(dt*RETURN_SPEED/6))
   for _=1,steps do
    local dx,dy=S.x-p.x,S.y-p.y;local d=math.max(.001,distance(p.x,p.y,S.x,S.y))
    local step=math.min(d,RETURN_SPEED*dt/steps)
    p.vx=dx/d*RETURN_SPEED;p.vy=dy/d*RETURN_SPEED
    p.x=p.x+dx/d*step;p.y=p.y+dy/d*step
    if S.featherHit(p) then dead=true;if S.defeated then return end;break end
   end
  else
   p.life=p.life-dt;dead=p.life<=0
   local speed=distance(0,0,p.vx,p.vy);local steps=math.max(1,math.ceil(speed*dt/6))
   for _=1,steps do
    if dead then break end
    p.x=p.x+p.vx*dt/steps;p.y=p.y+p.vy*dt/steps
    if p.x<20 or p.x>Arena.width-20 or p.y<35 or p.y>565 or Arena.blocked(p.x-3,p.y-3,6,6) then dead=true
    elseif distance(p.x,p.y,player.x+15,player.y+12)<(S.canReflect(p) and GOLDEN_PICKUP_RADIUS or 17) then
     if S.canReflect(p) then S.reflect(p);break else Hazards.kill('storm');dead=true end
    end
   end
  end
  if dead then table.remove(S.projectiles,i) end
 end
 S.contact()
end
function S.resize(r)
 for _,key in ipairs({'x','fromX','returnX','startX','endX','vx'}) do if S[key] then S[key]=S[key]*r end end
 S.nest.x=S.nest.x*r
 for _,list in ipairs({S.projectiles,S.strikes,S.trails,S.holes,S.rain}) do for _,p in ipairs(list) do p.x=p.x*r end end
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
 Rain.draw(S.rain)
 for _,p in ipairs(S.holes) do
  local points={}
  for i=0,31 do local a=i*math.pi/16;local r=p.r*(1+.07*math.sin(i*2.7+p.seed));points[#points+1]=p.x+math.cos(a)*r;points[#points+1]=p.y+math.sin(a)*r*.78 end
  g.setColor(.02,.04,.09,.98);g.polygon('fill',points)
  g.setColor(.68,.8,.93,.65);g.setLineWidth(3);g.polygon('line',points)
  g.setColor(.25,.45,.68,.22);g.ellipse('line',p.x,p.y,p.r*.7,p.r*.48)
 end
 for _,p in ipairs(S.strikes) do if p.age>=0 then
  if p.age<.85 then
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
  else FX.bolt(p.x,p.y,p.seed,p.age-.85,.55) end
 end end
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
  g.setColor(p.returned and .6 or .3,.65,1,p.returned and .55 or .18);g.setLineWidth(p.returned and 4 or 2);g.line(p.x-dx*24,p.y-dy*24,p.x,p.y)
  if p.golden then
   S.goldShader=S.goldShader or g.newShader([[vec4 effect(vec4 c, Image tex, vec2 uv, vec2 px) { vec4 t=Texel(tex,uv); float v=max(t.r,max(t.g,t.b)); return vec4(mix(vec3(.95,.72,.08),vec3(1.,1.,.65),v),t.a)*c; }]])
   g.setColor(1,.74,.12,.16);g.circle('fill',p.x,p.y,13);g.setShader(S.goldShader)
  end
  g.setColor(1,1,1);Art.draw('black_feather',p.x,p.y,32,angle);g.setShader()
  if p.returned then g.setColor(.75,1,1,.9);g.circle('fill',p.x,p.y,2) end
 end
 g.pop()
end
return S
