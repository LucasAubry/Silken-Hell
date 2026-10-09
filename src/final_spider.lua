-- Renaissance guardian. Eggs are independent actors, including the carried clutch.
local ArtSet=require 'final_art'
local Escape=require 'queen_escape'
local F={active=false,name='La Gardienne de la Soie',maxHp=13}
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
 local ox,oy=F.x,F.y;towards(F,F.chargeX,F.chargeY,920,dt)
 local xx,yy=F.x,F.y
 local px,py=require('collision_shapes').center();local playerCenter={x=px,y=py}
 local danger=F.contactGrace<=0 and entryTime(ox,oy,xx,yy,playerCenter,27) or nil
 local close=entryTime(ox,oy,xx,yy,playerCenter,44)
 local hits={};local first
 for _,b in ipairs(F.babies) do if not b.dead then
  local t=entryTime(ox,oy,xx,yy,b,27)
  if t and (not danger or t<=danger) then hits[#hits+1]={baby=b,t=t};first=math.min(first or t,t) end
 end end
 local stop
 if close and (#F.chargeDeaths>0 or first) then stop=math.max(close,#F.chargeDeaths>0 and 0 or first) end
 -- Nothing beyond the stopping point (or a lethal player contact) was touched.
 local limit=stop or danger or 1
 F.x=ox+(xx-ox)*limit;F.y=oy+(yy-oy)*limit
 table.sort(hits,function(a,b) if a.t==b.t then return (a.baby.seed or 0)<(b.baby.seed or 0) end;return a.t<b.t end)
 for _,hit in ipairs(hits) do if hit.t<=limit then
  local b=hit.baby;b.dead=true
  local corpse={x=b.x,y=b.y,seed=b.seed,silk=true,variant=b.variant,angle=b.angle or 0}
  F.shells[#F.shells+1]=corpse;F.chargeDeaths[#F.chargeDeaths+1]=corpse
  F.damage();if F.defeated then return end
 end end
 -- Each egg receives one crack per dash, only along the travelled segment.
 F.chargeEggs=F.chargeEggs or {}
 for i=#F.eggs,1,-1 do local e=F.eggs[i]
  if not F.chargeEggs[e] and entryTime(ox,oy,F.x,F.y,e,32) then
   F.chargeEggs[e]=true;e.hits=(e.hits or 0)+1;e.crackShake=.32
   if e.hits>=2 then F.breakEgg(i);if F.defeated then return end end
  end
 end
 if stop then F.mourn();return end
 if danger and F.contactGrace<=0 then Hazards.kill();return end
 if length(F.x-F.chargeX,F.y-F.chargeY)<4 or F.phaseTime>1.7 then
  if #F.chargeDeaths>0 then F.mourn() else F.phase='recover';F.phaseTime=0;F.target=nil end
 end
end
function F.reset(active)
 Escape.reset(F)
 F.active=active;F.hp=13;F.maxHp=13;F.defeated=false;F.x=Arena.width*.5;F.y=165;F.angle=0;F.clock=0;F.flash=0
 F.chargeDeaths={};F.chargeEggs={};F.grief=nil
 F.afterimages={};F.ghostClock=0;F.walkPhase=0;F.walkMoving=false;F.surge=1;F.dashing=false
 F.phase='passive';F.engaged=false;F.jumpCooldown=0;F.jump=nil;F.jumpHeight=0;F.contactGrace=0;F.phaseTime=0;F.shot=.65;F.volley=0;F.snareSource=nil;F.layPulse=0;F.eggs={};F.babies={};F.shells={};F.webs={};F.stuck={};F.carried=24;F.wave=0;F.snare=0;F.webGrace=0;F.target=nil;F.gate=false;F.batch=0;F.nest=nil
end
function F.visualAngle()
 local dir=ArtSet.facing(F.angle)
 return ({down=0,up=math.pi,left=math.pi/2,right=-math.pi/2})[dir]
end
function F.leap(resume)
 F.jumpResume=resume or 'webs';F.jumpResumeTime=F.phaseTime;F.jumpCooldown=4
 F.phase='intro_jump';F.phaseTime=0;F.contactGrace=1.2
 F.jump={x=F.x,y=F.y,tx=F.x<Arena.width*.5 and Arena.width-110 or 110,ty=F.y<300 and 480 or 120}
 F.angle=math.atan2(F.jump.ty-F.y,F.jump.tx-F.x)-math.pi/2
end
function F.beginCombat()
 F.engaged=true;F.leap('webs')
end
function F.damage()
 if F.defeated then return end
 F.hp=math.max(0,F.hp-1);F.flash=.25
 if F.hp==0 then
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
 F.shells[#F.shells+1]={x=e.x,y=e.y,seed=e.seed};F.damage()
end
function F.chooseNest()
 local p=playerPoint();local best,score
 for i=1,16 do
  local c={x=love.math.random(150,math.max(150,math.floor(Arena.width-150))),y=love.math.random(155,430)}
  local d=length(c.x-p.x,c.y-p.y)
  if not score or d>score then best,score=c,d end
  if d>240 and d<Arena.width*.65 then best=c;break end
 end
 F.nest=best
end
function F.layEgg()
 if F.carried<=0 or (not F.cornerLay and #F.babies+#F.eggs>=36) then return end
 if not F.nest then F.chooseNest() end
 local point
 if F.cornerLay then point=Escape.point(F) else
 for i=1,80 do
  local angle=love.math.random()*math.pi*2;local radius=math.sqrt(love.math.random())*110
  local c={x=clamp(F.nest.x+math.cos(angle)*radius,65,Arena.width-65),y=clamp(F.nest.y+math.sin(angle)*radius,105,525)}
  local free=not near(c,playerPoint(),65)
  for _,e in ipairs(F.eggs) do if near(c,e,44) then free=false;break end end
  if free then point=c;break end
 end
 end
 if not point then return end
 F.carried=F.carried-1;F.batch=F.batch+1
 F.layPulse=.32
 local a=F.angle or 0;local rearX,rearY=F.x+math.sin(a)*14,F.y-math.cos(a)*14
 F.eggs[#F.eggs+1]={x=point.x,y=point.y,fromX=rearX,fromY=rearY,age=0,hatch=7.5,seed=F.wave*8+F.batch}
end
function F.trap(target)
 if F.defeated or F.cornerLay or grieving() or F.phase=='charge' or F.phase=='aim' or F.phase=='intro_jump' then return end
 F.chargeDeaths={};F.chargeEggs={};F.grief=nil
 F.resume=F.phase;F.target=target;F.phase='aim';F.phaseTime=0
 if target==player then F.snare=2.1;F.escapeTaps={} else target.webbed=true end
 local p=target==player and playerPoint() or target;F.chargeX=p.x;F.chargeY=p.y
end
function F.shoot()
 local p=playerPoint();local angle=math.atan2(p.y-F.y,p.x-F.x)
 F.angle=angle-math.pi/2
 F.volley=(F.volley or 0)+1
 local count=({1,2,1,3})[(F.volley-1)%4+1]
 for i=1,count do
  local a=angle+(i-(count+1)/2)*.19
  local dx,dy=math.cos(a),math.sin(a)
  F.webs[#F.webs+1]={x=F.x+dx*23,y=F.y+dy*23,vx=dx*460,vy=dy*460}
 end
end
function F.wallWeb(x,y)
 for _,w in ipairs(F.stuck) do if (w.x-x)^2+(w.y-y)^2<24^2 then return end end
 F.stuck[#F.stuck+1]={x=x,y=y,variant=#F.stuck%3+1}
end
function F.updateWebs(dt)
 if grieving() then return end
 local p=playerPoint()
 for i=#F.webs,1,-1 do local w=F.webs[i];local xx,yy=w.x+w.vx*dt,w.y+w.vy*dt
  local victim,first=nil,2
  for _,b in ipairs(F.babies) do if not b.dead and not b.webbed then local hit,t=segment(w.x,w.y,xx,yy,b,19);if hit and t<first then victim=b;first=t end end end
  local hit,t=segment(w.x,w.y,xx,yy,p,21);if hit and t<first and F.webGrace<=0 then victim=player end
  if victim then
   if victim==player then if F.snare<=0 then F.escapeTaps={} end;F.snare=2.1;F.snareSource='shot' else victim.webbed=true end
   F.trap(victim);table.remove(F.webs,i)
  elseif xx<34 or xx>Arena.width-34 or yy<34 or yy>566 then
   F.wallWeb(clamp(xx,34,Arena.width-34),clamp(yy,34,566));table.remove(F.webs,i)
  else w.x=xx;w.y=yy end
 end
 for _,w in ipairs(F.stuck) do if near(w,p,24) and F.snare<=0 and (F.webGrace or 0)<=0 then F.trap(player);F.snare=2.1;F.snareSource='floor';F.webGrace=3;break end end
end
local function updateBehavior(dt)

 if not F.active then return end
 F.layPulse=math.max(0,(F.layPulse or 0)-dt)
 F.jumpCooldown=math.max(0,(F.jumpCooldown or 0)-dt)
 F.clock=F.clock+dt;F.phaseTime=F.phaseTime+dt;F.flash=math.max(0,F.flash-dt);F.snare=math.max(0,F.snare-dt);F.webGrace=math.max(0,(F.webGrace or 0)-dt)
 Escape.struggle(F,dt)
 if F.defeated then
  towards(F,Arena.width*.5,95,110,dt)
  for i,b in ipairs(F.babies) do towards(b,Arena.width*.5+((i-1)%9-4)*36,55+math.floor((i-1)/9)*25,140,dt) end
  Aftermath.update(dt)
  if Campaign.canCollect() and isTouching(player,objet.larme) then
   require('psychedelic_fx').collect(objet.larme.x+15,objet.larme.y+20,player.x+15,player.y+12)
   Profile.record('tears');objet.larme.taken=true;Ending.openReunion()
  end
  return
 end
 local p=playerPoint()
 if not F.engaged then
  F.angle=math.atan2(p.y-F.y,p.x-F.x)-math.pi/2
  if near(F,p,29) then
   F.beginCombat()
  end
  return
 end
 local jumping=F.phase=='intro_jump'
 if jumping then
  local t=math.min(1,F.phaseTime/.85);local ease=t*t*(3-2*t);local j=F.jump
  F.x=j.x+(j.tx-j.x)*ease;F.y=j.y+(j.ty-j.y)*ease
  F.jumpHeight=math.sin(t*math.pi)*115
  if t>=1 then F.phase=F.jumpResume or 'webs';F.phaseTime=F.phase=='lay' and F.jumpResumeTime or 0;F.shot=.45;F.contactGrace=.35;F.jump=nil;F.jumpHeight=0 end
 end
 if not F.cornerLay and not jumping and F.jumpCooldown<=0 and (F.phase=='webs' or F.phase=='lay') and near(F,p,115) then
  F.leap(F.phase);jumping=true
 end
 F.contactGrace=math.max(0,(F.contactGrace or 0)-dt)
 if F.phase~='charge' and not grieving() and F.contactGrace<=0 and require('collision_shapes').touchCircle('queen',F.x,F.y,27) then Hazards.kill();return end
 for i=#F.eggs,1,-1 do local e=F.eggs[i];e.age=e.age+dt;e.crackShake=math.max(0,(e.crackShake or 0)-dt)
  local touching=near(e,p,32)
  local broken=false
  if touching and not e.touching then
   e.touching=true;e.hits=(e.hits or 0)+1;e.crackShake=.32
   if e.hits>=2 then F.breakEgg(i);broken=true;if F.defeated then return end end
  elseif not near(e,p,40) then e.touching=false end
  if not broken and e.age>=e.hatch then
   table.remove(F.eggs,i);F.shells[#F.shells+1]={x=e.x,y=e.y,seed=e.seed}
   if Bestiary.discover('queen_child') then Bestiary.save() end
   F.babies[#F.babies+1]={x=e.x,y=e.y,age=0,variant=e.seed%11==0 and 'black' or e.seed%2==0 and 'white' or 'red',seed=e.seed}
  end
 end
 for _,b in ipairs(F.babies) do
  b.age=b.age+dt
  if not b.dead and not b.webbed then
   local dx,dy=p.x-b.x,p.y-b.y;local d=math.max(1,length(dx,dy));local tx,ty=p.x,p.y
   for _,other in ipairs(F.babies) do if other~=b and not other.dead then local x,y=b.x-other.x,b.y-other.y;local n=length(x,y);if n>0 and n<30 then tx=tx+x/n*(30-n)*2;ty=ty+y/n*(30-n)*2 end end end
   local contactX,contactY=b.x,b.y
   towards(b,tx,ty,120+(b.seed%5)*9,dt);b.x=clamp(b.x,35,Arena.width-35);b.y=clamp(b.y,35,565)
   if b.age>.7 and require('collision_shapes').touchCircle('queen_baby',contactX,contactY,25) then Hazards.kill();return end
  end
 end
 F.updateWebs(dt)
 if jumping then return end
 if F.phase=='aim' then
  F.angle=math.atan2(F.chargeY-F.y,F.chargeX-F.x)-math.pi/2
  if F.phaseTime>.65 then F.phase='charge';F.phaseTime=0 end
 elseif F.phase=='charge' then
  F.updateCharge(dt);if F.defeated or player.reset then return end
 elseif F.phase=='mourn' then
  local grief=F.grief;local target=math.atan2(grief.y-F.y,grief.x-F.x)-math.pi/2
  local delta=math.atan2(math.sin(target-grief.angle),math.cos(target-grief.angle))
  local t=clamp(F.phaseTime/.32,0,1);F.angle=grief.angle+delta*t*t*(3-2*t)
  if F.phaseTime>=1.2 then F.recoil(p) end
 elseif F.phase=='recoil_jump' then
  local t=clamp(F.phaseTime/.65,0,1);local ease=t*t*(3-2*t);local jump=F.jump
  F.x=jump.x+(jump.tx-jump.x)*ease;F.y=jump.y+(jump.ty-jump.y)*ease;F.jumpHeight=math.sin(t*math.pi)*85
  if t>=1 then
   F.phase='recover';F.phaseTime=0;F.contactGrace=.45;F.jump=nil;F.jumpHeight=0;F.grief=nil;F.chargeDeaths={};F.shot=.6
  end
 elseif F.phase=='recover' then
  if F.phaseTime>1 then F.phase='webs';F.phaseTime=0;F.shot=.5 end
 elseif F.phase=='lay' and F.cornerLay then
  Escape.lay(F,dt,towards)
 elseif F.phase=='lay' then
  -- Keep running away, turning along the arena edge instead of getting stuck.
  local away=math.atan2(F.y-p.y,F.x-p.x);local best,score
  for _,offset in ipairs({0,.6,-.6,1.2,-1.2,1.8,-1.8}) do
   local tx=clamp(F.x+math.cos(away+offset)*140,100,Arena.width-100)
   local ty=clamp(F.y+math.sin(away+offset)*140,110,490)
   local travel=length(tx-F.x,ty-F.y)
   local value=length(tx-p.x,ty-p.y)+travel*.4
   if not score or value>score then best={x=tx,y=ty};score=value end
  end
  towards(F,best.x,best.y,270*F.surge,dt)
  F.nest={x=F.x,y=F.y}
  if F.phaseTime>=.65+F.batch*.34 and F.batch<8 then F.layEgg() end
  if F.batch>=8 or F.phaseTime>4.5 then F.phase='webs';F.phaseTime=0;F.shot=.5 end
 else
  if F.phaseTime>6 and #F.babies+#F.eggs<29 then
   F.phase='lay';F.phaseTime=0;F.wave=F.wave+1;F.batch=0
   if F.carried<8 then F.carried=24 end
   Escape.beginLay(F)
  else
   F.shot=F.shot-dt
   if F.shot<=0 then F.shoot();F.shot=.5 end
   local webbed;for _,b in ipairs(F.babies) do if b.webbed and not b.dead then webbed=b;break end end
   if webbed then F.trap(webbed)
   else
    towards(F,Arena.width*.5+math.sin(F.clock*.5)*Arena.width*.18,175+math.cos(F.clock*.65)*45,90*F.surge,dt)
    -- Keep aiming at the player while strafing between web shots.
    F.angle=math.atan2(p.y-F.y,p.x-F.x)-math.pi/2
   end
  end
 end
 if not grieving() and F.contactGrace<=0 and require('collision_shapes').touchCircle('queen',F.x,F.y,27) then Hazards.kill();return end
 for i=#F.babies,1,-1 do if F.babies[i].dead then table.remove(F.babies,i) end end
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
function F.draw()

 if not F.active then return end
 local g=love.graphics;g.push('all')
 for _,s in ipairs(F.shells) do
  if s.silk and s.variant then
   g.push('all');g.translate(s.x,s.y);g.scale(1,.6);g.setColor(.5,.45,.5,.85)
   ArtSet.spider('baby_'..s.variant,0,0,36,s.angle);g.pop()
  else g.setColor(1,1,1,.8);ArtSet.draw('shell',s.x,s.y,34,(s.seed or 0)*.7) end
 end
 for _,w in ipairs(F.stuck) do web(w.x,w.y,25,.78) end
 for _,e in ipairs(F.eggs) do
  local t=math.min(1,e.age/.32);local ease=1-(1-t)^2
  local pose={crackShake=e.crackShake,seed=e.seed,x=(e.fromX or e.x)+(e.x-(e.fromX or e.x))*ease,y=(e.fromY or e.y)+(e.y-(e.fromY or e.y))*ease-math.sin(t*math.pi)*18}
  F.egg(pose,17*(.65+.35*ease),math.max(e.age/e.hatch,(e.hits or 0)>0 and .45 or 0))
 end
 for _,b in ipairs(F.babies) do if not b.dead then require('monster_fx').halo(b.x,b.y,36);F.spider(b.x,b.y,36,b.variant,b.angle);if b.webbed then web(b.x,b.y,24) end end end
 if F.phase=='aim' then g.setColor(1,.28,.25,.5);g.setLineWidth(2);g.circle('line',F.chargeX,F.chargeY,34+math.sin(F.clock*18)*3) end
 -- Keep the body grounded; only a deliberate escape leap raises it.
 for _,ghost in ipairs(F.afterimages) do
  g.setColor(1,.35,.28,ghost.alpha*.6)
  ArtSet.spider('queen',ghost.x,ghost.y,62,ghost.angle,ghost)
 end
 local pulse=(F.layPulse or 0)/.32
 local facing=F.visualAngle()
 if F.jumpHeight>0 then g.setColor(0,0,0,.28);g.ellipse('fill',F.x,F.y+16,24,8);g.setColor(1,1,1) end
 require('monster_fx').halo(F.x,F.y-F.jumpHeight,84)
 g.push();g.translate(F.x,F.y-F.jumpHeight);g.scale(1+pulse*.045,1-pulse*.045)
 F.spider(0,0,62,'queen',facing,F)
 ArtSet.clutch(0,0,62,F.carried,facing);F.drawGriefTear(facing);g.pop()
 for _,w in ipairs(F.webs) do g.setColor(1,1,1);ArtSet.draw('web_shot',w.x,w.y,32,math.atan2(w.vy,w.vx)) end
 Escape.draw(F)
 if F.gate then
  local x=Arena.width*.5;g.setColor(1,1,1);ArtSet.draw('web_gate',x,50,104,0,125)
  UI.text('Retrouvailles',x-90,83,'small',{.85,1,.9},180,'center')
 end
 g.pop()
end
function F.resize(r)
 if F.grief then F.grief.x=F.grief.x*r end
 if F.jump then F.jump.x=F.jump.x*r;F.jump.tx=F.jump.tx*r end
 if F.nest then F.nest.x=F.nest.x*r end
 for _,p in ipairs(F.cornerSlots or {}) do p.x=p.x*r end
 F.x=F.x*r;if F.chargeX then F.chargeX=F.chargeX*r end
 for _,list in ipairs({F.eggs,F.babies,F.shells,F.webs,F.stuck,F.afterimages}) do for _,o in ipairs(list or {}) do o.x=o.x*r;if o.vx then o.vx=o.vx*r end end end
end
return F
