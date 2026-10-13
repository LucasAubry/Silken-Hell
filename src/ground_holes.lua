-- Authored brush strokes share exactly the same footprint in editor and game.
local H={cache=setmetatable({},{__mode='k'})}
function H.bounds(e)
 local p=e.points;local rx,ry=e.rx or e.radius or 28,e.ry or e.radius or 28
 local x0,y0,x1,y1=p[1],p[2],p[1],p[2]
 for i=3,#p,2 do x0=math.min(x0,p[i]);x1=math.max(x1,p[i]);y0=math.min(y0,p[i+1]);y1=math.max(y1,p[i+1]) end
 return x0-rx,y0-ry,x1+rx,y1+ry
end
function H.contains(e,x,y)
 local rx,ry=e.rx or e.radius or 28,e.ry or e.radius or 28
 x,y=(x-e.x)/rx,(y-e.y)/ry
 local p=e.points
 local ax,ay=p[1]/rx,p[2]/ry
 if (x-ax)^2+(y-ay)^2<=1 then return true end
 for i=3,#p,2 do
  local bx,by=p[i]/rx,p[i+1]/ry
  local dx,dy=bx-ax,by-ay;local len=dx*dx+dy*dy
  local t=len>0 and math.max(0,math.min(1,((x-ax)*dx+(y-ay)*dy)/len)) or 0
  if (x-ax-dx*t)^2+(y-ay-dy*t)^2<=1 then return true end
  ax,ay=bx,by
 end
 return false
end
function H.stroke(points,radius)
 local x0,y0,x1,y1=points[1],points[2],points[1],points[2]
 for i=3,#points,2 do x0=math.min(x0,points[i]);x1=math.max(x1,points[i]);y0=math.min(y0,points[i+1]);y1=math.max(y1,points[i+1]) end
 local e={kind='hole',x=(x0+x1)/2,y=(y0+y1)/2,radius=radius,points={}}
 for i=1,#points,2 do e.points[i]=points[i]-e.x;e.points[i+1]=points[i+1]-e.y end
 return e
end
function H.draw(e,scale)
 local g=love.graphics;local p=e.points
 local rx,ry=e.rx or e.radius or 28,e.ry or e.radius or 28
 scale=scale or 1
 local cache=H.cache[e]
 if not cache or cache.points~=p or cache.count~=#p or cache.rx~=rx or cache.ry~=ry then
  if cache then for _,mesh in pairs(cache.meshes) do mesh:release() end end
  cache={points=p,count=#p,rx=rx,ry=ry,meshes={}};H.cache[e]=cache
 end
 if not cache.meshes[scale] then
  rx,ry=rx*scale,ry*scale
  local vertices={}
  local function vertex(x,y) vertices[#vertices+1]={x,y,0,0} end
  for i=1,#p,2 do
   local x,y=p[i],p[i+1]
   for n=0,19 do
    local a,b=n*math.pi/10,(n+1)*math.pi/10
    vertex(x,y);vertex(x+math.cos(a)*rx,y+math.sin(a)*ry);vertex(x+math.cos(b)*rx,y+math.sin(b)*ry)
   end
   if i>1 then
    local ax,ay=p[i-2],p[i-1];local dx,dy=(x-ax)/rx,(y-ay)/ry
    local length=math.sqrt(dx*dx+dy*dy)
    if length>0 then
     local nx,ny=-dy/length*rx,dx/length*ry
     vertex(ax+nx,ay+ny);vertex(ax-nx,ay-ny);vertex(x+nx,y+ny)
     vertex(x+nx,y+ny);vertex(ax-nx,ay-ny);vertex(x-nx,y-ny)
    end
   end
  end
  cache.meshes[scale]=g.newMesh(vertices,'triangles','static')
 end
 g.draw(cache.meshes[scale],e.x,e.y)
end
return H
