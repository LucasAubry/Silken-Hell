-- Decorative storm rendering: no random draws or simulation mutations.
local A={}
local tau=math.pi*2
function A.warning(p,time,texture)
 local g=love.graphics;local charge=math.min(1,p.age/p.delay)
 A.warningShader=A.warningShader or g.newShader('assets/shaders/sky_warning.glsl')
 g.setShader(A.warningShader);A.warningShader:send('clock',time);A.warningShader:send('charge',charge)
 A.warningShader:send('drift',{p.seed*.73,p.seed*.31});g.setColor(1,1,1)
 g.draw(texture,p.x-72,p.y-65,0,144,130);g.setShader()
 for i=1,28 do
  local a=i*tau/28+p.seed*.7;local life=(time*(.65+charge)+i*.37)%1
  local radius=40+math.sin(a*5+p.seed)*5+life*13
  local x,y=p.x+math.cos(a)*radius,p.y+math.sin(a)*radius*.9-life*9
  local alpha=(.3+charge*.65)*(1-life)
  g.setColor(.47,.75,1,alpha);g.rectangle('fill',math.floor(x),math.floor(y),2,2)
  if charge>.65 and i%4==0 then
   g.setColor(.76,.9,1,alpha);g.setLineWidth(1)
   g.line(x,y,x-3,y-4,x+1,y-7)
  end
 end
end
return A
