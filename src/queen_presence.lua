local Q={}
function Q.land(f)
 f.landed={x=f.x,y=f.y,at=f.clock}
end
function Q.ground(f)
 local g=love.graphics;g.push('all');g.setShader()
 local height=f.jumpHeight or 0
 -- A planted shadow expands and softens as she rises.
 if height<=0 then Art.contactShadow(f.x,f.y+13,28,11,.32) end
 local landing=f.landed
 if landing and (not Graphics or Graphics.effects) then
  local t=(f.clock-landing.at)/.7
  if t>=0 and t<1 then
   for i=1,16 do
    local a=i*2.39996;local r=9+t*(25+i%4*5)
    local x=landing.x+math.cos(a)*r;local y=landing.y+math.sin(a)*r*.5-math.sin(t*math.pi)*10
    g.setColor(.69,.60,.45,(1-t)*.4);g.circle('fill',x,y,1.4+i%3*.5)
   end

  end
 end
 g.pop()
end
return Q
