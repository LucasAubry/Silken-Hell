-- Separate painted mantle; the articulated vector arms keep their gameplay reach.
local H={}
function H.draw(a,x,y,angle,scale,flash)
 if not Art.images.octopus_mantle then Art.add('octopus_mantle','assets/monstres/ocean/poulpe/mantle.png') end
 local qx,qy,qw,qh=a.quad:getViewport()
 local g=love.graphics;g.push('all');g.translate(x,y);g.rotate(angle);g.setColor(1,1-flash,1-flash)
 Art.draw('octopus_mantle',(624.5-qx-qw/2)*scale,(599-qy-qh/2)*scale,373*scale,0,522*scale)
 g.pop()
end
return H
