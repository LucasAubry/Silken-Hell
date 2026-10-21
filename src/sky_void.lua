-- The visible cloud shelf follows exactly the same contour as edge falls.
local V={}
function V.draw(width)
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
 require('terrain_surface').drawSkyField(V.field,1)
end
return V
