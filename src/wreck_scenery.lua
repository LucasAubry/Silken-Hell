-- A cutaway wooden wreck, anchored in world space while the camera swims through it.
local W={right=1.07}
function W.draw(w,h,camera,t,front)
 local g=love.graphics;local decor=require('transition_scenery')
 g.push('all');g.translate(-camera*w,0);g.scale(w,h)
 if not front then
  decor.material(true)
  g.setColor(.10,.17,.16);g.polygon('fill',.06,.53,.14,.25,.81,.21,.96,.29,1.04,.39,.99,.71,.82,.79,.28,.77,.13,.67)
  -- The intact cabin lies behind the open hull, including its continuous deck.
  for i=0,10 do
   local y=.29+i*.039
   g.setColor(.14+i%3*.014,.20+i%2*.018,.17+i%3*.008)
   g.polygon('fill',.17,y,.93,y-.025,.97,y+.007,.18,y+.032)
  end
  g.setColor(.07,.12,.11);g.polygon('fill',.12,.63,.97,.63,1.07,.69,.94,.73,.26,.73,.14,.67)
  for i=0,10 do
   local x=.19+i*.069
   g.setColor(.19,.23,.17);g.polygon('fill',x,.636,x+.051,.635,x+.075,.685,x+.015,.69)
  end
  g.setShader()
  for _,x in ipairs({.31,.73}) do
   g.setColor(.025,.055,.067);g.ellipse('fill',x,.43,.046,.078)
   g.setColor(.035,.14,.18);g.ellipse('fill',x,.43,.037,.063)
   g.setLineWidth(3/w);g.setColor(.30,.29,.17);g.ellipse('line',x,.43,.043,.073)
   g.setColor(.14,.23,.22);g.ellipse('line',x,.43,.047,.079)
   for j=0,7 do local a=j*math.pi/4;g.setColor(.43,.39,.22);g.ellipse('fill',x+math.cos(a)*.043,.43+math.sin(a)*.073,.0018,.003) end
   g.setColor(.12,.32,.34,.35);g.polygon('fill',x-.022,.39,x-.008,.37,x+.028,.46,x+.013,.48)
  end
  -- The lantern's empty hook remains after the spider lifts the lamp away.
  g.setColor(.28,.31,.24);g.setLineWidth(2/w);g.line(.54,.28,.54,.335)
  g.arc('line','open',.54,.338,.006,0,math.pi*1.65)
 else
  decor.material(true)
  -- A snapped mast and slack rigging identify the wreck before entering the cabin.
  g.setColor(.105,.16,.13)
  g.polygon('fill',.42,.25,.33,.035,.35,.064,.351,.025,.375,.08,.45,.25)
  g.setColor(.25,.28,.18);g.polygon('fill',.33,.035,.35,.064,.351,.025,.356,.075)
  g.setShader();g.setColor(.24,.30,.23,.85);g.setLineWidth(1.7/w)
  g.line(.35,.08,.27,.17,.15,.29);g.line(.35,.08,.51,.19,.66,.235)
  g.setColor(.15,.22,.19,.8)
  g.polygon('fill',.38,.10,.53,.19,.48,.18,.47,.21,.43,.18,.41,.195)
  decor.material(true)
  -- Heavy ribs, a broken roof and splintered edges frame both real openings.
  g.setColor(.08,.12,.10)
  g.polygon('fill',.10,.29,.22,.24,.87,.20,.98,.27,.96,.31,.86,.275,.23,.30,.14,.37)
  g.polygon('fill',.07,.49,.13,.32,.17,.30,.15,.43,.13,.48,.15,.51,.13,.56,.14,.63,.20,.69,.18,.73,.11,.66)
  for _,x in ipairs({.20,.84}) do
   g.setColor(.105,.155,.12);g.polygon('fill',x,.28,x+.025,.277,x+.015,.38,x+.02,.64,x-.008,.65,x-.016,.40)
   g.setShader();g.setColor(.32,.31,.20)
   for _,y in ipairs({.31,.59,.64}) do g.ellipse('fill',x+.003,y,.002,.0033) end
   decor.material(true)
  end
  -- A wide breach at the right has a clear swimming path between its splinters.
  g.setColor(.10,.145,.105)
  g.polygon('fill',.93,.27,1.02,.33,1.07,.43,1.025,.405,1.04,.455,.992,.42,.975,.47,.954,.39)
  g.polygon('fill',.955,.60,.99,.565,.987,.62,1.035,.59,1.01,.65,1.07,.66,1.035,.71,.95,.73)
  g.setColor(.27,.27,.16);g.polygon('fill',.992,.42,1.04,.455,1.018,.422)
  g.polygon('fill',.99,.565,.987,.62,.977,.63)
  g.setShader()
  -- Plants stay rooted to the hull and move only at their tips.
  for i=1,12 do
   local x=.13+i*.071;local y=.26-.028*math.sin(i*.4)
   g.setColor(.07,.24,.20,.85);g.setLineWidth((2+i%2)/w)
   local points={}
   for j=0,10 do points[#points+1]=x+math.sin(t*.8+i+j*.35)*.005*j/10;points[#points+1]=y+j*.007 end
   g.line(points)
  end
 end
 g.pop()
end
return W
