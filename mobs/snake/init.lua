local mobImage=require 'mobs.shared.images'
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
            up = mobImage("texture/mob/snake_up.png"),
            down = mobImage("texture/mob/snake_down.png"),
            left = mobImage("texture/mob/snake_left.png"),
            right = mobImage("texture/mob/snake_right.png")
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


        if isTouching(player, m) and not player.reset then
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
