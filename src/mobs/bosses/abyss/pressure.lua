-- A pressure front sweeps right, leaving an opening in the wave.
local P={}
function P.spawn(a)
 local x=a.mouth()
 a.pressureCount=(a.pressureCount or 0)+1
 a.pressure={x=x,startX=x,drift=a.pressureCount%2==0 and -1 or 1,age=0,warning=1.1,gap=math.max(115,math.min(485,player.y+12)),halfGap=a.hp<=a.maxHp*.5 and 66 or 82}
 a.pressure.baseGap=a.pressure.gap
end
function P.update(a,dt)
 if not a.boss or a.defeated or a.open or (a.recoil or 0)>0 then a.pressure=nil;a.nextPressure=1.35;return end
 dt=dt*a.attackSpeed()
 if not a.pressure then
  a.nextPressure=a.nextPressure-dt
  if a.nextPressure<=0 then P.spawn(a) end
  return
 end
 local p=a.pressure;local previous=p.age;p.age=p.age+dt
 if p.age>=p.warning then
  local old=p.x;p.x=p.x+240*(p.age-math.max(previous,p.warning))
  local travel=math.max(0,math.min(1,(p.x-p.startX)/(Arena.width-p.startX)))
  p.gap=math.max(110,math.min(490,p.baseGap+p.drift*45*math.sin(travel*math.pi)))
  local px,py=player.x+15,player.y+12
  if px>=old-22 and px<=p.x+22 and math.abs(py-p.gap)>p.halfGap-12 then Hazards.kill('pressure') end
  if p.x>Arena.width+35 then a.pressure=nil;a.nextPressure=.9 end
 end
end
function P.draw(a)
 local p=a.pressure;if not p or p.age<p.warning then return end
 local g=love.graphics;g.push('all')
 g.setColor(.40,.84,.78,.85);g.setLineWidth(5)
 for _,range in ipairs({{35,p.gap-p.halfGap},{p.gap+p.halfGap,565}}) do
  local points={}
  for y=range[1],range[2],5 do
   points[#points+1]=p.x+math.sin(y*.06-p.age*12)*5;points[#points+1]=y
  end
  if #points>=4 then g.line(points) end
 end
 g.setColor(.8,1,.94,.8);g.setLineWidth(1)
 for y=40,560,18 do if math.abs(y-p.gap)>p.halfGap then
  g.circle('line',p.x-10-math.sin(y)*6,y,2+math.sin(p.age*8+y))
 end end
 g.pop()
end
return P
