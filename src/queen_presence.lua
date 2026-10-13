local Q={}
function Q.land(f)
 f.landed={x=f.x,y=f.y,at=f.clock}
end
function Q.ground(f)
 local g=love.graphics;g.push('all');g.setShader()
 local height=f.jumpHeight or 0
 -- A planted shadow expands and softens as she rises.
 Art.contactShadow(f.x,f.y+13,28+height*.06,11+height*.025,height>0 and .27 or .48)
 local landing=f.landed
 if landing and (not Graphics or Graphics.effects) then
  local t=(f.clock-landing.at)/.7
  if t>=0 and t<1 then
   for i=1,16 do
    local a=i*2.39996;local r=9+t*(25+i%4*5)
    local x=landing.x+math.cos(a)*r;local y=landing.y+math.sin(a)*r*.5-math.sin(t*math.pi)*10
    g.setColor(.69,.60,.45,(1-t)*.4);g.circle('fill',x,y,1.4+i%3*.5)
   end
   g.setLineWidth(1);g.setColor(.85,.80,.67,(1-t)*.22)
   g.ellipse('line',landing.x,landing.y+12,22+t*35,7+t*13)
  end
 end
 g.pop()
end
return Q
