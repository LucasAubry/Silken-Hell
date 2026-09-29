-- Renaissance guardian. Eggs are independent actors, including the carried clutch.
local ArtSet=require 'final_art'
local F={active=false,name='La Gardienne des fils',maxHp=20}
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
function F.reset(active)
 F.active=active;F.hp=20;F.maxHp=20;F.defeated=false;F.x=Arena.width*.5;F.y=165;F.angle=0;F.clock=0;F.flash=0
 F.phase='passive';F.engaged=false;F.jump=nil;F.jumpHeight=0;F.contactGrace=0;F.phaseTime=0;F.shot=.65;F.volley=0;F.snareSource=nil;F.layPulse=0;F.eggs={};F.babies={};F.shells={};F.webs={};F.stuck={};F.carried=24;F.wave=0;F.snare=0;F.webGrace=0;F.target=nil;F.gate=false;F.batch=0;F.nest=nil
end
function F.visualAngle()
 local dir=ArtSet.facing(F.angle)
 return ({down=0,up=math.pi,left=math.pi/2,right=-math.pi/2})[dir]
end
function F.beginCombat()
 F.engaged=true;F.phase='intro_jump';F.phaseTime=0;F.contactGrace=1.2
 F.jump={x=F.x,y=F.y,tx=F.x<Arena.width*.5 and Arena.width-110 or 110,ty=F.y<300 and 480 or 120}
 F.angle=math.atan2(F.jump.ty-F.y,F.jump.tx-F.x)-math.pi/2
end
function F.damage()
 if F.defeated then return end
 F.hp=math.max(0,F.hp-1);F.flash=.25
 if F.hp==0 then
  F.defeated=true;F.phase='retreat';F.phaseTime=0;F.snare=0;F.webs={};F.stuck={};F.target=nil
  for _,b in ipairs(F.babies) do b.webbed=false end
  for _,e in ipairs(F.eggs) do F.shells[#F.shells+1]={x=e.x,y=e.y,seed=e.seed} end;F.eggs={}
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
 if F.carried<=0 or #F.babies+#F.eggs>=36 then return end
 if not F.nest then F.chooseNest() end
 local point
 for i=1,80 do
  local angle=love.math.random()*math.pi*2;local radius=math.sqrt(love.math.random())*110
  local c={x=clamp(F.nest.x+math.cos(angle)*radius,65,Arena.width-65),y=clamp(F.nest.y+math.sin(angle)*radius,105,525)}
  local free=not near(c,playerPoint(),65)
  for _,e in ipairs(F.eggs) do if near(c,e,44) then free=false;break end end
  if free then point=c;break end
 end
 if not point then return end
 F.carried=F.carried-1;F.batch=F.batch+1
 F.layPulse=.32
 local a=F.angle or 0;local rearX,rearY=F.x+math.sin(a)*14,F.y-math.cos(a)*14
 F.eggs[#F.eggs+1]={x=point.x,y=point.y,fromX=rearX,fromY=rearY,age=0,hatch=7.5,seed=F.wave*8+F.batch}
end
function F.trap(target)
 if F.defeated or F.phase=='charge' or F.phase=='aim' then return end
 F.resume=F.phase;F.target=target;F.phase='aim';F.phaseTime=0
 if target==player then F.snare=2.1 else target.webbed=true end
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
 local p=playerPoint()
 for i=#F.webs,1,-1 do local w=F.webs[i];local xx,yy=w.x+w.vx*dt,w.y+w.vy*dt
  local victim,first=nil,2
  for _,b in ipairs(F.babies) do if not b.dead and not b.webbed then local hit,t=segment(w.x,w.y,xx,yy,b,19);if hit and t<first then victim=b;first=t end end end
  local hit,t=segment(w.x,w.y,xx,yy,p,21);if hit and t<first then victim=player end
  if victim then
   if victim==player then F.snare=2.1;F.snareSource='shot' else victim.webbed=true end
   F.trap(victim);table.remove(F.webs,i)
  elseif xx<34 or xx>Arena.width-34 or yy<34 or yy>566 then
   F.wallWeb(clamp(xx,34,Arena.width-34),clamp(yy,34,566));table.remove(F.webs,i)
  else w.x=xx;w.y=yy end
 end
 for _,w in ipairs(F.stuck) do if near(w,p,24) and F.snare<=0 and (F.webGrace or 0)<=0 then F.trap(player);F.snare=2.1;F.snareSource='floor';F.webGrace=3;break end end
end
function F.update(dt)
 if not F.active then return end
 F.layPulse=math.max(0,(F.layPulse or 0)-dt)
 F.clock=F.clock+dt;F.phaseTime=F.phaseTime+dt;F.flash=math.max(0,F.flash-dt);F.snare=math.max(0,F.snare-dt);F.webGrace=math.max(0,(F.webGrace or 0)-dt)
 if F.defeated then
  towards(F,Arena.width*.5,95,110,dt)
  for i,b in ipairs(F.babies) do towards(b,Arena.width*.5+((i-1)%9-4)*36,55+math.floor((i-1)/9)*25,140,dt) end
  if F.phaseTime>2.4 then F.gate=true end
  if F.gate and near(playerPoint(),{x=Arena.width*.5,y=38},42) then Ending.openReunion() end
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
 if F.phase=='intro_jump' then
  local t=math.min(1,F.phaseTime/.85);local ease=t*t*(3-2*t);local j=F.jump
  F.x=j.x+(j.tx-j.x)*ease;F.y=j.y+(j.ty-j.y)*ease
  F.jumpHeight=math.sin(t*math.pi)*115
  if t>=1 then F.phase='webs';F.phaseTime=0;F.shot=.45;F.contactGrace=.35;F.jump=nil;F.jumpHeight=0 end
  return
 end
 F.contactGrace=math.max(0,(F.contactGrace or 0)-dt)
 if F.contactGrace<=0 and near(F,p,27) then Hazards.kill();return end
 for i=#F.eggs,1,-1 do local e=F.eggs[i];e.age=e.age+dt
  local touching=near(e,p,32)
  local broken=false
  if touching and not e.touching then
   e.touching=true;e.hits=(e.hits or 0)+1
   if e.hits>=2 then F.breakEgg(i);broken=true;if F.defeated then return end end
  elseif not near(e,p,40) then e.touching=false end
  if not broken and e.age>=e.hatch then
   table.remove(F.eggs,i);F.shells[#F.shells+1]={x=e.x,y=e.y,seed=e.seed}
   F.babies[#F.babies+1]={x=e.x,y=e.y,age=0,variant=e.seed%11==0 and 'black' or e.seed%2==0 and 'white' or 'red',seed=e.seed}
  end
 end
 for _,b in ipairs(F.babies) do
  b.age=b.age+dt
  if not b.dead and not b.webbed then
   local dx,dy=p.x-b.x,p.y-b.y;local d=math.max(1,length(dx,dy));local tx,ty=p.x,p.y
   for _,other in ipairs(F.babies) do if other~=b and not other.dead then local x,y=b.x-other.x,b.y-other.y;local n=length(x,y);if n>0 and n<30 then tx=tx+x/n*(30-n)*2;ty=ty+y/n*(30-n)*2 end end end
   towards(b,tx,ty,120+(b.seed%5)*9,dt);b.x=clamp(b.x,35,Arena.width-35);b.y=clamp(b.y,35,565)
   if b.age>.7 and d<25 then Hazards.kill();return end
  end
 end
 F.updateWebs(dt)
 if F.phase=='aim' then
  F.angle=math.atan2(F.chargeY-F.y,F.chargeX-F.x)-math.pi/2
  if F.phaseTime>.65 then F.phase='charge';F.phaseTime=0 end
 elseif F.phase=='charge' then
  local ox,oy=F.x,F.y;towards(F,F.chargeX,F.chargeY,920,dt)
  for _,b in ipairs(F.babies) do if not b.dead and b.webbed and segment(ox,oy,F.x,F.y,b,27) then
   b.dead=true;F.shells[#F.shells+1]={x=b.x,y=b.y,seed=b.seed,silk=true};F.damage();if F.defeated then return end
  end end
  if F.contactGrace<=0 and segment(ox,oy,F.x,F.y,p,27) then Hazards.kill();return end
  if length(F.x-F.chargeX,F.y-F.chargeY)<4 or F.phaseTime>1.7 then F.phase='recover';F.phaseTime=0;F.target=nil end
 elseif F.phase=='recover' then
  if F.phaseTime>1 then F.phase='webs';F.phaseTime=0;F.shot=.5 end
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
  towards(F,best.x,best.y,270,dt)
  F.nest={x=F.x,y=F.y}
  if F.phaseTime>=.65+F.batch*.34 and F.batch<8 then F.layEgg() end
  if F.batch>=8 or F.phaseTime>4.5 then F.phase='webs';F.phaseTime=0;F.shot=.5 end
 else
  if F.phaseTime>6 and #F.babies+#F.eggs<29 then
   F.phase='lay';F.phaseTime=0;F.wave=F.wave+1;F.batch=0;F.chooseNest()
   if F.carried<8 then F.carried=24 end
  else
   F.shot=F.shot-dt
   if F.shot<=0 then F.shoot();F.shot=.5 end
   local webbed;for _,b in ipairs(F.babies) do if b.webbed and not b.dead then webbed=b;break end end
   if webbed then F.trap(webbed)
   else
    towards(F,Arena.width*.5+math.sin(F.clock*.5)*Arena.width*.18,175+math.cos(F.clock*.65)*45,90,dt)
    F.angle=math.atan2(p.y-F.y,p.x-F.x)-math.pi/2
   end
  end
 end
 if F.contactGrace<=0 and near(F,p,27) then Hazards.kill();return end
 for i=#F.babies,1,-1 do if F.babies[i].dead then table.remove(F.babies,i) end end
end
function F.spider(x,y,size,variant,angle)
 local name=(variant=='queen' or size>=100) and 'queen' or variant=='black' and 'baby_black' or variant=='white' and 'baby_white' or 'baby_red'
 love.graphics.setColor(1,1,1);ArtSet.spider(name,x,y,size,angle)
end
local function web(x,y,r,alpha)
 love.graphics.setColor(1,1,1,alpha or .85);ArtSet.draw('web_wall',x,y,r*2)
end
function F.egg(e,size,progress)
 local name=progress and progress>.66 and 'egg_crack2' or progress and progress>.3 and 'egg_crack1' or 'egg'
 love.graphics.setColor(1,1,1);ArtSet.draw(name,e.x,e.y,size*1.4,0,size*2)
end
function F.draw()
 if not F.active then return end
 local g=love.graphics;g.push('all')
 for _,s in ipairs(F.shells) do g.setColor(1,1,1,.8);ArtSet.draw('shell',s.x,s.y,34,s.seed*.7) end
 for _,w in ipairs(F.stuck) do web(w.x,w.y,25,.78) end
 for _,e in ipairs(F.eggs) do
  local t=math.min(1,e.age/.32);local ease=1-(1-t)^2
  local pose={x=(e.fromX or e.x)+(e.x-(e.fromX or e.x))*ease,y=(e.fromY or e.y)+(e.y-(e.fromY or e.y))*ease-math.sin(t*math.pi)*18}
  F.egg(pose,17*(.65+.35*ease),math.max(e.age/e.hatch,(e.hits or 0)>0 and .45 or 0))
 end
 for _,b in ipairs(F.babies) do if not b.dead then F.spider(b.x,b.y,36,b.variant,b.angle);if b.webbed then web(b.x,b.y,24) end end end
 if not F.engaged then
  UI.text('Approche-toi et touche la reine',F.x-150,F.y+46,'small',{.85,.82,.95},300,'center')
 end
 if F.phase=='aim' then g.setColor(1,.28,.25,.5);g.setLineWidth(2);g.circle('line',F.chargeX,F.chargeY,34+math.sin(F.clock*18)*3) end
 -- A shared walking bob and laying contraction keep the carried eggs attached.
 local moving=F.phase=='lay' or F.phase=='charge' or F.phase=='webs'
 local stride=moving and math.sin(F.clock*(F.phase=='charge' and 24 or 14)) or 0
 local pulse=(F.layPulse or 0)/.32
 local facing=F.visualAngle()
 if F.jumpHeight>0 then g.setColor(0,0,0,.28);g.ellipse('fill',F.x,F.y+16,24,8);g.setColor(1,1,1) end
 g.push();g.translate(F.x,F.y+stride*2-F.jumpHeight);g.rotate(stride*.018);g.scale(1+pulse*.045,1-pulse*.045)
 F.spider(0,0,62,'queen',facing)
 ArtSet.clutch(0,0,62,F.carried,facing);g.pop()
 for _,w in ipairs(F.webs) do g.setColor(1,1,1);ArtSet.draw('web_shot',w.x,w.y,32,math.atan2(w.vy,w.vx)) end
 if F.snare>0 and F.snareSource~='floor' then web(player.x+15,player.y+12,32) end
 if F.gate then
  local x=Arena.width*.5;g.setColor(1,1,1);ArtSet.draw('web_gate',x,50,104,0,125)
  UI.text('Retrouvailles',x-90,83,'small',{.85,1,.9},180,'center')
 end
 g.pop()
end
function F.resize(r)
 if F.nest then F.nest.x=F.nest.x*r end
 F.x=F.x*r;if F.chargeX then F.chargeX=F.chargeX*r end
 for _,list in ipairs({F.eggs,F.babies,F.shells,F.webs,F.stuck}) do for _,o in ipairs(list or {}) do o.x=o.x*r;if o.vx then o.vx=o.vx*r end end end
end
return F
