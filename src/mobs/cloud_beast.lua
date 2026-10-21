-- Cloud swimmer: dive, travel underneath, surface and charge on a fixed heading.
local B={}
local function splash(m)
 m.sparks=m.sparks or {};m.sparks[#m.sparks+1]={x=m.x,y=m.y,age=0}
end
local function phase(m,name,time) m.phase=name;m.phaseTime=time end
local function heading(m)
 local slot=0
 for _,other in ipairs(mobs) do
  if other.type=='cloud_beast' then slot=slot+1 end
  if other==m then break end
 end
 -- Layout order separates neighbouring swimmers; authored position adds a
 -- stable offset. Neither rendering time nor random generators are involved.
 return math.max(0,slot-1)*2.3999632297287+(m.x/Arena.width+m.y/600)*.2
end
local function tornadoAt(x,y)
 for _,t in ipairs(Realms.tornadoes or {}) do
  if not t.eject and (x-t.x)^2+(y-t.y)^2<100^2 then return true end
 end
 return false
end
function B.safeTarget(m)
 if not tornadoAt(m.tx,m.ty) then return end
 for ring=1,8 do for i=0,15 do
  local a=i*math.pi/8+(m.roamSeed or 0)
  local x,y=m.tx+math.cos(a)*ring*32,m.ty+math.sin(a)*ring*32
  if x>40 and x<Arena.width-40 and y>40 and y<560 and not tornadoAt(x,y) and not Arena.blocked(x-16,y-15,32,30) then m.tx,m.ty=x,y;return end
 end end
end
function B.update(m,dt)
 if m.dead or m.capture or m.is_frozen or m.tunnelTravel then return end
 if m.roamSeed==nil then m.roamSeed=heading(m) end
 m.age=m.age+dt;m.sparks=m.sparks or {}
 for i=#m.sparks,1,-1 do local p=m.sparks[i];p.age=p.age+dt;if p.age>.65 then table.remove(m.sparks,i) end end
 if type(m.phase)~='string' then phase(m,'surface',m.attackDelay and math.max(0,m.attackDelay-1.95) or 1.2);local a=require('mob_start_direction').angle(m) or m.roamSeed;m.vx=math.cos(a);m.vy=math.sin(a) end
 if m.phase=='surface' and tornadoAt(m.x,m.y) then phase(m,'dive',.45);splash(m) end
 m.phaseTime=m.phaseTime-dt
 if m.phase=='surface' or m.phase=='dive' then
  local speed=m.phase=='surface' and 42 or 42*math.max(0,m.phaseTime/.45)
  local hx,hy=Arena.move(m,(m.vx or 1)*speed*dt,(m.vy or 0)*speed*dt)
  if hx then m.vx=-(m.vx or 1) end;if hy then m.vy=-(m.vy or 0) end
  m.angle=math.atan2(m.vy or 0,m.vx or 1)-math.pi/2
 elseif m.phase=='hidden' then
  local dx,dy=m.tx-m.x,m.ty-m.y;local d=math.sqrt(dx*dx+dy*dy)
  if d>1 then Arena.move(m,dx/d*math.min(d,210*dt),dy/d*math.min(d,210*dt)) end
 elseif m.phase=='charge' then
  local steps=math.max(1,math.ceil((m.speed or 330)*dt/5))
  for _=1,steps do
   local hx,hy=Arena.move(m,m.vx*(m.speed or 330)*dt/steps,m.vy*(m.speed or 330)*dt/steps)
   if isTouching(player,m) then Hazards.kill('cloud_beast') end
   if hx or hy then m.phaseTime=0;break end
  end
 end
 if m.phaseTime<=0 then
  if m.phase=='surface' or m.phase=='charge' then phase(m,'dive',.45);splash(m)
  elseif m.phase=='dive' then
   phase(m,'hidden',1.1)
   local a=m.age*2.399+m.roamSeed
   m.tx,m.ty=Arena.clearSpot(math.max(55,math.min(Arena.width-85,player.x+math.cos(a)*135)),math.max(55,math.min(515,player.y+math.sin(a)*120)),32,30)
   m.tx,m.ty=m.tx+16,m.ty+15;B.safeTarget(m)
  elseif m.phase=='hidden' then
   if tornadoAt(m.x,m.y) then m.phaseTime=.3;B.safeTarget(m);return end
   phase(m,'emerge',.4);splash(m)
   local dx,dy=player.x+15-m.x,player.y+12-m.y;local d=math.max(.001,math.sqrt(dx*dx+dy*dy))
   m.vx,m.vy=dx/d,dy/d;m.angle=math.atan2(dy,dx)-math.pi/2
  elseif m.phase=='emerge' then phase(m,'charge',m.attackDuration or .9) end
 end
 if (m.phase=='surface' or m.phase=='charge') and isTouching(player,m) then Hazards.kill('cloud_beast') end
end
function B.art(x,y,size,time,angle,amount)
 local Art=require('art');local g=love.graphics
 if not Art.images.magma_larva then Art.add('magma_larva','assets/monstres/enfer/larve/magma_larva.png') end
 B.shader=B.shader or g.newShader([[
 vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
  vec4 p=Texel(image,uv);float v=max(p.r,max(p.g,p.b));
  vec3 cloud=mix(vec3(.12,.19,.29),vec3(.96,.99,1.0),smoothstep(.06,.85,v));
  return vec4(cloud,p.a)*color;
 }]])
 local a=Art.images.magma_larva;local breath=1+math.sin((time or 0)*15)*.035
 g.push('all');g.setShader(B.shader);g.setColor(1,1,1)
 local scale=size/math.max(a.w,a.h)
 g.draw(a.image,a.quad,x,y,angle or 0,scale*breath,scale*(amount or 1)/breath,a.w/2,a.h/2)
 g.pop()
end
function B.draw(m)
 local amount=m.phase=='hidden' and 0 or m.phase=='dive' and math.max(0,m.phaseTime/.45) or m.phase=='emerge' and math.min(1,1-m.phaseTime/.4) or 1
 if amount>0 then Art.contactShadow(m.x,m.y+5+(1-amount)*10,17*amount,6*amount,.28*amount);B.art(m.x,m.y+(1-amount)*10,45,m.age,m.angle,amount) end
 local g=love.graphics;g.push('all');g.setShader()
 for _,p in ipairs(m.sparks or {}) do
  local t=p.age/.65
  for i=1,10 do
   local a=i*2.399;local d=t*(15+i%3*8)
   local x=p.x+math.cos(a)*d;local y=p.y+math.sin(a)*d*.4-math.sin(t*math.pi)*(12+i%4*4)
   local r=(2+i%3)*(1-t*.7)
   g.setColor(.67,.80,.91,(1-t)*.8);g.circle('fill',x+1,y+1,r+1)
   g.setColor(.96,.99,1,(1-t)*.95);g.circle('fill',x,y,r)
  end
 end
 g.pop()
end
return B
