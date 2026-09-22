return function(R)
    local function motion(m,dt,before)
        local vx,vy,speed,dangerous=m.vx,m.vy,m.speed,true
        local s=m.school; local dash=s.age%3>=2.3
        vx,vy=math.cos(s.angle),math.sin(s.angle); speed=dash and 440 or 13
        if not dash then
            local leaderIndex=s.members[2] and 2 or 1
            local leader=s.members[leaderIndex] or m; local offset=(m.slot-leaderIndex)*29
            vx=vx+(leader.x+offset-m.x)*.12; vy=vy+(leader.y+math.abs(m.slot-leaderIndex)*24-m.y)*.12
            local length=math.max(1,math.sqrt(vx*vx+vy*vy)); vx=vx/length; vy=vy/length
        end
        return vx,vy,speed,dangerous
    end
    return require('mobs.shared.realm_behavior')(R,motion)
end
