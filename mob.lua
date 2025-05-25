MobBehaviors = {}
function load_mob()
    mobs = {} -- reset
end

-------------BOSS------------------------
function spawn_boss(x, y, speed)
    local boss = {
        type = "boss",
        x = x, y = y,
        size = 0.3,
        speed = speed,
        float = true,
        dir = "up",
        img = nil,
        imgs = {
            up = love.graphics.newImage("texture/mob/boss_up.png"),
            down = love.graphics.newImage("texture/mob/boss_down.png"),
            left = love.graphics.newImage("texture/mob/boss_left.png"),
            right = love.graphics.newImage("texture/mob/boss_right.png"),
        },
        hitBox_width = 40,
        hitBox_height = 40,
        offset_fix_x = 0,
		offset_fix_y = 0
    }
    boss.img = boss.imgs[texture]
    table.insert(mobs, boss)
end

MobBehaviors.boss = {
    update = function(m, dt)
        move_mob_towards_player(m, player, dt)
        if isTouching(player, m) and not m.active then
    		player.reset = true -- die (le reset et dans update pour eviter les bug
			player.death = player.death +1
            activateShaderEffect()
            m.active = true
        end
    end,

    draw = function(m)
        draw_mob(m)
    end
}

-----------------SNAKE----------------


function spawn_snake(x, y, speed)
    local snake = {
        type = "snake",
        x = x, y = y,
        size = 0.2,
        speed = speed or 1,
        float = true,
        dir = "right",
        img = nil,
        imgs = {
            up = love.graphics.newImage("texture/mob/snake_up.png"),
            down = love.graphics.newImage("texture/mob/snake_down.png"),
            left = love.graphics.newImage("texture/mob/snake_left.png"),
            right = love.graphics.newImage("texture/mob/snake_right.png")
        },
        hitBox_width = 20,
        hitBox_height = 110,
        hitBox_offset_x = -10,
        hitBox_offset_y = -50
    }

    snake.img = snake.imgs["up"]
    table.insert(mobs, snake)
end

MobBehaviors.snake = {
    update = function(m, dt)
		move_when_player_moves(m, player, dt)


        if isTouching(player, m) then
			player.reset = true
			player.death = player.death +1
            activateShaderEffect()
        end

        for _, other in ipairs(mobs) do
            if other.type == "piege" and not other.active and isTouching(m, other) then
                freeze(m, 2)
                other.active = true
                end
            end
        end,

	draw = function(m)
	    -- Calcul du centre de la hitbox pour placer le glow
	    local offsetX = m.hitBox_offset_x or 0
	    local offsetY = m.hitBox_offset_y or 0
	    local centerX = m.x + offsetX + (m.hitBox_width or 0) / 2
	    local centerY = m.y + offsetY + (m.hitBox_height or 0) / 2
	
	    -- Glow pulsant
	    local pulse = math.sin(love.timer.getTime() * 5) * 5 -- oscillation
	    draw_glow(centerX, centerY, 20 + pulse, 0, 1, 0, 0.08)
	
	    -- Dessin du mob normalement
	    draw_mob(m)
	end

}

-----------------SCIE----------------

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
            up = love.graphics.newImage("texture/mob/scie.png"),
            down = love.graphics.newImage("texture/mob/scie_pique.png"),
            left = love.graphics.newImage("texture/mob/scie_blanc.png"),
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

        if isTouching(player, m) then
			player.reset = true
			player.death = player.death +1
            activateShaderEffect()
        end
    end,

    draw = function(m)
        draw_mob(m, 50, m.img:getHeight() / 2)
    end
}


--------------------PIEGE------------------------------
function spawn_piege(x, y)
    local piege = {
        type = "piege",
        x = x, y = y,
        active = false,
        size = 0.3,
        speed = 0,
        float = false,
        dir = "up",
        img = nil,
        imgs = {
            up = love.graphics.newImage("texture/mob/piege.png"),
            active = love.graphics.newImage("texture/mob/piege_active.png")
        },
        hitBox_width = 20,
        hitBox_height = 20,
        hitBox_offset_x = -10,
        hitBox_offset_y = -10
    }
    table.insert(mobs, piege)
end

MobBehaviors.piege = {
    update = function(m, dt)
        static_mob(m)
        if isTouching(player, m) and not m.active then
            freeze(player, 2)
            m.active = true
        end
    end,

    draw = function(m)
        draw_mob(m)
    end
}




---------------------------------ANGE----------------------------

-- MobBehaviors.ange
function spawn_ange(x, y, speed, has_larme)
    local ange = {
        type = "ange",
        x = x, y = y,
        size = 0.2,
        speed = speed or 1,
        float = true,
        dir = "right",
        has_larme = has_larme or false,
        img = nil,
        imgs = {
            up = love.graphics.newImage("texture/mob/ange_up.png"),
            down = love.graphics.newImage("texture/mob/ange_down.png"),
            left = love.graphics.newImage("texture/mob/ange_left.png"),
            right = love.graphics.newImage("texture/mob/ange_right.png")
        },
        hitBox_width = 20,
        hitBox_height = 110,
        hitBox_offset_x = -10,
        hitBox_offset_y = -50
    }
    table.insert(mobs, ange)
end

MobBehaviors.ange = {
    update = function(m, dt)
        move_mob_towards_player(m, player, dt)


        if isTouching(player, m) then
			player.reset = true
			player.death = player.death +1
            activateShaderEffect()
        end

        for _, other in ipairs(mobs) do
            if other.type == "piege" and not other.active and isTouching(m, other) then
                freeze(m, 2)
                other.active = true

                if m.has_larme and not objet.larme_dropped then
                    objet.larme.x = m.x
                    objet.larme.y = m.y + 30
                    objet.larme_dropped = true
                end
            end
        end
    end,

	draw = function(m)
	    -- Calcul du centre de la hitbox pour placer le glow
	    local offsetX = m.hitBox_offset_x or 0
	    local offsetY = m.hitBox_offset_y or 0
	    local centerX = m.x + offsetX + (m.hitBox_width or 0) / 2
	    local centerY = m.y + offsetY + (m.hitBox_height or 0) / 2
	
	    -- Glow pulsant
	    local pulse = math.sin(love.timer.getTime() * 5) * 5 -- oscillation
	    draw_glow(centerX, centerY, 30 + pulse, 1.0, 0.9, 0.5, 0.15)
	
	    -- Dessin du mob normalement
	    draw_mob(m)
	end

}



------------------------------NEXT MOB-----------------------------------










function draw_mob(m, pivotX, pivotY)
    local img = m.img
    if not img then return end

    local w, h = img:getWidth(), img:getHeight()
    local ox = pivotX or w / 2
    local oy = pivotY or h / 2

    local float = 0
    if m.float then
        float = math.sin(love.timer.getTime() * 4) * 5
    end

    love.graphics.draw(
        img,
        m.x,
        m.y + float,
        m.rotation or 0,
        m.size,
        m.size,
        ox,
        oy
    )
end

------------------COMPORTEMENT DES MOBS ---------------------

--mouvement gauche droite
function move_mob(m, dt)
	if m.dir == "right" then
		m.x = m.x + m.speed
		if m.x > 700 then m.dir = "left" end
	elseif m.dir == "left" then
		m.x = m.x - m.speed
		if m.x < 100 then m.dir = "right" end
	end
	m.img = m.imgs[m.dir]
end

--mouvement qui suis le joueur
function move_mob_towards_player(m, player, dt)
    local dx = player.x - m.x
    local dy = player.y - m.y
    local angle = math.atan2(dy, dx)
    local speed = m.speed or 1

    m.x = m.x + math.cos(angle) * speed
    m.y = m.y + math.sin(angle) * speed

    -- Met à jour la direction (visuelle + logique)
    if math.abs(dx) > math.abs(dy) then
        m.dir = dx > 0 and "right" or "left"
    else
        m.dir = dy > 0 and "down" or "up"
    end

    -- Met à jour l’image si utile
    if m.imgs and m.imgs[m.dir] then
        m.img = m.imgs[m.dir]
    end
end



function static_mob(m)
	if m.active == false then
		m.img = m.imgs["up"]
	else
		m.img = m.imgs["active"]
	end
end


function turn_mob(m, dt)
    if not m.rotation then
        m.rotation = 0
    end
    m.rotation = m.rotation + math.rad(180) * dt -- 180°/s
end




--suis le jouer si il bouge
function move_when_player_moves(m, player, dt)
    if not player.has_moved then
        return -- Ne bouge pas si le joueur n’a pas bougé
    end

    local dx = player.x - m.x
    local dy = player.y - m.y
    local angle = math.atan2(dy, dx)
    local speed = m.speed or 1

    m.x = m.x + math.cos(angle) * speed
    m.y = m.y + math.sin(angle) * speed

    -- Met à jour la direction
    if math.abs(dx) > math.abs(dy) then
        m.dir = dx > 0 and "right" or "left"
    else
        m.dir = dy > 0 and "down" or "up"
    end

    -- Met à jour l’image
    if m.imgs and m.imgs[m.dir] then
        m.img = m.imgs[m.dir]
    end
end




----------------TOOLS FOR MOB-----------------------
---

function freeze(entity, duration)
	if not entity.is_frozen then
		entity.freeze_timer = duration
		entity.original_speed = entity.speed
		entity.speed = 0
		entity.is_frozen = true
	end
end

function update_freezes(dt)
	-- on parcourt uniquement ceux que tu veux (player et mobs)
	local all = { player }
	for _, m in ipairs(mobs) do table.insert(all, m) end


	for _, entity in ipairs(all) do
		if entity.is_frozen then
			entity.freeze_timer = entity.freeze_timer - dt
			if entity.freeze_timer <= 0 then
				entity.speed = entity.original_speed or 1.5
				entity.is_frozen = false
			end
		end
	end
end

