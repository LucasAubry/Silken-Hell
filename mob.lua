function load_mob()
	mob = {}
	Enemies = {} -- reset la liste des ennemis

	-- Ange
	mob.ange = {
		x = 0,
		y = 0,
		size = 0.2,
		speed = 1,
		float = true,
		dir = "right",
		img = nil,
		imgs = {
			up = love.graphics.newImage("texture/mob/ange_up.png"),
			down = love.graphics.newImage("texture/mob/ange_down.png"),
			left = love.graphics.newImage("texture/mob/ange_left.png"),
			right = love.graphics.newImage("texture/mob/ange_right.png")
		},
		hitBox_width = 40,
		hitBox_height = 120,
		hitBox_offset_x = 5,
		hitBox_offset_y = 15
	}
	table.insert(Enemies, mob.ange)

	-- Piège (immobile, mais hitbox quand même ?)
	mob.piege = {
		x = 100,
		y = 100,
		active = false,
		size = 0.3,
		speed = 0,
		float = false,
		dir = "up",
		img = nil,
		imgs = {
			up = love.graphics.newImage("texture/mob/piege.png"),
			active = love.graphics.newImage("texture/mob/piege_active.png"),
		},
		hitBox_width = 30,
		hitBox_height = 30,
		hitBox_offset_x = 15,
		hitBox_offset_y = 15
	}
	table.insert(Enemies, mob.piege)
end


--love.graphics.newImage("texture/mob/crane.png"),
--love.graphics.newImage("texture/mob/troll.png")
--love.graphics.newImage("texture/mob/pique.png"),

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
function move_mob_towards_player(m, target, dt)
	local dx = target.x - m.x
	local dy = target.y - m.y
	local dist = math.sqrt(dx * dx + dy * dy)

	if dist > 1 then
		-- Normalisation du vecteur direction
		local nx = dx / dist
		local ny = dy / dist

		-- Déplacement
		m.x = m.x + nx * m.speed
		m.y = m.y + ny * m.speed

		-- Direction principale pour choisir l'image
		if math.abs(dx) > math.abs(dy) then
			m.dir = dx > 0 and "right" or "left"
		else
			m.dir = dy > 0 and "down" or "up"
		end

		-- Mettre à jour l’image selon la direction
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




function draw_mob(enemy)
	if enemy and enemy.img and enemy.float then
		local float = math.sin(love.timer.getTime() * 4) * 5
		love.graphics.draw(enemy.img, enemy.x, enemy.y + float, 0, enemy.size)
	elseif enemy and enemy.img then
		love.graphics.draw(enemy.img, enemy.x, enemy.y, 0, enemy.size)
	end
end


function select_mob_level(dt)
	if player.level == 1 then
	elseif player.level == 2 then
		mob_level_2(dt)
	elseif player.level == 3 then
		mob_level_3(dt)
	elseif player.level == 4 then
		mob_level_4(dt)
	elseif player.level == 5 then
		mob_level_5(dt)
	elseif player.level == 6 then
		mob_level_6(dt)
	elseif player.level == 7 then
		mob_level_7(dt)
	elseif player.level == 8 then
		mob_level_8(dt)
	elseif player.level == 9 then
		mob_level_9(dt)
	elseif player.level == 10 then
		mob_level_10(dt)
	end
end

function mob_interaction(dt)
	if isTouching(mob.ange, mob.piege) and mob.piege.active == false then
		freeze(mob.ange, 2)
		mob.piege.active = true
	end
end


----------------TOOLS FOR MOB-----------------------

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
	local all = { player, mob.ange, mob.piege }

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

