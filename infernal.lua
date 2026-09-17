local function die()
    if not player.reset then player.reset=true; player.death=player.death+1; activateShaderEffect() end
end
function spawn_spinner(x,y,speed)
    mobs[#mobs+1]={type='spinner',x=x,y=y,speed=speed,rotation=(x+y)*.017,
        hitBox_width=40,hitBox_height=40,hitBox_offset_x=-20,hitBox_offset_y=-20}
end
function setup_spinner(m)
    local angle=(m.x+m.y)*.017
    m.vx=math.cos(angle); m.vy=math.sin(angle)
end
MobBehaviors.spinner={
    update=function(m,dt)
        m.rotation=m.rotation+dt*8
        local hitX,hitY=Arena.move(m,m.vx*m.speed*dt,m.vy*m.speed*dt)
        if hitX then m.vx=-m.vx end; if hitY then m.vy=-m.vy end
        m.dir=Art.direction(math.cos(m.rotation),math.sin(m.rotation))
        if isTouching(player,m) then die() end
    end,
    draw=function(m)
        love.graphics.setColor(1,1,1); Art.drawFacing('serpent',m.dir or 'down',m.x,m.y,58)
    end
}
function spawn_imp(x,y,speed,elite)
    mobs[#mobs+1]={type='imp',x=x,y=y,speed=speed,charge=1.5,dir='down',elite=elite,hitBox_width=30,hitBox_height=36,hitBox_offset_x=-15,hitBox_offset_y=-18}
end
MobBehaviors.imp={
    update=function(m,dt)
        for _,trap in ipairs(mobs) do
            if trap.type=='piege' and not trap.active and isTouching(m,trap) then
                freeze(m,2); trap.active=true
                if m.has_larme and not objet.larme_dropped then
                    objet.larme.x=m.x-15; objet.larme.y=m.y+25; objet.larme_dropped=true
                end
            end
        end
        if m.is_frozen then return end
        m.charge=m.charge-dt
        local dx,dy=player.x+15-m.x,player.y+12-m.y
        local a=math.atan2(dy,dx); m.dir=Art.direction(dx,dy,m.dir)
        local speed=m.speed
        if m.charge<0 then speed=speed*2.1 end
        if m.charge < -3 then m.charge=2.0 end
        Arena.navigate(m,player.x+15,player.y+12,speed,dt)
        if isTouching(player,m) then die() end
    end,
    draw=function(m)
        love.graphics.setColor(1,m.charge<0 and .7 or 1,1)
        Art.drawFacing('imp',m.dir,m.x,m.y,m.elite and 94 or 63); love.graphics.setColor(1,1,1)
    end
}
function setup_rotor(m)
    m.rotation=m.rotation or 0; m.radius=60
    -- The entire circular sweep must fit clear of the walls.
    for radius=60,28,-4 do
        local clear=true
        for i=0,31 do local a=i*math.pi/16
            if Arena.blocked(m.x+math.cos(a)*radius-21,m.y+math.sin(a)*radius-21,42,42) then clear=false; break end
        end
        if clear then m.radius=radius; break end
    end
    MobBehaviors.scie.update(m,0,true)
end
MobBehaviors.scie.update=function(m,dt,noCollision)
    m.rotation=(m.rotation or 0)+m.speed*dt*m.rota
    m.tipX=m.x+math.cos(m.rotation)*(m.radius or 60)
    m.tipY=m.y+math.sin(m.rotation)*(m.radius or 60)
    m.hitBox_width=42; m.hitBox_height=42
    m.hitBox_offset_x=m.tipX-m.x-21; m.hitBox_offset_y=m.tipY-m.y-21
    if not noCollision and isTouching(player,m) then die() end
end
MobBehaviors.scie.draw=function(m)
    local g=love.graphics; local x,y=m.tipX or m.x,m.tipY or m.y
    g.setColor(.13,.09,.05); g.setLineWidth(7); g.line(m.x,m.y,x,y)
    g.setColor(.65,.48,.23); g.setLineWidth(2)
    for i=0,7 do local t=i/8; g.circle('line',m.x+(x-m.x)*t,m.y+(y-m.y)*t,3) end
    g.setColor(.9,.7,.3); g.circle('fill',m.x,m.y,7); g.setLineWidth(1)
    g.setColor(1,1,1); Art.draw('wheel',x,y,60,m.rotation or 0)
end
