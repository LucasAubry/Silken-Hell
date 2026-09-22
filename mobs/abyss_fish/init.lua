return function(A)
 return {
  update=function(m,dt)
   if m.is_frozen or m.abyssHeld then return end
   m.age=m.age+dt
        local dx,dy=player.x+15-m.x,player.y+12-m.y; local d=math.max(1,math.sqrt(dx*dx+dy*dy))
        local vx,vy,speed
        if (player.illuminated or 0)>0 and d<300+120*(player.charges or 0) then vx,vy,speed=dx/d,dy/d,95+12*(player.charges or 0)
        elseif d<240 then vx,vy,speed=-dx/d,-dy/d,m.speed*.355
        else
            m.turn=m.turn-dt; if m.turn<=0 then m.heading=love.math.random()*math.pi*2; m.turn=1+love.math.random()*2 end
            vx,vy,speed=math.cos(m.heading),math.sin(m.heading),m.speed*.35
        end
        local hx,hy=Arena.move(m,vx*speed*dt,vy*speed*dt)
        if hx or hy then m.heading=m.heading+math.pi/2 end
        m.angle=math.atan2(vy,vx); m.dir=Art.direction(vx,vy,m.dir)
   if isTouching(player,m) then Hazards.kill() end
  end,
  draw=function(m)
   if m.abyssHeld then return end
   love.graphics.setColor(1,1,1);Art.draw('abyss_fish',m.x,m.y,85,m.angle or 0)
  end
 }
end
