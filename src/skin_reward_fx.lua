-- Deterministic cosmetic orbit; no gameplay RNG, emitters or per-frame uploads.
local F={}
function F.rays(x,y,size)
 if not Graphics.effects or size<20 then return end
 local g=love.graphics;local _,_,_,alpha=g.getColor()
 if alpha<.95 then return end -- Dash afterimages never multiply the light.
 F.rayShader=F.rayShader or g.newShader('assets/shaders/skin_rays.glsl')
 local radius=size*(App.state=='menu' and .95 or App.state=='playing' and 1.44 or 1.25)
 g.push('all');g.setBlendMode('add');g.setShader(F.rayShader)
 F.rayShader:send('clock',UI.clock);g.setColor(1,1,1,alpha)
 g.draw(UI.pixel,x-radius,y-radius,0,radius*2,radius*2)
 g.pop()
end
function F.orbit(x,y,size,front,locked)
 if locked or not Graphics.effects or size<20 then return end
 local g=love.graphics;local _,_,_,alpha=g.getColor()
 local time=UI.clock;local compact=size<40
 local count=compact and 5 or Graphics.quality==1 and 5 or 8
 g.push('all');g.setShader();g.setBlendMode('alpha')
 for i=1,count do
  local angle=time*1.5+i*math.pi*2/count
  local depth=math.sin(angle)
  if (depth>=0)==front then
   local px=x+math.cos(angle)*size*.53
   local py=y+depth*size*.29+math.sin(time*2+i)*size*.025
   local radius=(compact and size*.055 or math.max(3.2,size*.036))*(.75+.25*depth)*(App.state=='playing' and 1.15 or 1)
   local brightness=.88+.12*(.5+.5*math.sin(time*3+i*2))
   g.push();g.translate(px,py);g.rotate(time*.45+i)
   if not F.star then
    local points={}
    for j=0,7 do
     local a=-math.pi/2+j*math.pi/4
     local r=j%2==0 and (j%4==0 and 1.65 or 1) or .28
     points[#points+1]=math.cos(a)*r;points[#points+1]=math.sin(a)*r
    end
    F.star=love.math.triangulate(points)
   end
   g.push();g.scale(radius*1.8);g.setColor(1,.79,.35,alpha*.20*brightness)
   for _,triangle in ipairs(F.star) do g.polygon('fill',triangle) end;g.pop()
   g.push();g.scale(radius);g.setColor(1,.9,.53,alpha*brightness)
   for _,triangle in ipairs(F.star) do g.polygon('fill',triangle) end;g.pop()
   g.setColor(1,1,.91,alpha*brightness)
   g.polygon('fill',0,-radius*.65,radius*.22,0,0,radius*.65,-radius*.22,0)
   g.pop()
  end
 end
 g.pop()
end
return F
