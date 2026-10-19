-- Animate the cached lava preview at a limited rate without rebuilding geometry.
local E={builds=0,renders=0}
function E.draw(zones,biome,time)
 local S=require('terrain_surface');local field=S.field(zones,'lava');if not field then return end
 local g=love.graphics
 if E.field~=field or E.biome~=biome then
  if E.canvas then E.canvas:release() end
  E.canvas=g.newCanvas(math.ceil(field.w),math.ceil(field.h),{dpiscale=1})
  E.field=field;E.biome=biome;E.builds=E.builds+1;E.tick=nil
 end
 local rate=love.window.hasFocus() and 12 or 2
 local tick=math.floor((time or 0)*rate)
 if E.tick~=tick or E.rate~=rate then
  E.tick=tick;E.rate=rate;E.renders=E.renders+1
  g.push('all');g.setCanvas(E.canvas);g.origin();g.setScissor();g.clear();g.translate(-field.x,-field.y)
  S.draw(zones,'lava',tick/rate,1,biome);g.pop()
 end
 g.push('all');g.setShader();g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(E.canvas,field.x,field.y);g.pop()
end
return E
