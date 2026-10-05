function draw_mob(m, pivotX, pivotY)
    if require('paradise_ink').mob(m) then return end
    local img = m.img
    if not img then return end

    local w, h = img:getWidth(), img:getHeight()
    local ox = pivotX or w / 2
    local oy = pivotY or h / 2

    local float = 0
    if m.float then
        float = math.sin((m.floatTime or love.timer.getTime()) * 4) * 5
    end

    Art.shadow(img,m.x,m.y+float,m.rotation or 0,m.size,m.size,ox,oy)
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
function update_mob_float(m, dt)
    if m.float and not m.is_frozen and not m.tunnelTravel and not m.abyssHeld then
        m.floatTime=(m.floatTime or 0)+dt
    end
end

function move_mob_towards_player(m, player, dt, speedScale)
    if m.is_frozen then return end
    local x,y=m.x,m.y
    Arena.navigate(m,player.x+15,player.y+12,(m.speed or 1)*60*(speedScale or 1),dt)
    local dx,dy=m.x-x,m.y-y
    if dx~=0 or dy~=0 then
        -- Both pursuers face their real path, including slides along walls.
        m.dir=Art.direction(dx,dy,m.dir)
        if m.imgs and m.imgs[m.dir] then m.img=m.imgs[m.dir] end
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
    if player.has_moved then move_mob_towards_player(m, player, dt) end
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
