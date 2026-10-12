-- Continuous escape steering: preserve speed while turning away from danger.
local M={speed=440,margin=62,turnRate=5.5}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function angleDelta(a,b) return math.atan2(math.sin(a-b),math.cos(a-b)) end
local function desired(p,px,py,width,height)
 local dx,dy=p.x-px,p.y-py;local distance=math.max(.001,math.sqrt(dx*dx+dy*dy))
 local away=math.atan2(dy,dx)
 local heading=p.heading or away
 local flee=2.8*clamp((320-distance)/180,0,1)
 local look=M.speed/M.turnRate*2+35
 local best,score
 local function candidate(a)
  local x,y=p.x,p.y;local h=p.heading and heading or a;local clearance=distance
  -- Check the curved approach as well as the chosen direction.
  for _=1,10 do
   h=h+clamp(angleDelta(a,h),-M.turnRate*look/M.speed/10,M.turnRate*look/M.speed/10)
   x=x+math.cos(h)*look/10;y=y+math.sin(h)*look/10
   if x<M.margin+15 or x>width-M.margin-15 or y<M.margin+15 or y>height-M.margin-15 then return end
   clearance=math.min(clearance,math.sqrt((x-px)^2+(y-py)^2))
  end
  local value=math.cos(a-heading)*2+math.cos(a-away)*flee
      -math.max(0,95-clearance)*.1+math.sin(a-heading)*p.escapeSide*.025
  if not score or value>score then best,score=a,value end
 end
 -- Once safely away, keep running; only a threat or an approaching wall turns her.
 candidate(heading);candidate(away)
 for i=1,31 do candidate(heading+i*math.pi/16) end
 return best or away
end
function M.advance(p,px,py,width,height,dt)
 if dt<=0 then return 0 end
 p.escapeSide=p.escapeSide or (p.y<height*.5 and -1 or 1)
 local steps=math.max(1,math.ceil(dt*120));local step=M.speed*dt/steps
 local distance=0
 for _=1,steps do
  local moving=p.heading~=nil
  local target=desired(p,px,py,width,height)
  p.heading=moving and p.heading+clamp(angleDelta(target,p.heading),-M.turnRate*dt/steps,M.turnRate*dt/steps) or target
  local vx,vy=math.cos(p.heading),math.sin(p.heading)
  local x,y=p.x+vx*step,p.y+vy*step
  if x<M.margin or x>width-M.margin or y<M.margin or y>height-M.margin then
   -- A resize or a start against a wall still gets a full-length escape step.
   local best,score
   for i=0,31 do
    local a=i*math.pi/16;local xx,yy=p.x+math.cos(a)*step,p.y+math.sin(a)*step
    if xx>=M.margin and xx<=width-M.margin and yy>=M.margin and yy<=height-M.margin then
     local value=math.cos(a-p.heading)+math.cos(a-target)*.2
     if not score or value>score then best,score=a,value end
    end
   end
   if best then p.heading=best;vx,vy=math.cos(best),math.sin(best);x,y=p.x+vx*step,p.y+vy*step end
  end
  p.x,p.y=x,y;p.vx,p.vy=vx,vy;distance=distance+step
 end
 local horizontal=p.facing=='left' or p.facing=='right'
 if not p.facing or (horizontal and math.abs(p.vy)>math.abs(p.vx)+.18) or (not horizontal and math.abs(p.vx)>math.abs(p.vy)+.18) then
  horizontal=math.abs(p.vx)>math.abs(p.vy)
 end
 p.facing=horizontal and (p.vx>0 and 'right' or 'left') or (p.vy>0 and 'down' or 'up')
 p.angle=({down=0,up=math.pi,left=math.pi/2,right=-math.pi/2})[p.facing]
 return distance
end
return M
