return function(R)
    local function motion(m,dt,before)
        local vx,vy,speed,dangerous=m.vx,m.vy,m.speed,true
        local t=m.age%5; local phase,amount=R.molePhase(m.age); dangerous=phase=='surface' or (phase=='emerge' and amount>.65)
        if t<.05 or not m.targetX then m.targetX=player.x+15; m.targetY=player.y+12 end
        if t<1.7 then
            local a=math.atan2(m.targetY-m.y,m.targetX-m.x); vx,vy=math.cos(a),math.sin(a); speed=196
        elseif phase~='surface' then speed=0
        else local a=math.atan2(player.y+12-m.y,player.x+15-m.x); vx,vy=math.cos(a),math.sin(a) end
        return vx,vy,speed,dangerous
    end
    return require('mobs.shared.realm_behavior')(R,motion)
end
