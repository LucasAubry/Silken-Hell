local mobImage=require 'mobs.shared.images'
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
            up = mobImage("texture/mob/ange_up.png"),
            down = mobImage("texture/mob/ange_down.png"),
            left = mobImage("texture/mob/ange_left.png"),
            right = mobImage("texture/mob/ange_right.png")
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


        if isTouching(player, m) and not player.reset then
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
