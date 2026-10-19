-- Bend the continuous rim around a readable opening; never crop plant pixels.
local D={}
local function smooth(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function D.offset(x,y,spotX,spotY,side,half)
 local horizontal=side=='top' or side=='bottom'
 local along=math.abs(horizontal and x-spotX or y-spotY)
 local inward=side=='top' and y or side=='bottom' and 600-y or side=='left' and x or Arena.width-x
 local strength=(1-smooth((along-half-8)/70))*(1-smooth((inward-105)/70))
 local reach=Campaign.biome==3 and 112 or 80
 local shift=reach*strength
 return side=='left' and x-shift or side=='right' and x+shift or x,
  side=='top' and y-shift or side=='bottom' and y+shift or y
end
function D.draw(draw,x,y,side,half)
 local g=love.graphics;local target=g.getCanvas();local density=target and target:getDPIScale() or 1
 local key=table.concat({Arena.width,density,Campaign.biome,x,y,side,half},':')
 if D.key~=key then
  if D.canvas then D.canvas:release();D.mesh:release() end
  D.canvas=g.newCanvas(Arena.width,600,{dpiscale=density});D.canvas:setFilter('linear','linear')
  local vertices,indices={},{};local cols,rows=math.ceil(Arena.width/10),60
  for row=0,rows do for col=0,cols do
   local u,v=col/cols,row/rows;local px,py=D.offset(u*Arena.width,v*600,x,y,side,half)
   vertices[#vertices+1]={px,py,u,v,1,1,1,1}
  end end
  for row=0,rows-1 do for col=0,cols-1 do
   local a=row*(cols+1)+col+1;local b=a+1;local c=a+cols+1;local d=c+1
   for _,i in ipairs({a,b,c,b,d,c}) do indices[#indices+1]=i end
  end end
  D.mesh=g.newMesh(vertices,'triangles','static');D.mesh:setVertexMap(indices);D.mesh:setTexture(D.canvas);D.key=key
 end
 g.push('all');g.setCanvas(D.canvas);g.origin();g.setScissor();g.clear(0,0,0,0)
 draw();g.pop()
 g.push('all');g.setShader();g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied');g.draw(D.mesh);g.pop()
end
return D
