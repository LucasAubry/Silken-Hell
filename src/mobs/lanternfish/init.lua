return function(R)
    local function motion(m,dt,before)
        local vx,vy,speed,dangerous=m.vx,m.vy,m.speed,true
        vx,vy=math.cos(m.age*.45+m.phase),math.sin(m.age*.6+m.phase)*.65
        return vx,vy,speed,dangerous
    end
    return require('mobs.shared.realm_behavior')(R,motion)
end
