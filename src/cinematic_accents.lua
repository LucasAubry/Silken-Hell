-- Deterministic impact effects; never advance combat or consume its random stream.
local A={}
function A.shake(t,event,strength,duration)
 local age=t-event;duration=duration or .55
 if age<0 or age>=duration then return 0,0 end
 local power=strength*(1-age/duration)^2
 return math.sin(age*93+1)*power,math.sin(age*117+.4)*power*.7
end
function A.silk(x,y,age)
 if age<0 or age>1.2 then return end
 local g=love.graphics;g.push('all');g.setShader();g.setLineWidth(1.2)
 for i=1,18 do
  local a=i*2.399;local speed=30+i%5*13
  local px,py=x+math.cos(a)*speed*age,y+math.sin(a)*speed*age+35*age*age
  g.setColor(.67,.67,.49,(1-age/1.2)*.7)
  g.line(px,py,px+math.cos(a+age*3)*7,py+math.sin(a+age*3)*7)
 end
 g.pop()
end
return A
