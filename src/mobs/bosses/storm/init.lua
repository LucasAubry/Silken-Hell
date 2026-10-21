-- Deterministic tornado encounter. Every cycle uses the next authored route.
local Timing=require('boss_attack_timing')
local S={active=false,playerFeatherRadius=17}
local tau=math.pi*2
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function setting(key,value)return Timing.get(S,key,value)end
local function airborne()return player.throw or player.whirl or player.skyThrow or player.skyWhirl end
function S.speed()return 800*(S.movementRate or 1)end
function S.setPhase(phase)
 S.phase=phase;S.phaseAge=0;S.hidden=false
 if phase=='sweepTell' then
  S.phaseTime=setting('hidden',.9);S.sweepDir=player.x+15<Arena.width/2 and -1 or 1
  S.startX=S.sweepDir==1 and -110 or Arena.width+110;S.endX=S.sweepDir==1 and Arena.width+110 or -110
  S.x=S.startX;S.y=clamp(player.y+12,55,545);S.dir=S.sweepDir==1 and 'right' or 'left';S.pushed=false
  S.projectiles={};S.pushRemaining=0
 elseif phase=='sweep' then
  S.phaseTime=(Arena.width+220)/S.speed();S.sweepDuration=S.phaseTime;S.x=S.startX
  for _,t in ipairs(Realms.tornadoes)do t.eject=S.sweepDir;t.cooldown=0 end
  if player.whirl then player.whirl=nil end
 elseif phase=='retreat' then
  S.phaseTime=.65;S.fromX=S.x;S.fromY=S.y;S.retreatX=player.x+15<Arena.width/2 and Arena.width+110 or -110
 elseif phase=='approach' then
  S.round=S.round+1;S.pattern=(S.round-1)%3+1
  local anchorX,anchorY=clamp(player.x+15,60,Arena.width-60),clamp(player.y+12,65,535)
  -- JSON input round-tripping must not flip a route across the exact centerline.
  anchorX,anchorY=math.floor(anchorX*1000+.5)/1000,math.floor(anchorY*1000+.5)/1000
  local sx=anchorX<Arena.width/2 and 1 or -1;local sy=anchorY<300 and 1 or -1
  local spaceX=sx==1 and Arena.width-anchorX or anchorX;local spaceY=sy==1 and 600-anchorY or anchorY
  local step=math.min(190,(spaceX-35)/2,(spaceY-35))
  S.radius=math.min(180,step*1.15);S.route={}
  -- Keep the circle visible near the edge without putting its inner rim on the player.
  local margin=S.radius+32
  local cx,cy=clamp(anchorX,margin,Arena.width-margin),clamp(anchorY,margin,600-margin)
  local dx,dy=cx-anchorX,cy-anchorY;local distance=math.sqrt(dx*dx+dy*dy)
  local shift=distance>0 and math.min(1,(S.radius-42)/distance) or 0
  S.cx,S.cy=anchorX+dx*shift,anchorY+dy*shift
  -- Two diagonal links and one cardinal link in every authored route.
  local patterns={{{0,0},{1,1},{2,0},{2,1}},{{0,0},{0,1},{1,0},{2,1}},{{0,0},{1,1},{1,0},{2,1}}}
  for _,p in ipairs(patterns[S.pattern])do S.route[#S.route+1]={x=anchorX+p[1]*step*sx,y=anchorY+p[2]*step*sy}end
  S.fromX,S.fromY=S.x,S.y;S.startAngle=math.atan2(S.y-S.cy,S.x-S.cx)
  S.phaseTime=.8;S.spawned=0;S.nextSpawn=.6;S.orbitAngle=0
 elseif phase=='orbit' then
  S.phaseTime=setting('orbitDuration',14);S.shot=setting('firstShot',3.2)
  S.holes={{x=S.cx,y=S.cy,r=S.radius,start=S.startAngle,arc=0,width=17}}
 end
end
function S.reset(active)
 S.active=active;S.name='Merle noir';S.hp=10;S.maxHp=10;S.defeated=false;S.electric=false
 S.clock=0;S.flash=0;S.hitGrace=0;S.round=0;S.pattern=0;S.charges=0;S.chargeTime=0
 S.projectiles={};S.holes={};S.strikes={};S.trails={};S.rain={};S.pickups={};S.rods={};S.route={}
 S.nest={x=Arena.width-105,y=115};S.poseAge=1;S.vx=0;S.vy=0;S.setPhase('sweepTell')
end
function S.holeAt(x,y)
 if not S.active or S.defeated then return false end
 for _,p in ipairs(S.holes)do
  local dx,dy=x-p.x,y-p.y;local angle=(math.atan2(dy,dx)-p.start)%tau
  if math.abs(math.sqrt(dx*dx+dy*dy)-p.r)<p.width and (p.arc>=tau-.001 or angle<=p.arc)then return true end
 end
 return false
end
function S.finish()
 S.projectiles={};S.holes={};S.pushRemaining=0
 require('boss_liberation').start(S,'storm',function()
  S.defeated=true;objet.larme.taken=false
  objet.larme.x,objet.larme.y=Arena.clearSpot(clamp(S.cx or S.x,70,Arena.width-70)-15,clamp(S.cy or S.y,85,515)-20,30,40)
 end)
end
function S.contact()
 if not S.active or S.defeated or player.reset then return end
 if S.holeAt(player.x+15,player.y+12) and not airborne() then Hazards.kill('storm');if player.reset then player.falling=true end;return end
 if S.phase=='sweepTell' or S.phase=='approach' then return end
 local dx,dy=player.x+15-S.x,player.y+12-S.y
 if dx*dx+dy*dy<62^2 then
  if player.throw then
   if not player.throw.hitBoss and S.hitGrace<=0 then
    player.throw.hitBoss=true;S.hp=math.max(0,S.hp-1);S.hitGrace=.7;S.flash=.4
    BossFX.burst(S.x,S.y,{.25,.82,1},.8)
    if S.hp<=0 then S.finish()end
   end
  elseif S.phase=='orbit' and not player.whirl then Hazards.kill('storm') end
 end
end
function S.fire()
 local a=math.atan2(player.y+12-S.y,player.x+15-S.x)
 local speed=610+100*(1-S.hp/S.maxHp)
 S.projectiles[#S.projectiles+1]={x=S.x,y=S.y,vx=math.cos(a)*speed,vy=math.sin(a)*speed,life=5,age=0}
end
local function pushPlayer(dt)
 if S.pushRemaining<=0 or player.reset then return end
 local distance=math.min(S.pushRemaining,280*dt);S.pushRemaining=S.pushRemaining-distance
 local steps=math.max(1,math.ceil(distance/4))
 for _=1,steps do
  Arena.move(player,S.sweepDir*distance/steps,0)
  if Realms.fallAt(player.x+15,player.y+12) then Hazards.kill('storm');if player.reset then player.falling=true end;break end
 end
end
function S.update(dt)
 if not S.active or S.defeated or player.reset then return end
 S.clock=S.clock+dt;S.flash=math.max(0,S.flash-dt);S.hitGrace=math.max(0,S.hitGrace-dt)
 S.phaseAge=S.phaseAge+dt;S.phaseTime=S.phaseTime-dt
 if S.phase~='orbit' then
  for i=#S.holes,1,-1 do local p=S.holes[i];p.width=math.max(0,p.width-dt*45);if p.width==0 then table.remove(S.holes,i)end end
 end
 if S.phase=='sweepTell' then
  if S.phaseTime<=0 then S.setPhase('sweep')end
 elseif S.phase=='sweep' then
  local oldX=S.x;local t=math.min(1,S.phaseAge/S.sweepDuration);S.x=S.startX+(S.endX-S.startX)*t
  local px,py=player.x+15,player.y+12
  if not S.pushed and math.abs(py-S.y)<85 and px>=math.min(oldX,S.x)-65 and px<=math.max(oldX,S.x)+65 then
   S.pushed=true;S.pushRemaining=70
  end
  pushPlayer(dt);S.contact()
  if S.phaseTime<=0 then S.setPhase('approach')end
 elseif S.phase=='retreat' then
  local t=math.min(1,S.phaseAge/.65);t=t*t*(3-2*t)
  S.x=S.fromX+(S.retreatX-S.fromX)*t;S.dir=S.retreatX>S.fromX and 'right' or 'left'
  if S.phaseTime<=0 then S.setPhase('sweepTell')end
 elseif S.phase=='approach' then
  local t=math.min(1,S.phaseAge/.8);t=t*t*(3-2*t)
  local x,y=S.cx+math.cos(S.startAngle)*S.radius,S.cy+math.sin(S.startAngle)*S.radius
  S.x=S.fromX+(x-S.fromX)*t;S.y=S.fromY+(y-S.fromY)*t
  S.dir=Art.direction(x-S.fromX,y-S.fromY,S.dir)
  if S.phaseTime<=0 then S.setPhase('orbit')end
 elseif S.phase=='orbit' then
  local a=S.startAngle+S.phaseAge*tau/6*(S.movementRate or 1)
  S.x=S.cx+math.cos(a)*S.radius;S.y=S.cy+math.sin(a)*S.radius
  S.dir=Art.direction(-math.sin(a),math.cos(a),S.dir)
  S.orbitAngle=a-S.startAngle
  S.holes[1].arc=math.min(tau,math.max(0,S.orbitAngle-.8))
  if S.spawned<#S.route and S.phaseAge>=S.nextSpawn then
   S.spawned=S.spawned+1;local p=S.route[S.spawned]
   Realms.tornadoes[#Realms.tornadoes+1]={x=p.x,y=p.y,cooldown=0,growth=0,growthDuration=setting('growthDuration',1.8)+((S.spawned+S.pattern)%3)*.18}
   S.nextSpawn=S.nextSpawn+setting('tornadoInterval',.85)
  end
  S.shot=S.shot-dt*(S.attackRate or 1)
  if S.shot<=0 then S.fire();S.shot=S.shot+setting('shotInterval',.7)end
  S.contact()
  if not S.defeated and S.phaseTime<=0 then S.setPhase('retreat')end
 end
 for i=#S.projectiles,1,-1 do
  local p=S.projectiles[i];p.age=p.age+dt;p.life=p.life-dt
  local steps=math.max(1,math.ceil(math.sqrt(p.vx*p.vx+p.vy*p.vy)*dt/6))
  for _=1,steps do
   p.x=p.x+p.vx*dt/steps;p.y=p.y+p.vy*dt/steps
   if require('collision_shapes').featherTouches(p.x,p.y,14)then Hazards.kill('storm');p.life=0;break end
  end
  if p.life<=0 or p.x< -30 or p.x>Arena.width+30 or p.y< -30 or p.y>630 then table.remove(S.projectiles,i)end
 end
end
function S.resize(r)
 for _,k in ipairs({'x','cx','fromX','startX','endX'})do if S[k]then S[k]=S[k]*r end end
 S.nest.x=S.nest.x*r
 for _,list in ipairs({S.projectiles,S.holes,S.route})do for _,p in ipairs(list)do p.x=p.x*r end end
end
local function sprite(dir)
 local key=dir=='right' and 'merle_flight' or 'merle_flight_'..dir
 return Art.images[key] and key or 'merle_'..dir
end
local function bird()
 local key=sprite(S.dir);local a=Art.images[key];local scale=150/math.max(a.w,a.h);local flap=math.sin(S.clock*14)*.025
 Art.draw(key,S.x,S.y,a.w*scale*(1+flap),0,a.h*scale*(1-flap))
end
function S.visibleBounds()
 if not S.active or S.defeated then return end
 return S.x-80,S.y-80,160,160
end
function S.drawGround()
 if not S.active or S.defeated then return end
 local g=love.graphics;g.push('all')
 -- Analytic arc mask: no per-frame terrain rebuild/readback while digging.
 S.ringShader=S.ringShader or g.newShader([[
 extern float radius;extern float startAngle;extern float arc;extern float thickness;extern float clock;
 vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
  vec2 p=(uv-.5)*(radius+48.)*2.;float a=mod(atan(p.y,p.x)-startAngle+6.2831853,6.2831853);
  float noise=sin(atan(p.y,p.x)*23.+clock*.15)*1.8+sin(atan(p.y,p.x)*41.)*.8;
  float d=abs(length(p)-radius)-thickness+noise;
  if(a>arc||arc<.001||d>6.)discard;
  vec3 deep=mix(vec3(.018,.055,.10),vec3(.035,.12,.20),.5+.5*sin(p.x*.035+p.y*.025+clock*.2));
  vec3 rim=mix(vec3(.28,.44,.53),vec3(.83,.93,.96),smoothstep(-2.,3.,d));
  return vec4(mix(deep,rim,smoothstep(-9.,0.,d)),1.-smoothstep(3.,6.,d))*color;
 }
 ]])
 for _,p in ipairs(S.holes)do
  local shader=S.ringShader;shader:send('radius',p.r);shader:send('startAngle',p.start);shader:send('arc',p.arc);shader:send('thickness',p.width);shader:send('clock',S.clock)
  g.setShader(shader);g.setColor(1,1,1);local size=(p.r+48)*2;g.draw(UI.pixel,p.x-size/2,p.y-size/2,0,size,size)
 end
 g.pop()
end
function S.draw()
 if not S.active or (S.defeated and not S.liberating)then return end
 local g=love.graphics;g.push('all')
 if S.phase=='sweepTell' then
  local edge=S.sweepDir==1 and 0 or Arena.width
  local reach=12+10*math.min(1,S.phaseAge/.3)
  g.setColor(.20,.12,.025);g.polygon('fill',edge,S.y-9,edge+S.sweepDir*reach,S.y,edge,S.y+9)
  g.setColor(.96,.66,.12);g.polygon('fill',edge,S.y-6,edge+S.sweepDir*(reach-2),S.y,edge,S.y+3)
 else
  if S.phase=='sweep' then
   g.setColor(.7,.91,1,.45);g.setLineWidth(2)
   for i=1,16 do local x=S.x-S.sweepDir*(30+i*9);local y=S.y+math.sin(i*2.4)*60;g.line(x,y,x-S.sweepDir*30,y)end
  end
  if S.phase=='orbit' then
   local a=S.startAngle+S.orbitAngle-.8
   local x,y=S.cx+math.cos(a)*S.radius,S.cy+math.sin(a)*S.radius
   local midX,midY=(x+S.x)/2,(y+S.y)/2+6
   g.setColor(.12,.23,.28,.7);g.setLineWidth(3);g.line(S.x,S.y,midX,midY,x,y)
   g.setColor(.88,.96,1,.95);g.setLineWidth(1.2);g.line(S.x,S.y,midX,midY,x,y)
   require('cloud_snail').art(x,y,52,S.clock,a+math.pi/2,1)
  end
  g.setColor(1,1-S.flash,1-S.flash);bird()
 end
 for _,p in ipairs(S.projectiles)do
  local angle=math.atan2(p.vy,p.vx);local dx,dy=math.cos(angle),math.sin(angle)
  g.setColor(.15,.55,1,.3);g.setLineWidth(8);g.line(p.x-dx*27,p.y-dy*27,p.x,p.y)
  g.setColor(.25,.82,1,1);Art.draw('black_feather',p.x,p.y,34,angle)
  g.setColor(.92,.98,.66,.95);g.setLineWidth(1.5)
  local nx,ny=-dy,dx;g.line(p.x-dx*15,p.y-dy*15,p.x+nx*4,p.y+ny*4,p.x-nx*4+dx*5,p.y-ny*4+dy*5,p.x+dx*17,p.y+dy*17)
 end
 g.pop()
end
return S
