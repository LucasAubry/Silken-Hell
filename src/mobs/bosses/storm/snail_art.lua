-- Captives use the exact same sprite set, scale and facing as biome snails.
local A={}
function A.draw(p,time)
 local g=love.graphics;g.push('all');g.setShader()
 local x,y=p.x,p.y-(p.lift or 0)
 if p.phase=='strike' then
  local dx,dy=math.cos(p.angle or 0),math.sin(p.angle or 0)
  g.setColor(.6,.86,1,.5);g.setLineWidth(3);g.line(x-dx*15,y-dy*15,x-dx*42,y-dy*42)
 end
 if p.phase~='tethered' then
  local glow=math.min(1,p.age*3)
  for i=4,1,-1 do g.setColor(.55,.85,1,glow*.06);g.circle('fill',x,y,15+i*5)end
 end
 require('cloud_snail_art').draw(x,y,require('cloud_snail').size,time,p.angle)
 g.pop()
end
return A
