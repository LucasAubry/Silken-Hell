local F={}
local function clamp(x,a,b)return math.max(a,math.min(b,x))end
local function delta(a,b)return (a-b+math.pi)%(2*math.pi)-math.pi end
function F.aim(s,border)
 local px=clamp(player.x+15,170,Arena.width-170)
 local py=clamp(player.y+12,170,430)
 if border then
  local margin=95+(s.flightSpeed or 300)*.32
  if s.x<margin then px=math.max(px,Arena.width*.58)elseif s.x>Arena.width-margin then px=math.min(px,Arena.width*.42)end
  if s.y<margin then py=math.max(py,350)elseif s.y>600-margin then py=math.min(py,250)end
 end
 local dx,dy=px-s.x,py-s.y
 if dx*dx+dy*dy<10000 then dx,dy=Arena.width/2-s.x,300-s.y end
 s.flightHeading=math.atan2(dy,dx);s.flightRetarget=.7
end
function F.update(s,dt)
 s.flightRetarget=math.max(0,(s.flightRetarget or 0)-dt)
 local speed=s.flightSpeed or math.sqrt(s.vx*s.vx+s.vy*s.vy)
 local margin=95+speed*.32
 local cx,cy=math.cos(s.angle),math.sin(s.angle)
 local edges=(s.x<margin and cx<-.15 and 1 or 0)+(s.x>Arena.width-margin and cx>.15 and 2 or 0)
  +(s.y<margin and cy<-.15 and 4 or 0)+(s.y>600-margin and cy>.15 and 8 or 0)
 if edges~=0 and edges~=(s.flightEdges or 0) then F.aim(s,true) end
 s.flightEdges=edges
 local error=delta(s.flightHeading or s.angle,s.angle)
 local omega=s.flightOmega or 0
 if math.abs(error)>2.2 and error*omega<0 and math.abs(omega)>.3 then error=error+(omega>0 and 2*math.pi or -2*math.pi)end
 local desired=clamp(error*7,-2.6,2.6)
 omega=omega+clamp(desired-omega,-9*dt,9*dt)
 s.flightOmega=omega;s.angle=s.angle+omega*dt
 local target=(300+s.wave*12)*(s.movementRate or 1)*(1-.45*math.min(1,math.abs(error)/1.2))
 s.flightSpeed=speed+clamp(target-speed,-650*dt,400*dt)
 s.vx,s.vy=math.cos(s.angle)*s.flightSpeed,math.sin(s.angle)*s.flightSpeed
 s.x,s.y=s.x+s.vx*dt,s.y+s.vy*dt
end
return F
