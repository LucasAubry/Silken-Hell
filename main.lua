require "player"
require "world"
require "mob"
require "objet"
require "hit_box"
require "level"
require "levels/level_1"
require "levels/level_2"

player = require("player")

function love.load()
    font_demon = love.graphics.newFont("police.ttf", 40)
	particles = {}
	larme_float_timer = 0
	load_level()
 	load_world()
	load_player()
	load_mob()
	load_objet()
	load_hud()
	load_particles()

	reset_level()

end

local direction = "down"
function love.draw()
	print("X", x)
	print("Y", y)

 	draw_level()
	draw_player(direction)

	draw_hud()
--	draw_hit_box()--debug



	love.graphics.setColor(1, 1, 1, 1)

end

timer = 0
function love.update(dt)
	mouve()
	particleSystem:update(dt)
--	take_objet()
	larme_float_timer = larme_float_timer + dt
--	print("player X", player.x)
--	print("player Y", player.y)
	timer = timer + dt
	select_tp_larme(dt)



end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end




x = 0
y = 0
function mouve()
	local dx, dy = 0, 0

	if love.keyboard.isDown("right") then
		x = x + 5
		dx = 5
		player.last_mouve = "player.x+"
		direction = "right"
	elseif love.keyboard.isDown("left") then
		x = x -5
		dx = -5
		player.last_mouve = "player.x-"
		direction = "left"
	end

	if love.keyboard.isDown("up") then
		y = y -5
		dy = -5
		player.last_mouve = "player.y-"
		direction = "up"
	elseif love.keyboard.isDown("down") then
		y = y + 5
		dy = 5
		player.last_mouve = "player.y+"
		direction = "down"
	end

	local newX = player.x + dx * player.speed
	local newY = player.y + dy * player.speed

	if not willCollide(newX, newY) then
		player.x = newX
		player.y = newY
	end

	if love.keyboard.isDown("space") then
		local dashX, dashY = 0, 0
		direction = "dash"
		if player.last_mouve == "player.x+" then dashX = 10 end
		if player.last_mouve == "player.x-" then dashX = -10 end
		if player.last_mouve == "player.y+" then dashY = 10 end
		if player.last_mouve == "player.y-" then dashY = -10 end

		local dashNewX = player.x + dashX
		local dashNewY = player.y + dashY
		if not willCollide(dashNewX, dashNewY) then
			player.x = dashNewX
			player.y = dashNewY
			x = x + dashX
			y = y + dashY
		end
	end
end

