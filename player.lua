function load_player()
	player = {}
	player.level = 1
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
    draw_shadow(22,10,player.x+15,player.y+27)
    if (player.venom or 0)>0 then
        love.graphics.setColor(.24,1,.14,.2+.1*math.sin(larme_float_timer*10))
        love.graphics.ellipse('fill',player.x+15,player.y+14,34,22)
        love.graphics.setColor(.42,1,.32)
    else love.graphics.setColor(1,1,1) end
    Characters.draw(player.x+15,player.y+8,62,direction)
    love.graphics.setColor(1,1,1)
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
