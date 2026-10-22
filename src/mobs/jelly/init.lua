return function(R)
    local function motion(m,dt,before)
        local vx,vy,speed,dangerous=m.vx,m.vy,m.speed,true
        vx,vy=math.cos(m.age*.7+m.x*.001),math.sin(m.age*.8); speed=speed*.65
        if m.attackDelay==nil then m.attackDelay=1 end
        local due=require('mob_attack_timing').due(m,dt,1,3.5)
        if due then R.zap(m) end
        vx,vy=require('mob_start_direction').motion(m,vx,vy)
        return vx,vy,speed,dangerous
    end
    return require('mobs.shared.realm_behavior')(R,motion)
end
