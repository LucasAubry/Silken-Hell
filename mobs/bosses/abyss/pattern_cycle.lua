-- White arena zones with a learnable rhythm, then bones, energy and suction.
local C={}
local W=require 'mobs.bosses.abyss.whip_cycle'
local Jaw=require 'mobs.bosses.abyss.jaw'
C.jaw=Jaw
-- Fixed arena bands: frame, columns, rows, then a cross. Dark spaces stay safe.
C.sequence={
 {kind='frame',duration=.95},
 {kind='columns',duration=.95},
 {kind='rows',duration=.95},
 {kind='cross',duration=.95},
}
C.mouth=W.mouth
function C.pivot(a) return a.swimHead.x+30,a.swimHead.y+29 end
function C.playerMinX(a,y)
 if not a.active or not a.boss or a.defeated or player.abyssSpit then return 23 end
 local cy=(y or player.y)+12
 if cy<a.swimHead.y-135 or cy>a.swimHead.y+195 then return a.swimHead.x+213 end
 return a.swimHead.x+20
end
function C.inMouth(a,x,y) return not Jaw.blocked(a,x-15,y-12) end
C.blockedPlayer=Jaw.blocked
C.drawOverlay=Jaw.draw
C.sheltered=W.sheltered
function C.lockPlayer(a) return not a.defeated and not player.reset and (a.grab~=nil or a.phase=='suction') end
local durations={intro=1.2,rest=.9,fire=2.4,gap=1.6,bones=5.5,settle=.8,suction=6.5,recover=.8}
function C.geometry(a)
 a.beams={};a.zones={}
 if a.phase~='fire' then return end
 local left=math.min(260,Arena.width*.32);local width=Arena.width-left-24
 local function vertical(t) a.zones[#a.zones+1]={x=left+width*t-24,y=22,w=48,h=556} end
 local function horizontal(y) a.zones[#a.zones+1]={x=22,y=y-24,w=Arena.width-44,h=48} end
 local kind=C.sequence[a.attackIndex].kind
 if kind=='frame' then vertical(.25);vertical(.75);horizontal(175);horizontal(425)
 elseif kind=='columns' then vertical(.4);vertical(.85)
 elseif kind=='rows' then horizontal(245);horizontal(490)
 elseif kind=='cross' then vertical(.55);horizontal(300) end
end
function C.build(a)
 local h=a.swimHead;local key=a.open and 'skeleton_open' or 'skeleton_head'
 local spot=Art.images[key].glow or {u=.5,v=.5}
 a.mouthOffset={x=153,y=29}
 a.head={x=h.x,y=h.y,w=414,h=504,angle=0}
 a.bones={{key=key,x=h.x,y=h.y,w=414,h=504,angle=0,gx=h.x+(spot.u-.5)*414,gy=h.y+(spot.v-.5)*504}}
 C.geometry(a)
end
function C.setup(a)
 W.setup(a);a.hp=10;a.maxHp=10;a.whiteOrbs={};a.lightOnlySuction=false;a.healsFromEnergy=true;a.removedTeeth={};a.toothTargets={};a.fragments={};a.grab=nil;a.mouthPassage=function(x,y) return C.inMouth(a,x,y) end;a.attackIndex=1;a.boneTimer=.3;a.energyTimer=0
 player.charges=0;player.electrified=0;player.abyssSpit=nil;player.abyssKnock=nil;player.abyssHeld=nil
 C.enter(a,'intro')
end
function C.enter(a,phase)
 a.phase=phase;a.phaseTime=0;a.open=phase~='intro'
 a.visibleSince=nil
 if phase=='rest' or phase=='suction' or phase=='recover' then a.whiteOrbs={} end
 a.energy=phase=='fire' and 1 or 0
 if phase=='rest' then
  a.attackIndex=1;a.plankton={};a.debris={};a.round=a.round+1
  for _,p in ipairs(a.lumenParticles) do
   if p.consumed then p.x=35+(math.sin(p.id*127.1)*43758.5453%1)*(Arena.width-70);p.y=45+(math.sin(p.id*311.7)*19642.349%1)*510;p.consumed=false end
  end
 elseif phase=='bones' then a.boneTimer=.3;a.energyTimer=0;a.volley=0
 elseif phase=='suction' then
  a.debris={};a.absorbed=false;player.abyssKnock=nil;player.abyssSpit=nil;player.dashing=false
 elseif phase=='recover' then a.plankton={};a.debris={} 
 end
 a.buildBones()
end
function C.dangerAt(a,x,y)
 for _,z in ipairs(a.zones) do
  if x+11>z.x and x-11<z.x+z.w and y+9>z.y and y-9<z.y+z.h then return true end
 end
 return false
end
function C.contact(a)
 if a.defeated or player.reset then return end
 player.x=math.max(player.x,C.playerMinX(a))
 Jaw.contact(a)
 if a.phase=='fire' and a.visibleSince and a.phaseTime-a.visibleSince>=.12 and C.dangerAt(a,player.x+15,player.y+12) then Hazards.kill('abyss_laser');return end
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
 -- Restored health brings back the same number of teeth so victory stays possible.
 for index=1,6 do if heal>0 and a.removedTeeth[index] then a.removedTeeth[index]=nil;heal=heal-1 end end
 a.toothTargets={};a.flash=.35
 player.charges=0;player.electrified=0;player.illuminated=0
 BossFX.burst(mx,my,{.25,.8,1},2)
 player.abyssSpit={time=0,fromX=player.x,fromY=player.y,toX=math.min(Arena.width-65,math.max(260,Arena.width*.45)),toY=288}
 player.abyssGrace=.8
 C.enter(a,'recover')
end
function C.duration(a) return a.phase=='fire' and C.sequence[a.attackIndex].duration or durations[a.phase] end
local function tick(a,dt)
 local phase=a.phase
 a.clock=a.clock+dt;a.flash=math.max(0,a.flash-dt);a.spitFlash=math.max(0,a.spitFlash-dt)
 a.phaseTime=a.phaseTime+dt*(a.attackRate or 1)
 a.buildBones()
 C.contact(a)
 if player.reset then a.grab=nil;return end
 Jaw.update(a,dt)
 if a.defeated or player.reset then return end
 if phase=='suction' then
  C.suction(a,dt)
  if a.phase~=phase then a.refreshLight();return end
 end
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
    local dx,dy=mx-p.x,my-p.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy));local step=math.min(d,(450+d*2)*dt)
    p.vx=dx/d*(450+d*2);p.vy=dy/d*(450+d*2);p.x=p.x+dx/d*step;p.y=p.y+dy/d*step
    if d<18 then p.consumed=true end
   else p.vx=math.sin(p.age*.6+p.id)*9;p.vy=math.cos(p.age*.7+p.id)*7;p.x=math.max(25,math.min(Arena.width-25,p.x+p.vx*dt));p.y=math.max(35,math.min(565,p.y+p.vy*dt)) end
  end
 end
 C.contact(a)
 if a.defeated or player.reset then return end
 if a.phase==phase and a.phaseTime>=C.duration(a) then
  if phase=='intro' then C.enter(a,'rest')
  elseif phase=='rest' then C.enter(a,'fire')
  elseif phase=='fire' then C.enter(a,'gap')
  elseif phase=='gap' then
   if a.attackIndex<#C.sequence then a.attackIndex=a.attackIndex+1;C.enter(a,'fire') else C.enter(a,'bones') end
  elseif phase=='bones' then C.enter(a,'settle')
  elseif phase=='settle' then C.enter(a,'suction')
  elseif phase=='suction' then C.enter(a,'recover')
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
 for _,z in ipairs(a.zones) do g.rectangle('fill',z.x,z.y,z.w,z.h) end
 g.pop()
end
function C.draw(a)
 if a.defeated then return end
 W.draw(a)
 if #a.zones==0 then return end
 -- A zone must be displayed before its collision can become lethal.
 if not a.visibleSince then a.visibleSince=a.phaseTime end
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 for _,z in ipairs(a.zones) do
  g.setColor(1,1,1,.08);g.rectangle('fill',z.x-6,z.y-6,z.w+12,z.h+12)
  g.setColor(1,1,1,.86);g.rectangle('fill',z.x,z.y,z.w,z.h)
  g.setColor(1,1,1,1);g.setLineWidth(2);g.rectangle('line',z.x+1,z.y+1,z.w-2,z.h-2)
 end
 g.pop()
end
return C
