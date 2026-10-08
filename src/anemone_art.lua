-- Deform the tentacles of the existing PNG; the lower bulb stays anchored.
local A={}
local N=20
local tips={{.038,.48},{.194,.193},{.556,.035},{.754,.177},{.963,.502}}
function A.point(u,v,x,y,width,height,time)
 local phase=time*1.8+x*.013+y*.009
 local reach=math.max(0,(.72-v)/.72)
 local bend=reach*reach*(3-2*reach)
 return x+(u-.5+math.sin(phase+u*8-v*3)*.045*bend)*width,
  y+(v-.5+math.sin(phase*.83+u*11+v*4)*.018*bend)*height
end
function A.electric(x,y,width,height,time)
 local g=love.graphics;g.push('all');g.setBlendMode('add')
 local phase=time*1.8+x*.013+y*.009
 local frame=math.floor(time*12+x*.1+y*.07)
 local points={}
 for i,t in ipairs(tips)do
  local px,py=A.point(t[1],t[2],x,y,width,height,time);points[i]={px,py}
  local pulse=.65+.25*math.sin(phase*3+i*2)
  g.setColor(.12,.6,1,.09*pulse);g.circle('fill',px,py,5)
  g.setColor(.5,.9,1,.8*pulse);g.circle('fill',px,py,1.1)
 end
 local function arc(ax,ay,bx,by,seed)
  local line={ax,ay};local dx,dy=bx-ax,by-ay;local d=math.max(1,math.sqrt(dx*dx+dy*dy))
  for j=1,4 do
   local offset=math.sin(frame*8.7+seed*11+j*17)*2.2
   line[#line+1]=ax+dx*j/5-dy/d*offset;line[#line+1]=ay+dy*j/5+dx/d*offset
  end
  line[#line+1]=bx;line[#line+1]=by
  g.setColor(.12,.55,1,.18);g.setLineWidth(3);g.line(line)
  g.setColor(.65,.94,1,.9);g.setLineWidth(.8);g.line(line)
 end
 -- Short intermittent arcs stay on the crown: no misleading ranged attack.
 for i,p in ipairs(points)do
  if (frame+i*3)%9<3 then
   local angle=phase+i*2.4;local length=4+(i%3)*2
   arc(p[1],p[2],p[1]+math.cos(angle)*length,p[2]+math.sin(angle)*length,i)
  end
 end
 if frame%11<2 then
  local i=1+math.floor(frame/11)%4;local a,b=points[i],points[i+1]
  arc(a[1],a[2],b[1],b[2],i+6)
 end
 g.pop()
end
function A.draw(sprite,x,y,width,height,time)
 local g=love.graphics
 if not sprite.anemoneMesh then
  local qx,qy,qw,qh=sprite.quad:getViewport()
  local iw,ih=sprite.image:getDimensions()
  local vertices,indices={},{}
  for j=0,N do for i=0,N do
   local u,v=i/N,j/N
   vertices[#vertices+1]={(u-.5)*sprite.w,(v-.5)*sprite.h,(qx+u*qw)/iw,(qy+v*qh)/ih,1,1,1,1}
  end end
  for j=0,N-1 do for i=0,N-1 do
   local a=j*(N+1)+i+1;local b=a+1;local c=a+N+1;local d=c+1
   for _,index in ipairs({a,b,c,b,d,c})do indices[#indices+1]=index end
  end end
  sprite.anemoneVertices=vertices
  sprite.anemoneMesh=g.newMesh(vertices,'triangles','stream')
  sprite.anemoneMesh:setVertexMap(indices);sprite.anemoneMesh:setTexture(sprite.image)
 end
 for j=0,N do for i=0,N do
  local px,py=A.point(i/N,j/N,x,y,width,height,time)
  local vertex=sprite.anemoneVertices[j*(N+1)+i+1]
  vertex[1]=(px-x)*sprite.w/width;vertex[2]=(py-y)*sprite.h/height
 end end
 sprite.anemoneMesh:setVertices(sprite.anemoneVertices)
 g.draw(sprite.anemoneMesh,x,y,0,width/sprite.w,height/sprite.h)
end
return A
