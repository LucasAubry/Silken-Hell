local mobImage=require 'mobs.shared.images'
function spawn_scie(x, y, rotation, speed, texture)
    local scie = {
        type = "scie",
        x = x, y = y,
		rota = rotation, -- = -1 ou +1
        size = 0.29,
        speed = speed,
        float = false,
        dir = "up",
        img = nil,
        imgs = {
            up = mobImage("texture/mob/scie.png"),
            down = mobImage("texture/mob/scie_pique.png"),
            left = mobImage("texture/mob/scie_blanc.png"),
        },
        hitBox_width = 40,
        hitBox_height = 40,
        offset_fix_x = 1,
		offset_fix_y = -2

    }
    scie.img = scie.imgs[texture]
    table.insert(mobs, scie)
end

MobBehaviors.scie = {
    update = function(m, dt)
        m.rotation = (m.rotation or 0) + m.speed * dt * m.rota

        local radius = 60
        local cx = math.cos(m.rotation) * radius
        local cy = math.sin(m.rotation) * radius

        -- Position de la scie (centre de rotation + mouvement + offset fixe)
        m.hitBox_offset_x = cx + (m.offset_fix_x or 0) - m.hitBox_width / 2
        m.hitBox_offset_y = cy + (m.offset_fix_y or 0) - m.hitBox_height / 2

        if isTouching(player, m) and not player.reset then
			player.reset = true
			player.death = player.death +1
            activateShaderEffect()
        end
    end,

    draw = function(m)
        draw_mob(m, 50, m.img:getHeight() / 2)
    end
}

local die=require 'mobs.shared.infernal_contact'
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
