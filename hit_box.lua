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
	for _, wall in ipairs(Walls) do
		if checkCollision(newX +8, newY +5, player.hitBox_width, player.hitBox_height, wall.x, wall.y, wall.w, wall.h) then
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

function draw_hit_box()
    -- Hitbox des murs
    love.graphics.setColor(1, 0, 0, 0.5)
    for _, wall in ipairs(Walls) do
        love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
    end

    -- Hitbox du joueur
    love.graphics.setColor(0, 0, 1, 0.5)
    love.graphics.rectangle("fill", player.x + 8, player.y + 5, player.hitBox_width, player.hitBox_height)

    -- Hitbox de la larme (si elle est encore visible)
    if not objet.larme.taken then
        love.graphics.setColor(1, 1, 0, 0.5) -- jaune semi-transparent
        love.graphics.rectangle("fill", objet.larme.x, objet.larme.y, objet.larme.hitBox_width, objet.larme.hitBox_height)
    end

    -- Réinitialisation de la couleur
    love.graphics.setColor(1, 1, 1)
end

