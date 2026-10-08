-- Swimming volleys, suction and exhale; stored blue energy damages only the mouth.
local C={}
local W=require 'mobs.bosses.abyss.whip_cycle'
local Stock=require 'mobs.bosses.abyss.bone_stock'
local Bombs=require 'mobs.bosses.abyss.bombs'
local Jaw=require 'mobs.bosses.abyss.jaw'
C.jaw=Jaw
C.mouth=W.mouth
function C.moving(a) return a.phase=='retreat' or a.phase=='traverse' or a.phase=='exitSwim' or a.phase=='returnHead' or a.phase=='bombRain' end
function C.pivot(a) return a.swimHead.x+30,a.swimHead.y+29 end
function C.playerMinX(a,y)
 if a.physicsTest or not a.active or not a.boss or a.defeated or player.abyssSpit or C.moving(a) or a.phase=='bones' then return 23 end
 local cy=(y or player.y)+12
 if cy<a.swimHead.y-59 or cy>a.swimHead.y+85 then return a.swimHead.x+93 end
 return a.swimHead.x+8
end
function C.throat(a,x,y)
 local mx,my=C.mouth(a)
 return a.open and not C.moving(a) and (x-mx)^2/42^2+(y-my)^2/28^2<1
end
function C.inMouth(a,x,y) return a.open and not C.moving(a) and a.phase~='bones' and (C.throat(a,x,y) or not Jaw.blocked(a,x-15,y-12)) end
function C.blockedPlayer(a,x,y)
 if a.physicsTest or a.phase=='bones' or C.moving(a) or C.throat(a,x+15,y+12) then return false end
 return Jaw.blocked(a,x,y)
end
function C.drawOverlay(a) if a.returnMode then require('mobs.bosses.abyss.ricochet').overlay(a) end end
C.sheltered=W.sheltered
function C.lockPlayer(a) return not a.physicsTest and not a.defeated and not player.reset and (a.carryPlayer or a.grab~=nil or a.phase=='suction' or a.phase=='roar') end
local durations={bombRain=4.2,openingSpit=.9,roar=1.1,intro=1.2,rest=.9,retreat=.35,traverse=6,returnHead=.35,bones=5.5,settle=.8,suction=6.5,spit=.85,recover=1,exitSwim=.55}
function C.geometry(a) a.beams={};a.zones={} end
function C.pathPoint(a,distance)
 local x,y=a.swimHead.x,a.swimHead.y
 local angle=a.swimAngle or 0
 for i=#a.swimPath,1,-1 do local p=a.swimPath[i];local dx,dy=p.x-x,p.y-y;local d=math.sqrt(dx*dx+dy*dy)
  if d>0 and distance<=d then return x+dx*distance/d,y+dy*distance/d,math.atan2(-dy,-dx) end
  if d>0 then angle=math.atan2(-dy,-dx) end
  distance=distance-d;x,y=p.x,p.y
 end
 return x-math.cos(angle)*distance,y-math.sin(angle)*distance,angle
end
function C.swimMouth(a)
 local angle=a.swimAngle or 0;local c,s=math.cos(angle),math.sin(angle)
 return a.swimHead.x+c*66-s*12.6,a.swimHead.y+s*66+c*12.6
end
function C.swim(a,dt)
 local h=a.swimHead
 local target=math.atan2(player.y+12-h.y,player.x+15-h.x)
 local angle=a.swimAngle or (a.swimDir==1 and 0 or math.pi)
 local turn=(target-angle+math.pi)%(2*math.pi)-math.pi
 angle=angle+math.max(-2.4*dt,math.min(2.4*dt,turn));a.swimAngle=angle
 Stock.speed(a)
 local vx,vy=math.cos(angle)*a.swimSpeed,math.sin(angle)*a.swimSpeed
 a.swimDir=vx>=0 and 1 or -1
 h.x=h.x+vx*dt;h.y=h.y+vy*dt
 local last=a.swimPath[#a.swimPath]
 if not last or (h.x-last.x)^2+(h.y-last.y)^2>=64 then
  a.swimPath[#a.swimPath+1]={x=h.x,y=h.y};if #a.swimPath>170 then table.remove(a.swimPath,1)end
 end
 local mx,my=C.swimMouth(a);Bombs.mouth(a,mx,my,dt)
 a.toothOpen=math.max(0,(a.toothOpen or 0)-dt)
 if a.toothOpen>0 and not a.swallowBomb then a.open=true end
end
function C.shedBone(a)
 a.buildBones()
 local angle=a.swimAngle or 0;local c,s=math.cos(angle),math.sin(angle)
 local dx,dy=player.x+15-a.swimHead.x,player.y+12-a.swimHead.y
 local ahead,across=dx*c+dy*s,-dx*s+dy*c
 if ahead>0 and math.abs(across)<=ahead then
  if a.swallowBomb then return false end
  a.toothOpen=.3;a.open=true
  local mx,my=C.swimMouth(a)
  for _,side in ipairs({-1,1})do
   local x,y=mx-c*48-s*side*3,my-s*48+c*side*3
   local tx,ty=player.x+15-x,player.y+12-y;local d=math.max(1,math.sqrt(tx*tx+ty*ty))
   a.debris[#a.debris+1]={tooth=true,x=x,y=y,vx=c*640,vy=s*640,w=23,h=10,angle=angle,armTime=.13,life=4,throatTravel=72,toothSide=side*3,targetX=player.x+15,targetY=player.y+12}
  end
  return true
 end
 return false
end
function C.build(a)
 if a.physicsTest then a.bones={};return end
 local scale=a.webMode and (a.webScale or 1) or 1
 local headScale=scale*(a.returnMode and .78 or 1)
 local h=a.swimHead;local key=a.open and 'skeleton_open' or 'skeleton_head'
 local spot=Art.images[key].glow or {u=.5,v=.5}
 local swimming=a.phase=='traverse' or a.phase=='exitSwim';local barrage=a.phase=='bones' or (a.phase=='returnHead' and a.nextPhase=='bones');local dir=1
 local angle=a.phase=='bombRain' and math.pi or 0
 if swimming then angle=a.swimAngle or 0
 elseif barrage then angle=math.max(.3,math.min(1.5,math.atan2(player.y+12-h.y,player.x+15-h.x))) end
 a.mouthOffset={x=math.cos(angle)*66*dir-math.sin(angle)*12.6,y=math.sin(angle)*66*dir+math.cos(angle)*12.6}
 a.mouthOffset.x=a.mouthOffset.x*headScale;a.mouthOffset.y=a.mouthOffset.y*headScale
 a.head={x=h.x,y=h.y,w=180*headScale,h=219*headScale,angle=angle}
 local dx,dy=(spot.u-.5)*180*dir*headScale,(spot.v-.5)*219*headScale
 a.bones={{key=key,part='head',x=h.x,y=h.y,w=180*headScale,h=219*headScale,angle=angle,flip=dir==-1,gx=h.x+math.cos(angle)*dx-math.sin(angle)*dy,gy=h.y+math.sin(angle)*dx+math.cos(angle)*dy}}
 if swimming or barrage then
  -- Each vertebra shares a joint with its predecessor, including the neck.
  local jointX,jointY=h.x-math.cos(angle)*60*headScale,h.y-math.sin(angle)*60*headScale
  local jointAngle=angle
  local function connectedPose(targetX,targetY,halfLength,id)
   local desired=math.atan2(jointY-targetY,jointX-targetX)
   if a.returnMode then
    local previous=a.returnPosePositions[id]
    if previous then desired=math.atan2(jointY-previous.y,jointX-previous.x) end
    local index=id=='tail' and 7 or id
    local phase=a.clock*3.2-index*.62
    local dt=a.returnBuildDt or 0
    -- A travelling stroke grows toward the tail, with all joints kept attached.
    desired=desired+(math.sin(phase)-math.sin(phase-dt*3.2))*(.08+index*.035)
   end
   local bend=(desired-jointAngle+math.pi)%(2*math.pi)-math.pi
   local tilt=jointAngle+math.max(-.48,math.min(.48,bend))
   if a.returnMode then a.returnPoseAngles[id]=tilt end
   local x,y=jointX-math.cos(tilt)*halfLength,jointY-math.sin(tilt)*halfLength
   if a.returnMode then a.returnPosePositions[id]={x=x,y=y} end
   jointX,jointY=x-math.cos(tilt)*halfLength,y-math.sin(tilt)*halfLength
   jointAngle=tilt
   return x,y,tilt
  end
  for i=1,(a.webSegments or 9) do
   local part=a.returnMode and a.webPartIds[i] or i
   local x,y,tilt
   if barrage then x,y,tilt=h.x-65-i*62,h.y,0 else x,y,tilt=C.pathPoint(a,(65+i*(a.webMode and 46 or 62))*scale) end
   if a.webMode then
    local wave=a.clock*2-i*.55
    local offset=math.sin(wave)*i*1.2
    x=x-math.sin(tilt)*offset;y=y+math.cos(tilt)*offset
    x,y,tilt=connectedPose(x,y,23*scale,part)
   end
   local nx,ny=-math.sin(tilt)*scale,math.cos(tilt)*scale
   a.bones[#a.bones+1]={key='skeleton_spine',part=part,x=x,y=y,w=68*scale,h=34*scale,angle=tilt,gx=x,gy=y}
   a.bones[#a.bones+1]={key='skeleton_rib',part=part,side=-1,x=x-nx*45,y=y-ny*45,w=24*scale,h=80*scale,angle=tilt,gx=x-nx*45,gy=y-ny*45}
   a.bones[#a.bones+1]={key='skeleton_rib',part=part,side=1,x=x+nx*45,y=y+ny*45,w=24*scale,h=80*scale,angle=math.pi+tilt,gx=x+nx*45,gy=y+ny*45}
  end
  local x,y,tailAngle=C.pathPoint(a,a.webMode and (65+((a.webSegments or 6)+1)*46)*scale or 715)
  if barrage then x,y,tailAngle=h.x-715,h.y,0 end
  if swimming then local wag=math.sin(a.clock*5)*.10;x=x-math.sin(tailAngle)*wag*35;y=y+math.cos(tailAngle)*wag*35;tailAngle=tailAngle+wag end
  if a.webMode then x,y,tailAngle=connectedPose(x,y,32*scale,'tail') end
  if not a.webMode or a.webTail then a.bones[#a.bones+1]={key='skeleton_tail',part='tail',x=x,y=y,w=110*scale,h=120*scale,angle=tailAngle,flip=false,gx=x,gy=y} end
 end
 Stock.build(a)
 C.geometry(a)
end
function C.setup(a)
 a.returnMode=false;a.webMode=false;a.webSegments=nil;a.webTail=nil
 a.ropeFrame=nil;a.ropeFrameX=nil;a.ropeFrameY=nil;a.ropePlayerX=nil;a.ropePlayerY=nil;a.ropeDirX=nil;a.ropeDirY=nil;a.ropeAnchorX=nil;a.ropeAnchorY=nil;a.bombPlayerX=nil;a.bombPlayerY=nil
 Stock.reset(a);W.setup(a);a.round=0;a.hp=18;a.maxHp=18;a.whiteOrbs={};a.lightOnlySuction=false;a.healsFromEnergy=true;a.removedTeeth={};a.toothTargets={};a.fragments={};a.grab=nil;a.mouthPassage=function(x,y) return C.inMouth(a,x,y) end;a.attackIndex=1;a.boneTimer=.3;a.energyTimer=0;a.swimTrail={};a.trailTimer=0;a.damageProgress=0;a.detached={};a.swimY=300;a.cargoBlue=0;a.cargoBones=0;a.bodyHitCooldown=0;a.bodyContactLatched=false;a.bodyContact=nil;a.unlimitedCharge=true;a.noLightCharges=true;a.orbMist={};a.mistTimer=0;a.swimPath={};a.damageZones={};a.bombs={};a.bombBursts={};a.swallowBomb=nil;a.carryPlayer=false;a.pursuitCount=0;a.bombLayoutSerial=0
 player.charges=0;player.electrified=0;player.abyssSpit=nil;player.abyssKnock=nil;player.abyssHeld=nil
 a.mouthHitCooldown=0;a.mouthHitLatched=false
 for _,p in ipairs(a.lumenParticles)do p.consumed=true end
 C.enter(a,'intro')
 a.physicsTest=App.abyssPhysicsTest==true
 if a.physicsTest then C.enter(a,'traverse') end
 require('mobs.bosses.abyss.web_charge').setup(a)
 require('mobs.bosses.abyss.ricochet').setup(a)
end
local function roarSound() end
function C.enter(a,phase)
 local fromRight=phase=='traverse' and a.phase=='bombRain'
 a.motionFrom={x=a.swimHead.x,y=a.swimHead.y}
 a.phase=phase;a.phaseTime=0;a.open=phase~='intro' and phase~='bones' and not C.moving(a)
 if not C.moving(a) then a.swimHead.x=35;a.swimHead.y=300 end
 a.visibleSince=nil
 if phase=='rest' or phase=='suction' or phase=='recover' then a.whiteOrbs={} end
 a.energy=0
 if phase=='openingSpit' then
  a.round=1;a.plankton={};a.debris={};a.bombs={};a.cargoBlue=0;a.cargoBones=0;a.spitDone=false
  for _,p in ipairs(a.lumenParticles)do p.consumed=true;p.exhaled=false end
 elseif phase=='rest' then
  a.attackIndex=1;a.plankton={};a.round=a.round+1
  for _,p in ipairs(a.lumenParticles) do
   if p.consumed then p.x=35+(math.sin(p.id*127.1)*43758.5453%1)*(Arena.width-70);p.y=45+(math.sin(p.id*311.7)*19642.349%1)*510;p.consumed=false end
  end
 elseif phase=='roar' then
  a.grab=nil;a.pushFrom={x=player.x,y=player.y};roarSound()
 elseif phase=='retreat' then a.grab=nil;a.toothTargets={}
 elseif phase=='traverse' then
  a.pursuitCount=(a.pursuitCount or 0)+1;Stock.speed(a)
  a.swimDir=1;a.swimY=300;a.passDuration=(Arena.width+1260)/145;a.swimPath={};a.swimAngle=0;a.biteTime=0
  if #a.bombs==0 then Bombs.spawn(a) end
  a.pursuitBombCount=0;for _,b in ipairs(a.bombs)do if not b.hit then a.pursuitBombCount=a.pursuitBombCount+1 end end
  a.lastMouthX=nil;a.lastMouthY=nil;a.lastMouthAngle=nil;a.toothOpen=0;a.shedTimer=1.1;a.shedSerial=0;a.shedRibs={}
  a.grab=nil;a.boneTimer=.3;a.swimHead.x=fromRight and Arena.width-35 or 35;a.swimHead.y=a.swimY;a.swimAngle=fromRight and math.pi or 0;a.toothTargets={};a.trailTimer=0;a.lastDropX=nil;a.bodyContactLatched=false;a.bodyHitCooldown=0
 elseif phase=='bombRain' then
  a.open=true;a.round=a.round+1;a.grab=nil;a.carryPlayer=false
  a.swimHead.x=Arena.width-35;a.swimHead.y=300;a.swimAngle=math.pi
  a.bombs={};a.reloadTimer=.4;a.reloadCount=0
 elseif phase=='exitSwim' then
  a.open=false;a.exitDir=a.nextPhase=='bombRain' and 1 or (a.swimHead.x<player.x+15 and -1 or 1);a.swimDir=a.exitDir;a.swimAngle=a.exitDir==1 and 0 or math.pi
  a.exitTarget=a.exitDir==1 and Arena.width+1000 or -1000;a.exitY=player.y<288 and 500 or 100
 elseif phase=='returnHead' then
  a.returnX=a.nextPhase=='bones' and Arena.width*.8 or 35;a.returnY=a.nextPhase=='bones' and 115 or 300
  a.returnFrom=a.returnX>Arena.width*.5 and Arena.width+850 or -850
  a.swimHead.x=a.returnFrom;a.swimHead.y=a.returnY;a.grab=nil;a.toothTargets={}

 elseif phase=='bones' then a.swimHead.x=Arena.width*.8;a.swimHead.y=115;a.boneTimer=.3;a.energyTimer=0;a.volley=0
 elseif phase=='suction' then
  a.absorbed=false;a.swallowAge=0;a.cargoBlue=0;a.cargoBones=0;player.abyssKnock=nil;player.abyssSpit=nil;player.dashing=false
 elseif phase=='spit' then
  a.carryPlayer=false
  a.cargoBlue=0;a.plankton={};a.spitTimer=0;a.spitSerial=0;a.spitDone=false
  for _,p in ipairs(a.lumenParticles) do p.consumed=true;p.exhaled=false end
 elseif phase=='recover' then a.grab=nil
 end
 a.buildBones()
end
function C.contact(a)
 if a.returnMode then return require('mobs.bosses.abyss.ricochet').contact(a) end
 if a.webMode then return require('mobs.bosses.abyss.web_charge').contact(a) end
 if a.physicsTest then Bombs.player(a);return end
 if a.defeated or player.reset then return end
 if a.phase=='bombRain' then Bombs.player(a);return end
 if a.defeated or player.reset or a.phase=='roar' or a.phase=='openingSpit' or a.phase=='exitSwim' or a.phase=='returnHead' or a.phase=='retreat' then return end
 player.x=math.max(player.x,C.playerMinX(a))
 local px,py=player.x+15,player.y+12;local mx,my=C.mouth(a)
 local inThroat=C.throat(a,px,py)
 if not inThroat then a.mouthHitLatched=false end
 if a.phase=='traverse' then
  local touching=false
  for i=1,#a.bones do if a.overlapsBone(a.bones[i]) then touching=true;break end end
  if not touching then a.bodyContactLatched=false end
 end
 Bombs.player(a);if player.reset then return end
 if not a.carryPlayer then W.contact(a) end
end
function C.fireBones(a)
 a.volley=a.volley+1;a.buildBones()
 for _=1,2 do if Stock.launch(a,Stock.choose(a,nil,false),680)then a.buildBones() end end
end
function C.suction(a,dt)
 if a.absorbed or a.defeated or player.reset or a.grab then return end
 local mx,my=C.mouth(a);local dx,dy=mx-player.x-15,my-player.y-12
 local d=math.sqrt(dx*dx+dy*dy);local step=math.min(d,(460+d*1.8)*dt)
 player.dashing=false
 if d>0 then player.x=player.x+dx/d*step;player.y=player.y+dy/d*step end
 if d-step>30 then return end
 a.absorbed=true;a.grab=nil
 player.charges=0;player.electrified=0;player.illuminated=0
 BossFX.burst(mx,my,{.25,.8,1},2)
end
function C.spit(a,dt,freeVolley)
 if a.spitDone then return end
 a.spitDone=true;a.spitFlash=.65
 if not freeVolley then player.abyssSpit={time=0,duration=.3,arc=-35,fromX=player.x,fromY=player.y,toX=Arena.width-65,toY=288}
 player.abyssGrace=1.2 end
 local mx,my=C.mouth(a)
 for i=1,a.cargoBones do
  local angle=(i%2==0 and -1 or 1)*(.65+(i%4)*.13)
  a.debris[#a.debris+1]={x=mx,y=my,vx=math.cos(angle)*1050,vy=math.sin(angle)*1050,w=40,h=14,angle=angle}
 end
 a.cargoBlue=0;a.cargoBones=0
 for _,p in ipairs(a.lumenParticles) do if p.consumed then
  local n=p.id+a.round*97;local rx=math.sin(n*127.1)*43758.5453%1;local ry=math.sin(n*311.7)*19642.349%1
  p.tx=35+rx*(Arena.width-70);p.ty=45+ry*510;p.fromX=mx;p.fromY=my;p.scatter=0
  p.x=mx;p.y=my;p.vx=(p.tx-mx)/.4;p.vy=(p.ty-my)/.4;p.consumed=false;p.exhaled=true
 end end
 Bombs.spawn(a,mx,my)
 if freeVolley then for _,b in ipairs(a.bombs)do b.flightDuration=.85;b.dangerInFlight=true end end
 BossFX.burst(mx,my,{.3,.85,1},6)
end

function C.transition(a,target)
 if a.phase=='bones' then
  a.swimPath={};for i=100,0,-1 do a.swimPath[#a.swimPath+1]={x=a.swimHead.x-i*8,y=a.swimHead.y}end
 end
 a.nextPhase=target;C.enter(a,'exitSwim')
end
function C.duration(a) return a.phase=='traverse' and a.passDuration or durations[a.phase] end
local function tick(a,dt)
 local phase=a.phase
 a.bodyHitCooldown=math.max(0,a.bodyHitCooldown-dt)
 a.mouthHitCooldown=math.max(0,(a.mouthHitCooldown or 0)-dt)
 a.clock=a.clock+dt;a.flash=math.max(0,a.flash-dt);a.spitFlash=math.max(0,a.spitFlash-dt)
 a.phaseTime=a.phaseTime+dt*(phase=='traverse' and 1 or (a.attackRate or 1))
 if phase=='roar' then
  local t=math.min(1,a.phaseTime/1.1);t=1-(1-t)^3
  player.x=a.pushFrom.x+(Arena.width-110-a.pushFrom.x)*t
  player.y=math.max(45,math.min(530,a.pushFrom.y));player.dashing=false
 end
 if phase=='retreat' then
  local t=math.min(1,a.phaseTime/durations.retreat);t=t*t
  a.swimHead.x=a.motionFrom.x+(-220-a.motionFrom.x)*t
  a.swimHead.y=a.motionFrom.y+(300-a.motionFrom.y)*t
 elseif phase=='exitSwim' then
  local t=math.min(1,a.phaseTime/durations.exitSwim);t=t*t
  a.swimHead.x=a.motionFrom.x+(a.exitTarget-a.motionFrom.x)*t
  a.swimHead.y=a.motionFrom.y+(a.exitY-a.motionFrom.y)*t
  local last=a.swimPath[#a.swimPath]
  if not last or (last.x-a.swimHead.x)^2+(last.y-a.swimHead.y)^2>=64 then a.swimPath[#a.swimPath+1]={x=a.swimHead.x,y=a.swimHead.y};if #a.swimPath>170 then table.remove(a.swimPath,1)end end
 elseif phase=='returnHead' then
  local t=math.min(1,a.phaseTime/durations.returnHead);t=t*t*(3-2*t)
  a.swimHead.x=a.returnFrom+(a.returnX-a.returnFrom)*t;a.swimHead.y=a.returnY
 elseif phase=='bombRain' then
  a.reloadTimer=a.reloadTimer-dt
  if a.reloadCount<Bombs.count and a.reloadTimer<=0 then
   Bombs.launch(a);a.reloadCount=a.reloadCount+1;a.reloadTimer=.45
  end
 elseif phase=='traverse' then
  C.swim(a,dt);if a.defeated then return end
  a.shedTimer=a.shedTimer-dt;if a.shedTimer<=0 then C.shedBone(a);a.shedTimer=a.shedTimer+1.2 end
  a.trailTimer=a.trailTimer-dt
  if a.trailTimer<=0 then
   a.trailTimer=a.trailTimer+.04
   local x,y=C.pathPoint(a,240)
   if x>-80 and x<Arena.width+80 then a.swimTrail[#a.swimTrail+1]={x=x,y=y,age=0} end
  end
 end
 for i=#a.detached,1,-1 do local p=a.detached[i];p.age=p.age+dt;p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt;p.vy=p.vy+(p.gravity or 0)*dt;p.vy=p.vy+150*dt;p.angle=p.angle+dt*.8;if p.age>1.5 then table.remove(a.detached,i) end end
 for i=#a.swimTrail,1,-1 do local p=a.swimTrail[i];p.age=p.age+dt;if p.age>1.65 then table.remove(a.swimTrail,i) end end
 a.mistTimer=a.mistTimer-dt
 if a.mistTimer<=0 then
  a.mistTimer=.065
  for _,p in ipairs(a.plankton) do if not p.red and not p.lethal then
   a.orbMist[#a.orbMist+1]={x=p.x,y=p.y,age=0,seed=a.clock*11+p.y}
  end end
 end
 for i=#a.orbMist,1,-1 do local p=a.orbMist[i]
  p.age=p.age+dt;p.y=p.y+math.sin(p.seed+p.age*2)*10*dt
  if p.age>1.6 then table.remove(a.orbMist,i) end
 end
 a.buildBones()
 Bombs.update(a,dt)
 if a.carryPlayer then local mx,my=C.mouth(a);player.x=mx-15;player.y=my-12 end
 C.contact(a)
 if player.reset then a.grab=nil;return end
 if a.defeated or player.reset then return end
 if phase=='suction' then
  C.suction(a,dt)
  if a.absorbed then
   local mx,my=C.mouth(a);player.x=mx-15;player.y=my-12;a.swallowAge=a.swallowAge+dt
   if a.swallowAge>.35 then a.carryPlayer=true;C.transition(a,'spit');a.refreshLight();return end
  end
 end
 if phase=='spit' or phase=='openingSpit' then C.spit(a,dt) end
 if phase=='bones' then
  a.boneTimer=a.boneTimer-dt
  if a.boneTimer<=0 then C.fireBones(a);a.boneTimer=a.boneTimer+1.05 end

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
  if p.armTime then p.armTime=math.max(0,p.armTime-dt) end
  if p.recoverTime then p.recoverTime=math.max(0,p.recoverTime-dt)end
  if p.life then p.life=p.life-dt end
  if p.life and p.life<=0 then table.remove(a.debris,i)
  elseif phase=='suction' then
   local dx,dy=mx-p.x,my-p.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy));local step=math.min(d,(520+d*2)*dt)
   p.x=p.x+dx/d*step;p.y=p.y+dy/d*step
   if d-step<20 then if not p.tooth and not Stock.restore(a,p)then a.cargoBones=a.cargoBones+1 end;table.remove(a.debris,i);a.buildBones() end
  else
   local ox,oy=p.x,p.y
   p.x=p.x+p.vx*dt;p.y=p.y+(p.vy or 0)*dt;p.vy=(p.vy or 0)+(p.gravity or 0)*dt
   if p.throatTravel and p.throatTravel>0 then
    p.throatTravel=math.max(0,p.throatTravel-640*dt)
    local mx,my=C.swimMouth(a);local angle=a.swimAngle or 0;local c,s=math.cos(angle),math.sin(angle)
    local along=24-p.throatTravel;local across=p.toothSide or 0
    p.x,p.y=mx+c*along-s*across,my+s*along+c*across;p.angle=angle
    if p.throatTravel==0 then
     local dx,dy=p.targetX-p.x,p.targetY-p.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy))
     p.vx,p.vy=dx/d*640,dy/d*640;p.angle=math.atan2(dy,dx)
    end
   end
   if Bombs.tooth(a,p,ox,oy)then table.remove(a.debris,i)
   elseif Stock.recover(a,p,ox,oy)then table.remove(a.debris,i);a.buildBones()
   elseif p.stockId then
    if p.x<30 or p.x>Arena.width-30 or p.y<40 or p.y>560 then p.x=math.max(30,math.min(Arena.width-30,p.x));p.y=math.max(40,math.min(560,p.y));p.vx=0;p.vy=0 end
   elseif p.x>Arena.width+70 or p.x< -70 or p.y>670 or p.y< -70 then table.remove(a.debris,i) end
  end
 end
 for _,p in ipairs(a.lumenParticles) do
  p.age=p.age+dt
  if not p.consumed then
   if phase=='suction' then
    local dx,dy=mx-p.x,my-p.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy));local step=math.min(d,(450+d*2)*dt)
    p.vx=dx/d*(450+d*2);p.vy=dy/d*(450+d*2);p.x=p.x+dx/d*step;p.y=p.y+dy/d*step
    if d<18 then p.consumed=true end
   elseif p.scatter then
    p.scatter=math.min(1,p.scatter+dt/.4);local t=1-(1-p.scatter)^2;p.x=p.fromX+(p.tx-p.fromX)*t;p.y=p.fromY+(p.ty-p.fromY)*t
    if p.scatter==1 then p.scatter=nil;p.exhaled=false;p.vx=0;p.vy=0 end
   elseif p.exhaled then p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt;p.vx=p.vx*math.exp(-dt*1.5);p.vy=p.vy*math.exp(-dt*1.5);if math.abs(p.vx)<12 then p.exhaled=false end
   else require('abyss_light_fx').stir(p,dt);p.vx=math.sin(p.age*.6+p.id)*9;p.vy=math.cos(p.age*.7+p.id)*7;p.x=math.max(25,math.min(Arena.width-25,p.x+p.vx*dt));p.y=math.max(35,math.min(565,p.y+p.vy*dt)) end
  end
 end
 C.contact(a)
 if a.defeated or player.reset then return end
 local finished=a.phaseTime>=C.duration(a)
 if phase=='traverse' then
  finished=true;for _,bomb in ipairs(a.bombs)do if not bomb.hit then finished=false;break end end
 end
 if a.phase==phase and finished and not a.swallowBomb then
  if phase=='intro' then C.enter(a,'openingSpit')
  elseif phase=='openingSpit' then C.enter(a,'traverse')
  elseif phase=='rest' then C.enter(a,a.round==1 and 'roar' or 'retreat')
  elseif phase=='roar' then C.enter(a,'retreat')
  elseif phase=='retreat' then C.enter(a,'traverse')
  elseif phase=='traverse' then C.transition(a,'bombRain')
  elseif phase=='bombRain' then C.enter(a,'traverse')
  elseif phase=='exitSwim' then C.enter(a,(a.nextPhase=='traverse' or a.nextPhase=='bombRain') and a.nextPhase or 'returnHead')
  elseif phase=='returnHead' then local target=a.nextPhase or 'bones';C.enter(a,target)
  elseif phase=='bones' then C.transition(a,'suction')
  elseif phase=='settle' then C.enter(a,'suction')
  elseif phase=='suction' then C.transition(a,'spit')
  elseif phase=='spit' then a.round=a.round+1;C.enter(a,'traverse')
  elseif phase=='recover' then C.enter(a,'rest') end
 end
 a.refreshLight()
end
function C.togglePhysics(a)
 if a.webMode then a.physicsTest=not a.physicsTest;a.buildBones();return end
 a.physicsTest=not a.physicsTest;App.abyssPhysicsTest=a.physicsTest
 a.debris={};a.threads={};a.toothOpen=0;a.spitFlash=0;a.swallowBomb=nil;a.carryPlayer=false;a.grab=nil
 player.abyssSpit=nil;player.abyssHeld=nil
 if a.physicsTest then
  Replay.recording=false;Online.current=nil;App.singleLevel=true
  Bombs.spawn(a);a.buildBones()
 else C.enter(a,'traverse') end
end
function C.update(a,dt)
 if a.returnMode then return require('mobs.bosses.abyss.ricochet').update(a,dt) end
 if a.webMode then return require('mobs.bosses.abyss.web_charge').update(a,dt) end
 Bombs.beginFrame(a,dt)
 if a.physicsTest then
  if player.reset then return end
  a.clock=a.clock+dt;a.bones={}
  local steps=math.max(1,math.ceil(dt*180))
  for _=1,steps do Bombs.update(a,dt/steps);Bombs.player(a);if player.reset then break end end
  local alive=false;for _,b in ipairs(a.bombs)do if not b.hit then alive=true end end
  if not alive and not player.reset then Bombs.spawn(a) end
  return
 end
 if a.defeated or player.reset then return end
 local steps=math.max(1,math.ceil(dt*math.max(1,a.attackRate or 1)*180))
 for _=1,steps do tick(a,dt/steps);if a.defeated or player.reset then break end end
end
local mistShader
local function mist(a,mask)
 local g=love.graphics
 mistShader=mistShader or g.newShader([[
 extern vec2 center;extern vec2 radius;extern float clock;extern float seed;
 varying vec2 mistPosition;
 #ifdef VERTEX
 vec4 position(mat4 transform_projection,vec4 vertex_position){mistPosition=vertex_position.xy;return transform_projection*vertex_position;}
 #endif
 #ifdef PIXEL
 float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
 float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
 vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
  vec2 p=(mistPosition-center)/radius;float d=length(p);
  float n=noise(p*3.+vec2(clock*.6+seed,clock*.35));
  float wisps=noise(p*6.+n*2.-clock*.3);
  float fade=exp(-d*d*3.)*(1.-smoothstep(.65,1.,d));
  return vec4(color.rgb,color.a*fade*(.42+.58*n)*(.7+.3*wisps));
 }
 #endif
 ]])
 g.push('all');g.setBlendMode('add');g.setShader(mistShader);mistShader:send('clock',a.clock)
 local function cloud(x,y,rx,ry,alpha,seed)
  mistShader:send('center',{x,y});mistShader:send('radius',{rx,ry});mistShader:send('seed',seed)
  if mask then g.setColor(1,1,1,alpha) else g.setColor(.12,.5,1,alpha*.7) end
  g.rectangle('fill',x-rx,y-ry,rx*2,ry*2)
 end
 for _,p in ipairs(a.orbMist) do
  local radius=32+p.age*26
  cloud(p.x+math.sin(p.seed+p.age*2)*p.age*9,p.y,radius,radius*.72,(1-p.age/1.6)*.18,p.seed)
 end
 for _,p in ipairs(a.plankton) do if not p.red and not p.lethal then cloud(p.x,p.y,88,76,.65,p.y*.03) end end
 g.pop()
end
function C.drawMask(a)
 if a.defeated then return end
 mist(a,true)
end
function C.draw(a)
 if a.returnMode then return require('mobs.bosses.abyss.ricochet').draw(a) end
 if a.webMode then return require('mobs.bosses.abyss.web_charge').draw(a) end
 if a.defeated then return end
 W.draw(a);mist(a,false)
 if a.spitFlash>0 then
  local g=love.graphics;local mx,my=C.mouth(a);local t=1-a.spitFlash/.65
  g.push('all');g.setBlendMode('add');g.setColor(.35,.8,1,(1-t)*.6);g.setLineWidth(5*(1-t)+1)
  g.arc('line','open',mx,my,35+t*700,-1.25,1.25);g.pop()
 end
 Bombs.draw(a)
 local glow=love.graphics;glow.push('all');glow.setBlendMode('add')
 for i,p in ipairs(a.swimTrail) do
  local fade=1-p.age/1.65
  glow.setColor(.15,.55,1,.10*fade);glow.ellipse('fill',p.x,p.y,28,12)
  glow.setColor(.5,.85,1,.5*fade);glow.circle('fill',p.x,p.y,2.5*fade)
  local previous=a.swimTrail[i-1]
  if previous and (previous.x-p.x)^2+(previous.y-p.y)^2<65^2 then glow.setColor(.25,.7,1,.18*fade);glow.setLineWidth(3);glow.line(previous.x,previous.y,p.x,p.y) end
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
