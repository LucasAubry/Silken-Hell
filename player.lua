function load_player()
	player = {}
	player.level = 7
	player.death = 0
	player.x = 0--init dans levle
	player.y = 0--idem
	player.size = 0.14
	player.speed = 1
	player.has_moved = true
	player.last_mouve = "player.y+"
	player.img_up = love.graphics.newImage("texture/spider_up.png")
	player.img_down = love.graphics.newImage("texture/spider_down.png")
	player.img_left = love.graphics.newImage("texture/spider_left.png")
	player.img_right = love.graphics.newImage("texture/spider_right.png")
	player.hitBox_width = 60
	player.hitBox_height = 30
	player.hitBox_offset_x = 5
	player.hitBox_offset_y = 10
	player.reset = false

end


function draw_player(direction)
	draw_shadow(25, 20, player.x + 40, player.y + 40)
	local image = nil

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




return player
