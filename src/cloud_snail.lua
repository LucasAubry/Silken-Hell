-- A cloud-eating snail leaves permanent lethal holes in its wake.
local N={size=52}
N.width=N.size*.24
local function weather() return require('sky_weather') end
function N.fallAt(x,y,ignoreOwner)
 for _,p in ipairs(weather().snailHoles or {}) do
  local dx,dy=p.tx-p.x,p.ty-p.y;local length=dx*dx+dy*dy
  local t=length>0 and math.max(0,math.min(1,((x-p.x)*dx+(y-p.y)*dy)/length)) or 0
  if (not ignoreOwner or p.owner~=ignoreOwner) and (x-p.x-t*dx)^2+(y-p.y-t*dy)^2<=(p.radius or N.width)^2 then return true end
 end
 return false
end
function N.trail(x,y,tx,ty,owner)
 local list=weather().snailHoles
 local function key(p,q)return math.floor(p/6+.5)..','..math.floor(q/6+.5) end
 if N.list~=list then
  N.list=list;N.keys={}
  for _,p in ipairs(list) do
   local a,b=key(p.x,p.y),key(p.tx,p.ty);if a>b then a,b=b,a end
   N.keys[a..':'..b..':'..tostring(p.owner)]=true
  end
 end
 local a,b=key(x,y),key(tx,ty);if a>b then a,b=b,a end
 local k=a..':'..b..':'..tostring(owner);if N.keys[k] then return end
 N.keys[k]=true
 list[#list+1]={x=x,y=y,tx=tx,ty=ty,owner=owner,radius=N.width*(.88+.24*(.5+.5*math.sin(tx*.11+ty*.08)))}
end
function N.target(m)
 m.roamIndex=(m.roamIndex or 0)+1
 local sector=(m.roamIndex*5+math.floor(m.x*.039+m.y*.017))%9
 m.tx=80+(sector%3+.5)*(Arena.width-160)/3
 m.ty=80+(math.floor(sector/3)+.5)*440/3
 m.tx,m.ty=Arena.clearSpot(m.tx-16,m.ty-15,32,30)
 m.tx,m.ty=m.tx+16,m.ty+15;m.roamTime=12
end
function N.update(m,dt)
 if m.dead then return end
 if m.falling then m.fallTimer=(m.fallTimer or 0)+dt;if m.fallTimer>=.5 then m.dead=true end;return end
 if not m.snailId then for i,other in ipairs(mobs) do if other==m then m.snailId=i;break end end end
 if N.fallAt(m.x,m.y,m.snailId) then m.falling=true;m.fallTimer=0;Campaign.dropTear(m);return end
 if m.capture or m.is_frozen or m.tunnelTravel then return end
 m.age=m.age+dt;m.roamTime=(m.roamTime or 0)-dt
 if not m.tx or m.roamTime<=0 or (m.tx-m.x)^2+(m.ty-m.y)^2<14^2 then N.target(m) end
 local dx,dy=m.tx-m.x,m.ty-m.y;local d=math.sqrt(dx*dx+dy*dy)
 if d>.01 then
  m.vx,m.vy=dx/d,dy/d;m.angle=math.atan2(dy,dx)
  local distance=math.min(d,math.max(20,m.speed or 66)*dt);local steps=math.max(1,math.ceil(distance/8))
  for _=1,steps do
   local x,y=m.x,m.y;local hitX,hitY=Arena.move(m,m.vx*distance/steps,m.vy*distance/steps)
   if hitX or hitY then Arena.navigate(m,m.tx,m.ty,math.max(20,m.speed or 66),dt/steps) end
   if N.fallAt(m.x,m.y,m.snailId) then m.falling=true;m.fallTimer=0;Campaign.dropTear(m);return end
   -- Sample by distance, not frame count; holes follow every sampled movement segment.
   if not m.cx then m.cx,m.cy=x,y end
   if (m.x-m.cx)^2+(m.y-m.cy)^2>=6^2 then N.trail(m.cx,m.cy,m.x,m.y,m.snailId);m.cx,m.cy=m.x,m.y end
  end
 end
end
local function paintTrail()
 local g=love.graphics;g.push('all');g.setShader();g.setLineStyle('smooth')
 -- The opening retains its collision footprint. Successively inset floors
 -- descend beneath the upper lip, exposing a shaded vertical wall.
 local layers={
  {5,0,{.40,.52,.63}}, {2,0,{.09,.15,.23}},
  {0,0,{.16,.25,.35}}, {-2,1,{.12,.19,.28}},
  {-4,3,{.08,.13,.21}}, {-6,4,{.045,.078,.135}},
  {-8,5,{.02,.039,.078}}, {-10,6,{.006,.014,.034}},
 }
 for _,layer in ipairs(layers) do
  g.setColor(layer[3]);local inset,depth=layer[1]*N.width/23,layer[2]*N.width/23
  for _,p in ipairs(weather().snailHoles or {}) do
   local radius=(p.radius or N.width)+inset;g.setLineWidth(radius*2)
   g.line(p.x,p.y+depth,p.tx,p.ty+depth)
   g.circle('fill',p.x,p.y+depth,radius)
   g.circle('fill',p.tx,p.ty+depth,radius)
  end
 end
 g.pop()
end
-- Permanent terrain only needs repainting when its geometry changes.
function N.drawTrail()
 local list=weather().snailHoles or {};local g=love.graphics
 if #list==0 then return end
 local width=math.ceil(Arena.width)
 if not N.canvas or N.canvas:getWidth()~=width then
  if N.canvas then N.canvas:release() end
  N.canvas=g.newCanvas(width,600,{dpiscale=1});N.drawList=nil
 end
 if N.drawList~=list or N.drawCount~=#list or N.drawRevision~=N.revision then
  g.push('all');g.setCanvas(N.canvas);g.origin();g.setScissor();g.setShader();g.clear()
  paintTrail();g.pop()
  N.drawList=list;N.drawCount=#list;N.drawRevision=N.revision
 end
 g.push('all');g.setShader();g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied');g.draw(N.canvas);g.pop()
end
function N.art(x,y,size,time,angle,alpha) require('cloud_snail_art').draw(x,y,size,time,angle,alpha) end
function N.draw(m)
 if m.dead then return end
 local t=math.min(1,(m.fallTimer or 0)/.5);local g=love.graphics
 if t==0 then Art.contactShadow(m.x,m.y+13,18,7,.32) end
 g.push('all');g.setColor(1,1,1,1-t)
 N.art(m.x,m.y+t*10,N.size*(1-t*.95),m.age,m.angle,1-t);g.pop()
end
return N
