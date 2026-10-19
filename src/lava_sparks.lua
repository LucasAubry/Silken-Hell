-- Small deterministic eruptions, anchored inside lava, independent of gameplay.
local E={sites=setmetatable({},{__mode='k'})}
local function sites(zone)
 local H=require('ground_holes')
 local key=table.concat({zone.x,zone.y,zone.rx or zone.radius or 0,zone.ry or zone.radius or 0},':')
 if zone.points then key=key..H.geometry(zone).signature end
 local cached=E.sites[zone];if cached and cached.key==key then return cached.points end
 local points={}
 local x0,y0,x1,y1
 if zone.points then x0,y0,x1,y1=H.bounds(zone)
 else x0,y0,x1,y1=-zone.rx,-zone.ry,zone.rx,zone.ry end
 for i=1,32 do
  local x=zone.x+x0+(x1-x0)*((i*.618034)%1)
  local y=zone.y+y0+(y1-y0)*((i*.414214)%1)
  local inside
  if zone.points then inside=H.contains(zone,x,y)
  else inside=((x-zone.x)/zone.rx)^2+((y-zone.y)/zone.ry)^2<.85 end
  if inside then points[#points+1]={x,y};if #points>=3 then break end end
 end
 E.sites[zone]={key=key,points=points};return points
end
function E.draw(zones,time,alpha)
 if Graphics and not Graphics.effects then return end
 local g=love.graphics;g.push('all');g.setShader();g.setBlendMode('add');g.setLineWidth(1)
 local budget=Graphics and Graphics.quality==1 and 12 or 24
 for _,zone in ipairs(zones) do for i,p in ipairs(sites(zone)) do
  if budget<=0 then break end;budget=budget-1
  local t=((time or 0)*.34+i*.217+p[1]*.013+p[2]*.009)%1
  local a=(alpha or 1);local pulse=.5+.5*math.sin(t*math.pi*2)
  for r=3,1,-1 do
   g.setColor(1,.20,.015,a*(.025+.025*pulse));g.ellipse('fill',p[1],p[2],r*6,r*3)
  end
  if t<.62 then
   local jump=t/.62;local y=p[2]-math.sin(jump*math.pi)*(12+i%3*5)
   g.setColor(1,.30,.035,a*.7);g.circle('fill',p[1],y,2.1)
   g.setColor(1,.8,.25,a*.85);g.circle('fill',p[1]-.4,y-.5,.85)
  elseif t<.86 then
   local burst=(t-.62)/.24
   g.setColor(1,.4,.06,(1-burst)*a*.6)
   g.ellipse('line',p[1],p[2],2+burst*8,1+burst*3)
   for k=1,5 do
    local angle=k*2.399+i
    local x=p[1]+math.cos(angle)*burst*13
    local y=p[2]+math.sin(angle)*burst*6-math.sin(burst*math.pi)*5
    g.circle('fill',x,y,1.2*(1-burst)+.3)
   end
  end
 end end
 g.pop()
end
return E
