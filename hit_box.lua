--fonction pour metre a jours les hit box en fonction  du levle
Walls = walls_1
function update_walls_level()
	Walls = _G["walls_" .. tostring(player.level)] or {}
--_G cest la variable global en lua qui contien tout les variable global
end

function addWall(x, y, w, h)
    table.insert(Walls, {x = x, y = y, w = w, h = h})
end

function willCollide(newX, newY)
	local offsetX = player.hitBox_offset_x or 0
	local offsetY = player.hitBox_offset_y or 0

	for _, wall in ipairs(Walls) do
		if checkCollision(
			newX + offsetX, newY + offsetY,
			player.hitBox_width, player.hitBox_height,
			wall.x, wall.y, wall.w, wall.h
		) then
			return true
		end
	end
	return false
end



function checkCollision(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and
           bx < ax + aw and
           ay < by + bh and
           by < ay + ah
end


function isTouching(a, b)
	local ax = a.x + (a.hitBox_offset_x or 0)
	local ay = a.y + (a.hitBox_offset_y or 0)
	local bx = b.x + (b.hitBox_offset_x or 0)
	local by = b.y + (b.hitBox_offset_y or 0)

	return checkCollision(
		ax, ay, a.hitBox_width, a.hitBox_height,
		bx, by, b.hitBox_width, b.hitBox_height
	)
end



function draw_enemy_hitboxes()
	love.graphics.setColor(1, 0, 1, 0.5)

	for _, e in ipairs(mobs) do
		if e.hitBox_width and e.hitBox_height then
			local offsetX = e.hitBox_offset_x or 0
			local offsetY = e.hitBox_offset_y or 0
			love.graphics.rectangle("fill", e.x + offsetX, e.y + offsetY, e.hitBox_width, e.hitBox_height)
		end
	end

	love.graphics.setColor(1, 1, 1)
end


function draw_hit_box()
	-- murs
	love.graphics.setColor(1, 0, 0, 0.5)
	for _, wall in ipairs(Walls) do
		love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
	end

	-- joueur
	local offsetX = player.hitBox_offset_x or 0
	local offsetY = player.hitBox_offset_y or 0
	love.graphics.setColor(0, 0, 1, 0.5)
	love.graphics.rectangle("fill", player.x + offsetX, player.y + offsetY, player.hitBox_width, player.hitBox_height)

	-- larme
	if not objet.larme.taken then
		love.graphics.setColor(1, 1, 0, 0.5)
		love.graphics.rectangle("fill", objet.larme.x, objet.larme.y, objet.larme.hitBox_width, objet.larme.hitBox_height)
	end

	-- ennemis
	draw_enemy_hitboxes()

	love.graphics.setColor(1, 1, 1)
end

