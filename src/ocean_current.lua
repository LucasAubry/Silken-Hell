-- The ordered stroke is both the water channel and its flow direction.
local C={cache=setmetatable({},{__mode='k'})}
function C.path(e)
 local p=e.points
 if not p then return end
 local rx,ry=e.rx or e.radius or 28,e.ry or e.radius or 28
 local c=C.cache[e]
 if c and c.points==p and c.count==#p and c.rx==rx and c.ry==ry and c.lastX==p[#p-1] and c.lastY==p[#p] then return c end
 if c and c.band then c.band:release() end
 c={points=p,count=#p,lastX=p[#p-1],lastY=p[#p],segments={},length=0,rx=rx,ry=ry};C.cache[e]=c
 c.x0,c.y0,c.x1,c.y1=require('ground_holes').bounds(e)
 for i=3,#p,2 do
  local x,y=p[i-2],p[i-1];local dx,dy=p[i]-x,p[i+1]-y;local length=math.sqrt(dx*dx+dy*dy)
  if length>.001 then
   local nx,ny=dx/length/rx,dy/length/ry
   c.segments[#c.segments+1]={x=x,y=y,dx=dx/length,dy=dy/length,length=length,start=c.length,nx=nx,ny=ny,inverse=1/(nx*nx+ny*ny)}
   c.length=c.length+length
  end
 end
 return c
end
function C.sample(c,d)
 d=math.max(0,math.min(c.length,d))
 -- Arc lengths are sorted; long hand-drawn paths need only a few comparisons.
 local lo,hi=1,#c.segments
 while lo<hi do
  local mid=math.floor((lo+hi)/2);local s=c.segments[mid]
  if d<=s.start+s.length then hi=mid else lo=mid+1 end
 end
 local s=c.segments[lo]
 if s then local t=d-s.start;return s.x+s.dx*t,s.y+s.dy*t,s.dx,s.dy end
 return 0,0,1,0
end
function C.nearest(e,x,y)
 local c=C.path(e);if not c then return end
 x,y=x-e.x,y-e.y
 local best,along=math.huge,0
 for _,s in ipairs(c.segments) do
  local t=math.max(0,math.min(s.length,((x-s.x)/c.rx*s.nx+(y-s.y)/c.ry*s.ny)*s.inverse))
  local d=((x-s.x-s.dx*t)/c.rx)^2+((y-s.y-s.dy*t)/c.ry)^2
  if d<best then best=d;along=s.start+t end
 end
 if #c.segments==0 then best=((x-e.points[1])/c.rx)^2+((y-e.points[2])/c.ry)^2 end
 return best,along,c
end
function C.contains(e,x,y)
 if e.points then
  local c=C.path(e);local px,py=x-e.x,y-e.y
  if px<c.x0 or px>c.x1 or py<c.y0 or py>c.y1 then return false end
  return C.nearest(e,x,y)<=1
 end
 return ((x-e.x)/(e.rx or 50))^2+((y-e.y)/(e.ry or 150))^2<=1
end
function C.sign(e) return e.dx==-1 and -1 or 1 end
function C.direction(e,x,y,along,c)
 if not e.points then return C.sign(e),0 end
 if not c then local distance;distance,along,c=C.nearest(e,x,y) end
 local sign=C.sign(e)
 local px,py,dx,dy=C.sample(c,along)
 -- Aim ahead around bends and gently return to the centre of the channel.
 local ahead=along+sign*24
 local tx,ty=C.sample(c,ahead)
 if ahead<0 or ahead>c.length then tx,ty=px+dx*sign*24,py+dy*sign*24 end
 local vx,vy=tx-px+(e.x+px-x)*.6,ty-py+(e.y+py-y)*.6
 local length=math.sqrt(vx*vx+vy*vy)
 if length<.001 then return dx*sign,dy*sign end
 return vx/length,vy/length
end
function C.velocity(x,y,vx,vy,zones)
 local fx,fy,count=0,0,0
 for _,e in ipairs(zones or {}) do
  local inside,along,c
  if e.points then
   c=C.path(e);local px,py=x-e.x,y-e.y
   if px>=c.x0 and px<=c.x1 and py>=c.y0 and py<=c.y1 then
    local distance;distance,along=C.nearest(e,x,y);inside=distance<=1
   end
  else inside=C.contains(e,x,y) end
  if inside then
   local dx,dy=C.direction(e,x,y,along,c);local speed=e.speed or 80
   fx,fy=fx+dx*speed,fy+dy*speed;count=count+1
  end
 end
 if count==0 then return vx,vy end
 return vx*.65+fx/count,vy*.65+fy/count
end
local function band(e,c)
 if c.band then return end
 local g=love.graphics;local x0,y0,x1,y1=require('ground_holes').bounds(e)
 c.x,c.y=math.floor(x0)-2,math.floor(y0)-2
 c.band=g.newCanvas(math.ceil(x1-c.x)+2,math.ceil(y1-c.y)+2,{dpiscale=1})
 g.push('all');g.setCanvas(c.band);g.origin();g.setScissor();g.setShader();g.clear()
 g.translate(-c.x,-c.y);g.scale(c.rx,c.ry);g.setBlendMode('replace','premultiplied');g.setLineJoin('none')
 local points={};for i=1,#e.points,2 do points[i]=e.points[i]/c.rx;points[i+1]=e.points[i+1]/c.ry end
 for layer=0,12 do
  local r=1-layer*.06;local a=.24*(1-r)^.4;g.setColor(.20*a,.78*a,.88*a,a);g.setLineWidth(2*r)
  if #points>=4 then g.line(points) end
  for i=1,#points,2 do g.circle('fill',points[i],points[i+1],r,24) end
 end
 g.pop()
end
function C.draw(e,time,editor)
 local g=love.graphics;g.push('all');g.setShader()
 local c=C.path(e)
 if not c then
  g.setColor(.2,.78,.88,.2);g.ellipse('fill',e.x,e.y,e.rx or 50,e.ry or 150);g.pop();return
 end
 band(e,c);g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(c.band,e.x+c.x,e.y+c.y);g.setBlendMode('alpha')
 if c.length>0 then
  local sign=C.sign(e);local count=math.min(180,math.max(6,math.ceil(c.length/14)))
  for i=1,count do
   local d=(i*c.length/count+time*(e.speed or 80)*sign)%c.length
   local x,y,dx,dy=C.sample(c,d);local side=math.sin(i*2.399)*.65
   x,y=e.x+x-dy*c.rx*side,e.y+y+dx*c.ry*side
   local trail=18+i%4*5;local tail=math.max(0,math.min(c.length,d-sign*trail))
   local ax,ay,adx,ady=C.sample(c,tail);ax,ay=e.x+ax-ady*c.rx*side,e.y+ay+adx*c.ry*side
   -- Both endpoints are sampled on the path, offset by at most 65% of
   -- its radius. They are already inside the channel: no full path scan.
   do
    local fade=math.min(1,d/20,(c.length-d)/20)
    g.setLineWidth(i%3==0 and 2 or 1);g.setColor(.58,.94,1,(.30+i%3*.08)*fade);g.line(ax,ay,x,y)
    if i%4==0 then g.setColor(.83,.98,1,.55*fade);g.circle('fill',x,y,1.6) end
   end
  end
  if editor then
   g.setColor(.78,1,1,.95);g.setLineWidth(2)
   local count=math.max(1,math.floor(c.length/65))
   for i=1,count do
    local x,y,dx,dy=C.sample(c,c.length*(i-.5)/count);x,y=e.x+x,e.y+y;dx,dy=dx*sign,dy*sign
    g.line(x-dx*10,y-dy*10,x+dx*10,y+dy*10)
    g.line(x+dx*3-dy*6,y+dy*3+dx*6,x+dx*10,y+dy*10,x+dx*3+dy*6,y+dy*3-dx*6)
   end
  end
 end
 g.pop()
end
return C
