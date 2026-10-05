return {
    update=function(m,dt)
        m.age=m.age+dt;Realms.capture(m);if m.is_frozen or m.tunnelTravel then return end
        m.x=m.cx+math.cos(m.age*1.6)*m.radius; m.y=m.cy+math.sin(m.age*1.6)*m.radius*.75
        m.dir=Art.direction(-math.sin(m.age*1.6),math.cos(m.age*1.6))
        if isTouching(player,m) then Hazards.kill() end
    end,
    draw=function(m)
        love.graphics.setColor(1,1,1);Art.drawFacing('merle',m.dir,m.x,m.y,34)
    end
}
