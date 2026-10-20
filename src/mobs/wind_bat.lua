-- A small bat follows the authored horizontal lane, then loops from the edge.
local B={}
function B.update(m,dt)
 if m.capture or m.is_frozen then return end
 m.age=(m.age or 0)+dt
 local direction=m.dx==-1 and -1 or 1
 local speed=m.speed and m.speed>0 and m.speed or 210
 m.angle=direction==1 and -math.pi/2 or math.pi/2
 m.dir=direction==1 and 'right' or 'left'
 m.hitBox_width=24;m.hitBox_height=16;m.hitBox_offset_x=-12;m.hitBox_offset_y=-8
 local distance=speed*dt;local steps=math.max(1,math.ceil(distance/6))
 for _=1,steps do
  m.x=m.x+direction*distance/steps
  if isTouching(player,m) then Hazards.kill() end
  if direction==1 and m.x>Arena.width+48 then m.x=-48
  elseif direction==-1 and m.x< -48 then m.x=Arena.width+48 end
 end
end
function B.draw(m)
 local angle=(m.dx==-1) and math.pi/2 or -math.pi/2
 love.graphics.push('all')
 require('sky_insect_art').draw('wind_bat',m.x,m.y,48,m.age or 0,angle)
 love.graphics.pop()
end
return B
