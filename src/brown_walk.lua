-- Lightweight 2D mesh rig: the original pixels stay intact; leg regions alternate.
local W={meshes={}}
local tau=math.pi*2
local function smooth(a,b,x) local t=math.max(0,math.min(1,(x-a)/(b-a)));return t*t*(3-2*t) end
function W.advance(p,distance,dt)
 p.walkMoving=distance>.01 and dt>0
 if p.walkMoving then p.walkPhase=((p.walkPhase or 0)+distance*tau/110)%tau end
end
local function build(img,dir,bounds)
 local cols,rows=20,20;local vertices,map,rig={},{},{}
 local iw,ih=img:getDimensions();local qx,qy,w,h=0,0,iw,ih
 if bounds then qx,qy,w,h=bounds:getViewport() end
 local function protected(u,v,cx,cy,rx,ry)
  return 1-smooth(.8,1.2,math.sqrt(((u-cx)/rx)^2+((v-cy)/ry)^2))
 end
 for y=0,rows do for x=0,cols do
  local u,v=x/cols,y/rows;local pu=dir=='right' and 1-u or u
  local body
  if dir=='left' or dir=='right' then body=math.max(protected(pu,v,.31,.64,.25,.29),protected(pu,v,.63,.23,.27,.25))
  else body=math.max(protected(u,v,.5,.63,.23,.3),protected(u,v,.5,.23,.25,.25)) end
  local side=u<.5 and -1 or 1
  local legWeight=(1-body)*smooth(.1,.3,math.abs(u-.5))
  vertices[#vertices+1]={u*w,v*h,(qx+u*w)/iw,(qy+v*h)/ih,1,1,1,1}
  rig[#rig+1]={x=u*w,y=v*h,weight=legWeight,side=side,offset=v*math.pi*2+(side>0 and math.pi or 0)}
 end end
 for y=0,rows-1 do for x=0,cols-1 do
  local a=y*(cols+1)+x+1;local b=a+1;local c=a+cols+1;local d=c+1
  map[#map+1]=a;map[#map+1]=b;map[#map+1]=c;map[#map+1]=b;map[#map+1]=d;map[#map+1]=c
 end end
 local mesh=love.graphics.newMesh(vertices,'triangles','dynamic');mesh:setVertexMap(map);mesh:setTexture(img)
 return {mesh=mesh,rig=rig,vertices=vertices,w=w,h=h}
end
local function pose(img,dir,p,bounds)
 if not p.walkMoving or p.reset==true or p.falling or p.abyssHeld or p.abyssSpit or p.abyssKnock or p.whirl or p.skyWhirl or p.throw or p.skyThrow or p.tunnelTravel then return false end
 local poses=W.meshes[img]
 if not poses then poses={};W.meshes[img]=poses end
 local cached=poses[dir]
 if not cached then cached=build(img,dir,bounds);cached.image=img;poses[dir]=cached end
 local phase=p.walkPhase or 0
 local amplitude=(p==player or p.sanctuaryPlayer) and 1.55 or 1
 -- Several display frames may share one 60 Hz simulation pose.
 -- Reuse that mesh, and batch changed vertices into a single upload.
 if cached.phase~=phase or cached.amplitude~=amplitude then
  for i,r in ipairs(cached.rig) do
   local stride=math.sin(phase+r.offset);local lift=math.max(0,math.cos(phase+r.offset))
   local v=cached.vertices[i]
   v[1]=r.x+(stride*r.side*.043)*cached.w*r.weight*amplitude
   v[2]=r.y+(stride*.031-lift*.024)*cached.h*r.weight*amplitude
  end
  cached.mesh:setVertices(cached.vertices)
  cached.phase=phase;cached.amplitude=amplitude
 end
 return cached
end
function W.draw(img,dir,x,y,width,p,bounds)
 local cached=pose(img,dir,p,bounds);if not cached then return false end
 local phase=p.walkPhase or 0
 local scale=width/cached.w;local bob=math.cos(phase*2)*.55*width/62
 love.graphics.draw(cached.mesh,x,y+bob,math.sin(phase)*.012,scale,scale,cached.w/2,cached.h/2)
 return true
end
-- Map a source-image landmark through the same triangles used by the walk rig.
function W.point(img,dir,x,y,width,p,bounds,sx,sy)
 local qx,qy,w,h=bounds:getViewport();local px,py=sx-qx,sy-qy
 local cached=pose(img,dir,p,bounds)
 if cached then
  local u,v=math.max(0,math.min(20,px/w*20)),math.max(0,math.min(20,py/h*20))
  local col,row=math.min(19,math.floor(u)),math.min(19,math.floor(v));u=u-col;v=v-row
  local a=row*21+col+1;local b,c,d=a+1,a+21,a+22
  local vertices=cached.vertices
  local function sample(k)
   if u+v<=1 then return vertices[a][k]*(1-u-v)+vertices[b][k]*u+vertices[c][k]*v end
   return vertices[b][k]*(1-v)+vertices[c][k]*(1-u)+vertices[d][k]*(u+v-1)
  end
  px,py=sample(1),sample(2)
 end
 local scale=width/w;px=(px-w/2)*scale;py=(py-h/2)*scale
 local phase=p.walkPhase or 0;local turn=cached and math.sin(phase)*.012 or 0
 local bob=cached and math.cos(phase*2)*.55*width/62 or 0
 return x+px*math.cos(turn)-py*math.sin(turn),y+px*math.sin(turn)+py*math.cos(turn)+bob
end
return W
