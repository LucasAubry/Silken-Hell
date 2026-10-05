-- Emissive halos are presentation only: no particles allocated, no gameplay RNG.
-- Called beneath each visible creature, before darkness and existing attack tells.
local F={enabled=true}
local colors={
 ange={.85,.72,1},snake={.28,1,.73},scie={1,.52,.24},piege={1,.46,.19},
 imp={1,.22,.07},fish={.18,.81,1},jelly={.5,.45,1},worm={.96,.55,.23},
 mole={.93,.67,.32},gull={.58,.82,1},lanternfish={.24,.9,1},
}
function F.halo(x,y,size,color,seed)
 if not F.enabled or not Graphics.effects then return end
 local g=love.graphics;local t=(UI and UI.clock or 0)+(seed or x*.017+y*.013)
 local p=color or require('prism_palette').get()[1]
 local r=size*(.52+.025*math.sin(t*2.4))
 local low=Graphics.quality==1;local layers=low and 4 or 8
 g.push('all');g.setShader();g.setBlendMode('add','alphamultiply')
 for i=layers,1,-1 do
  local q=i/layers
  g.setColor(p[1],p[2],p[3],(.19/layers)*(1-q*.6))
  g.circle('fill',x,y,r*(.55+q*.8),low and 20 or 32)
 end
 -- Incomplete, counter-rotating arcs leave the silhouette and attack cues clear.
 for i=1,2 do
  local a=t*(i==1 and .45 or -.32)+i*math.pi
  g.setLineWidth(i==1 and 1.3 or .7)
  g.setColor(p[1],p[2],p[3],.34+.08*math.sin(t*1.7+i))
  g.arc('line','open',x,y,r*(.94+i*.10),a,a+.85,low and 8 or 16)
 end
 for i=1,low and 2 or 4 do
  local phase=(t*.23+i*.237)%1;local a=i*2.399+t*.28
  local d=r*(.86+phase*.45);local px,py=x+math.cos(a)*d,y+math.sin(a)*d-phase*6
  local alpha=math.sin(phase*math.pi)*.68
  g.setColor(p[1],p[2],p[3],alpha*.12);g.circle('fill',px,py,4)
  g.setColor(.35+p[1]*.65,.35+p[2]*.65,.35+p[3]*.65,alpha)
  g.setLineWidth(1);g.line(px-2,py,px+2,py);g.line(px,py-2,px,py+2)
 end
 g.pop()
end
function F.mob(m)
 if m.dead or m.abyssHeld or m.tunnelTravel or Realms.underground(m) then return end
 local h=m.hitBox or {};local size=math.min(88,math.max(34,h.w or 40,h.h or 40))
 local x,y=m.tipX or m.x,m.tipY or m.y
 F.halo(x,y,size,colors[m.type])
end
return F
