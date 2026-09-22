return function(A)
 return {
  update=function(m,dt)
   if m.is_frozen or m.abyssHeld then return end
   local before=m.age;m.age=m.age+dt
   local vx,vy=math.cos(m.age*.6),math.sin(m.age*.7)
   Arena.move(m,vx*m.speed*dt,vy*m.speed*dt);m.angle=math.atan2(vy,vx)-math.pi/2
   if math.floor((before+(m.shotOffset or 0))/3)<math.floor((m.age+(m.shotOffset or 0))/3) then A.emit(m) end
   local touching=not player.abyssHeld and checkCollision(player.x,player.y,30,24,m.x-22,m.y-22,44,44)
   if touching and not m.touchingPlayer then A.charge(6) end
   m.touchingPlayer=touching
  end,
  draw=function(m)
   if m.abyssHeld then return end
   local g=love.graphics;g.setColor(1,1,1);Art.drawSwimmer('abyss_octopus',m.x,m.y,78,m.angle or 0,m.age)
   g.setColor(.4,.85,1,.35);g.circle('line',m.x,m.y,27+math.sin(m.age*3)*3);g.setColor(1,1,1)
  end
 }
end
