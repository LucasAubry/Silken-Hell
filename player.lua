function load_player()
	player = {}
	player.level = 5
	player.x = 0--init dans levle
	player.y = 0--idem
	player.size = 0.14
	player.speed = 1
	player.last_mouve = "player.y+"
	player.img_up = love.graphics.newImage("texture/spider_up.png")
	player.img_down = love.graphics.newImage("texture/spider_down.png")
	player.img_left = love.graphics.newImage("texture/spider_left.png")
	player.img_right = love.graphics.newImage("texture/spider_right.png")
	player.hitBox_width = 60
	player.hitBox_height = 30
	player.hitBox_offset_x = 5
	player.hitBox_offset_y = 10

end

local direction = "down"

function draw_player(direction)
	draw_shadow(25, 20, player.x + 40, player.y + 40)

	if direction == "up" then
		image = player.img_up
	elseif direction == "down" then
		image = player.img_down
	elseif direction == "left" then
		image = player.img_left
	elseif direction == "right" then
		image = player.img_right
	elseif direction == "dash" then
		if player.last_mouve == "player.x+" then
			image = player.img_right
		elseif player.last_mouve == "player.x-" then
			image = player.img_left
		elseif player.last_mouve == "player.y+" then
			image = player.img_down
		elseif player.last_mouve == "player.y-" then
			image = player.img_up
		end
	end


	if image then
		love.graphics.draw(image, player.x, player.y, 0, player.size)
	end
end

function load_hud()
	hud = {}
	hud.time_cardant = love.graphics.newImage("texture/hud/time_cadrant.png")
	hud.cadrant_demon = love.graphics.newImage("texture/hud/cadrant_demon.png")
	hud.cadrant_demon2 = love.graphics.newImage("texture/hud/cadrant_demon2.png")
	hud.cadrant_croix = love.graphics.newImage("texture/hud/cadrant_croix.png")
	hud.cadrant_ange = love.graphics.newImage("texture/hud/cadrant_ange.png")
	hud.hud = love.graphics.newImage("texture/hud/hud.png")
end

function draw_hud()
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

    love.graphics.setColor(1, 0, 0)
    love.graphics.print(time_text, 340, 10)

    love.graphics.setColor(1, 1, 1)
end


return player
