-- Deterministic cosmetic orbit; no gameplay RNG, emitters or per-frame uploads.
local F={}
function F.orbit(x,y,size,front,locked)
 if locked or not Graphics.effects or size<40 then return end
 local g=love.graphics;local _,_,_,alpha=g.getColor()
 local time=UI.clock;local count=Graphics.quality==1 and 5 or 8
 g.push('all');g.setShader();g.setBlendMode('alpha')
 for i=1,count do
  local angle=time*1.5+i*math.pi*2/count
  local depth=math.sin(angle)
  if (depth>=0)==front then
   local px=x+math.cos(angle)*size*.53
   local py=y+depth*size*.29+math.sin(time*2+i)*size*.025
   local radius=math.max(1.1,size*.019)*(.75+.25*depth)
   local brightness=.6+.4*(.5+.5*math.sin(time*3+i*2))
   g.setColor(1,.64,.10,alpha*.12*brightness);g.circle('fill',px,py,radius*2.6)
   g.setColor(1,.82,.28,alpha*.85*brightness);g.circle('fill',px,py,radius)
   if i%3==0 then
    g.setLineWidth(math.max(.6,size*.003))
    g.setColor(1,.96,.7,alpha*.8*brightness)
    g.line(px-radius*2,py,px+radius*2,py);g.line(px,py-radius*2,px,py+radius*2)
   end
  end
 end
 g.pop()
end
return F
