local W=require('sky_weather')
local B={}
function B.update(m,dt)
 if m.capture or m.is_frozen or m.tunnelTravel then return end
 m.age=m.age+dt;m.cooldown=(m.cooldown or 0)-dt
 if m.type=='dragonfly' then
  if m.phase~='orbit' then
   m.phase='orbit';m.heading=math.atan2(m.y-player.y-12,m.x-player.x-15)
   m.seed=(m.x*.017+m.y*.013)%(math.pi*2)
  end
  -- Orbit a moving player while alternating inward/outward on each zigzag.
  local side=math.sin(m.seed)>=0 and 1 or -1
  m.heading=m.heading+dt*.85*side
  local zig=2/math.pi*math.asin(math.sin(m.age*5.8+m.seed))
  local radius=132+zig*42
  m.tx=math.max(48,math.min(Arena.width-48,player.x+15+math.cos(m.heading)*radius))
  m.ty=math.max(48,math.min(552,player.y+12+math.sin(m.heading)*radius))
  local dx,dy=m.tx-m.x,m.ty-m.y;local d=math.sqrt(dx*dx+dy*dy)
  if d>.01 then
   local distance=math.min(d,((m.speed or 90)*1.5+65)*dt)
   local steps=math.max(1,math.ceil(distance/6))
   m.vx,m.vy=dx/d,dy/d;m.angle=math.atan2(dy,dx)-math.pi/2
   for _=1,steps do
    local x,y=m.x,m.y
    Arena.move(m,m.vx*distance/steps,m.vy*distance/steps)
    m.x=math.max(48,math.min(Arena.width-48,m.x));m.y=math.max(48,math.min(552,m.y))
    W.trail(x,y,m.x,m.y)
    if isTouching(player,m) then Hazards.kill() end
   end
  end
 else
  m.cx=m.cx or m.x;m.cy=m.cy or m.y
  local x=m.cx+math.sin(m.age*.6)*100;local y=m.cy+math.sin(m.age*.9)*60
  local dx,dy=x-m.x,y-m.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy));local step=math.min(d,(m.speed or 55)*dt)
  Arena.move(m,dx/d*step,dy/d*step);m.x=math.max(55,math.min(Arena.width-55,m.x));m.y=math.max(55,math.min(545,m.y))
  m.angle=math.atan2(dy,dx)-math.pi/2
  if m.cooldown<=0 then
   W.fog(m.x,m.y);W.fog(m.x+math.sin(m.age*3)*24,m.y+math.cos(m.age*3)*20)
   m.cooldown=.16
  end
 end
 if isTouching(player,m) then Hazards.kill() end
end
function B.draw(m)
 require('sky_insect_art').draw(m.type,m.x,m.y,m.type=='mist_moth' and 76 or 72,m.age,m.angle)
end
return B
