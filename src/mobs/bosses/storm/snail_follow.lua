-- Fixed distance slots on the bird's actual route: no rotating fan or shortcuts.
local F={gap=70,lead=220}
local function length(x,y)return math.sqrt(x*x+y*y)end
function F.reset(s)
 s.snailRoute={};s.snailDistance=0
 local reach=F.lead+math.max(0,s.wave-1)*F.gap+80
 local dx,dy=math.cos(s.angle),math.sin(s.angle)
 for d=-reach,0,5 do s.snailRoute[#s.snailRoute+1]={x=s.x+dx*d,y=s.y+dy*d,distance=d}end
 s.snailRoute[#s.snailRoute+1]={x=s.x,y=s.y,distance=0}
end
function F.record(s)
 if not s.snailRoute then F.reset(s)end
 local route=s.snailRoute;local last=route[#route]
 local d=length(s.x-last.x,s.y-last.y)
 if d<.001 then return end
 s.snailDistance=s.snailDistance+d
 route[#route+1]={x=s.x,y=s.y,distance=s.snailDistance}
 local reach=F.lead+math.max(0,s.wave-1)*F.gap
 for _,p in ipairs(s.snails)do reach=math.max(reach,p.routeOffset or 0)end
 local oldest=s.snailDistance-reach-80
 while #route>2 and route[2].distance<oldest do table.remove(route,1)end
end
function F.sample(s,id)
 local route=s.snailRoute;local p=s.snails and s.snails[id]
 local target=s.snailDistance-(p and p.routeOffset or F.lead+(id-1)*F.gap)
 for i=#route-1,1,-1 do
  local a,b=route[i],route[i+1]
  if a.distance<=target then
   local t=math.max(0,math.min(1,(target-a.distance)/math.max(.001,b.distance-a.distance)))
   return a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t
  end
 end
 return route[1].x,route[1].y
end
function F.move(s,p,dt)
 local x,y=F.sample(s,p.id);local dx,dy=x-p.x,y-p.y
 p.x,p.y=x,y;p.vx,p.vy=dx/math.max(.0001,dt),dy/math.max(.0001,dt)
 if length(dx,dy)>.001 then
  local a=math.atan2(dy,dx);local turn=(a-p.angle+math.pi)%(2*math.pi)-math.pi
  p.angle=p.angle+turn*(1-math.exp(-12*dt))
 end
end
function F.resize(s,r)
 -- Rebuild distances after stretching the arena so slot positions stay continuous.
 local route=s.snailRoute;if not route then return end
 local distance=0
 for i,p in ipairs(route)do
  p.x=p.x*r
  if i>1 then local a=route[i-1];distance=distance+length(p.x-a.x,p.y-a.y)end
  p.distance=distance
 end
 s.snailDistance=distance
 -- Preserve each scaled position rather than snapping to a new distance slot.
 for _,p in ipairs(s.snails)do if p.phase=='tethered' then
  local best,along=math.huge,0
  for i=1,#route-1 do
   local a,b=route[i],route[i+1];local dx,dy=b.x-a.x,b.y-a.y
   local t=math.max(0,math.min(1,((p.x-a.x)*dx+(p.y-a.y)*dy)/math.max(.001,dx*dx+dy*dy)))
   local d=(p.x-a.x-t*dx)^2+(p.y-a.y-t*dy)^2
   if d<best then best=d;along=a.distance+t*(b.distance-a.distance)end
  end
  p.routeOffset=distance-along
 end end
end
return F
