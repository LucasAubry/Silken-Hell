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
  -- Visit distant sectors across the whole map instead of circling one nest.
  m.roamSeed=m.roamSeed or math.floor(m.x*.039+m.y*.017)
  m.roamTime=(m.roamTime or 0)-dt
  if not m.tx or m.roamTime<=0 or (m.tx-m.x)^2+(m.ty-m.y)^2<24^2 then
   m.roamIndex=(m.roamIndex or 0)+1
   local sector=(m.roamIndex*5+m.roamSeed)%9
   local tx=70+(sector%3+.5)*(Arena.width-140)/3
   local ty=70+(math.floor(sector/3)+.5)*460/3
   m.tx,m.ty=Arena.clearSpot(tx-15,ty-12,30,24);m.tx=m.tx+15;m.ty=m.ty+12
   m.roamTime=7
  end
  local dx,dy=m.tx-m.x,m.ty-m.y
  Arena.navigate(m,m.tx,m.ty,math.max(140,(m.speed or 55)*2.5),dt)
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
