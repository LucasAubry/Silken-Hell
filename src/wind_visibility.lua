-- Continuous swept-rectangle visibility: four interval tests per wall, not
-- hundreds of 3-pixel collision samples for every wind particle.
local V={}
local function clip(lo,hi,p,v,r)
 if math.abs(v)<1e-9 then if math.abs(p)>=r then return nil end;return lo,hi end
 local a,b=(-r-p)/v,(r-p)/v;if a>b then a,b=b,a end
 lo=math.max(lo,a);hi=math.min(hi,b)
 if lo>=hi then return nil end
 return lo,hi
end
function V.limit(x,y,vx,vy,range)
 local limit=range
 for _,r in ipairs(Arena.walls) do
  local a=(r.rotation or 0)*math.pi/180;local c,s=math.cos(a),math.sin(a)
  local dx,dy=x-r.x-r.w/2,y-r.y-r.h/2
  local lo,hi=clip(0,limit,dx,vx,15+math.abs(c)*r.w/2+math.abs(s)*r.h/2)
  if lo then lo,hi=clip(lo,hi,dy,vy,12+math.abs(s)*r.w/2+math.abs(c)*r.h/2) end
  if lo then lo,hi=clip(lo,hi,dx*c+dy*s,vx*c+vy*s,r.w/2+math.abs(c)*15+math.abs(s)*12) end
  if lo then lo,hi=clip(lo,hi,-dx*s+dy*c,-vx*s+vy*c,r.h/2+math.abs(s)*15+math.abs(c)*12) end
  if lo and not Hazards.openEdge(r,x+vx*lo-15,y+vy*lo-12,30,24) then limit=lo end
 end
 return limit
end
function V.clear(x,y,tx,ty)
 local dx,dy=tx-x,ty-y;local d=math.sqrt(dx*dx+dy*dy)
 if d<1e-9 then return not Arena.blocked(x-15,y-12,30,24) end
 return V.limit(x,y,dx/d,dy/d,d)>=d
end
return V
