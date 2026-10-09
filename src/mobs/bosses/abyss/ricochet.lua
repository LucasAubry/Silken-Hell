local R={}
local Hunt=require('mobs.bosses.abyss.hunt')
local Escape=require('mobs.bosses.abyss.rear_escape')
local BoltMotion=require('mobs.bosses.abyss.bolt_motion')
local Fish=require('mobs.bosses.abyss.charged_fish')
local Wake=require('mobs.bosses.abyss.tooth_wake')
local function unit(x,y) local d=math.max(.001,math.sqrt(x*x+y*y));return x/d,y/d,d end
local function burst(x,y,power) if BossFX then BossFX.burst(x,y,{.65,.9,1},power or 2) end end
function R.setup(a)
 Wake.setup(a);Fish.setup(a);Escape.setup(a);Hunt.setup(a)
 a.returnSafeUntil=0;a.returnContactLatched=false;a.returnMode=true;a.webAnchors={};a.webLinks={};a.webHeld=nil
 a.hp=8;a.maxHp=8;a.returnHealth={head=1,tail=1};a.webPartIds={1,2,3,4,5,6}
 for i=1,6 do a.returnHealth[i]=1 end
 a.returnShots={};a.returnShards={};a.returnStuck={};a.returnShotTimer=1.6;a.returnVolley=0
 a.returnKnockTime=0;a.returnKnockX=0;a.returnKnockY=0
 a.returnPause=0;a.returnImpact=0;a.returnTurn=0;a.returnSpeed=190;a.returnPoseAngles={};a.returnPosePositions={};a.returnFlee=0;a.returnMouth=0;a.returnPX=player.x+15;a.returnPY=player.y+12
 a.swimHead={x=Arena.width*.64,y=210};a.swimAngle=0;a.swimPath={}
 for d=600,0,-6 do a.swimPath[#a.swimPath+1]={x=a.swimHead.x-d,y=210} end
 a.buildBones()
end
function R.pace(a)
 local rage=math.max(0,math.min(1,(a.maxHp-a.hp)/math.max(1,a.maxHp-1)))
 return 1.12+rage*.63,.85-rage*.43
end
function R.rearPart(a)
 return a.webTail and 'tail' or a.webPartIds[#a.webPartIds] or 'head'
end
local function target(a,x,y)
 local best,dist
 for _,b in ipairs(a.bones)do
  if b.part~='head' or a.hp<=1 then
   local d=(b.x-x)^2+(b.y-y)^2
   if not dist or d<dist then best,dist=b,d end
  end
 end
 return best
end
function R.reflect(a,p)
 local b=target(a,p.x,p.y);if not b then return end
 p.friendly=true;p.target=b.part;p.life=3;p.window=0
 p.vx,p.vy=unit(b.x-p.x,b.y-p.y);p.vx=p.vx*780;p.vy=p.vy*780
 burst(p.x,p.y,1.4)
end
function R.hit(a,b,p)
 if b.part~=R.rearPart(a) then return end
 local hp=a.returnHealth[b.part];if not hp or hp<=0 then return end
 a.returnHealth[b.part]=hp-1;a.returnImpact=.16
 burst(p.x,p.y,hp==1 and 4 or 2)
 if hp>1 then
  local c,s=math.cos(b.angle),math.sin(b.angle);local dx,dy=p.x-b.x,p.y-b.y
  a.returnStuck[#a.returnStuck+1]={part=b.part,key=b.key,dx=dx*c+dy*s,dy=-dx*s+dy*c,angle=p.angle-b.angle,tooth=p.tooth}
 else
  for _,bone in ipairs(a.bones)do if bone.part==b.part then
   for i=1,3 do
    local theta=i*2.399+bone.x*.01
    a.returnShards[#a.returnShards+1]={x=bone.x,y=bone.y,vx=math.cos(theta)*110,vy=math.sin(theta)*110,age=0,life=2.2,angle=theta}
   end
  end end
  if b.part=='tail' then a.webTail=false elseif type(b.part)=='number' then
   for i,id in ipairs(a.webPartIds)do if id==b.part then table.remove(a.webPartIds,i);break end end
   a.webSegments=#a.webPartIds
  end
  for i=#a.returnStuck,1,-1 do if a.returnStuck[i].part==b.part then table.remove(a.returnStuck,i) end end
  a.returnFlee=.65
 end
 a.hurt(1);a.buildBones()
 if a.hp<=0 then R.clearCombat(a) end
end
function R.clearCombat(a)
 Escape.setup(a);Hunt.setup(a)
 a.returnShots={};a.returnShards={};a.returnStuck={};a.chargedFish={}
 a.debris={};a.threads={};a.bombs={};a.bombBursts={};a.orbMist={};a.lightMotes={}
 a.returnKnockTime=0;a.returnKnockX=0;a.returnKnockY=0;a.returnMouth=0;a.returnImpact=0;a.returnFlee=0
 a.fishCharge=0;player.charges=0;player.electrified=0;player.illuminated=0
 player.abyssKnock=nil;player.abyssSpit=nil
end
function R.fire(a)
 if a.defeated or a.hp<=0 or a.bite then return end
 a.returnVolley=a.returnVolley+1
 local pattern=a.returnVolley%4
 local volley=pattern==1 and {true} or pattern==2 and {false,true} or pattern==3 and {false,true,false} or {true,false}
 local count=#volley
 a.returnMouth=.5;a.open=true;a.buildBones()
 local mx,my=a.mouth()
 local c,s=math.cos(a.swimAngle),math.sin(a.swimAngle)
 for i=1,count do
  local lightning=volley[i]
  local side=(i-(count+1)/2)*8
  local x,y=mx-c*16-s*side,my-s*16+c*side
  local aim=math.atan2(player.y+12-y,player.x+15-x)+(i-(count+1)/2)*.25
  if lightning then x,y=mx+c*8-s*side,my+s*8+c*side;aim=a.swimAngle end
  local speed=lightning and 460 or 560
  a.returnShots[#a.returnShots+1]={x=x,y=y,wakeX=x,wakeY=y,vx=math.cos(aim)*speed,vy=math.sin(aim)*speed,w=25,h=12,angle=aim,life=5,age=0,window=0,tooth=not lightning,lightning=lightning,bounces=0}
 end
end
function R.contact(a)
 if a.defeated or a.hp<=0 or player.reset or a.physicsTest then return end
 local mx,my=a.mouth();local dx,dy=player.x+15-mx,player.y+12-my
 local c,s=math.cos(a.swimAngle),math.sin(a.swimAngle)
 local along,across=dx*c+dy*s,-dx*s+dy*c
 if along*along/28^2+across*across/(a.open and 32 or 21)^2<1 then Hazards.kill('abyss_bite');return end
 local touched
 for _,b in ipairs(a.bones)do if a.overlapsBone(b)then touched=b;break end end
 if not touched then if a.clock>=a.returnSafeUntil then a.returnContactLatched=false end;return end
 -- A successful ram remains safe until the player clears the skeleton.
 -- This protection never applies to teeth or incoming fish.
 if a.returnContactLatched then return end
 if a.fishCharge>0 then
  local bone
  local rear=R.rearPart(a)
  for _,b in ipairs(a.bones)do if b.part==rear then bone=b;break end end
  if bone then
   local damage=math.min(a.hp,a.fishCharge)
   a.fishCharge=0;player.charges=0;player.electrified=0;player.illuminated=0
   a.returnContactLatched=true;a.returnSafeUntil=a.clock+.55
   local nx,ny,d=unit(touched.x-player.x-15,touched.y-player.y-12)
   if d<1 then nx,ny=-math.cos(a.swimAngle),-math.sin(a.swimAngle) end
   for _=1,damage do
    local rearPart=R.rearPart(a)
    local nextBone
    for _,b in ipairs(a.bones)do if b.part==rearPart then nextBone=b;break end end
    if not nextBone or a.hp<=0 then break end
    R.hit(a,nextBone,{x=player.x+15,y=player.y+12,angle=a.swimAngle})
   end
   if a.hp<=0 then R.clearCombat(a);return end
   a.returnKnockTime=.4;a.returnKnockX=nx*720;a.returnKnockY=ny*720
   a.returnFlee=0;a.returnTurn=0
   require('mobs.bosses.abyss.player_recoil').start(a,-nx,-ny)
  else Hazards.kill('abyss_bite') end
 else Hazards.kill('abyss_bite') end
end
function R.update(a,dt)
 if a.defeated or a.hp<=0 then R.clearCombat(a);return end
 if dt<=0 or player.reset then return end
 local px,py=player.x+15,player.y+12
 local oldX,oldY=a.returnPX or px,a.returnPY or py
 a.returnPX,a.returnPY=px,py
 if a.physicsTest then Wake.update(a,dt,{});return end
 local wakes={}
 for _,p in ipairs(a.returnShots)do p.wakeX,p.wakeY=p.x,p.y end
 local steps=math.max(1,math.ceil(dt*240));local step=dt/steps
 for n=1,steps do
  local x,y=oldX+(px-oldX)*n/steps,oldY+(py-oldY)*n/steps
  a.clock=a.clock+step;a.flash=math.max(0,a.flash-step)
  a.returnImpact=math.max(0,a.returnImpact-step);a.returnPause=math.max(0,a.returnPause-step);a.returnFlee=math.max(0,a.returnFlee-step)
  a.returnMouth=math.max(0,a.returnMouth-step);a.open=a.returnMouth>0
  if a.returnPause<=0 then
   local h=a.swimHead
   local pace=R.pace(a)
   local aim,moveSpeed,moveRate,biting=Hunt.update(a,step,x,y)
   a.open=biting or a.returnMouth>0
   local escapeAim,escapeSpeed,escapeRate
   if not biting and not a.excursion then escapeAim,escapeSpeed,escapeRate=Escape.update(a,step,x,y) end
   if escapeAim then aim=escapeAim end
   local turn=(aim-a.swimAngle+math.pi)%(2*math.pi)-math.pi
   if a.rearEscape and a.rearEscape.age>=.5 and a.rearEscape.age<1.1 and turn*a.rearEscape.side<0 then turn=turn+a.rearEscape.side*math.pi*2 end
   local recovering=1-a.returnKnockTime/.4
   local offscreen=h.x<0 or h.x>Arena.width or h.y<0 or h.y>600
   local rate=(escapeRate or moveRate)*recovering*pace
   local desired=math.max(-rate,math.min(rate,turn*2.5))
   a.returnTurn=a.returnTurn+(desired-a.returnTurn)*(1-math.exp(-7*step))
   a.swimAngle=a.swimAngle+a.returnTurn*step
   local desiredSpeed=((escapeSpeed or moveSpeed)+math.sin(a.clock*.8)*12)*pace*(a.returnImpact>0 and .85 or 1)
   a.returnSpeed=a.returnSpeed+(desiredSpeed-a.returnSpeed)*(1-math.exp(-6*step))
   local speed=a.returnSpeed*recovering
   if a.returnKnockTime>0 then
    local recoilStep=math.min(step,a.returnKnockTime)
    local decay=math.exp(-6*recoilStep)
    local kx,ky=a.returnKnockX*(1-decay)/6,a.returnKnockY*(1-decay)/6
    h.x=h.x+kx;h.y=h.y+ky
    -- Move the history and joints together: recoil must not stretch the neck.
    for _,p in ipairs(a.swimPath)do p.x=p.x+kx;p.y=p.y+ky end
    for _,p in pairs(a.returnPosePositions)do p.x=p.x+kx;p.y=p.y+ky end
    a.returnKnockX=a.returnKnockX*decay;a.returnKnockY=a.returnKnockY*decay
    a.returnKnockTime=math.max(0,a.returnKnockTime-recoilStep)
   end
   h.x=h.x+math.cos(a.swimAngle)*speed*step
   h.y=h.y+math.sin(a.swimAngle)*speed*step
   local last=a.swimPath[#a.swimPath]
   if not last or (last.x-h.x)^2+(last.y-h.y)^2>36 then
    a.swimPath[#a.swimPath+1]={x=h.x,y=h.y};if #a.swimPath>180 then table.remove(a.swimPath,1) end
   end
   a.returnBuildDt=step;a.buildBones();a.returnBuildDt=nil
  end
  a.returnShotTimer=a.returnShotTimer-step
  if not a.bite and a.returnShotTimer<=0 and #a.returnShots<16 then local _,interval=R.pace(a);R.fire(a);a.returnShotTimer=interval end
  for i=#a.returnShots,1,-1 do
   local p=a.returnShots[i];p.life=p.life-step;p.age=p.age+step
   local dx,dy,d=unit(p.x-x,p.y-y)
   if not p.friendly and d<25 then
    if p.lightning then Fish.trigger(a);p.life=0
    else Hazards.kill('abyss_bite');p.life=0 end
   end
   if p.lightning then BoltMotion.update(p,step)
   else p.x=p.x+p.vx*step;p.y=p.y+p.vy*step end
   if p.life<=0 or p.x<0 or p.x>Arena.width or p.y<0 or p.y>600 then
    if p.tooth then wakes[#wakes+1]={ox=p.wakeX or p.x,oy=p.wakeY or p.y,x=p.x,y=p.y} end
    table.remove(a.returnShots,i)
   end
  end
  for i=#a.returnShards,1,-1 do
   local p=a.returnShards[i];p.age=p.age+step;p.life=p.life-step
   p.x=p.x+p.vx*step;p.y=p.y+p.vy*step;p.vx=p.vx*math.exp(-2*step);p.vy=p.vy*math.exp(-2*step)
   if p.life<=0 then table.remove(a.returnShards,i) end
  end
  Fish.update(a,step,x,y)
  if player.reset or a.hp<=0 then break end
 end
 for _,p in ipairs(a.returnShots)do if p.tooth then
  wakes[#wakes+1]={ox=p.wakeX or p.x,oy=p.wakeY or p.y,x=p.x,y=p.y}
 end end
 Wake.update(a,dt,wakes)
 R.contact(a)
end
function R.draw(a)
 Wake.draw(a)
 if a.defeated or a.hp<=0 then return end
 Fish.draw(a)
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 for _,p in ipairs(a.returnShots)do
  local glowing=p.friendly
  if glowing then
   g.setColor(.3,.85,1,.16);g.circle('fill',p.x,p.y,23)
   g.setColor(.7,.95,1,.85);g.setLineWidth(2);g.circle('line',p.x,p.y,16+math.sin(a.clock*22)*2)
  end
  g.setColor(.82,.94,1)
  if p.lightning then
   require('abyss_light_fx').bolt(p,a.clock)
  elseif p.tooth then
   g.push();g.translate(p.x,p.y);g.rotate(p.angle);g.polygon('fill',14,0,-10,-5,-6,0,-10,5);g.pop()
  else Art.draw(p.key,p.x,p.y,p.w,p.angle,p.h) end
 end
 for _,p in ipairs(a.returnShards)do
  g.setColor(.65,.9,1,.17);g.circle('fill',p.x,p.y,17)
  g.setColor(.85,.95,1,math.min(1,p.life));Art.draw('skeleton_spine',p.x,p.y,20,p.angle+p.age,11)
 end
 g.pop()
end
function R.overlay(a)
 if a.defeated or a.hp<=0 then return end
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 for _,b in ipairs(a.bones)do
  local damage=1-(a.returnHealth[b.part] or 1)
  if damage>0 then
   g.push();g.translate(b.x,b.y);g.rotate(b.angle);g.setColor(.65,.95,1,.9);g.setLineWidth(1.5)
   g.line(-12,-8,-4,-2,-7,4,7,10)
   if damage>1 then g.line(-4,-2,4,-9,13,-5);g.line(-7,4,-15,11) end
   g.pop()
  end
 end
 for _,p in ipairs(a.returnStuck)do for _,b in ipairs(a.bones)do if b.part==p.part and b.key==p.key then
  local c,s=math.cos(b.angle),math.sin(b.angle)
  g.setColor(.9,.97,1)
  g.push();g.translate(b.x+c*p.dx-s*p.dy,b.y+s*p.dx+c*p.dy);g.rotate(b.angle+p.angle)
  g.polygon('fill',11,0,-8,-4,-5,0,-8,4);g.pop();break
 end end end
 g.pop()
end
return R
