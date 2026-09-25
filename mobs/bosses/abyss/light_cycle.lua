local C={}
local function distance(x,y,tx,ty) return math.sqrt((tx-x)^2+(ty-y)^2) end
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
function C.sheltered() return false end
function C.lockPlayer() return false end
function C.setup(a)
 a.hp=6;a.maxHp=6;a.name='Le Léviathan des Abysses';a.round=0;a.volley=0
 a.threads={};a.lightMotes={};a.octopuses={};a.mines={};a.beams={};a.waves={};a.lightSites={}
 a.lightTrail={};a.lumenParticles={};a.debris={};a.vacuumCargo={};a.energy=0;a.hitGrace=0
 a.swimHead={x=55,y=300,angle=0};a.chain={};a.aim=nil
 for i=1,90 do
  a.lumenParticles[i]={x=35+(math.sin(i*127.1)*43758.5453%1)*(Arena.width-70),y=45+(math.sin(i*311.7)*19642.349%1)*510,age=i,life=1000,id=i}
 end
 C.enter(a,'rest')
end
function C.mouth(a) return a.swimHead.x+84,a.swimHead.y+16 end
function C.target(a) local x,y=C.mouth(a);return x+50,y end
function C.build(a)
 local h=a.swimHead;if not h then return end
 local key=a.open and 'skeleton_open' or 'skeleton_head';local spot=Art.images[key].glow or {u=.5,v=.5}
 a.head={x=h.x,y=h.y,w=220,h=190,angle=0}
 a.bones={{key=key,x=h.x,y=h.y,w=220,h=190,angle=0,gx=h.x+(spot.u-.5)*220,gy=h.y+(spot.v-.5)*190}}
end
function C.enter(a,phase)
 a.phase=phase;a.phaseTime=0;a.open=phase=='suction' or phase=='recover' or phase=='inhaleTell';a.energy=0
 if phase=='tell' then
  a.volley=a.volley+1;a.beams={}
  local x,y=C.mouth(a);local angle=math.atan2(player.y+12-y,math.max(40,player.x+15-x))
  local offsets=a.volley==3 and {-.3,0,.3} or {0}
  for _,offset in ipairs(offsets) do a.beams[#a.beams+1]={angle=clamp(angle+offset,-1.15,1.15)} end
  a.aim={x=x+math.cos(angle)*Arena.width,y=y+math.sin(angle)*Arena.width}
 elseif phase=='inhaleTell' then a.beams={};a.aim=nil
 elseif phase=='recover' then a.exposed=true;local x,y=C.mouth(a);BossFX.burst(x,y,{.3,.8,1},1)
 elseif phase=='rest' then a.beams={};a.volley=0;a.round=a.round+1;a.exposed=false;a.aim=nil end
 a.buildBones()
end
function C.contact(a)
 if a.defeated or player.reset or (player.abyssGrace or 0)>0 then return end
 local px,py=player.x+15,player.y+12;local mx,my=C.mouth(a)
 if a.phase=='recover' then
  local tx,ty=C.target(a)
  if a.exposed and player.dashing and distance(px,py,tx,ty)<32 then
   a.exposed=false;a.hurt(1);BossFX.burst(tx,ty,{1,.8,.25},2);return
  end
  -- The recovery pocket is safe, allowing a clean retreat after the hit.
  if distance(px,py,mx+42,my)<72 then return end
 end
 if a.phase=='fire' then
  for _,b in ipairs(a.beams) do
   local dx,dy=px-mx,py-my;local along=dx*math.cos(b.angle)+dy*math.sin(b.angle)
   local across=math.abs(-dx*math.sin(b.angle)+dy*math.cos(b.angle))
   if along>=0 and along<=Arena.width*1.6 and across<19 then Hazards.kill('abyss_bite');return end
  end
 end
 if a.phase=='suction' and distance(px,py,mx,my)<38 then Hazards.kill('abyss_bite');return end
 for _,b in ipairs(a.bones) do if a.overlapsBone(b) then Hazards.kill('abyss_bite');return end end
end
function C.suction(a,dt)
 local mx,my=C.mouth(a);local dx,dy=mx-player.x-15,my-player.y-12;local d=math.max(1,distance(0,0,dx,dy))
 local speed=(165+90*math.max(0,1-d/Arena.width))*(a.pullStrength or 1)
 local steps=math.max(1,math.ceil(speed*dt/5))
 for _=1,steps do
  Arena.move(player,dx/d*speed*dt/steps,dy/d*speed*dt/steps);C.contact(a)
  if player.reset then return end
 end
end
function C.update(a,dt)
 if a.defeated or player.reset then return end
 a.clock=a.clock+dt;a.flash=math.max(0,a.flash-dt);a.spitFlash=math.max(0,a.spitFlash-dt)
 a.phaseTime=a.phaseTime+dt*(a.attackRate or 1)
 local durations={rest=1.1,tell=a.hp<=3 and .8 or 1.05,fire=.55,gap=.4,inhaleTell=1.25,suction=4.2,recover=2.6}
 if a.phaseTime>=durations[a.phase] then
  local nextPhase={rest='tell',tell='fire',fire='gap',gap=a.volley<3 and 'tell' or 'inhaleTell',inhaleTell='suction',suction='recover',recover='rest'}
  C.enter(a,nextPhase[a.phase])
 end
 -- Lock the mouth during laser warnings and fire so the announced line stays exact.
 if a.phase=='rest' or a.phase=='recover' then
  a.swimHead.y=a.swimHead.y+(300+math.sin(a.clock*.8)*40-a.swimHead.y)*(1-math.exp(-dt*2));a.buildBones()
 end
 a.energy=a.phase=='tell' and math.min(1,a.phaseTime/durations.tell) or (a.phase=='fire' and 1 or 0)
 if a.phase=='suction' then C.suction(a,dt) end
 local mx,my=C.mouth(a)
 for _,p in ipairs(a.lumenParticles) do
  p.age=p.age+dt
  if a.phase=='suction' or a.phase=='inhaleTell' then
   local dx,dy=mx-p.x,my-p.y;local d=math.max(1,distance(0,0,dx,dy));local speed=a.phase=='suction' and (180+d*.65) or 38
   p.vx=dx/d*speed;p.vy=dy/d*speed
   if d<15 then p.x=Arena.width-35;p.y=45+(math.sin(p.id*43+p.age)*.5+.5)*510 end
  else p.vx=math.sin(p.age*.6+p.id)*9+5;p.vy=math.cos(p.age*.7+p.id)*7 end
  p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt
  if p.x>Arena.width-25 then p.x=30 end;p.y=clamp(p.y,35,565)
 end
 C.contact(a);a.refreshLight()
end
function C.drawMask(a)
 if a.defeated then return end
 local g=love.graphics
 local mx,my=C.mouth(a)
 g.setColor(.45,.45,.45,1);g.circle('fill',mx,my,90)
 if a.phase=='tell' or a.phase=='fire' then
  for _,b in ipairs(a.beams) do
   g.setColor(.8,.8,.8,1);g.setLineWidth(a.phase=='fire' and 45 or 8)
   g.line(mx,my,mx+math.cos(b.angle)*Arena.width*1.6,my+math.sin(b.angle)*Arena.width*1.6)
  end
 end
end
function C.draw(a)
 if a.defeated then return end
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 local mx,my=C.mouth(a)
 for _,p in ipairs(a.lumenParticles) do
  local glow=.45+.25*math.sin(p.age*2+p.id)
  g.setColor(.2,.65,.9,.09);g.circle('fill',p.x,p.y,5)
  g.setColor(.45,.85,1,glow);g.circle('fill',p.x,p.y,1.3)
  if a.phase=='suction' then g.setColor(.3,.75,1,.3);g.setLineWidth(1);g.line(p.x,p.y,p.x-(p.vx or 0)*.045,p.y-(p.vy or 0)*.045) end
 end
 if a.phase=='tell' or a.phase=='fire' then
  for _,b in ipairs(a.beams) do
   local tx,ty=mx+math.cos(b.angle)*Arena.width*1.6,my+math.sin(b.angle)*Arena.width*1.6
   if a.phase=='tell' then
    g.setColor(1,.38,.22,.07+a.energy*.1);g.setLineWidth(28);g.line(mx,my,tx,ty)
    g.setColor(1,.65,.32,.65);g.setLineWidth(1.5);g.line(mx,my,tx,ty)
   else
    for _,v in ipairs({{54,.06},{36,.16},{22,.7},{9,1}}) do
     g.setColor(v[1]==9 and .8 or .12,.7,1,v[2]);g.setLineWidth(v[1]);g.line(mx,my,tx,ty)
    end
    g.setColor(.92,1,1);g.setLineWidth(3);g.line(mx,my,tx,ty)
    for i=1,18 do local t=(i/18+a.clock*2)%1;local x,y=mx+(tx-mx)*t,my+(ty-my)*t
     g.setColor(.45,.9,1,.65);g.circle('fill',x-math.sin(b.angle)*math.sin(i*3+a.clock*20)*20,y+math.cos(b.angle)*math.sin(i*3+a.clock*20)*20,1.5)
    end
   end
  end
 end
 if a.phase=='inhaleTell' or a.phase=='suction' then
  for i=1,4 do local t=(i/4-a.clock*.65)%1;g.setColor(.35,.75,1,(1-t)*.35);g.setLineWidth(1.5);g.ellipse('line',mx,my,20+t*90,12+t*65) end
  if a.phase=='inhaleTell' then g.setColor(1,.55,.25,.8);g.setLineWidth(3);g.arc('line','open',mx,my,44,-1.4,1.4) end
 elseif a.phase=='recover' and a.exposed then
  local x,y=C.target(a);local pulse=math.sin(a.clock*8)*3
  g.setColor(1,.6,.1,.12);g.circle('fill',x,y,32+pulse)
  g.setColor(1,.8,.25,.9);g.setLineWidth(2);g.circle('line',x,y,23+pulse)
  g.setColor(1,.9,.5);g.polygon('fill',x,y-11,x+8,y,x,y+11,x-8,y)
 end
 g.pop()
end
return C
