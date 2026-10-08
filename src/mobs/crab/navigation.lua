-- Keep a detour until its corner is reached instead of pressing into the wall.
local N={}
function N.steer(c,dt,tx,ty)
 local wandering=tx==nil
 if wandering then
  if c.crabGoal then tx,ty=c.crabGoal.x,c.crabGoal.y
  else tx,ty=c.x+(c.vx or 0)*220,c.y+(c.vy or 1)*220 end
 end
 local graph=Arena.navGraph(c)
 if wandering then
  tx=math.max(46,math.min(Arena.width-46,tx));ty=math.max(44,math.min(Arena.height-44,ty))
 end
 if graph.clear(tx,ty) and graph.line(c.x,c.y,tx,ty) then
  c.crabPath=nil
  if not c.crabGoal then return false end
  if (tx-c.x)^2+(ty-c.y)^2<12^2 then c.crabGoal=nil;return false end
 else
  c.crabNavTime=(c.crabNavTime or 0)-dt
  if not c.crabPath or #c.crabPath==0 or c.crabNavTime<=0 or c.crabNavVersion~=Arena.navigationVersion then
   c.crabPath=Arena.route(c,tx,ty);c.crabNavTime=.55;c.crabNavVersion=Arena.navigationVersion
   if wandering and #c.crabPath>0 then
    local goal=c.crabPath[#c.crabPath];c.crabGoal={x=goal.x,y=goal.y}
   end
  end
  while c.crabPath[1] and (c.crabPath[1].x-c.x)^2+(c.crabPath[1].y-c.y)^2<6^2 do table.remove(c.crabPath,1)end
  if not c.crabPath[1] then c.crabGoal=nil;return false end
  tx,ty=c.crabPath[1].x,c.crabPath[1].y
 end
 local dx,dy=tx-c.x,ty-c.y;local d=math.sqrt(dx*dx+dy*dy)
 if d<.01 then return false end
 c.vx,c.vy=dx/d,dy/d
 return true
end
return N
