-- All stone remains opaque: camera travel and gravity carry it out of view.
local R={}
function R.draw(w,h,p,t)
 local g=love.graphics;local decor=require('transition_scenery')
 g.push('all')
 -- The ledge's parent cliff rises out of frame as the camera follows the slide.
 g.translate(0,-p.camera*h)
 decor.material(false)
 g.setColor(.07,.18,.23)
 g.polygon('fill',0,.58*h,.26*w,.60*h,.34*w,.70*h,.29*w,.84*h,.32*w,1.12*h,0,1.25*h)
 g.setColor(.12,.29,.33)
 g.polygon('fill',0,.58*h,.26*w,.60*h,.30*w,.65*h,.17*w,.66*h,0,.64*h)
 g.setShader()
 for i=1,11 do
  local x=w*(.02+i*.022);local y=h*(.605+i%3*.006)
  g.setColor(.14,.46,.44,.85);g.setLineWidth(2)
  g.line(x,y,x+math.sin(t*1.3+i)*w*.004,y-h*(.015+i%4*.009))
 end
 g.pop();g.push('all')
 g.translate(p.rockX*w,p.rockY*h)
 g.rotate(.16*p.depth+.12*p.leave)
 decor.material(false)
 g.setColor(.11,.24,.29)
 g.polygon('fill',-.19*w,0,-.10*w,-.013*h,.09*w,-.008*h,.17*w,.01*h,.145*w,.08*h,.06*w,.13*h,-.08*w,.11*h,-.16*w,.065*h)
 g.setColor(.22,.39,.40)
 g.polygon('fill',-.19*w,0,-.10*w,-.013*h,.09*w,-.008*h,.17*w,.01*h,.08*w,.032*h,-.09*w,.027*h)
 g.setColor(.07,.17,.23)
 g.polygon('fill',-.09*w,.027*h,.08*w,.032*h,.06*w,.13*h,-.01*w,.083*h)
 g.setShader();g.setLineWidth(1.3)
 for i=1,5 do
  local x=(-.14+i*.05)*w
  g.setColor(.32,.51,.51,.5);g.line(x,.042*h,x+.025*w,.061*h,x+.013*w,.083*h)
 end
 -- Tiny attached anemones sway with the current, keeping the stone alive.
 for i=1,9 do
  local x=(-.16+i*.017)*w
  g.setColor(.19,.53,.49,.8);g.setLineWidth(2)
  g.line(x,0,x+math.sin(t*1.7+i)*3,-(5+i%3*4))
 end
 g.pop()
 -- Gravel and trapped bubbles break free only once the ledge detaches.
 if p.slide>0 then
  for i=1,20 do
   local age=p.slide*(.5+i%5*.13)
   local x=w*(.27+(i*.061)% .27-.16*age)
   local y=h*(.64+age*age*.12-p.camera)
   g.setColor(.17,.31,.34,.65);g.circle('fill',x,y,2+i%3)
   g.setColor(.43,.73,.79,.3);g.setLineWidth(1)
   g.circle('line',w*(.29+(i*.043)% .25),h*(.62-age*.22-p.camera),2+i%4)
  end
 end
end
return R
