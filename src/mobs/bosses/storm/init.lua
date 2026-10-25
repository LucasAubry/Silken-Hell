-- Stable storm encounter ID, now a shell guardian with immediately usable snails.
local S={active=false}
local Timing=require('boss_attack_timing')
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function airborne()return player.throw or player.whirl or player.skyThrow or player.skyWhirl end
function S.anchor()return S.x,S.y end
function S.spawnSnails()
 S.snails={}
 for i=1,3 do
  local a=S.wave*.73+i*math.pi*2/3
  local x,y=Arena.clearSpot(clamp(S.x+math.cos(a)*190,65,Arena.width-65)-20,clamp(S.y+math.sin(a)*160,140,510)-18,40,36)
  S.snails[i]={x=x+20,y=y+18,phase='ready',age=0,angle=a}
 end
end
function S.setPhase(phase)
 S.phase=phase;S.phaseAge=0
 if phase=='tell' then
  local dx,dy=player.x+15-S.x,player.y+12-S.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy))
  S.vx,S.vy=dx/d*360*(S.movementRate or 1),dy/d*360*(S.movementRate or 1);S.angle=math.atan2(dy,dx);S.phaseTime=Timing.get(S,'hidden',1.15)
 elseif phase=='charge' then S.phaseTime=Timing.get(S,'chargeDuration',.95)
 elseif phase=='recover' then
  S.phaseTime=Timing.get(S,'recoverDuration',2.1)
  S.rings[#S.rings+1]={x=S.x,y=S.y,age=-.65,radius=0,angle=S.wave*.73}
 end
end
function S.reset(active)
 S.active=active;S.name="L’Escargot d’orage";S.hp=9;S.maxHp=9;S.defeated=false;S.hidden=false
 S.x=Arena.width/2;S.y=230;S.wave=1;S.clock=0;S.flash=0;S.vx=0;S.vy=0;S.angle=0
 S.snails={};S.rings={};S.holes={};S.bursts={};S.projectiles={};S.smoke={};S.groundRevision=0;S.fogAmount=0;S.trailKeys={};S.nest={x=S.x,y=S.y}
 S.setPhase('tell');if active then S.spawnSnails()end
end
function S.holeAt()return false end
function S.releaseSnails()end
function S.cut(p)
 if p.phase~='ready' then return end
 p.phase='strike';p.age=0
 S.bursts[#S.bursts+1]={x=p.x,y=p.y,age=0}
end
function S.finish()
 S.rings={};S.snails={};S.projectiles={}
 require('boss_liberation').start(S,'storm',function()
  S.defeated=true;objet.larme.taken=false
  objet.larme.x,objet.larme.y=Arena.clearSpot(S.x-15,S.y-20,30,40)
 end)
end
function S.contact()
 if not S.active or S.defeated or S.liberating or player.reset then return end
 for _,p in ipairs(S.snails)do
  if p.phase=='ready' and require('collision_shapes').touchRect('storm_snail',p.x-23,p.y-21,46,42)then S.cut(p)end
 end
 if require('collision_shapes').touchCircle('storm_body',S.x,S.y,43)then Hazards.kill('storm')end
end
function S.updateSnails(dt)
 local pending=0
 for _,p in ipairs(S.snails)do
  p.age=p.age+dt
  if p.phase~='spent' then pending=pending+1 end
  if p.phase=='strike' then
   local dx,dy=S.x-p.x,S.y-p.y;local d=math.sqrt(dx*dx+dy*dy);local step=(650+p.age*420)*dt
   p.angle=math.atan2(dy,dx)
   if d<=step+38 then
    p.phase='spent';S.hp=math.max(0,S.hp-1);S.flash=.35
    S.bursts[#S.bursts+1]={x=S.x,y=S.y,age=0}
    if S.hp==0 then S.finish();return end
   else p.x=p.x+dx/d*step;p.y=p.y+dy/d*step end
  end
 end
 if pending==0 then S.wave=S.wave+1;S.spawnSnails()end
end
function S.update(dt)
 if not S.active or S.defeated or S.liberating or player.reset then return end
 local steps=math.max(1,math.ceil(dt*120));local step=dt/steps
 for _=1,steps do
  S.clock=S.clock+step;S.phaseAge=S.phaseAge+step;S.phaseTime=S.phaseTime-step*(S.attackRate or 1);S.flash=math.max(0,S.flash-step)
  if S.phase=='charge' then
   local x,y=S.x+S.vx*step,S.y+S.vy*step
   if x<65 or x>Arena.width-65 or y<85 or y>515 or Arena.blocked(x-43,y-35,86,70)then S.setPhase('recover')
   else S.x,S.y=x,y end
  end
  if S.phaseTime<=0 then S.setPhase(S.phase=='tell' and 'charge' or S.phase=='charge' and 'recover' or 'tell')end
  for i=#S.rings,1,-1 do
   local r=S.rings[i];r.age=r.age+step;r.radius=math.max(0,r.age)*155
   if r.age>3.4 then table.remove(S.rings,i)
   elseif r.age>=0 and not airborne()then
    local d=math.sqrt((player.x+15-r.x)^2+(player.y+12-r.y)^2)
    -- Two wide breaks rotate between waves, leaving a route without a jump.
    local a=math.atan2(player.y+12-r.y,player.x+15-r.x)-r.angle
    if math.abs(d-r.radius)<12 and math.abs(math.sin(a))>.42 then Hazards.kill('storm')end
   end
  end
  for i=#S.bursts,1,-1 do local b=S.bursts[i];b.age=b.age+step;if b.age>.65 then table.remove(S.bursts,i)end end
  S.updateSnails(step);S.contact()
  if S.liberating or S.defeated or player.reset then break end
 end
end
function S.resize(r)
 S.x=S.x*r;S.nest.x=S.nest.x*r
 for _,list in ipairs({S.snails,S.rings,S.bursts})do for _,p in ipairs(list)do p.x=p.x*r end end
end
function S.visibleBounds()if not S.active or S.defeated then return end;return S.x-80,S.y-100,160,170 end
function S.drawGround()
 if not S.active or S.defeated then return end
 local g=love.graphics;g.push('all');g.setShader()
 if S.phase=='tell' then
  local t=math.min(1,S.phaseAge/math.max(.01,S.phaseAge+S.phaseTime))
  g.setColor(.72,.83,.75,.18+t*.2);g.setLineWidth(44)
  g.line(S.x,S.y,clamp(S.x+S.vx*Timing.get(S,'chargeDuration',.95)/(S.attackRate or 1),65,Arena.width-65),clamp(S.y+S.vy*Timing.get(S,'chargeDuration',.95)/(S.attackRate or 1),85,515))
 end
 for _,r in ipairs(S.rings)do
  g.setColor(.69,.86,.87,r.age<0 and .3 or .8);g.setLineWidth(r.age<0 and 2 or 5)
  local radius=r.age<0 and 32+(-r.age)*40 or r.radius
  for j=0,1 do local a=r.angle+j*math.pi+.44
   g.arc('line','open',r.x,r.y,radius,a,a+math.pi-.88,60)
  end
 end
 g.pop()
end
function S.drawFog()end
function S.draw()
 if not S.active or S.defeated and not S.liberating then return end
 local g=love.graphics;g.push('all');g.setShader()
 for _,p in ipairs(S.snails)do if p.phase~='spent' then
  Art.contactShadow(p.x,p.y+7,12,4,.25);require('mobs.bosses.storm.snail_art').draw(p,S.clock)
 end end
 Art.contactShadow(S.x,S.y+27,57,19,.25)
 require('cloud_snail_art').draw(S.x,S.y,155,S.clock,S.angle)
 if S.flash>0 then g.setColor(.79,.93,1,S.flash);g.circle('line',S.x,S.y,58)end
 for _,b in ipairs(S.bursts)do
  g.setColor(.71,.89,.91,1-b.age/.65);g.setLineWidth(2);g.circle('line',b.x,b.y,8+b.age*80)
 end
 g.pop()
end
return S
