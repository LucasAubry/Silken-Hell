-- One drop, one fixed landing point. Rendering and damage share these timings.
local R={impact=.85,activeUntil=1.2,lifetime=1.4,rx=24,ry=12}
function R.update(drops,dt)
 for i=#drops,1,-1 do
  local p=drops[i];local previous=p.age;p.age=p.age+dt
  if p.age>=R.impact and previous<R.activeUntil
   and ((player.x+15-p.x)/R.rx)^2+((player.y+12-p.y)/R.ry)^2<1 then Hazards.kill('rain') end
  if p.age>=R.lifetime then table.remove(drops,i) end
 end
end
function R.draw(drops)
 local g=love.graphics;g.push('all')
 for _,p in ipairs(drops) do
  local falling=p.age<R.impact
  local fade=falling and 1 or math.max(0,(R.lifetime-p.age)/(R.lifetime-R.activeUntil))
  fade=math.min(1,fade)
  g.setColor(.08,.21,.35,(falling and .25 or .48)*fade);g.ellipse('fill',p.x,p.y,R.rx,R.ry)
  -- A dark edge and a thin pale rim remain visible against the cloud floor.
  g.setColor(.04,.10,.18,.9*fade);g.setLineWidth(3);g.ellipse('line',p.x,p.y,R.rx,R.ry)
  g.setColor(.79,.92,1,.95*fade);g.setLineWidth(1);g.ellipse('line',p.x,p.y,R.rx,R.ry)
  if falling then
   g.setColor(.84,.95,1,.9);g.circle('fill',p.x,p.y,1.8)
   local progress=math.max(0,p.age/R.impact);local y=p.y-155*(1-progress*progress)
   g.setColor(.08,.25,.42,.8);g.setLineWidth(4);g.line(p.x,y-17,p.x,y)
   g.setColor(.65,.87,1,1);g.setLineWidth(1.5);g.line(p.x,y-15,p.x,y)
   g.setColor(.92,.98,1);g.ellipse('fill',p.x,y,2.2,4)
  else
   local t=(p.age-R.impact)/(R.lifetime-R.impact);local r=R.rx*math.min(1,t*3)
   g.setColor(.7,.9,1,(1-t)*.9);g.ellipse('line',p.x,p.y,r,r*.5)
   for j=0,5 do local a=j*math.pi/3
    g.circle('fill',p.x+math.cos(a)*r,p.y+math.sin(a)*r*.5-math.sin(t*math.pi)*8,1.3*(1-t))
   end
  end
 end
 g.pop()
end
return R
