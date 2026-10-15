-- Legacy rain wave data now drives lightning strikes; ambient rain stays harmless.
local R={impact=.85,activeUntil=1.2,lifetime=1.4,rx=24,ry=12}
function R.electrify(x,y,rx,ry)
 local changed=false;rx=rx or 45;ry=ry or rx
 for _,m in ipairs(mobs or {}) do
  if m.type=='gull' and not m.dead and not m.electric and ((m.x-x)/rx)^2+((m.y-y)/ry)^2<1 then
   m.electric=true;changed=true
  end
 end
 if changed then Bestiary.discover('electric_gull');Bestiary.save() end
end
function R.update(drops,dt)
 for i=#drops,1,-1 do
  local p=drops[i];local previous=p.age;p.age=p.age+dt
  if Campaign.biome==6 and p.age>=R.impact and not p.struck then
   p.struck=true;Realms.lightningImpact(p.x,p.y,p.x+p.y)
  end
  if p.age>=R.impact and previous<R.activeUntil then
   R.electrify(p.x,p.y,R.rx,R.ry)
   if ((player.x+15-p.x)/R.rx)^2+((player.y+12-p.y)/R.ry)^2<1 then Hazards.kill('lightning') end
  end
  if p.age>=R.lifetime then table.remove(drops,i) end
 end
end
function R.draw(drops)
 local g=love.graphics;g.push('all');g.setShader()
 for _,p in ipairs(drops) do
  if Campaign.biome==6 then
   local light=require('storm_lightning')
   if p.age<R.impact then light.warning(p.x,p.y,math.max(0,p.age/R.impact),R.rx,R.ry)
   end
  else
  local warning=p.age<R.impact
  local fade=warning and 1 or math.min(1,math.max(0,(R.lifetime-p.age)/(R.lifetime-R.activeUntil)))
  g.setColor(.09,.07,.025,(warning and .4 or .65)*fade);g.ellipse('fill',p.x,p.y,R.rx,R.ry)
  g.setColor(.08,.06,.02,.95*fade);g.setLineWidth(4);g.ellipse('line',p.x,p.y,R.rx,R.ry)
  g.setColor(1,.82,.28,.95*fade);g.setLineWidth(1.5);g.ellipse('line',p.x,p.y,R.rx,R.ry)
  if warning then
   local charge=math.max(0,p.age/R.impact)
   g.setColor(1,.9,.46,.6+charge*.4)
   g.polygon('fill',p.x+2,p.y-9,p.x-7,p.y+1,p.x-1,p.y+1,p.x-3,p.y+9,p.x+7,p.y-2,p.x+1,p.y-2)
   g.setLineWidth(2);g.arc('line','open',p.x,p.y,29,-math.pi/2,-math.pi/2+math.max(.01,charge)*math.pi*2)
  else
   -- Height is a visual projection above the marked ground impact.
   local points={p.x-12,p.y-190,p.x+13,p.y-145,p.x-9,p.y-110,p.x+12,p.y-66,p.x-6,p.y-31,p.x,p.y}
   g.setColor(1,.78,.16,.12*fade);g.setLineWidth(7);g.line(points)
   g.setColor(1,.85,.30,fade);g.setLineWidth(2.5);g.line(points)
   g.setColor(1,1,.88,fade);g.setLineWidth(1);g.line(points)
   for j=1,6 do
    local angle=j*math.pi/3;local radius=8+(p.age-R.impact)*22
    g.line(p.x+math.cos(angle)*5,p.y+math.sin(angle)*3,p.x+math.cos(angle)*radius,p.y+math.sin(angle)*radius*.5)
   end
  end
  end
 end
 g.pop()
end
return R
