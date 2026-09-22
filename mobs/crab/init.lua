return function(O)
return {
    update=function(c,dt)
        if c.dead then return end
        c.age=c.age+dt; Realms.capture(c)
        if c.is_frozen then return end
        local controller=(Bosses and Bosses.octopusFor(c)) or O
        controller.inkCrab(c,dt)
        local function contact() controller.crabContact(c) end
        if c.fling then controller.moveFlungCrab(c,dt,contact)
        else controller.walkCrab(c,dt,contact) end
    end,
    draw=function(c)
        if c.dead then return end
        local g=love.graphics;g.setColor(c.inked and .08 or 1,c.inked and .07 or 1,c.inked and .1 or 1)
        Art.draw(math.floor(c.age*6)%2==0 and 'crab_open' or 'crab_closed',c.x,c.y,46,(c.angle or 0)-math.pi/2)
    end
}
end
