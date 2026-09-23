return {
    update=function(m,dt)
        m.age=m.age+dt;Realms.capture(m);if m.is_frozen or m.tunnelTravel then return end
        m.dir=Art.direction(player.x+15-m.x,player.y+12-m.y,m.dir)
        Arena.navigate(m,player.x+15,player.y+12,m.speed,dt)
        if isTouching(player,m) then Hazards.kill() end
    end,
    draw=function(m)
        love.graphics.setColor(1,1,1);Art.drawLarva(m.x,m.y,36,math.atan2(player.y+12-m.y,player.x+15-m.x)+math.pi,m.age)
    end
}
