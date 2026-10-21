-- The visible cloud shelf follows exactly the same contour as edge falls.
local V={}
function V.edgeField(width)
 local g=love.graphics
 if not V.field or V.width~=width then
  if V.field then V.field.image:release() end
  local step=2;local iw,ih=math.ceil(width/step),300
  local data=love.image.newImageData(iw,ih);local sky=require('sky')
  for y=0,ih-1 do for x=0,iw-1 do
   local px,py=(x+.5)*step,(y+.5)*step
   local d=math.max(sky.edgeDepth(py,3)-px,px-width+sky.edgeDepth(py,4),sky.edgeDepth(px,1)-py,py-600+sky.edgeDepth(px,2))
   data:setPixel(x,y,math.max(0,math.min(1,.5+d/128)),0,0,1)
  end end
  local image=g.newImage(data);data:release();image:setFilter('linear','linear')
  V.field={image=image,x=0,y=0,w=iw*step,h=600,step=step};V.width=width
 end
 return V.field
end
function V.draw(width,zones)
 local surface=require('terrain_surface');local edge=V.edgeField(width)
 local field=surface.field(zones or {},'hole');local g=love.graphics
 if not field then surface.drawSkyField(edge,1);return end
 local key=width..':'..field.key
 if V.key~=key then
  if not V.mask or V.mask:getWidth()~=math.ceil(width) then
   if V.mask then V.mask:release() end
   V.mask=g.newCanvas(math.ceil(width),600,{dpiscale=1})
  end
  g.push('all');g.setCanvas(V.mask);g.origin();g.setScissor();g.setShader();g.clear(0,0,0,1)
  g.setBlendMode('lighten','premultiplied');g.setColor(1,1,1)
  g.draw(edge.image,0,0,0,edge.step,edge.step)
  g.draw(field.image,field.x,field.y,0,field.step,field.step);g.pop()
  require('hole_union_distance').build(V.mask,V);V.key=key
 end
 surface.drawSkyField({image=V.distanceResult,x=0,y=0,w=math.ceil(width),h=600,step=1},1)
end
return V
