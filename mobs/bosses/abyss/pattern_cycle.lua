-- Tail-first dismantling, upper/lower swimming volleys, suction and a gradual exhale.
local C={}
local W=require 'mobs.bosses.abyss.whip_cycle'
local Jaw=require 'mobs.bosses.abyss.jaw'
C.jaw=Jaw
C.mouth=W.mouth
function C.moving(a) return a.phase=='retreat' or a.phase=='traverse' or a.phase=='returnHead' end
function C.pivot(a) return a.swimHead.x+30,a.swimHead.y+29 end
function C.playerMinX(a,y)
 if not a.active or not a.boss or a.defeated or player.abyssSpit or C.moving(a) then return 23 end
 local cy=(y or player.y)+12
 if cy<a.swimHead.y-98 or cy>a.swimHead.y+141 then return a.swimHead.x+155 end
 return a.swimHead.x+14
end
function C.inMouth(a,x,y) return not C.moving(a) and not Jaw.blocked(a,x-15,y-12) end
function C.blockedPlayer(a,x,y)
 if C.moving(a) then return false end
 return Jaw.blocked(a,x,y)
end
function C.targetPart(a)
 local damage=a.damageProgress or 0
 if damage<2 then return 'tail' elseif damage<9 then return 11-damage else return 'head' end
end
function C.drawOverlay(a)
 if a.defeated or a.phase~='traverse' then return end
 local g=love.graphics;g.push('all');g.setBlendMode('add')
 local target=C.targetPart(a)
 for _,b in ipairs(a.bones) do if b.part==target and b.key~='skeleton_rib' then
  local x,y=b.part=='head' and b.gx or b.x,b.part=='head' and b.gy or b.y
  local r=b.part=='tail' and 28 or 18
  g.setColor(.35,.8,1,.12);g.circle('fill',x,y,r)
  g.setColor(.65,.95,1,.65);g.setLineWidth(1.5);g.circle('line',x,y,r*.65+math.sin(a.clock*5)*2)
 end end
 g.pop()
end
C.sheltered=W.sheltered
function C.lockPlayer(a) return not a.defeated and not player.reset and (a.grab~=nil or a.phase=='suction' or a.phase=='roar') end
local durations={roar=1.1,intro=1.2,rest=.9,retreat=.85,traverse=6,returnHead=.95,bones=5.5,settle=.8,suction=6.5,spit=2.6,recover=1}
function C.geometry(a) a.beams={};a.zones={} end
function C.build(a)
 local h=a.swimHead;local key=C.moving(a) and 'skeleton_head' or 'skeleton_open'
 local spot=Art.images[key].glow or {u=.5,v=.5}
 local swimming=a.phase=='traverse';local dir=swimming and a.swimDir or 1
 local angle=swimming and math.cos(a.phaseTime*3.4)*.045*dir or 0
 a.mouthOffset={x=110*dir,y=21}
 a.head={x=h.x,y=h.y,w=300,h=365,angle=angle}
 local dx,dy=(spot.u-.5)*300*dir,(spot.v-.5)*365
 a.bones={{key=key,part='head',x=h.x,y=h.y,w=300,h=365,angle=angle,flip=dir==-1,gx=h.x+math.cos(angle)*dx-math.sin(angle)*dy,gy=h.y+math.sin(angle)*dx+math.cos(angle)*dy}}
 if swimming then
  for i=1,9 do if (a.damageProgress or 0)<9 and i<=math.min(9,11-(a.damageProgress or 0)) then
   local x=h.x-dir*(120+i*62)
   local y=(a.swimY or 140)+math.sin(a.phaseTime*3.4-i*.55)*(12+i*2)
   local tilt=math.cos(a.phaseTime*3.4-i*.55)*.13*dir
   a.bones[#a.bones+1]={key='skeleton_spine',part=i,x=x,y=y,w=68,h=34,angle=tilt,gx=x,gy=y}
   a.bones[#a.bones+1]={key='skeleton_rib',part=i,x=x,y=y-45,w=24,h=80,angle=tilt,gx=x,gy=y-45}
   a.bones[#a.bones+1]={key='skeleton_rib',part=i,x=x,y=y+45,w=24,h=80,angle=math.pi+tilt,gx=x,gy=y+45}
  end end
  if (a.damageProgress or 0)<2 then
  local x,y=h.x-dir*770,(a.swimY or 140)+math.sin(a.phaseTime*3.4-5.5)*34
  a.bones[#a.bones+1]={key='skeleton_tail',part='tail',x=x,y=y,w=110,h=120,angle=math.cos(a.phaseTime*3.4-5.5)*.16*dir,flip=dir==-1,gx=x,gy=y}
 end end
 C.geometry(a)
end
function C.setup(a)
 W.setup(a);a.hp=10;a.maxHp=10;a.whiteOrbs={};a.lightOnlySuction=false;a.healsFromEnergy=true;a.removedTeeth={};a.toothTargets={};a.fragments={};a.grab=nil;a.mouthPassage=function(x,y) return C.inMouth(a,x,y) end;a.attackIndex=1;a.boneTimer=.3;a.energyTimer=0;a.swimTrail={};a.trailTimer=0;a.damageProgress=0;a.detached={};a.swimY=140;a.cargoBlue=0;a.cargoBones=0;a.bodyHitCooldown=0;a.bodyContactLatched=false;a.bodyContact=function(b) return C.bodyContact(a,b) end
 player.charges=0;player.electrified=0;player.abyssSpit=nil;player.abyssKnock=nil;player.abyssHeld=nil
 C.enter(a,'intro')
end
local function roarSound()
 if not Audio.abyssRoar then
  local rate,n=22050,22050
  local data=love.sound.newSoundData(n,rate,16,1)
  for i=0,n-1 do
   local t=i/rate;local phase=2*math.pi*(145*t-45*t*t)
   data:setSample(i,(math.sin(phase)+.4*math.sin(phase*2.03)+.15*math.sin(phase*7.1))*.22*math.sin(math.pi*t)^.5)
  end
  Audio.abyssRoar=love.audio.newSource(data,'static')
 end
 Audio.play('abyssRoar')
end
function C.enter(a,phase)
 a.motionFrom={x=a.swimHead.x,y=a.swimHead.y}
 a.phase=phase;a.phaseTime=0;a.open=not C.moving(a)
 if not C.moving(a) then a.swimHead.x=35;a.swimHead.y=300 end
 a.visibleSince=nil
 if phase=='rest' or phase=='suction' or phase=='recover' then a.whiteOrbs={} end
 a.energy=0
 if phase=='rest' then
  a.attackIndex=1;a.plankton={};a.debris={};a.round=a.round+1
  for _,p in ipairs(a.lumenParticles) do
   if p.consumed then p.x=35+(math.sin(p.id*127.1)*43758.5453%1)*(Arena.width-70);p.y=45+(math.sin(p.id*311.7)*19642.349%1)*510;p.consumed=false end
  end
 elseif phase=='roar' then
  a.grab=nil;a.pushFrom={x=player.x,y=player.y};roarSound()
 elseif phase=='retreat' then a.grab=nil;a.toothTargets={}
 elseif phase=='traverse' then
  a.swimDir=a.round%2==1 and 1 or -1;a.swimY=a.round%2==0 and 445 or 140;a.passDuration=a.hp<=4 and 5.3 or 6
  a.grab=nil;a.debris={};a.boneTimer=.3;a.swimHead.x=a.swimDir==1 and -220 or Arena.width+220;a.swimHead.y=a.swimY;a.toothTargets={};a.trailTimer=0;a.lastDropX=nil;a.bodyContactLatched=false;a.bodyHitCooldown=0
 elseif phase=='returnHead' then
  a.swimHead.x=-220;a.swimHead.y=300;a.grab=nil;a.toothTargets={}

 elseif phase=='bones' then a.boneTimer=.3;a.energyTimer=0;a.volley=0
 elseif phase=='suction' then
  a.absorbed=false;a.swallowAge=0;a.cargoBlue=0;a.cargoBones=0;player.abyssKnock=nil;player.abyssSpit=nil;player.dashing=false
 elseif phase=='spit' then
  a.cargoBlue=a.cargoBlue+#a.plankton;a.cargoBones=a.cargoBones+#a.debris;a.plankton={};a.debris={};a.spitTimer=0;a.spitSerial=0
  local mx,my=C.mouth(a)
  player.abyssSpit={time=0,duration=.7,arc=-55,fromX=player.x,fromY=player.y,toX=math.min(Arena.width-65,math.max(300,Arena.width*.5)),toY=288}
  player.abyssGrace=1
  for _,p in ipairs(a.lumenParticles) do p.consumed=true;p.exhaled=false end
 elseif phase=='recover' then a.debris={} 
 end
 a.buildBones()
end
function C.bodyContact(a,b)
 if a.phase~='traverse' then return false end
 if a.bodyHitCooldown>0 then return true end
 if b.part~=C.targetPart(a) or not player.dashing or a.bodyContactLatched then return false end
 a.bodyContactLatched=true;a.bodyHitCooldown=.7
 local old=a.damageProgress;a.damageProgress=a.damageProgress+1
 if old>=1 then
  for _,piece in ipairs(a.bones) do
   if piece.part==b.part or (old==8 and type(piece.part)=='number') then
    a.detached[#a.detached+1]={key=piece.key,x=piece.x,y=piece.y,w=piece.w,h=piece.h,angle=piece.angle,flip=piece.flip,age=0,vx=-a.swimDir*100,vy=a.swimY>300 and -100 or 100}
   end
  end
 end
 a.hurt(1)
 player.dashing=false
 player.abyssKnock={time=.24,vx=(a.swimDir or 1)*100,vy=a.swimY>300 and -480 or 480}
 BossFX.burst(player.x+15,player.y+12,{.45,.85,1},1)
 return true
end
function C.contact(a)
 if a.defeated or player.reset or a.phase=='roar' then return end
 player.x=math.max(player.x,C.playerMinX(a))
 if a.phase=='traverse' then
  local touching=false
  for i=1,#a.bones do if a.overlapsBone(a.bones[i]) then touching=true;break end end
  if not touching then a.bodyContactLatched=false end
 end
 W.contact(a)
end
function C.fireBones(a)
 a.volley=a.volley+1
 -- Cover both borders; leave two shifting inner lanes open for dodging.
 local gap=1+(a.volley*2+a.round)%6
 for lane=0,8 do if lane~=gap and lane~=gap+1 then
  a.debris[#a.debris+1]={x=-45,y=40+lane*65,vx=440+(a.hp<=3 and 80 or 0),w=58,h=17,angle=0}
 end end
end
function C.fireEnergy(a)
 local x,y=C.mouth(a)
 -- Blue balls cross the bone lanes and never home onto the player.
 local offset=(a.volley%3-1)*.17
 for _,edgeY in ipairs({44,556}) do
  a.plankton[#a.plankton+1]={x=x,y=edgeY,vx=205,vy=0,r=9,red=false}
 end
 for _,angle in ipairs({-.46+offset,.02+offset,.46+offset}) do
  a.plankton[#a.plankton+1]={x=x,y=y,vx=math.cos(angle)*205,vy=math.sin(angle)*205,r=9,red=false}
 end
end
function C.suction(a,dt)
 if a.absorbed or a.defeated or player.reset or a.grab then return end
 local mx,my=C.mouth(a);local dx,dy=mx-player.x-15,my-player.y-12
 local d=math.sqrt(dx*dx+dy*dy);local step=math.min(d,(460+d*1.8)*dt)
 player.dashing=false
 if d>0 then player.x=player.x+dx/d*step;player.y=player.y+dy/d*step end
 if d-step>30 then return end
 a.absorbed=true;a.grab=nil
 local heal=math.min(3,player.charges or 0,a.maxHp-a.hp)
 a.hp=a.hp+heal
 a.flash=heal>0 and .35 or 0
 player.charges=0;player.electrified=0;player.illuminated=0
 BossFX.burst(mx,my,{.25,.8,1},2)
end
function C.spit(a,dt)
 a.spitTimer=a.spitTimer-dt
 if a.spitTimer>0 then return end
 a.spitTimer=a.spitTimer+.08;a.spitSerial=a.spitSerial+1
 local mx,my=C.mouth(a);local serial=a.spitSerial
 for _=1,2 do if a.cargoBlue>0 then
  local angle=math.sin(serial*2.4+a.cargoBlue)*.9
  a.plankton[#a.plankton+1]={x=mx,y=my,vx=math.cos(angle)*330,vy=math.sin(angle)*330,gravity=35,r=9,red=false}
  a.cargoBlue=a.cargoBlue-1
 end end
 if a.cargoBones>0 then
  local angle=(serial%2==0 and -1 or 1)*(.6+(serial%3)*.16)
  a.debris[#a.debris+1]={x=mx,y=my,vx=math.cos(angle)*340,vy=math.sin(angle)*340,gravity=90,w=40,h=14,angle=angle}
  a.cargoBones=a.cargoBones-1
 end
 local released=0
 for _,p in ipairs(a.lumenParticles) do if p.consumed and released<4 then
  local angle=math.sin(p.id*2.4)*1.1;local speed=210+p.id%7*35
  p.x=mx;p.y=my;p.vx=math.cos(angle)*speed;p.vy=math.sin(angle)*speed;p.consumed=false;p.exhaled=true;released=released+1
 end end
end
function C.duration(a) return a.phase=='traverse' and a.passDuration or durations[a.phase] end
local function tick(a,dt)
 local phase=a.phase
 a.bodyHitCooldown=math.max(0,a.bodyHitCooldown-dt)
 a.clock=a.clock+dt;a.flash=math.max(0,a.flash-dt);a.spitFlash=math.max(0,a.spitFlash-dt)
 a.phaseTime=a.phaseTime+dt*(a.attackRate or 1)
 if phase=='roar' then
  local t=math.min(1,a.phaseTime/.85);t=1-(1-t)^3
  player.x=a.pushFrom.x+(Arena.width-110-a.pushFrom.x)*t
  player.y=math.max(45,math.min(530,a.pushFrom.y));player.dashing=false
 end
 if phase=='retreat' then
  local t=math.min(1,a.phaseTime/durations.retreat);t=t*t*(3-2*t)
  a.swimHead.x=a.motionFrom.x+(-220-a.motionFrom.x)*t
  a.swimHead.y=a.motionFrom.y+(140-a.motionFrom.y)*t
 elseif phase=='returnHead' then
  local t=math.min(1,a.phaseTime/durations.returnHead);t=t*t*(3-2*t)
  a.swimHead.x=-220+255*t;a.swimHead.y=300
 elseif phase=='traverse' then
  local t=math.min(1,a.phaseTime/a.passDuration);local ease=t*t*(3-2*t)
  local travel=(Arena.width+1260)*ease
  a.swimHead.x=a.swimDir==1 and -220+travel or Arena.width+220-travel
  a.swimHead.y=a.swimY+math.sin(a.phaseTime*3.4)*12
  a.boneTimer=a.boneTimer-dt
  if a.boneTimer<=0 then
   local x=a.swimHead.x-a.swimDir*190
   if x>35 and x<Arena.width-35 and (not a.lastDropX or math.abs(x-a.lastDropX)>=(a.hp<=4 and 110 or 135)) then
    local sign=a.swimY>300 and -1 or 1
    for _,offset in ipairs({-23,23}) do a.debris[#a.debris+1]={x=x+offset,y=a.swimHead.y+sign*80,vx=0,vy=sign*660,w=16,h=62,angle=math.pi/2} end
    a.lastDropX=x;a.boneTimer=a.hp<=4 and .30 or .40
   end
  end
  a.trailTimer=a.trailTimer-dt
  if a.trailTimer<=0 then
   a.trailTimer=a.trailTimer+.04
   local x=a.swimHead.x-a.swimDir*240
   if x>-80 and x<Arena.width+80 then a.swimTrail[#a.swimTrail+1]={x=x,y=a.swimY+math.sin(a.phaseTime*3.4-.9)*18,age=0} end
  end
 end
 for i=#a.detached,1,-1 do local p=a.detached[i];p.age=p.age+dt;p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt;p.vy=p.vy+(p.gravity or 0)*dt;p.vy=p.vy+150*dt;p.angle=p.angle+dt*.8;if p.age>1.5 then table.remove(a.detached,i) end end
 for i=#a.swimTrail,1,-1 do local p=a.swimTrail[i];p.age=p.age+dt;if p.age>1.65 then table.remove(a.swimTrail,i) end end
 a.buildBones()
 C.contact(a)
 if player.reset then a.grab=nil;return end
 if a.defeated or player.reset then return end
 if phase=='suction' then
  C.suction(a,dt)
  if a.absorbed then
   local mx,my=C.mouth(a);player.x=mx-15;player.y=my-12;a.swallowAge=a.swallowAge+dt
   if a.swallowAge>.55 then C.enter(a,'spit');a.refreshLight();return end
  end
 end
 if phase=='spit' then C.spit(a,dt) end
 if phase=='bones' then
  a.boneTimer=a.boneTimer-dt;a.energyTimer=a.energyTimer-dt
  if a.boneTimer<=0 then C.fireBones(a);a.boneTimer=a.boneTimer+.85 end
  if a.energyTimer<=0 then
   C.fireEnergy(a)
   a.energyTimer=a.energyTimer+.95
  end
 end
 local mx,my=C.mouth(a)
 for i=#a.plankton,1,-1 do
  local p=a.plankton[i]
  if phase=='suction' and not p.lethal then
   local dx,dy=mx-p.x,my-p.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy));local step=math.min(d,(500+d*2)*dt)
   p.x=p.x+dx/d*step;p.y=p.y+dy/d*step
   if d<18 then a.cargoBlue=a.cargoBlue+1;table.remove(a.plankton,i) end
  else
   p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt
   if p.x>Arena.width+30 or p.y<0 or p.y>610 then table.remove(a.plankton,i) end
  end
 end
 for i=#a.debris,1,-1 do
  local p=a.debris[i]
  if phase=='suction' then
   local dx,dy=mx-p.x,my-p.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy));local step=math.min(d,(520+d*2)*dt)
   p.x=p.x+dx/d*step;p.y=p.y+dy/d*step
   if d<20 then a.cargoBones=a.cargoBones+1;table.remove(a.debris,i) end
  else
   p.x=p.x+p.vx*dt;p.y=p.y+(p.vy or 0)*dt;p.vy=(p.vy or 0)+(p.gravity or 0)*dt
   if p.x>Arena.width+70 or p.x< -70 or p.y>670 or p.y< -70 then table.remove(a.debris,i) end
  end
 end
 for _,p in ipairs(a.lumenParticles) do
  p.age=p.age+dt
  if not p.consumed then
   if phase=='suction' then
    local dx,dy=mx-p.x,my-p.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy));local step=math.min(d,(450+d*2)*dt)
    p.vx=dx/d*(450+d*2);p.vy=dy/d*(450+d*2);p.x=p.x+dx/d*step;p.y=p.y+dy/d*step
    if d<18 then p.consumed=true end
   elseif p.exhaled then p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt;p.vx=p.vx*math.exp(-dt*1.5);p.vy=p.vy*math.exp(-dt*1.5);if math.abs(p.vx)<12 then p.exhaled=false end
   else p.vx=math.sin(p.age*.6+p.id)*9;p.vy=math.cos(p.age*.7+p.id)*7;p.x=math.max(25,math.min(Arena.width-25,p.x+p.vx*dt));p.y=math.max(35,math.min(565,p.y+p.vy*dt)) end
  end
 end
 C.contact(a)
 if a.defeated or player.reset then return end
 if a.phase==phase and a.phaseTime>=C.duration(a) then
  if phase=='intro' then C.enter(a,'rest')
  elseif phase=='rest' then C.enter(a,'roar')
  elseif phase=='roar' then C.enter(a,'retreat')
  elseif phase=='retreat' then C.enter(a,'traverse')
  elseif phase=='traverse' then C.enter(a,'returnHead')
  elseif phase=='returnHead' then C.enter(a,'bones')
  elseif phase=='bones' then C.enter(a,'settle')
  elseif phase=='settle' then C.enter(a,'suction')
  elseif phase=='suction' then C.enter(a,'spit')
  elseif phase=='spit' then C.enter(a,'recover')
  elseif phase=='recover' then C.enter(a,'rest') end
 end
 a.refreshLight()
end
function C.update(a,dt)
 if a.defeated or player.reset then return end
 local steps=math.max(1,math.ceil(dt*math.max(1,a.attackRate or 1)*180))
 for _=1,steps do tick(a,dt/steps);if a.defeated or player.reset then break end end
end
function C.drawMask(a)
 if a.defeated then return end
 W.drawMask(a)
 -- Keep the whole player readable even far from projectiles and without charges.
 local g=love.graphics;g.push('all');g.setColor(.88,.88,.88,1)
 g.ellipse('fill',player.x+15,player.y+8,37,35);g.pop()
 g.push('all');g.setColor(1,1,1,1)
 for _,b in ipairs(a.beams) do g.push();g.translate(b.x,b.y);g.rotate(b.angle);g.rectangle('fill',0,-b.width/2,b.length,b.width);g.pop() end
 g.pop()
end
function C.draw(a)
 if a.defeated then return end
 W.draw(a)
 local glow=love.graphics;glow.push('all');glow.setBlendMode('add')
 for i,p in ipairs(a.swimTrail) do
  local fade=1-p.age/1.65
  glow.setColor(.15,.55,1,.10*fade);glow.ellipse('fill',p.x,p.y,28,12)
  glow.setColor(.5,.85,1,.5*fade);glow.circle('fill',p.x,p.y,2.5*fade)
  local previous=a.swimTrail[i-1]
  if previous and math.abs(previous.x-p.x)<65 then glow.setColor(.25,.7,1,.18*fade);glow.setLineWidth(3);glow.line(previous.x,previous.y,p.x,p.y) end
 end
 glow.pop()
 if a.phase=='roar' then
  local g=love.graphics;local x,y=C.pivot(a);g.push('all')
  g.setColor(.75,.9,1,.3);g.setLineWidth(4)
  for i=1,4 do local r=(a.phaseTime*720+i*110)%(Arena.width+100);g.arc('line','open',x,y,r,-1.3,1.3) end
  g.pop()
 end
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 for _,p in ipairs(a.detached) do
  g.setColor(.3,.4,.45,1-p.age/1.5);Art.draw(p.key,p.x,p.y,p.flip and -p.w or p.w,p.angle,p.h)
 end
 g.pop()
end
return C
