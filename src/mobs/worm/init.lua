return function(R)
    local function motion(m,dt,before)
        local vx,vy,speed,dangerous=m.vx,m.vy,m.speed,true
        local a=math.atan2(player.y+12-m.y,player.x+15-m.x)
        vx,vy=math.cos(a),math.sin(a)
        dangerous=m.age%4>=1.2
        if not dangerous then speed=speed*1.3 else speed=speed*.3 end
        if math.floor((before+2.8)/4)<math.floor((m.age+2.8)/4) then R.spit(m) end
        return vx,vy,speed,dangerous
    end
    return require('mobs.shared.realm_behavior')(R,motion)
end
