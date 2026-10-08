local B={}
local function hit(p,dt,r)
 local angle=(r.rotation or 0)*math.pi/180;local c,s=math.cos(angle),math.sin(angle)
 local dx,dy=p.x-r.x-r.w/2,p.y-r.y-r.h/2
 local x,y=dx*c+dy*s,-dx*s+dy*c
 local vx,vy=(p.vx*c+p.vy*s)*dt,(-p.vx*s+p.vy*c)*dt
 local enter,leave=0,1;local nx,ny=0,0
 for axis=1,2 do
  local q=axis==1 and x or y;local v=axis==1 and vx or vy
  local half=(axis==1 and r.w or r.h)/2+3
  if math.abs(v)<.000001 then if math.abs(q)>half then return end
  else
   local first,last=(-half-q)/v,(half-q)/v;local sign=-1
   if first>last then first,last=last,first;sign=1 end
   if first>=enter then enter=first;nx=axis==1 and sign or 0;ny=axis==2 and sign or 0 end
   leave=math.min(leave,last);if enter>leave then return end
  end
 end
 if enter<0 or enter>1 or nx==0 and ny==0 then return end
 return enter,nx*c-ny*s,nx*s+ny*c
end
function B.update(p,dt,walls)
 local remaining=dt
 for _=1,3 do
  local best,nx,ny
  for _,r in ipairs(walls or Arena.walls)do
   local t,x,y=hit(p,remaining,r)
   if t and (not best or t<best)then best,nx,ny=t,x,y end
  end
  if not best then p.x=p.x+p.vx*remaining;p.y=p.y+p.vy*remaining;return end
  p.x=p.x+p.vx*remaining*best;p.y=p.y+p.vy*remaining*best
  if (p.bounces or 0)>=2 then p.life=0;return end
  p.bounces=(p.bounces or 0)+1
  local dot=p.vx*nx+p.vy*ny
  p.vx=p.vx-2*dot*nx;p.vy=p.vy-2*dot*ny;p.angle=math.atan2(p.vy,p.vx)
  p.x=p.x+nx*.05;p.y=p.y+ny*.05
  remaining=remaining*(1-best)
 end
end
return B
