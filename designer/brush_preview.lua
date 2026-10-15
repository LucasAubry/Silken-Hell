-- While the pointer moves, draw only the brush footprint. Flood filling and
-- baking the joined terrain material are deferred until the gesture ends.
local P={}
function P.draw(e)
 local g=love.graphics;local rx,ry=e.rx or e.radius or 28,e.ry or e.radius or 28
 g.push('all');g.setShader();g.translate(e.x,e.y);g.scale(rx,ry)
 if e.kind=='lava' then g.setColor(1,.29,.025) else g.setColor(.025,.04,.08) end
 local points={}
 for i=1,#e.points,2 do points[i]=e.points[i]/rx;points[i+1]=e.points[i+1]/ry end
 g.setLineWidth(2);g.setLineStyle('rough');g.setLineJoin('none')
 if #points>=4 then g.line(points) end
 for i=1,#points,2 do g.circle('fill',points[i],points[i+1],1,20) end
 -- A moved, completed stroke keeps its already computed enclosed pockets.
 local geometry=require('ground_holes').cache[e]
 if geometry then
  for _,rect in ipairs(geometry.fill) do g.rectangle('fill',rect[1]/rx,rect[2]/ry,rect[3]/rx,rect[4]/ry) end
 end
 g.pop()
end
return P
