function load_world()
    world = {}
    world.background_lv = love.graphics.newImage("texture/background_paradie.png")

	world.lv_1 = {
		poto_1 = love.graphics.newImage("texture/poto_1.png"),
		poto_2 = love.graphics.newImage("texture/poto_2.png"),
		poto_3 = love.graphics.newImage("texture/poto_3.png"),
		poto_hori = love.graphics.newImage("texture/poto_hori.png"),
		wall = love.graphics.newImage("texture/wall.png"),
	--	muret = love.graphics.newImage("texture/muret.png")
		ltd = love.graphics.newImage("texture/hud/ltd.png"),
		cadran_time = love.graphics.newImage("texture/hud/cadran_time.png"),
		cadran_litle = love.graphics.newImage("texture/hud/cadran_litle.png"),

		death = love.graphics.newImage("texture/hud/death.png"),
		time = love.graphics.newImage("texture/hud/time.png"),
		level = love.graphics.newImage("texture/hud/level.png")
	}
end




function set_time_print()
--    love.graphics.draw(hud.cadrant_ange, 320, 480, 0, 0.35)
    local minutes = math.floor(timer / 60)
    local seconds = math.floor(timer % 60)
    local milliseconds = math.floor((timer % 1) * 1000)

    local time_text = string.format("%02d:%02d:%03d", minutes, seconds, milliseconds)


	love.graphics.setFont(font_demon)
    -- Ombre/épaisseur simulée
    love.graphics.setColor(0.2, 0, 0)
    for dx = -1, 1 do
        for dy = -1, 1 do
            love.graphics.print(time_text, 340 + dx, 10 + dy)
        end
    end
	return time_text
end

function set_level_contour()
    love.graphics.setColor(0.2, 0, 0)
    for dx = -1, 1 do
        for dy = -1, 1 do
            love.graphics.print(player.level, 190 + dx, 25 + dy)
        end
    end
end

function set_death_contour()
    love.graphics.setColor(0.2, 0, 0)
    for dx = -1, 1 do
        for dy = -1, 1 do
            love.graphics.print(player.death, 600 + dx, 10 + dy)
        end
    end
end

function draw_hud()

    love.graphics.setColor(1, 1, 1)
--	love.graphics.draw(world.lv_1.ltd, xx, yy, 0, 0.3)

love.graphics.setColor(1, 1, 1, 0.8)
love.graphics.draw(world.lv_1.cadran_litle, 120, -20, 0, 0.26)
love.graphics.draw(world.lv_1.cadran_time, 330, -20, 0, 0.26)
love.graphics.draw(world.lv_1.cadran_litle, 530, -20, 0, 0.26)

love.graphics.setColor(1, 1, 1, 0.3)
love.graphics.draw(world.lv_1.death, 540, -15, 0, 0.23)
love.graphics.draw(world.lv_1.time, 330, -17, 0, 0.26)
love.graphics.draw(world.lv_1.level, 125, -30, 0, 0.26)
love.graphics.setColor(1, 1, 1, 1)

	
	local time_text = set_time_print()
	set_level_contour()
	set_death_contour()


    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.print(player.level, 190, 25)
    love.graphics.print(time_text, 340, 10)
    love.graphics.print(player.death, 600, 10)
	
end
