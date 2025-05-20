-- FICHIER PRINCIPAL DU JEU : avec système de mobs refait et corrections intégrées

require "player"
require "world"
require "objet"
require "hit_box"
require "level"
require "levels/level_1"
require "levels/level_2"
require "levels/level_3"
require "levels/level_4"
require "levels/level_5"
require "levels/level_6"
require "levels/level_7"
require "levels/level_8"
require "levels/level_9"
require "levels/level_10"
require "mob" -- Assure que draw_mob est bien chargé

mobs = {}
larme_indexes = {}

just_loaded = true
local direction = "down"

function love.load()
    font_demon = love.graphics.newFont("police.ttf", 40)
    load_level()
    load_world()
    load_player()
    load_objet()
    load_mob()
    load_hud()
    load_particles()
    reset_level()
end

local direction = "down"
xx = 0
yy = 0
function mouve()
    local dx, dy = 0, 0

    if love.keyboard.isDown("right") then
        dx = 5
		xx = xx +5
        player.last_mouve = "player.x+"
        direction = "right"
    elseif love.keyboard.isDown("left") then
        dx = -5
		xx = xx -5
        player.last_mouve = "player.x-"
        direction = "left"
    end

    if love.keyboard.isDown("up") then
        dy = -5
		yy = yy -5
        player.last_mouve = "player.y-"
        direction = "up"
    elseif love.keyboard.isDown("down") then
        dy = 5
		yy = yy +5
        player.last_mouve = "player.y+"
        direction = "down"
    end

    local newX = player.x + dx * player.speed
    local newY = player.y + dy * player.speed

    if not willCollide(newX, newY) then
        player.x = newX
        player.y = newY
    end

    -- Dash
	if love.keyboard.isDown("space") and player.speed > 0 then
	    local dashX, dashY = 0, 0
	    if player.last_mouve == "player.x+" then dashX = player.speed * 4 end
	    if player.last_mouve == "player.x-" then dashX = -player.speed * 4 end
	    if player.last_mouve == "player.y+" then dashY = player.speed * 4 end
	    if player.last_mouve == "player.y-" then dashY = -player.speed * 4 end
	
	    local dashNewX = player.x + dashX
	    local dashNewY = player.y + dashY
	
	    if not willCollide(dashNewX, dashNewY) then
	        player.x = dashNewX
	        player.y = dashNewY
	    end
	end

print("X:  ", xx)
print("Y:  ", yy)
end


function love.update(dt)
    mouve()
    update_freezes(dt)
    particleSystem:update(dt)
    timer = timer + dt
    larme_float_timer = larme_float_timer + dt
	if player.level == 5 then
		update_larme_dos_ange()
	else
    	select_tp_larme(dt)
	end


	for _, mob in ipairs(mobs) do
		local behavior = MobBehaviors[mob.type]
	    if behavior and behavior.update then
       		behavior.update(mob, dt)
    	end
	end
end

function love.draw()
    draw_level()

	for _, mob in ipairs(mobs) do
	    local behavior = MobBehaviors[mob.type]
	    if behavior and behavior.draw then
	        behavior.draw(mob)
	    end
	end
    draw_player(direction)

--	draw_hit_box()

    draw_hud()
	love.graphics.setColor(255,0,0)
	love.graphics.rectangle("fill", xx, yy, 10, 10)
	love.graphics.setColor(1,1,1)
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end
