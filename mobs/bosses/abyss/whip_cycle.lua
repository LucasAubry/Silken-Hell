local C={}
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function ease(v) v=clamp(v,0,1);return v*v*(3-2*v) end
local function distance(x,y) return math.sqrt(x*x+y*y) end
local durations={rest=1,windup=.85,whip=2.1,retract=.75,inhaleTell=.55,suction=3,recover=.8,hide=.65,barrage=4,returning=.7}
local nextPhase={rest='windup',windup='whip',whip='retract',retract='inhaleTell',inhaleTell='suction',suction='recover',recover='hide',hide='barrage',barrage='returning',returning='rest'}
function C.sheltered() return false end
function C.lockPlayer(a)
 if not a.defeated and a.phase=='suction' then player.has_moved=false;player.dashing=false;return true end
 return false
end
function C.setup(a)
 a.hp=6;a.maxHp=6;a.name='Le Léviathan des Abysses';a.round=0
 a.threads={};a.lightMotes={};a.octopuses={};a.mines={};a.beams={};a.waves={};a.lightSites={}
 a.lightTrail={};a.lumenParticles={};a.debris={};a.vacuumCargo={};a.energy=0;a.hitGrace=0
 a.swimHead={x=35,y=300,angle=0};a.chain={};a.aim=nil
 for i=1,90 do a.lumenParticles[i]={x=35+(math.sin(i*127.1)*43758.5453%1)*(Arena.width-70),y=45+(math.sin(i*311.7)*19642.349%1)*510,age=i,id=i} end
 C.enter(a,'rest')
end
function C.mouth(a) local offset=a.mouthOffset or {x=84,y=16};return a.swimHead.x+offset.x,a.swimHead.y+offset.y end
function C.build(a)
 local h=a.swimHead;if not h then return end
 a.bones={}
 local function bone(key,x,y,w,height,angle)
  local spot=Art.images[key].glow or {u=.5,v=.5};local c,s=math.cos(angle or 0),math.sin(angle or 0)
  local dx,dy=(spot.u-.5)*w,(spot.v-.5)*height
  a.bones[#a.bones+1]={key=key,x=x,y=y,w=w,h=height,angle=angle or 0,gx=x+c*dx-s*dy,gy=y+s*dx+c*dy}
 end
 a.head={x=h.x,y=h.y,w=220,h=190,angle=0}
 -- Narrow, separated vertebrae leave real passages; no invisible connecting hitbox.
 local extension=0
 if a.phase=='windup' then extension=.16*ease(a.phaseTime/durations.windup)
 elseif a.phase=='whip' then extension=.16+.84*ease(a.phaseTime/.22)
 elseif a.phase=='retract' then extension=1-ease(a.phaseTime/durations.retract) end
 if extension>0 then
  local count=math.max(6,math.ceil(Arena.width/112))
  for i=1,count do
   local u=i/count;local x=h.x-80+(Arena.width-50)*u*extension
   local wave=a.phase=='whip' and math.sin(a.phaseTime*math.pi*2/.7-u*2.2) or 0
   local y=h.y-330*math.sin(u*math.pi*.8)*extension+wave*170*extension
   local rib=58+28*(1-u)
   bone('skeleton_spine',x,y,25,27,wave*.3)
   bone('skeleton_rib',x,y-rib*.5-16,16,rib,-.12+wave*.18)
   bone('skeleton_rib',x,y+rib*.5+16,16,rib,math.pi+.12+wave*.18)
   if i==count then bone('skeleton_tail',x+38,y,68,110,wave*.5) end
  end
 end
 bone(a.open and 'skeleton_open' or 'skeleton_head',h.x,h.y,220,190,0)
end
function C.enter(a,phase)
 a.phase=phase;a.phaseTime=0;a.open=phase=='suction' or phase=='inhaleTell' or phase=='recover'
 a.energy=0;a.shotTimer=0
 a.fromHead={x=a.swimHead.x,y=a.swimHead.y}
 if phase=='rest' then
  a.round=a.round+1;a.plankton={};a.debris={};a.absorbed=false
  for i,p in ipairs(a.lumenParticles) do
   if p.consumed then p.x=50+(math.sin(i*41+a.round)*.5+.5)*(Arena.width-100);p.y=45+(math.sin(i*19)*.5+.5)*510;p.consumed=false end
  end
 elseif phase=='whip' then a.volley=0
 elseif phase=='suction' then a.absorbed=false;player.abyssKnock=nil;player.abyssSpit=nil;player.dashing=false
 elseif phase=='barrage' then a.volley=0;a.plankton={} end
 a.buildBones()
end
function C.absorb(a)
 if a.absorbed or a.defeated or player.reset then return end
 a.absorbed=true
 local charges=math.min(3,player.charges or 0)
 if charges==0 then Hazards.kill('abyss_bite');return end
 local mx,my=C.mouth(a)
 player.charges=0;player.electrified=0;player.illuminated=0
 a.hurt(charges);BossFX.burst(mx,my,{.25,.8,1},2)
 -- Expel the player into a clear pocket before the horizontal bone attack.
 player.abyssSpit={time=0,fromX=player.x,fromY=player.y,toX=math.min(Arena.width-65,math.max(260,Arena.width*.45)),toY=288}
 player.abyssGrace=.6;a.plankton={};a.refreshLight()
 if not a.defeated then C.enter(a,'recover') end
end
function C.contact(a)
 if a.defeated or player.reset then return end
 local px,py=player.x+15,player.y+12;local mx,my=C.mouth(a)
 if a.phase=='suction' and not a.lightOnlySuction and not a.healsFromEnergy then
  if distance(px-mx,py-my)<35 then C.absorb(a) end
  return -- The current feeds into the mouth without hitting the skull first.
 end
 if (player.abyssGrace or 0)>0 or player.abyssSpit then return end
 for i=#a.plankton,1,-1 do
  local p=a.plankton[i]
  if distance(px-p.x,py-p.y)<p.r+12 then
   table.remove(a.plankton,i)
   if p.red or p.lethal or (a.lightOnlySuction and a.phase=='suction') then Hazards.kill('abyss_projectile');return end
   player.charges=math.min(3,(player.charges or 0)+1);player.electrified=60;a.refreshLight()
   BossFX.burst(p.x,p.y,{.2,.7,1},.35)
  end
 end
 for _,p in ipairs(a.debris) do
  if math.abs(px-p.x)<p.w*.5+12 and math.abs(py-p.y)<p.h*.5+10 then Hazards.kill('abyss_projectile');return end
 end
 if a.healsFromEnergy and a.phase=='suction' then return end -- The current carries the player safely between the jaws.
 local inMouth=a.mouthPassage and a.mouthPassage(px,py)
 for _,b in ipairs(a.bones) do
  local throat=inMouth and (b.key=='skeleton_head' or b.key=='skeleton_open')
  if not throat and a.overlapsBone(b) then Hazards.kill('abyss_bite');return end
 end
end
function C.suction(a,dt)
 if a.absorbed or a.defeated or player.reset then return end
 local mx,my=C.mouth(a);local dx,dy=mx-player.x-15,my-player.y-12;local d=distance(dx,dy)
 local step=math.min(d,(460+d*1.8)*dt)
 -- Direct movement is intentional: input and authored terrain cannot defeat the pull.
 if d>0 then player.x=player.x+dx/d*step;player.y=player.y+dy/d*step end
 C.contact(a)
end
function C.fireEnergy(a)
 a.volley=a.volley+1
 local x,y=C.mouth(a);local angle=math.atan2(player.y+12-y,math.max(110,player.x+15-x))
 for i=-1,1 do
  local theta=clamp(angle+i*.32,-1.25,.25);local speed=245
  a.plankton[#a.plankton+1]={x=x,y=y,vx=math.cos(theta)*speed,vy=math.sin(theta)*speed,r=9,red=i==(a.volley%2==0 and -1 or 1) and a.volley%3==0}
 end
end
function C.fireBones(a)
 a.volley=a.volley+1
 -- A shifted empty lane makes each broadside readable and traversable.
 local gap=(a.volley*2+a.round)%6
 for lane=0,5 do if lane~=gap and lane~=(gap+1)%6 then
  a.debris[#a.debris+1]={x=-45,y=75+lane*88,vx=440+(a.hp<=3 and 80 or 0),w=58,h=17,angle=0}
 end end
end
local function tick(a,dt)
 a.clock=a.clock+dt;a.flash=math.max(0,a.flash-dt);a.spitFlash=math.max(0,a.spitFlash-dt)
 a.phaseTime=a.phaseTime+dt*(a.attackRate or 1)
 local phase=a.phase;local t=a.phaseTime;local h=a.swimHead
 local tx,ty=35,300
 if phase=='windup' or phase=='whip' then ty=475
 elseif phase=='hide' or phase=='barrage' then tx=-260 end
 local blend=ease(t/((phase=='whip' or phase=='barrage') and .1 or durations[phase]))
 h.x=a.fromHead.x+(tx-a.fromHead.x)*blend;h.y=a.fromHead.y+(ty-a.fromHead.y)*blend
 a.buildBones()
 if phase=='whip' or phase=='barrage' then
  a.shotTimer=a.shotTimer-dt*(a.attackRate or 1)
  if a.shotTimer<=0 then
   a.shotTimer=a.shotTimer+(phase=='whip' and .32 or .72)
   if phase=='whip' then C.fireEnergy(a) else C.fireBones(a) end
  end
 end
 local mx,my=C.mouth(a)
 for i=#a.plankton,1,-1 do
  local p=a.plankton[i]
  if phase=='suction' then
   local dx,dy=mx-p.x,my-p.y;local d=math.max(1,distance(dx,dy));local step=math.min(d,(500+d*2)*dt)
   p.x=p.x+dx/d*step;p.y=p.y+dy/d*step
   if d<18 then table.remove(a.plankton,i) end
  else
   p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt
   if p.x>Arena.width+30 or p.y<0 or p.y>610 then table.remove(a.plankton,i) end
  end
 end
 for i=#a.debris,1,-1 do local p=a.debris[i];p.x=p.x+p.vx*dt;if p.x>Arena.width+70 then table.remove(a.debris,i) end end
 for _,p in ipairs(a.lumenParticles) do
  p.age=p.age+dt
  if not p.consumed then
   if phase=='suction' or phase=='recover' then
    local dx,dy=mx-p.x,my-p.y;local d=math.max(1,distance(dx,dy));local step=math.min(d,(450+d*2)*dt)
    p.vx=dx/d*(450+d*2);p.vy=dy/d*(450+d*2);p.x=p.x+dx/d*step;p.y=p.y+dy/d*step
    if d<18 then p.consumed=true end
   else p.vx=math.sin(p.age*.6+p.id)*9;p.vy=math.cos(p.age*.7+p.id)*7;p.x=clamp(p.x+p.vx*dt,25,Arena.width-25);p.y=clamp(p.y+p.vy*dt,35,565) end
  end
 end
 if phase=='suction' then C.suction(a,dt) else C.contact(a) end
 if a.defeated or player.reset then return end
 if a.phase==phase and t>=durations[phase] then
  if phase=='suction' then
   player.x=mx-15;player.y=my-12;C.absorb(a)
  else C.enter(a,nextPhase[phase]) end
 end
 a.refreshLight()
end
function C.update(a,dt)
 if a.defeated or player.reset then return end
 -- Sweep fast bones and the whip at a fixed maximum step to prevent tunnelling.
 local steps=math.max(1,math.ceil(dt/(1/180)))
 for _=1,steps do tick(a,dt/steps);if a.defeated or player.reset then break end end
end
function C.drawMask(a)
 if a.defeated then return end
 local g=love.graphics;g.setColor(.65,.65,.65,1)
 for _,p in ipairs(a.plankton) do g.circle('fill',p.x,p.y,32) end
 for _,p in ipairs(a.debris) do g.ellipse('fill',p.x,p.y,42,22) end
end
function C.draw(a)
 if a.defeated then return end
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 local mx,my=C.mouth(a)
 for _,p in ipairs(a.lumenParticles) do if not p.consumed then
  g.setColor(.2,.65,.9,.12);g.circle('fill',p.x,p.y,5)
  g.setColor(.45,.85,1,.55);g.circle('fill',p.x,p.y,1.4)
  if a.phase=='suction' then g.setColor(.3,.75,1,.35);g.setLineWidth(1);g.line(p.x,p.y,p.x-p.vx*.045,p.y-p.vy*.045) end
 end end
 for _,p in ipairs(a.plankton) do
  local r,green,b=p.red and 1 or .15,p.red and .12 or .65,p.red and .15 or 1
  g.setColor(r,green,b,.12);g.circle('fill',p.x,p.y,24)
  g.setColor(r,green,b,.35);g.circle('fill',p.x,p.y,14)
  g.setColor(r,green,b,1);g.circle('fill',p.x,p.y,p.r)
  g.setColor(1,p.red and .65 or 1,1,.9);g.circle('fill',p.x-2,p.y-2,3)
 end
 for _,p in ipairs(a.debris) do
  local visibility=1
  if a.lightOnlySuction and a.phase=='suction' then
   visibility=.035
   for _,orb in ipairs(a.plankton) do if orb.lethal then visibility=math.max(visibility,1-distance(p.x-orb.x,p.y-orb.y)/150) end end
  end
  g.setColor(.3,.7,1,.18*visibility);g.setLineWidth(3);g.line(p.x-65,p.y,p.x-25,p.y)
  g.setColor(.82*visibility,.94*visibility,visibility);Art.draw('skeleton_spine',p.x,p.y,p.w,0,p.h)
 end
 if a.phase=='inhaleTell' or a.phase=='suction' then
  for i=1,5 do local t=(i/5-a.clock*.8)%1;g.setColor(.3,.8,1,(1-t)*.5);g.setLineWidth(2);g.ellipse('line',mx,my,20+t*110,12+t*75) end
 end
 if a.phase=='windup' then
  g.setColor(.3,.8,1,.65);g.setLineWidth(2);g.line(20,550,75,550,65,535)
 end
 -- Three visible slots make the energy limit immediately legible.
 if (player.charges or 0)>0 and not (Abyss and Abyss.playerHidden()) then for i=1,3 do
  g.setColor(.2,.75,1,i<=player.charges and .95 or .2);g.circle(i<=player.charges and 'fill' or 'line',player.x+15+(i-2)*11,player.y-12,3.5)
 end end
 g.pop()
end
return C
