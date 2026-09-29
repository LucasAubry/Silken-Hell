-- Small cages assembled from bowed ribs and knuckled bone bars.
local C={}
local function bone(points)
 local g=love.graphics
 g.setColor(.11,.105,.08);g.setLineWidth(6);g.line(points)
 g.setColor(.58,.57,.44);g.setLineWidth(3.5);g.line(points)
 g.setColor(.82,.80,.63);g.setLineWidth(1.2);g.line(points)
 for _,i in ipairs({1,#points-1}) do
  local x,y=points[i],points[i+1]
  g.setColor(.65,.64,.49);g.circle('fill',x-1,y,2.7);g.circle('fill',x+1.6,y+.5,2.2)
 end
end
function C.draw(p,time)
 local g=love.graphics;g.push('all');g.setBlendMode('alpha');g.translate(p.x,p.y)
 local power=p.light or 0
 g.setColor(.005,.012,.021,.8);g.ellipse('fill',0,18,32,12)
 if power>0 then
  local intensity=math.min(1,power)
  -- All light layers stay between the ribs: a bright captive core, not a wide halo.
  for r=5,1,-1 do
   g.setColor(.07,.43,.85,intensity*(.12+.025*(5-r)))
   g.ellipse('fill',0,-2,5+r*2.5,7+r*3)
  end
  for i=1,3 do
   local amount=math.max(0,math.min(1,power-i+1))
   local a=time*(1+i*.12)+i*2.1
   local x,y=math.cos(a)*(i==1 and 3 or 9),-3+math.sin(a)*10
   g.setColor(.16,.69,1,amount*.9);g.circle('fill',x,y,5)
   g.setColor(.72,.96,1,amount);g.circle('fill',x,y,2.7)
   g.setColor(1,1,1,amount*.9);g.circle('fill',x-.6,y-.8,1.1)
  end
 end
 bone({-27,14,-24,-8,-13,-27,0,-33,13,-27,24,-8,27,14})
 for _,x in ipairs(p.locked and {-14,0,14} or {-20,20}) do
  bone({x,21,x*.85,5,x*.7,-15,x*.5,-30})
 end
 bone({-27,14,-18,23,0,26,18,23,27,14})
 if p.locked then bone({-25,2,-12,7,0,9,12,7,25,2}) end
 g.pop()
end
return C
