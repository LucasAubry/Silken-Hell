-- main.lua

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
require "mob"
require "effect"

mobs = {}
larme_indexes = {}

just_loaded = true
local direction = "down"
local xx, yy = 0, 0

-- Shader effect control
local shaderTime = 0
local postProcessShader
local grainShader
local gameCanvas
local intermediateCanvas

shader_effect_timer = 0
shader_duration = 0.4

function activateShaderEffect()
    shader_effect_timer = shader_duration
end

function isShaderActive()
    return shader_effect_timer > 0
end

function load_shader()
    gameCanvas = love.graphics.newCanvas()
    intermediateCanvas = love.graphics.newCanvas()
    postProcessShader = love.graphics.newShader("hyper_demon_shader.glsl")
    grainShader = love.graphics.newShader("grain_shader.glsl")
end

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
	load_shader()
end

function mouve()
    local dx, dy = 0, 0

    if love.keyboard.isDown("right") then
        dx = 5
        xx = xx + 5
        player.last_mouve = "player.x+"
        direction = "right"
    elseif love.keyboard.isDown("left") then
        dx = -5
        xx = xx - 5
        player.last_mouve = "player.x-"
        direction = "left"
    end

    if love.keyboard.isDown("up") then
        dy = -5
        yy = yy - 5
        player.last_mouve = "player.y-"
        direction = "up"
    elseif love.keyboard.isDown("down") then
        dy = 5
        yy = yy + 5
        player.last_mouve = "player.y+"
        direction = "down"
    end

    local newX = player.x + dx * player.speed
    local newY = player.y + dy * player.speed

    if not willCollide(newX, newY) then
        player.x = newX
        player.y = newY
    end

	if love.keyboard.isDown("space") and player.speed > 0 then
	    local dashX, dashY = 0, 0
	    if player.last_mouve == "player.x+" then dashX = player.speed * 4 end
	    if player.last_mouve == "player.x-" then dashX = -player.speed * 4 end
	    if player.last_mouve == "player.y+" then dashY = player.speed * 4 end
	    if player.last_mouve == "player.y-" then dashY = -player.speed * 4 end
	
	    local dashNewX = player.x + dashX
	    local dashNewY = player.y + dashY
	
	    if not willCollide(dashNewX, dashNewY) then
	        -- ajoute un ghost juste avant de bouger
	        table.insert(ghosts, {
	            x = player.x,
	            y = player.y,
	            direction = direction,
	            alpha = 0.4,
	            time = 0
	        })
	
	        player.x = dashNewX
	        player.y = dashNewY
	    end
	end



    print("X:  ", xx)
    print("Y:  ", yy)
end

function love.update(dt)
	update_shadow_dash(dt)

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

    shaderTime = shaderTime + dt
    postProcessShader:send("time", shaderTime)
    postProcessShader:send("screen_size", {love.graphics.getWidth(), love.graphics.getHeight()})
    grainShader:send("time", shaderTime)
    grainShader:send("screen_size", {love.graphics.getWidth(), love.graphics.getHeight()})

    if shader_effect_timer > 0 then
        shader_effect_timer = shader_effect_timer - dt
    end
end

function love.draw()
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear()
    love.graphics.origin()

    draw_level()

    for _, mob in ipairs(mobs) do
        local behavior = MobBehaviors[mob.type]
        if behavior and behavior.draw then
            behavior.draw(mob)
        end
    end
	draw_shadow_dash()

    draw_player(direction)
    draw_hud()

   -- draw_hit_box()

    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", xx, yy, 10, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setCanvas()

    -- Appliquer shader de collision si actif vers intermediateCanvas
	-- Étape 1 : canvas intermédiaire avec shader post-process (si actif)
	love.graphics.setCanvas(intermediateCanvas)
	love.graphics.clear()
	if isShaderActive() then
	    love.graphics.setShader(postProcessShader)
	end
	love.graphics.draw(gameCanvas, 0, 0)
	love.graphics.setShader()
	love.graphics.setCanvas()
	
	-- Étape 2 : écran final avec shader de grain
	love.graphics.setShader(grainShader)
	love.graphics.draw(intermediateCanvas, 0, 0)
	love.graphics.setShader()

end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

