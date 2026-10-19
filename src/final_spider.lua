-- Renaissance guardian. Eggs are independent actors, including the carried clutch.
local ArtSet=require 'final_art'
local Escape=require 'queen_escape'
local Brood=require 'queen_brood'
local Heirs=require 'queen_heirs'
local F={active=false,name='La Gardienne de la Soie',maxHp=13,leapRadius=180}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function length(x,y) return math.sqrt(x*x+y*y) end
local function towards(o,x,y,speed,dt)
 local dx,dy=x-o.x,y-o.y;local d=length(dx,dy)
 if d>0 then local step=math.min(d,speed*dt);o.x=o.x+dx/d*step;o.y=o.y+dy/d*step;o.angle=math.atan2(dy,dx)-math.pi/2 end
 return d
end
local function near(a,b,r) return (a.x-b.x)^2+(a.y-b.y)^2<r*r end
local function playerPoint() return {x=player.x+15,y=player.y+12} end
local function segment(x,y,xx,yy,p,r)
 local dx,dy=xx-x,yy-y;local n=dx*dx+dy*dy
 local t=n>0 and clamp(((p.x-x)*dx+(p.y-y)*dy)/n,0,1) or 0
 return (x+dx*t-p.x)^2+(y+dy*t-p.y)^2<=r*r,t
end
-- Entry time, rather than nearest-point time, orders contacts within a fast dash.
local function entryTime(x,y,xx,yy,p,r)
 local dx,dy=xx-x,yy-y;local rx,ry=x-p.x,y-p.y
 local c=rx*rx+ry*ry-r*r;if c<=0 then return 0 end
 local a=dx*dx+dy*dy;if a<.000001 then return nil end
 local b=rx*dx+ry*dy;local discriminant=b*b-a*c
 if discriminant<0 then return nil end
 local t=(-b-math.sqrt(discriminant))/a
 if t>=0 and t<=1 then return t end
end
local function grieving() return F.phase=='mourn' or F.phase=='recoil_jump' end
function F.mourn()
 local x,y=0,0
 for _,b in ipairs(F.chargeDeaths) do x=x+b.x;y=y+b.y end
 F.grief={x=x/#F.chargeDeaths,y=y/#F.chargeDeaths,angle=F.angle}
 F.phase='mourn';F.phaseTime=0;F.target=nil;F.snare=0;F.snareSource=nil;F.webGrace=2.5
 F.webs={};F.afterimages={};F.dashing=false
end
function F.recoil(p)
 local away=math.atan2(F.y-p.y,F.x-p.x);local best,score
 for _,offset in ipairs({0,.45,-.45,.9,-.9,1.4,-1.4}) do
  local a=away+offset
  local tx=clamp(F.x+math.cos(a)*225,55,Arena.width-55);local ty=clamp(F.y+math.sin(a)*225,75,525)
  local value=length(tx-p.x,ty-p.y)+length(tx-F.x,ty-F.y)*.25+math.cos(offset)*20
  if not score or value>score then best={x=F.x,y=F.y,tx=tx,ty=ty};score=value end
 end
 F.jump=best;F.jumpHeight=0;F.phase='recoil_jump';F.phaseTime=0;F.jumpCooldown=4
end
function F.updateCharge(dt)
 local x,y=F.x,F.y;towards(F,F.chargeX,F.chargeY,920,dt)
 local px,py=require('collision_shapes').center()
 local hit=F.contactGrace<=0 and entryTime(x,y,F.x,F.y,{x=px,y=py},27)
 if hit then F.x=x+(F.x-x)*hit;F.y=y+(F.y-y)*hit;if F.snare>0 then Hazards.kill() else F.damage() end;return end
 if length(F.x-F.chargeX,F.y-F.chargeY)<4 or F.phaseTime>1.7 then F.phase='recover';F.phaseTime=0;F.target=nil end
end
function F.reset(active)
 F.landed=nil;F.weaveResume=nil;F.weaveX=nil;F.weaveY=nil;F.weaveAngle=nil;F.weaveCount=nil;F.weaveFired=nil;F.weaveSide=nil
 Escape.reset(F)
 F.id=0;F.frozen=0;F.eggSerial=0;F.pendingEggs=0;F.bombs={};F.bursts={};F.cast=0;F.damageGrace=0
 F.active=active;F.hp=13;F.maxHp=13;F.defeated=false;F.x=Arena.width*.5;F.y=165;F.angle=0;F.clock=0;F.flash=0
 F.chargeDeaths={};F.chargeEggs={};F.grief=nil
 F.afterimages={};F.ghostClock=0;F.walkPhase=0;F.walkMoving=false;F.surge=1;F.dashing=false
 F.phase='passive';F.engaged=false;F.jumpCooldown=0;F.jump=nil;F.jumpHeight=0;F.contactGrace=0;F.phaseTime=0;F.shot=.65;F.volley=0;F.snareSource=nil;F.layPulse=0;F.eggs={};F.babies={};F.shells={};F.webs={};F.stuck={};F.carried=0;F.wave=0;F.snare=0;F.webGrace=0;F.target=nil;F.gate=false;F.batch=0;F.nest=nil
end
function F.visualAngle()
 local dir=ArtSet.facing(F.angle)
 return ({down=0,up=math.pi,left=math.pi/2,right=-math.pi/2})[dir]
end
function F.leap(resume)
 F.jumpResume=F.pendingEggs>0 and 'seek_nest' or resume or 'webs';F.jumpResumeTime=F.phaseTime;F.jumpCooldown=4
 F.phase='intro_jump';F.phaseTime=0;F.contactGrace=.85
 F.target=nil;F.cornerLay=false;F.cast=0
 F.jump=require('queen_jump').choose(F,F)
 F.angle=math.atan2(F.jump.ty-F.y,F.jump.tx-F.x)-math.pi/2
end
function F.beginCombat()
 F.engaged=true;F.leap('webs')
end
function F.damage(egg)
 if F.defeated or F.hp<=0 or (not egg and F.damageGrace>0) then return end
 F.engaged=true;F.damageGrace=.95
 F.hp=math.max(0,F.hp-1);F.flash=.25
 BossFX.shake(8)
 if F.hp>0 then
  if (F.maxHp-F.hp)%2==0 then F.pendingEggs=F.pendingEggs+1;F.chooseNest() end
  F.frozen=0;F.leap('webs')
 else
  F.bombs={};F.bursts={};F.stuck={};F.snare=0;F.frozen=0
  for _,b in ipairs(F.babies) do b.frozen=0 end
  require('boss_liberation').start(F,'final_spider',function()
   F.defeated=true;F.enraged=false;F.silkBits={};F.phase='retreat';F.phaseTime=0;F.snare=0;F.webs={};F.stuck={};F.target=nil;F.grief=nil;F.chargeDeaths={};F.jump=nil;F.jumpHeight=0
   for _,b in ipairs(F.babies) do b.webbed=false end
   for _,e in ipairs(F.eggs) do F.shells[#F.shells+1]={x=e.x,y=e.y,seed=e.seed} end;F.eggs={}
   objet.larme.taken=false;objet.larme.x=Arena.width/2-15;objet.larme.y=280
  end)
 end
end
function F.breakEgg(index)
 local e=table.remove(F.eggs,index);if not e then return end
 F.shells[#F.shells+1]={x=e.x,y=e.y,seed=e.seed};F.damage(true)
end
function F.chooseNest()
 local p=playerPoint();local best,score
 local function consider(x,y)
  if Arena.blocked(x-20,y-24,40,48) then return end
  for _,e in ipairs(F.eggs) do if (e.x-x)^2+(e.y-y)^2<48^2 then return end end
  local d=(x-p.x)^2+(y-p.y)^2
  if not score or d>score then best={x=x,y=y};score=d end
 end
 -- Include the exact arena corners; scan inward when an egg occupies one.
 for _,x in ipairs({55,Arena.width-55}) do for _,y in ipairs({70,530}) do consider(x,y) end end
 for x=55,Arena.width-55,16 do for y=70,530,16 do consider(x,y) end end
 F.nest=best
 return best
end
function F.layEgg()
 local point={x=F.x,y=F.y}
 F.eggSerial=F.eggSerial+1;F.layPulse=.32
 F.eggs[#F.eggs+1]={x=point.x,y=point.y,fromX=F.x,fromY=F.y,age=0,hatch=1.5,seed=F.eggSerial}
end
function F.trap(target)
 if F.defeated or F.cornerLay or grieving() or F.phase=='charge' or F.phase=='aim' or F.phase=='intro_jump' then return end
 F.chargeDeaths={};F.chargeEggs={};F.grief=nil
 F.resume=F.phase;F.target=target;F.phase='aim';F.phaseTime=0
 if target==player then F.snare=2.1;F.escapeTaps={} else target.webbed=true end
 local p=target==player and playerPoint() or target;F.chargeX=p.x;F.chargeY=p.y
end
function F.pressure()
 return F.hp<=4 and 3 or F.hp<=8 and 2 or 1
end
function F.shotInterval() return ({.95,.88,.8})[F.pressure()] end
function F.fire(actor,radial)
 actor.cast=.16;actor.volley=(actor.volley or 0)+1
 local angle=math.atan2(player.y+12-actor.y,player.x+15-actor.x)
 if not radial then actor.angle=angle-math.pi/2 end
 local count=radial and (actor==F and 10 or 8) or (actor==F and F.pressure()==3 and actor.volley%3==0 and 2 or 1)
 for i=1,count do
  local a=radial and i*math.pi*2/count+actor.volley*.11 or angle+(i-(count+1)/2)*.20
  local dx,dy=math.cos(a),math.sin(a);local speed=radial and 265 or 420
  F.webs[#F.webs+1]={x=actor.x+dx*32,y=actor.y+dy*32,vx=dx*speed,vy=dy*speed,age=0,owner=actor.id}
 end
end
function F.shoot() F.fire(F,false) end
function F.landingVolley() F.fire(F,true) end
function F.updateWebs(dt)
 Brood.update(F,dt)
 local p=playerPoint()
 for i=#F.webs,1,-1 do local w=F.webs[i];w.owner=w.owner or 0;w.age=(w.age or 0)+dt;local xx,yy=w.x+w.vx*dt,w.y+w.vy*dt
  local wallX,wallY,wallT=Brood.impact(w.x,w.y,xx,yy)
  local victim,first=nil,wallT or 2
  for _,b in ipairs(F.babies) do if b.id~=w.owner and b.phase~='intro_jump' then local hit,t=segment(w.x,w.y,xx,yy,b,25);if hit and t<first then victim=b;first=t end end end
  if w.owner~=0 and F.phase~='intro_jump' then local hit,t=segment(w.x,w.y,xx,yy,F,27);if hit and t<first then victim=F;first=t end end
  local hit,t=segment(w.x,w.y,xx,yy,p,21);if hit and t<first and F.webGrace<=0 then victim=player end
  if victim then
   if victim==player then
    if F.snare<=0 then F.escapeTaps={} end;F.snare=2.1;F.snareSource='shot'
    if (w.owner or 0)==0 then F.trap(player) else
     for _,b in ipairs(F.babies) do if b.id==w.owner and b.phase~='intro_jump' then b.phase='aim';b.phaseTime=0;b.chargeX=p.x;b.chargeY=p.y end end
    end
   else victim.frozen=2.2 end
   table.remove(F.webs,i)
  elseif wallX then
   Brood.spawn(F,wallX,wallY);table.remove(F.webs,i)
  else w.x=xx;w.y=yy end
 end

end
function F.updateEggs(dt)
 for i=#F.eggs,1,-1 do
  local e=F.eggs[i];e.age=e.age+dt
  local touching=near(e,playerPoint(),27)
  e.crackShake=math.max(0,(e.crackShake or 0)-dt)
  if touching and not e.touching then
   e.touching=true;e.hits=(e.hits or 0)+1;e.crackShake=.25
   if e.hits>=4 then F.breakEgg(i) end
  elseif not near(e,playerPoint(),37) then e.touching=false end
  if F.eggs[i]==e and e.age>=e.hatch then
   table.remove(F.eggs,i);F.shells[#F.shells+1]={x=e.x,y=e.y,seed=e.seed};Heirs.hatch(F,e)
   if Bestiary.discover('queen_child') then Bestiary.save() end
  end
 end
end
local function updateBehavior(dt)

 if not F.active then return end
 F.damageGrace=math.max(0,F.damageGrace-dt);F.cast=math.max(0,F.cast-dt)
 F.layPulse=math.max(0,(F.layPulse or 0)-dt)
 F.jumpCooldown=math.max(0,(F.jumpCooldown or 0)-dt)
 F.clock=F.clock+dt;F.phaseTime=F.phaseTime+dt;F.flash=math.max(0,F.flash-dt);F.snare=math.max(0,F.snare-dt);F.webGrace=math.max(0,(F.webGrace or 0)-dt)
 Escape.struggle(F,dt)
 if F.defeated then
  F.settle(dt)
  if F.jumpHeight<=0 then
   if towards(F,Arena.width*.5,95,110,dt)<4 then F.angle=math.atan2(player.y+12-F.y,player.x+15-F.x)-math.pi/2 end
  end
  for i,b in ipairs(F.babies) do
   local x,y=b.x,b.y
   if b.jumpHeight<=0 then
    local tx=Arena.width*.5+(i-(#F.babies+1)/2)*68;local ty=60
    if towards(b,tx,ty,140,dt)<4 then b.angle=math.atan2(player.y+12-b.y,player.x+15-b.x)-math.pi/2 end
   end
   require('brown_walk').advance(b,length(b.x-x,b.y-y),dt)
  end
  Aftermath.update(dt)
  if Campaign.canCollect() and isTouching(player,objet.larme) then
   require('psychedelic_fx').collect(objet.larme.x+15,objet.larme.y+20,player.x+15,player.y+12)
   Profile.record('tears');objet.larme.taken=true;Ending.openReunion()
  end
  return
 end
 if F.frozen>0 then
  if F.phase~='intro_jump' and require('collision_shapes').touchCircle('queen',F.x,F.y,27) then F.damage();return end
  F.frozen=math.max(0,F.frozen-dt);F.phaseTime=F.phaseTime-dt;return
 end
 local p=playerPoint()
 if not F.engaged then
  F.angle=math.atan2(p.y-F.y,p.x-F.x)-math.pi/2
  if require('collision_shapes').touchCircle('queen',F.x,F.y,27) then F.damage();return end
  if near(F,p,F.leapRadius) then
   F.beginCombat()
  end
  return
 end
 local jumping=F.phase=='intro_jump'
 if jumping then
  local t=math.min(1,F.phaseTime/.85);local ease=t*t*(3-2*t);local j=F.jump
  F.x=j.x+(j.tx-j.x)*ease;F.y=j.y+(j.ty-j.y)*ease
  F.jumpHeight=math.sin(t*math.pi)*115
  if t>=1 then require('queen_presence').land(F);F.landingVolley();F.phase=F.jumpResume or 'webs';F.phaseTime=F.phase=='lay' and F.jumpResumeTime or 0;F.shot=.45;F.contactGrace=.35;F.jump=nil;F.jumpHeight=0 end
 end
 F.contactGrace=math.max(0,(F.contactGrace or 0)-dt)
 if not jumping and F.phase~='charge' and F.contactGrace<=0 and require('collision_shapes').touchCircle('queen',F.x,F.y,27) then F.damage();return end
 if jumping then return end
 if F.phase=='aim' then
  F.angle=math.atan2(F.chargeY-F.y,F.chargeX-F.x)-math.pi/2
  if F.phaseTime>.65 then F.phase='charge';F.phaseTime=0 end
 elseif F.phase=='weave' then
  require('queen_weave').update(F)
 elseif F.phase=='charge' then
  F.updateCharge(dt);if F.defeated or player.reset then return end
 elseif F.phase=='mourn' then
  local grief=F.grief;local target=math.atan2(grief.y-F.y,grief.x-F.x)-math.pi/2
  local delta=math.atan2(math.sin(target-grief.angle),math.cos(target-grief.angle))
  local t=clamp(F.phaseTime/.32,0,1);F.angle=grief.angle+delta*t*t*(3-2*t)
  if F.phaseTime>=.12 then F.recoil(p) end
 elseif F.phase=='recoil_jump' then
  local t=clamp(F.phaseTime/.65,0,1);local ease=t*t*(3-2*t);local jump=F.jump
  F.x=jump.x+(jump.tx-jump.x)*ease;F.y=jump.y+(jump.ty-jump.y)*ease;F.jumpHeight=math.sin(t*math.pi)*85
  if t>=1 then
   require('queen_presence').land(F);F.landingVolley()
   F.phase='recover';F.phaseTime=0;F.contactGrace=.45;F.jump=nil;F.jumpHeight=0;F.grief=nil;F.chargeDeaths={};F.shot=.6
  end
 elseif F.phase=='seek_nest' then
  local nest=F.chooseNest()
  if nest then
   if towards(F,nest.x,nest.y,340,dt)<4 then
    F.layEgg();F.pendingEggs=math.max(0,F.pendingEggs-1)
    F.phase=F.pendingEggs>0 and 'seek_nest' or 'webs';F.phaseTime=0;F.shot=.45
   end
  end
 elseif F.phase=='recover' then
  if F.phaseTime>.12 then F.phase=F.pendingEggs>0 and 'seek_nest' or 'webs';F.phaseTime=0;F.shot=.5 end
 else
  F.shot=F.shot-dt
  if F.shot<=0 then F.shoot();F.shot=F.shotInterval() end
  if F.cast<=0 and F.shot>.10 then
   local egg=F.eggs[1]
   local tx=Arena.width*.5+math.sin(F.clock*.5)*Arena.width*.18;local ty=175+math.cos(F.clock*.65)*45
   if egg then
    local dx,dy=p.x-egg.x,p.y-egg.y;local d=math.max(1,length(dx,dy))
    tx=clamp(egg.x+dx/d*65,55,Arena.width-55);ty=clamp(egg.y+dy/d*65,70,530)
   end
   towards(F,tx,ty,(egg and 155 or 110)*F.surge,dt)
   F.angle=math.atan2(p.y-F.y,p.x-F.x)-math.pi/2
  end
 end
 if F.phase~='intro_jump' and F.phase~='recoil_jump' and F.contactGrace<=0 and require('collision_shapes').touchCircle('queen',F.x,F.y,27) then F.damage();return end
 for i=#F.babies,1,-1 do if F.babies[i].dead then table.remove(F.babies,i) end end
end
function F.settle(dt)
 F.jump=nil;F.jumpHeight=math.max(0,(F.jumpHeight or 0)-dt*260)
 for _,b in ipairs(F.babies) do b.jump=nil;b.jumpHeight=math.max(0,(b.jumpHeight or 0)-dt*260);b.walkMoving=false end
end
function F.update(dt)
 if not F.active then return end
 local x,y=F.x,F.y
 for i=#F.afterimages,1,-1 do
  local ghost=F.afterimages[i];ghost.alpha=ghost.alpha-dt*2.4
  if ghost.alpha<=0 then table.remove(F.afterimages,i) end
 end
 local cycle=(F.clock+dt)%4.8
 local u=clamp((cycle-2.9)/.85,0,1)
 F.surge=1+math.sin(u*math.pi)^2*.65
 if not F.defeated then
  F.updateEggs(dt)
  if not F.defeated then Heirs.update(F,dt);F.updateWebs(dt) end
 end
 updateBehavior(dt)
 local distance=length(F.x-x,F.y-y)
 require('brown_walk').advance(F,distance*1.35,dt)
 if F.jumpHeight>0 or F.phase=='intro_jump' or grieving() then F.walkMoving=false end
 F.dashing=not F.defeated and F.walkMoving and (F.phase=='charge' or F.surge>1.2)
 if F.dashing then
  F.ghostClock=F.ghostClock+dt
  if F.ghostClock>=.05 then
   F.afterimages[#F.afterimages+1]={x=x,y=y,angle=F.visualAngle(),alpha=.26,walkPhase=F.walkPhase,walkMoving=true}
   F.ghostClock=0
  end
 else F.ghostClock=0 end
end
function F.spider(x,y,size,variant,angle,walk)
 local name=(variant=='queen' or size>=100) and 'queen' or variant=='black' and 'baby_black' or variant=='white' and 'baby_white' or 'baby_red'
 love.graphics.setColor(1,1,1);ArtSet.spider(name,x,y,size,angle,walk)
end
local function web(x,y,r,alpha)
 love.graphics.setColor(1,1,1,alpha or .85);ArtSet.draw('web_wall',x,y,r*2)
end
function F.egg(e,size,progress)
 local name=progress and progress>.66 and 'egg_crack2' or progress and progress>.3 and 'egg_crack1' or 'egg'
 local g=love.graphics;g.push('all');g.translate(e.x,e.y)
 local shake=math.max((e.crackShake or 0)/.32,(progress or 0)>.66 and ((progress-.66)/.34)*.7 or 0)
 g.translate(math.sin(F.clock*75+(e.seed or 0))*shake*1.8,0)
 g.setColor(1,1,1);ArtSet.draw(name,0,0,size*1.4,0,size*2)
 if (progress or 0)>.3 then
  g.scale(size/17);g.setLineJoin('bevel');g.setLineWidth(2.1);g.setColor(.22,.14,.16,.95)
  g.line(0,-13,-3,-8,2,-4,-2,1,3,6,0,12)
  if progress>.66 then g.line(2,-4,6,-6,9,-4);g.line(-2,1,-6,4,-8,2);g.line(3,6,7,10) end
  g.setLineWidth(.65);g.setColor(.76,.60,.46,.8);g.line(1,-13,-2,-8,3,-4,-1,1,4,6,1,12)
 end
 g.pop()
end
function F.drawGriefTear(facing)
 if F.phase~='mourn' or F.phaseTime<.32 then return end
 local g=love.graphics;local dir=ArtSet.facing(facing)
 local eye=({down={6.5,8},up={-7,-15},left={-19,5},right={19,5}})[dir]
 local t=clamp((F.phaseTime-.32)/.78,0,1);local fall=t*t*13
 local alpha=clamp((1.2-F.phaseTime)/.18,0,1);local radius=1.2+math.min(t*4,1)*1.1
 g.push('all');g.setShader();g.setLineWidth(1)
 g.setColor(.6,.87,1,.48*alpha);g.line(eye[1],eye[2],eye[1],eye[2]+fall)
 g.setBlendMode('add');g.setColor(.25,.65,1,.16*alpha);g.circle('fill',eye[1],eye[2]+fall,radius+2)
 g.setBlendMode('alpha');g.setColor(.48,.82,1,alpha)
 g.polygon('fill',eye[1],eye[2]+fall-radius*1.8,eye[1]-radius,eye[2]+fall,eye[1]+radius,eye[2]+fall)
 g.ellipse('fill',eye[1],eye[2]+fall,radius,radius*.85)
 g.setColor(.95,1,1,alpha);g.circle('fill',eye[1]-.5,eye[2]+fall-.5,.65);g.pop()
end
function F.drawGround()
 if not F.active then return end
 local g=love.graphics;g.push('all')
 for _,s in ipairs(F.shells) do
  if s.silk and s.variant then
   g.push('all');g.translate(s.x,s.y);g.scale(1,.6);g.setColor(.5,.45,.5,.85)
   ArtSet.spider('baby_'..s.variant,0,0,36,s.angle);g.pop()
  else g.setColor(1,1,1,.8);ArtSet.draw('shell',s.x,s.y,34,(s.seed or 0)*.7) end
 end
 Brood.drawGround(F)
 for _,e in ipairs(F.eggs) do
  local t=math.min(1,e.age/.32);local ease=1-(1-t)^2
  local pose={crackShake=e.crackShake,seed=e.seed,x=(e.fromX or e.x)+(e.x-(e.fromX or e.x))*ease,y=(e.fromY or e.y)+(e.y-(e.fromY or e.y))*ease-math.sin(t*math.pi)*18}
  F.egg(pose,17*(.65+.35*ease),math.max(e.age/e.hatch,(e.hits or 0)/4))
 end
 g.pop()
end
function F.draw(skipGround)
 if not F.active then return end
 if not skipGround then F.drawGround() end
 local g=love.graphics;g.push('all')
 require('queen_weave').draw(F);Brood.draw(F)
 Heirs.draw(F)

 if F.phase=='aim' then g.setColor(1,.28,.25,.5);g.setLineWidth(2);g.circle('line',F.chargeX,F.chargeY,34+math.sin(F.clock*18)*3) end
 -- Keep the body grounded; only a deliberate escape leap raises it.
 for _,ghost in ipairs(F.afterimages) do
  g.setColor(1,.35,.28,ghost.alpha*.6)
  ArtSet.spider('queen',ghost.x,ghost.y,62,ghost.angle,ghost)
 end
 local pulse=(F.layPulse or 0)/.32
 local facing=F.visualAngle()
 require('queen_presence').ground(F);g.setColor(1,1,1)
 require('monster_fx').halo(F.x,F.y-F.jumpHeight,84)
 local breath=math.sin(F.clock*(F.enraged and 5 or 2.6))*.012
 g.push();g.translate(F.x,F.y-F.jumpHeight);g.scale(1+pulse*.045+breath,1-pulse*.045-breath*.55)
 F.spider(0,0,62,'queen',facing,F)
 ArtSet.clutch(0,0,62,F.carried,facing);F.drawGriefTear(facing);g.pop()
 if F.frozen>0 then web(F.x,F.y-F.jumpHeight,35,.8) end
 for _,w in ipairs(F.webs) do
  local a=math.atan2(w.vy,w.vx);local dx,dy=math.cos(a),math.sin(a)
  g.setShader();g.setColor(.18,.24,.12,.3);g.setLineWidth(4);g.line(w.x-dx*17+2,w.y-dy*17+5,w.x+2,w.y+5)
  g.setColor(.88,.94,.73,.7);g.setLineWidth(1.2);g.line(w.x-dx*17,w.y-dy*17,w.x,w.y)
  local c=Heirs.color(w.owner or 0);g.setColor(c[1],c[2],c[3]);ArtSet.draw('web_shot',w.x,w.y,26,a)
 end
 Escape.draw(F)
 if F.gate then
  local x=Arena.width*.5;g.setColor(1,1,1);ArtSet.draw('web_gate',x,50,104,0,125)
  UI.text('Retrouvailles',x-90,83,'small',{.85,1,.9},180,'center')
 end
 g.pop()
end
function F.resize(r)
 if F.weaveX then F.weaveX=F.weaveX*r;F.weaveAngle=math.atan2(math.sin(F.weaveAngle),math.cos(F.weaveAngle)*r) end
 if F.grief then F.grief.x=F.grief.x*r end
 if F.jump then F.jump.x=F.jump.x*r;F.jump.tx=F.jump.tx*r end
 if F.nest then F.nest.x=F.nest.x*r end
 for _,p in ipairs(F.cornerSlots or {}) do p.x=p.x*r end
 F.x=F.x*r;if F.chargeX then F.chargeX=F.chargeX*r end
 for _,b in ipairs(F.babies)do if b.jump then b.jump.x=b.jump.x*r;b.jump.tx=b.jump.tx*r end;if b.chargeX then b.chargeX=b.chargeX*r end end
 for _,list in ipairs({F.eggs,F.babies,F.shells,F.webs,F.stuck,F.bombs,F.bursts,F.afterimages}) do for _,o in ipairs(list or {}) do o.x=o.x*r;if o.vx then o.vx=o.vx*r end end end
end
return F
