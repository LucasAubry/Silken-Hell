local A={}
function A.draw(time)
 if not require('sky').openEdges() then return end
 local g=love.graphics;local width=Arena.width
 g.push('all');g.setShader();g.setLineWidth(1)
 -- Stable decorative seeds never consume the simulation's random stream.
 for i=1,105 do
  local x=(i*137.31+time*(5+i%6))%width
  local y=(i*79.73-time*(2+i%4)+math.sin(time*.4+i)*9)%600
  local pulse=.5+.5*math.sin(time*1.3+i*2.4);local r=.6+i%3*.45
  g.setColor(.7,.87,1,.025+pulse*.035);g.circle('fill',x,y,r*4)
  g.setColor(.85,.95,1,.16+pulse*.3);g.circle('fill',x,y,r)
 end
 -- A light curtain of fine rain, kept separate from dangerous lightning.
 for i=1,72 do
  local x=(i*173.9-time*34)%width;local y=(i*97.7+time*(180+i%5*17))%600
  g.setColor(.65,.81,.95,.08+(i%4)*.018);g.line(x,y,x-2,y+6+i%5)
 end
 for i=1,18 do
  local x=(i*191+time*13)%width;local y=(i*61+math.sin(time*.7+i)*11)%600
  g.setColor(.84,.93,1,.12);g.line(x-6,y+2,x,y,x+10,y+1)
 end
 g.pop()
end
return A
