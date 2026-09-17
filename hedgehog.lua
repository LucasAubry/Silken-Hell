local H={active=false,projectiles={}}
function H.reset(active)
    H.active=active; H.name='Le Hérisson des profondeurs'; H.hp=7; H.maxHp=7
    H.defeated=false; H.flash=0; H.phase='standing'; H.phaseTime=1.35; H.shot=.28
    H.x=Arena.width/2; H.y=185; H.dir='down'; H.stage=1; H.bounces=0; H.rotation=0
    H.hitBox_width=64; H.hitBox_height=64; H.hitBox_offset_x=-32; H.hitBox_offset_y=-32
    H.projectiles={}; H.bounceGrace=0
    if active then H.mole() end
end
function H.mole()
    Realms.spawnMole(H.x,H.y)
end
function H.roll()
    H.phase='ball'; H.bounces=0
    local angle=math.atan2(player.y+12-H.y,player.x+15-H.x)
    -- A diagonal minimum prevents long unchanging horizontal/vertical rallies.
    local dx,dy=math.cos(angle),math.sin(angle)
    if math.abs(dx)<.28 then dx=dx<0 and -.28 or .28 end
    if math.abs(dy)<.28 then dy=dy<0 and -.28 or .28 end
    local length=math.sqrt(dx*dx+dy*dy); local speed=(410+(H.stage-1)*18)*(H.movementRate or 1)
    H.vx=dx/length*speed; H.vy=dy/length*speed
end
function H.requiredBounces()
    return math.min(2,H.stage)
end
function H.impact()
    if H.defeated then return end
    H.bounces=H.bounces+1; H.flash=.15
    if H.bounces<H.requiredBounces() then return end
    H.finishRound()
end
function H.finishRound()
    if H.defeated then return end
    H.hp=H.hp-1
    Audio.play('pick')
    if H.hp==0 then
        H.defeated=true; H.projectiles={}; objet.larme.taken=false
        objet.larme.x,objet.larme.y=Arena.clearSpot(H.x-15,H.y-20,30,40)
    else
        H.stage=H.stage+1; H.phase='stunned'; H.phaseTime=.45; H.shot=.05
        if H.stage<=5 then H.mole() end
    end
end
function H.fire()
    local phase=H.stage*.21
    for i=0,11 do local a=i*math.pi*2/12+phase
        H.projectiles[#H.projectiles+1]={x=H.x,y=H.y,vx=math.cos(a)*300,vy=math.sin(a)*300,life=5}
    end
end
function H.update(dt)
    if not H.active or H.defeated then return end
    H.flash=math.max(0,H.flash-dt); H.bounceGrace=math.max(0,H.bounceGrace-dt)
    if H.phase=='standing' then
        H.phaseTime=H.phaseTime-dt; H.shot=H.shot-dt*(H.attackRate or 1)
        if H.phaseTime<=0 then H.roll()
        elseif H.shot<=0 then H.fire(); H.shot=1.25 end
    elseif H.phase=='stunned' then
        H.phaseTime=H.phaseTime-dt
        if H.phaseTime<=0 then
            H.phase='standing'; H.phaseTime=.65; H.shot=.05
        end
    else
        local speed=(410+(H.stage-1)*18)*(H.movementRate or 1)
        local current=math.atan2(H.vy,H.vx); local target=math.atan2(player.y+12-H.y,player.x+15-H.x)
        local delta=(target-current+math.pi)%(math.pi*2)-math.pi
        local angle=current+math.max(-dt*1.35,math.min(dt*1.35,delta))
        H.vx,H.vy=math.cos(angle)*speed,math.sin(angle)*speed
        local steps=math.max(1,math.ceil(speed*dt/4))
        for _=1,steps do
            local hx,hy=Arena.move(H,H.vx*dt/steps,H.vy*dt/steps)
            if hx then H.vx=-H.vx end; if hy then H.vy=-H.vy end
            H.dir=Art.direction(H.vx,H.vy,H.dir); H.rotation=H.rotation+dt/steps*9
            if (hx or hy) and H.bounceGrace<=0 then H.bounceGrace=.035; H.impact() end
            if H.defeated or H.phase~='ball' then break end
            if checkCollision(player.x,player.y,30,24,H.x-30,H.y-30,60,60) then Hazards.kill(); return end
        end
    end
    if H.defeated then return end
    if checkCollision(player.x,player.y,30,24,H.x-30,H.y-30,60,60) then Hazards.kill(); return end
    for i=#H.projectiles,1,-1 do
        local p=H.projectiles[i]; p.life=p.life-dt; local dead=p.life<=0
        local steps=math.max(1,math.ceil(300*dt/4))
        for _=1,steps do
            if dead then break end
            p.x=p.x+p.vx*dt/steps; p.y=p.y+p.vy*dt/steps
            if Arena.blocked(p.x-3,p.y-3,6,6) then dead=true
            elseif checkCollision(p.x-4,p.y-4,8,8,player.x,player.y,30,24) then Hazards.kill(); dead=true end
        end
        if dead then table.remove(H.projectiles,i) end
    end
end
function H.draw()
    if not H.active or H.defeated then return end
    local g=love.graphics
    g.setColor(0,0,0,.25); g.ellipse('fill',H.x,H.y+25,42,17)
    if H.phase=='standing' and H.phaseTime<.6 then
        g.setColor(1,.7,.25,.7); g.circle('line',H.x,H.y,48+math.sin(H.phaseTime*35)*3)
    end
    g.setColor(1,1-H.flash,1-H.flash)
    if H.phase=='ball' then
        g.push(); g.translate(H.x,H.y); g.rotate(H.rotation)
        Art.drawFacing('hedgehog_ball',H.dir,0,0,92); g.pop()
    else Art.drawFacing('hedgehog',H.dir,H.x,H.y,104) end
    if H.phase=='stunned' then
        for i=1,3 do local a=H.phaseTime*7+i*math.pi*2/3
            g.setColor(1,.86,.25,.9); g.circle('fill',H.x+math.cos(a)*27,H.y-44+math.sin(a)*7,3)
        end
    end
    for _,p in ipairs(H.projectiles) do
        g.push(); g.translate(p.x,p.y); g.rotate(math.atan2(p.vy,p.vx))
        g.setColor(.19,.10,.045); g.polygon('fill',-12,-4,12,0,-12,4)
        g.setColor(.95,.83,.57); g.polygon('fill',-7,-2,12,0,-7,2); g.pop()
    end
    g.setColor(1,1,1)
end
return H
