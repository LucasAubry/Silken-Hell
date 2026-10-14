-- The editor and the arena share the same brush geometry and molten material.
local L={}
function L.draw(zone,time,alpha)
 local g=love.graphics;local H=require('ground_holes');alpha=alpha or 1
 g.push('all');g.setShader()
 g.setColor(.14,.025,.015,alpha);H.draw(zone,1.12)
 g.setColor(1,.38,.035,alpha);H.draw(zone,1.04)
 L.shader=L.shader or g.newShader('assets/shaders/lava_zone.glsl')
 local x,y=g.transformPoint(0,0);local xx,yy=g.transformPoint(1,1)
 L.shader:send('origin',{x,y});L.shader:send('scale',{xx-x,yy-y});L.shader:send('clock',time or 0)
 g.setShader(L.shader);g.setColor(1,1,1,alpha);H.draw(zone)
 g.pop()
end
return L
