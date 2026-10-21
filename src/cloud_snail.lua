-- A cloud-eating snail leaves permanent lethal holes in its wake.
local N={size=52,mergeMargin=3}
N.width=N.size*.24
local function weather() return require('sky_weather') end
local function nearby(x,y)
 local list=weather().snailHoles or {}
 if N.indexList~=list or N.indexRevision~=N.revision or (N.indexCount or 0)>#list then
  N.indexList=list;N.indexRevision=N.revision;N.indexCount=0;N.cells={}
 end
 for i=N.indexCount+1,#list do
  local p=list[i];local r=(p.radius or N.width)+N.mergeMargin
  for row=math.floor((math.min(p.y,p.ty)-r)/64),math.floor((math.max(p.y,p.ty)+r)/64) do
   for col=math.floor((math.min(p.x,p.tx)-r)/64),math.floor((math.max(p.x,p.tx)+r)/64) do
    local key=col..':'..row;N.cells[key]=N.cells[key] or {};N.cells[key][#N.cells[key]+1]=p
   end
  end
 end
 N.indexCount=#list
 return N.cells[math.floor(x/64)..':'..math.floor(y/64)] or {}
end
function N.fallAt(x,y,ignoreOwner)
 for _,p in ipairs(nearby(x,y)) do
  local dx,dy=p.tx-p.x,p.ty-p.y;local length=dx*dx+dy*dy
  local t=length>0 and math.max(0,math.min(1,((x-p.x)*dx+(y-p.y)*dy)/length)) or 0
  if (not ignoreOwner or p.owner~=ignoreOwner) and (x-p.x-t*dx)^2+(y-p.y-t*dy)^2<=((p.radius or N.width)+N.mergeMargin)^2 then return true end
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
-- Look ahead before moving: holes remain lethal, but a free route is preferred.
function N.unsafe(x,y,m)
 if x<45 or x>Arena.width-45 or y<45 or y>555 or Arena.blocked(x-16,y-14,32,28) then return true end
 if N.fallAt(x,y) or weather().fallAt(x,y) then return true end
 for _,p in ipairs(Realms.holes or {}) do
  if p.points then
   if require('ground_holes').contains(p,x,y) then return true end
  elseif ((x-p.x)/p.rx)^2+((y-p.y)/p.ry)^2<1.5 then return true end
 end
 if Storm and Storm.holeAt and Storm.holeAt(x,y) then return true end
 for _,other in ipairs(mobs) do
  if other~=m and other.type=='cloud_snail' and not other.dead and not other.falling
   and (x-other.x)^2+(y-other.y)^2<48^2 then return true end
 end
 return false
end
function N.steer(m,dx,dy,distance)
 local base=math.atan2(dy,dx);local side=(m.snailId or 1)%2==0 and 1 or -1
 for _,offset in ipairs({0,.35,-.35,.7,-.7,1.1,-1.1,1.57,-1.57,2.2,-2.2,math.pi}) do
  local angle=base+offset*side;local vx,vy=math.cos(angle),math.sin(angle)
  local clear=true
  for _,ahead in ipairs({18,30,44}) do
   local cx,cy=m.x+vx*(ahead+distance),m.y+vy*(ahead+distance)
   if N.unsafe(cx,cy,m) or N.unsafe(cx-vy*12,cy+vx*12,m) or N.unsafe(cx+vy*12,cy-vx*12,m) then clear=false;break end
  end
  if clear then return vx,vy end
 end
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
  local distance=math.min(d,math.max(20,m.speed or 66)*dt);local steps=math.max(1,math.ceil(distance/8))
  local vx,vy=N.steer(m,dx,dy,distance/steps)
  if not vx then m.roamTime=0;return end
  m.vx,m.vy=vx,vy;m.angle=math.atan2(vy,vx)
  for _=1,steps do
   local x,y=m.x,m.y;local hitX,hitY=Arena.move(m,m.vx*distance/steps,m.vy*distance/steps)
   if hitX or hitY then m.roamTime=0;break end
   if N.fallAt(m.x,m.y,m.snailId) then m.falling=true;m.fallTimer=0;Campaign.dropTear(m);return end
   -- Sample by distance, not frame count; holes follow every sampled movement segment.
   if not m.cx then m.cx,m.cy=x,y end
   if (m.x-m.cx)^2+(m.y-m.cy)^2>=6^2 then N.trail(m.cx,m.cy,m.x,m.y,m.snailId);m.cx,m.cy=m.x,m.y end
  end
 end
end
-- Extend a GPU distance mask only when a new segment is eaten. The cloud
-- shader stays live, so the rim follows the same moving sky as authored holes.
function N.drawTrail()
 local list=weather().snailHoles or {};local g=love.graphics
 if #list==0 then return end
 local width=math.ceil(Arena.width)
 if not N.canvas or N.canvas:getWidth()~=width then
  if N.canvas then N.canvas:release() end
  N.canvas=g.newCanvas(width,600,{dpiscale=1});N.canvas:setFilter('linear','linear');N.drawList=nil
 end
 local rebuild=N.drawList~=list or N.drawRevision~=N.revision or (N.drawCount or 0)>#list
 if rebuild or N.drawCount~=#list then
  N.maskShader=N.maskShader or g.newShader('assets/shaders/snail_hole_mask.glsl')
  g.push('all');g.setCanvas(N.canvas);g.origin();g.setScissor();g.setShader(N.maskShader)
  if rebuild then g.clear(0,0,0,1);N.drawCount=0 end
  -- Maximum signed distance joins overlapping capsules without painted seams.
  g.setBlendMode('lighten','premultiplied');g.setColor(1,1,1)
  for i=(N.drawCount or 0)+1,#list do
   local p=list[i];local radius=(p.radius or N.width)+N.mergeMargin;local margin=radius+18
   N.maskShader:send('ends',{p.x,p.y,p.tx,p.ty});N.maskShader:send('radius',radius)
   g.rectangle('fill',math.min(p.x,p.tx)-margin,math.min(p.y,p.ty)-margin,
    math.abs(p.tx-p.x)+margin*2,math.abs(p.ty-p.y)+margin*2)
  end
  g.pop();N.drawList=list;N.drawCount=#list;N.drawRevision=N.revision
 end
 local surface=require('terrain_surface');local zones={}
 for _,source in ipairs({Realms.holes or {},weather().holes or {}}) do
  for _,hole in ipairs(source) do if not hole.temporary then zones[#zones+1]=hole end end
 end
 local field=surface.field(zones,'hole')
 if not N.union or N.union:getWidth()~=width then
  if N.union then N.union:release() end
  N.union=g.newCanvas(width,600,{dpiscale=1});N.union:setFilter('linear','linear');N.unionList=nil
 end
 local key=field and field.key or ''
 if N.unionList~=list or N.unionCount~=#list or N.unionRevision~=N.revision or N.unionKey~=key then
  local dirty
  if N.unionList==list and N.unionRevision==N.revision and N.unionKey==key and (N.unionCount or 0)<#list then
   dirty={math.huge,math.huge,-math.huge,-math.huge}
   for i=(N.unionCount or 0)+1,#list do
    local p=list[i];local pad=(p.radius or N.width)+N.mergeMargin+18
    dirty[1]=math.min(dirty[1],p.x-pad,p.tx-pad);dirty[2]=math.min(dirty[2],p.y-pad,p.ty-pad)
    dirty[3]=math.max(dirty[3],p.x+pad,p.tx+pad);dirty[4]=math.max(dirty[4],p.y+pad,p.ty+pad)
   end
  end
  g.push('all');g.setCanvas(N.union);g.origin();g.setScissor();g.setShader();g.clear(0,0,0,1)
  g.setBlendMode('lighten','premultiplied');g.setColor(1,1,1);g.draw(N.canvas)
  local edge=require('sky_void').edgeField(width);g.draw(edge.image,0,0,0,edge.step,edge.step)
  if field then g.draw(field.image,field.x,field.y,0,field.step,field.step) end
  g.pop();require('hole_union_distance').build(N.union,N,dirty);N.unionList=list;N.unionCount=#list;N.unionRevision=N.revision;N.unionKey=key
 end
 surface.drawSkyField({image=N.distanceResult,x=0,y=0,w=width,h=600,step=1},1)
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
