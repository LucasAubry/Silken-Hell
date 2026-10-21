-- Small storm snails have a faceted golden shell, a blue body and luminous horns.
local A={}
function A.draw(p,time)
 local g=love.graphics;local glow=p.phase=='strike' and 1 or p.phase~='tethered' and math.min(1,p.age*3) or 0
 g.push('all');g.translate(p.x,p.y-(p.lift or 0));g.rotate(p.angle or 0)
 if p.phase=='strike' then
  g.setColor(.6,.86,1,.5);g.setLineWidth(3);g.line(-10,0,-42,0)
  g.setColor(1,.93,.66,.8);g.setLineWidth(1);g.line(-8,-3,-30,-5);g.line(-8,3,-30,5)
 end
 if glow>0 then
  for i=4,1,-1 do g.setColor(.55,.85,1,glow*.06);g.circle('fill',0,0,15+i*5)end
 end
 g.setColor(.025,.065,.13);g.ellipse('fill',0,5,17,6)
 g.setColor(.24,.54,.69);g.ellipse('fill',1,3,15,5);g.circle('fill',12,0,5)
 g.setLineWidth(1.8);g.setColor(.57,.85,.94);g.line(12,-2,15,-9);g.line(15,0,20,-5)
 g.setColor(1,.9,.44);g.circle('fill',15,-9,2);g.circle('fill',20,-5,2)
 g.setColor(.13,.11,.12);g.polygon('fill',-14,-5,-8,-14,2,-16,11,-8,9,3,-3,8,-14,3)
 g.setColor(.72,.46,.16);g.polygon('fill',-12,-5,-7,-12,2,-14,9,-7,7,2,-3,6,-12,2)
 g.setColor(.98,.77,.34);g.polygon('fill',-7,-12,2,-14,9,-7,-1,-3)
 g.setColor(.38,.23,.14);g.polygon('fill',-12,-5,-1,-3,-3,6,-12,2)
 g.setLineWidth(1.5);g.setColor(.95,.91,.68);local points={}
 for i=0,24 do local a=i*.29;local r=8-i*.26;points[#points+1]=-2+math.cos(a)*r;points[#points+1]=-3+math.sin(a)*r end
 g.line(points)
 if glow>0 then g.setColor(.88,.97,1,glow*(.35+.2*math.sin(time*18)));g.circle('fill',-2,-3,9)end
 g.pop()
end
return A
