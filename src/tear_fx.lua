-- A shared breath and small motes for every collectible tear, without simulation RNG.
local F={}
function F.breath(time) return 1+.04*math.sin(time*2.6),1+.065*math.sin(time*2.6) end
function F.draw(x,y,color,time)
 if Graphics and not Graphics.effects then return end
 local g=love.graphics;g.push('all');g.setShader();g.setBlendMode('add')
 for i=1,(Graphics.quality==1 and 7 or 12) do
  local age=(time*.35+i*.137)%1;local a=i*2.399+time*.38
  local radius=12+age*12;local xx=x+math.cos(a)*radius;local yy=y+math.sin(a)*radius*.55-age*18
  local alpha=math.sin(age*math.pi)*.7
  g.setColor(color[1],color[2],color[3],alpha*.13);g.circle('fill',xx,yy,3.2)
  g.setColor(.35+color[1]*.65,.35+color[2]*.65,.35+color[3]*.65,alpha)
  g.circle('fill',xx,yy,.7+(1-age)*.6)
 end
 g.pop()
end
return F
