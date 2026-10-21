-- Authored brush strokes share exactly the same footprint in editor and game.
local H={cache=setmetatable({},{__mode='k'}),shared={},order={},builds=0}
function H.bounds(e)
 local p=e.points;local rx,ry=e.rx or e.radius or 28,e.ry or e.radius or 28
 local x0,y0,x1,y1=p[1],p[2],p[1],p[2]
 for i=3,#p,2 do x0=math.min(x0,p[i]);x1=math.max(x1,p[i]);y0=math.min(y0,p[i+1]);y1=math.max(y1,p[i+1]) end
 return x0-rx,y0-ry,x1+rx,y1+ry
end
-- Fill pockets enclosed by the brush footprint, including crossed/retraced paths.
-- The open inside of an L-shaped stroke remains untouched.
function H.geometry(e)
 local p=e.points;local rx,ry=e.rx or e.radius or 28,e.ry or e.radius or 28
 local signature=table.concat(p,',')..':'..rx..':'..ry
 local cache=H.cache[e]
 if cache and cache.signature==signature then return cache end
 -- Layout entities are copied on every retry; geometry belongs to the shape,
 -- not to that short-lived entity. Editing points still changes the signature.
 cache=H.shared[signature]
 if cache then H.cache[e]=cache;return cache end
 H.builds=H.builds+1
 cache={signature=signature,meshes={},fill={}};H.cache[e]=cache
 H.shared[signature]=cache;H.order[#H.order+1]=signature
 if #H.order>64 then H.shared[table.remove(H.order,1)]=nil end
 -- Live entities may still reference an evicted mesh: let GC release it safely.
 if #p<6 then return cache end
 local x0,y0,x1,y1=H.bounds(e)
 local step=math.max(2,math.sqrt((x1-x0+8)*(y1-y0+8)/160000))
 x0=x0-step*2;y0=y0-step*2
 local w=math.ceil((x1-x0)/step)+3;local h=math.ceil((y1-y0)/step)+3
 local solid={}
 for i=1,#p,2 do
  local ax,ay=p[math.max(1,i-2)],p[math.max(2,i-1)];local bx,by=p[i],p[i+1]
  local dx,dy=(bx-ax)/rx,(by-ay)/ry;local length=dx*dx+dy*dy
  local left=math.max(0,math.floor((math.min(ax,bx)-rx-x0)/step))
  local right=math.min(w-1,math.ceil((math.max(ax,bx)+rx-x0)/step))
  local top=math.max(0,math.floor((math.min(ay,by)-ry-y0)/step))
  local bottom=math.min(h-1,math.ceil((math.max(ay,by)+ry-y0)/step))
  for row=top,bottom do for col=left,right do
   local x=(x0+(col+.5)*step-ax)/rx;local y=(y0+(row+.5)*step-ay)/ry
   local t=length>0 and math.max(0,math.min(1,(x*dx+y*dy)/length)) or 0
   if (x-dx*t)^2+(y-dy*t)^2<=1 then solid[row*w+col+1]=true end
  end end
 end
 local outside,queue={[1]=true},{1};local head=1
 local function visit(n)
  if not solid[n] and not outside[n] then outside[n]=true;queue[#queue+1]=n end
 end
 while head<=#queue do
  local n=queue[head];head=head+1;local col=(n-1)%w
  if col>0 then visit(n-1) end;if col<w-1 then visit(n+1) end
  if n>w then visit(n-w) end;if n<=w*(h-1) then visit(n+w) end
 end
 cache.grid={x=x0,y=y0,step=step,w=w,h=h,cells={}}
 for row=0,h-1 do
  local first
  for col=0,w do
   local n=row*w+col+1;local filled=col<w and not solid[n] and not outside[n]
   if filled then cache.grid.cells[n]=true;if not first then first=col end
   elseif first then
    cache.fill[#cache.fill+1]={x0+(first-1)*step,y0+(row-1)*step,(col-first+2)*step,step*3};first=nil
   end
  end
 end
 return cache
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
 local grid=H.geometry(e).grid
 if grid then
  local col=math.floor((x*rx-grid.x)/grid.step);local row=math.floor((y*ry-grid.y)/grid.step)
  if col>=0 and col<grid.w and row>=0 and row<grid.h then return grid.cells[row*grid.w+col+1]==true end
 end
 return false
end
-- Runtime strokes are immutable between resizes. Compile their normalized
-- segments once; broad bounds reject distant points before any segment work.
H.fastCache=setmetatable({},{__mode='k'})
function H.containsFast(e,x,y)
 local p=e.points;local rx,ry=e.rx or e.radius or 28,e.ry or e.radius or 28
 local c=H.fastCache[e]
 if not c or c.points~=p or c.count~=#p or c.rx~=rx or c.ry~=ry then
  local x0,y0,x1,y1=H.bounds(e)
  c={points=p,count=#p,rx=rx,ry=ry,x0=x0,y0=y0,x1=x1,y1=y1,segments={}}
  local ax,ay=p[1]/rx,p[2]/ry;c.ax,c.ay=ax,ay
  for i=3,#p,2 do
   local bx,by=p[i]/rx,p[i+1]/ry;local dx,dy=bx-ax,by-ay
   c.segments[#c.segments+1]={ax,ay,dx,dy,dx*dx+dy*dy,math.min(ax,bx)-1,math.min(ay,by)-1,math.max(ax,bx)+1,math.max(ay,by)+1}
   ax,ay=bx,by
  end
  H.fastCache[e]=c
 end
 x,y=x-e.x,y-e.y
 if x<c.x0-1e-9 or y<c.y0-1e-9 or x>c.x1+1e-9 or y>c.y1+1e-9 then return false end
 local px,py=x/rx,y/ry
 if (px-c.ax)^2+(py-c.ay)^2<=1 then return true end
 for _,v in ipairs(c.segments) do
  if px>=v[6] and py>=v[7] and px<=v[8] and py<=v[9] then
   local t=v[5]>0 and math.max(0,math.min(1,((px-v[1])*v[3]+(py-v[2])*v[4])/v[5])) or 0
   if (px-v[1]-v[3]*t)^2+(py-v[2]-v[4]*t)^2<=1 then return true end
  end
 end
 if not c.gridReady then c.grid=H.geometry(e).grid;c.gridReady=true end
 local grid=c.grid
 if grid then
  local col=math.floor((px*rx-grid.x)/grid.step);local row=math.floor((py*ry-grid.y)/grid.step)
  if col>=0 and col<grid.w and row>=0 and row<grid.h then return grid.cells[row*grid.w+col+1]==true end
 end
 return false
end
function H.stroke(points,radius,kind)
 local x0,y0,x1,y1=points[1],points[2],points[1],points[2]
 for i=3,#points,2 do x0=math.min(x0,points[i]);x1=math.max(x1,points[i]);y0=math.min(y0,points[i+1]);y1=math.max(y1,points[i+1]) end
 local e={kind=kind or 'hole',x=(x0+x1)/2,y=(y0+y1)/2,radius=radius,points={}}
 for i=1,#points,2 do e.points[i]=points[i]-e.x;e.points[i+1]=points[i+1]-e.y end
 return e
end
function H.resize(e,ratio)
 H.fastCache[e]=nil
 e.x=e.x*ratio
 if e.points then
  e.rx=(e.rx or e.radius)*ratio;e.ry=e.ry or e.radius
  for i=1,#e.points,2 do e.points[i]=e.points[i]*ratio end
 end
end
function H.draw(e,scale)
 local g=love.graphics;local p=e.points
 local rx,ry=e.rx or e.radius or 28,e.ry or e.radius or 28
 scale=scale or 1
 local cache=H.geometry(e)
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
  for _,rect in ipairs(cache.fill) do
   local x,y,w,h=unpack(rect)
   -- Narrower depth layers expose more of the enclosed pocket. Extend its
   -- fill to meet the inner stroke edge instead of leaving a rectangular seam.
   local padX=(e.rx or e.radius or 28)*math.max(0,1-scale)
   local padY=(e.ry or e.radius or 28)*math.max(0,1-scale)
   x,y,w,h=x-padX,y-padY,w+padX*2,h+padY*2
   vertex(x,y);vertex(x+w,y);vertex(x,y+h)
   vertex(x,y+h);vertex(x+w,y);vertex(x+w,y+h)
  end
  cache.meshes[scale]=g.newMesh(vertices,'triangles','static')
 end
 g.draw(cache.meshes[scale],e.x,e.y)
end
return H
