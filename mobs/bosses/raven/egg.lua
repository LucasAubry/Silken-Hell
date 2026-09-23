-- Generated transparent shell with progressive cracks overlaid in game.
local E={}
function E.draw(x,y,size,cracks,angle)
 local g=love.graphics
 if not Art.images.merle_egg then Art.add('merle_egg','assets/sprites/merle_egg.png') end
 g.push('all');g.translate(x,y);g.rotate(angle or 0);g.scale(size/16)
 g.setColor(1,1,1);Art.draw('merle_egg',0,0,22,0,32)
 if (cracks or 0)>0 then
  local path={0,-15.7,-1.6,-12,1.1,-8.5,-1.4,-5,1.8,-1.8,-.7,2,2.2,5.5,-.8,9,1.1,12.5,0,15.7}
  local count=math.min(10,math.max(2,math.ceil(cracks)+1))
  local points={};for i=1,count*2 do points[i]=path[i] end
  g.setLineWidth(.85);g.setColor(.12,.18,.24);g.line(unpack(points))
  g.setLineWidth(.23);g.setColor(.83,.87,.90);g.push();g.translate(.45,0);g.line(unpack(points));g.pop()
  if cracks>=4 then g.setColor(.16,.23,.3);g.setLineWidth(.4);g.line(-1.4,-5,-4,-6.5,-5,-9) end
  if cracks>=7 then g.line(2.2,5.5,5,4.5,6,1.5) end
 end
 g.pop()
end
return E
