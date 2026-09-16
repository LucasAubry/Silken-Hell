local W={active=false,projectiles={},minions={}}
function W.reset(active)
    W.active=active; W.name='La Guêpe solitaire'; W.hp=10; W.maxHp=10; W.defeated=false; W.flash=0
    W.x=Arena.width/2; W.y=180; W.elapsed=0; W.phase='flying'; W.phaseTime=5; W.shot=0.6; W.summon=2
    W.projectiles={}; W.minions={}; W.landings=0; W.dir='down'; W.hitGrace=0
end
function W.interval() return 0.48-0.31*(1-W.hp/W.maxHp) end
function W.stingerVector()
    if W.dir=='left' then return 1,0 elseif W.dir=='right' then return -1,0 end
    return 0,1
end
function W.stinger() local dx,dy=W.stingerVector(); return W.x+dx*45,W.y+dy*45 end
function W.contact()
    if not W.active or W.defeated or W.phase~='landed' then return end
    -- Any contact with the grounded body is a safe hit, with or without sprint.
    if checkCollision(player.x,player.y,30,24,W.x-38,W.y-42,76,84) then
        W.hitGrace=.35; W.hp=math.max(0,W.hp-1); W.flash=.3; Audio.play('pick')
        W.phase='flying'; W.phaseTime=math.max(2.8,5-(1-W.hp/W.maxHp)*2); W.shot=.6
        if W.hp==0 then
            W.defeated=true; W.projectiles={}; W.minions={}; objet.larme.taken=false
            objet.larme.x=W.x-15; objet.larme.y=W.y-20
        end
    end
end
function W.fire(kind)
    local a=math.atan2(player.y+12-W.y,player.x+15-W.x)
    local speed=kind=='venom' and 145 or 255+60*(1-W.hp/W.maxHp)
    local spread=kind=='venom' and {-0.22,0,0.22} or {0}
    for _,offset in ipairs(spread) do local angle=a+offset
        W.projectiles[#W.projectiles+1]={x=W.x,y=W.y,vx=math.cos(angle)*speed,vy=math.sin(angle)*speed,kind=kind,life=7}
    end
end
function W.update(dt)
    if not W.active or W.defeated then return end
    W.hitGrace=math.max(0,W.hitGrace-dt); W.elapsed=W.elapsed+dt; W.flash=math.max(0,W.flash-dt); W.phaseTime=W.phaseTime-dt; W.shot=W.shot-dt
    if W.phase=='flying' then
        local oldX,oldY=W.x,W.y
        W.x=Arena.width/2+math.sin(W.elapsed*0.65)*Arena.width*0.28
        W.y=280+math.sin(W.elapsed*0.91)*140
        W.dir=Art.direction(W.x-oldX,W.y-oldY,W.dir)
        if W.phaseTime<=0 then
            W.phase='landing'; W.phaseTime=.8
            local x,y=Arena.clearSpot(W.x-65,W.y-65,130,130)
            W.x,W.y=x+65,y+65
        end
        W.summon=W.summon-dt
        if W.summon<=0 and #W.minions<5 then
            W.minions[#W.minions+1]={x=W.x-45,y=W.y,life=9}
            W.minions[#W.minions+1]={x=W.x+45,y=W.y,life=9}; W.summon=4.5; Bestiary.discover('waspling'); Bestiary.save()
        end
    elseif W.phase=='landing' then
        if W.phaseTime<=0 then W.phase='landed'; W.phaseTime=4.5; W.shot=0.3; W.landings=W.landings+1 end
    elseif W.phaseTime<=0 then W.phase='flying'; W.phaseTime=4; W.shot=0.5 end
    if W.shot<=0 and W.phase~='landing' then
        W.fire(W.phase=='landed' and 'venom' or 'sting'); W.shot=W.interval()*(W.phase=='landed' and 1.7 or 1)
    end
    W.contact()
    for i=#W.projectiles,1,-1 do
        local p=W.projectiles[i]; p.life=p.life-dt; local dead=p.life<=0
        local steps=math.max(1,math.ceil(math.sqrt(p.vx*p.vx+p.vy*p.vy)*dt/4))
        for _=1,steps do
            if dead then break end
            p.x=p.x+p.vx*dt/steps; p.y=p.y+p.vy*dt/steps
            if checkCollision(p.x-5,p.y-5,10,10,player.x,player.y,30,24) then
                if p.kind=='venom' then player.venom=3 elseif W.hitGrace<=0 then Hazards.kill() end; dead=true
            elseif Arena.blocked(p.x-4,p.y-4,8,8) then dead=true end
        end
        if dead then table.remove(W.projectiles,i) end
    end
    for i=#W.minions,1,-1 do local m=W.minions[i]; m.life=m.life-dt
        local a=math.atan2(player.y+12-m.y,player.x+15-m.x)
        m.dir=Art.direction(math.cos(a),math.sin(a))
        m.x=m.x+math.cos(a)*95*dt; m.y=m.y+math.sin(a)*95*dt
        if (player.x+15-m.x)^2+(player.y+12-m.y)^2<20^2 and W.hitGrace<=0 then Hazards.kill() end
        if m.life<=0 then table.remove(W.minions,i) end
    end
end
function W.drawGround()
    if not W.active or W.defeated then return end
    local g=love.graphics
    g.setColor(0,0,0,0.23); g.ellipse('fill',W.x,W.y+22,46,20)
    if W.phase~='flying' then
        g.setColor(1,.85,.2,.7); g.ellipse('line',W.x,W.y,48,48)
    end
end
function W.draw(airborne)
    if not W.active then return end
    local g=love.graphics
    if not W.defeated and airborne==(W.phase~='landed') then
        local flying=W.phase~='landed'
        g.setColor(1,1-W.flash,1-W.flash)
        Art.drawFacing(flying and 'wasp' or 'wasp_ground',W.dir,W.x,W.y+(flying and -12+math.sin(W.elapsed*36)*2 or 0),flying and 120 or 90)

    end
    if airborne then
        for _,m in ipairs(W.minions) do g.setColor(1,1,1); Art.drawFacing('wasp',m.dir,m.x,m.y,34) end
        for _,p in ipairs(W.projectiles) do
            if p.kind=='venom' then
                g.setColor(0.2,0.9,0.13,0.3); g.circle('fill',p.x,p.y,12)
                g.setColor(0.55,1,0.12); g.circle('fill',p.x,p.y,6)
            else
                g.push(); g.translate(p.x,p.y); g.rotate(math.atan2(p.vy,p.vx)); g.setColor(0.2,0.13,0.03)
                g.polygon('fill',-12,-5,13,0,-12,5); g.setColor(1,0.8,0.25); g.line(-9,0,10,0); g.pop()
            end
        end
    end
    g.setColor(1,1,1)
end
return W
