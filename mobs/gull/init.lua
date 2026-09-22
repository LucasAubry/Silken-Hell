return function(R)
    local function motion(m,dt,before)
        local vx,vy,speed,dangerous=m.vx,m.vy,m.speed,true
        R.moveGull(m,dt)
        if dangerous and isTouching(player,m) then Hazards.kill() end
        return vx,vy,speed,dangerous,true
    end
    return require('mobs.shared.realm_behavior')(R,motion)
end
