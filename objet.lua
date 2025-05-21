function load_objet()
	objet = {}

	objet.larme = {
		img = love.graphics.newImage("texture/larme.png"),
		size = 0.15,
		x = 395,
		y = 70,
		hitBox_width = 30,
		hitBox_height = 40
	}
	objet.aureole = {
		img = love.graphics.newImage("texture/aureole.png"),
		size = 0.2,
		x = 600,
		y = 280,
	}
end

function draw_shadow(size_w, size_h, hotel_x, hotel_y)
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.ellipse("fill", hotel_x, hotel_y, size_w, size_h)
    love.graphics.setColor(1, 1, 1, 1)
end


function load_particles()
    local img = love.graphics.newImage("texture/particle_white.png")
    particleSystem = love.graphics.newParticleSystem(img, 100)

    particleSystem:setParticleLifetime(0.5, 1.2)  -- durée de vie
    particleSystem:setEmissionRate(100)            -- nombre de particules par seconde
    particleSystem:setSizeVariation(1)            -- variation de taille
    particleSystem:setSizes(0.5, 1)              -- taille initiale > finale
    particleSystem:setLinearAcceleration(-30, -30, 30, 30)
	particleSystem:setColors(
	    1, 0, 0, 0,    -- 🔴
	    1, 0.5, 0, 1,  -- 🟠
	    1, 1, 0, 1     -- 🟡
	)

    particleSystem:setSpread(math.rad(360))
    particleSystem:setSpeed(20, 50)
    particleSystem:start()
end



function take_objet(obj)

	local px = player.x
	local py = player.y
	local pw = player.hitBox_width
	local ph = player.hitBox_height

	local ox = obj.x
	local oy = obj.y
	local ow = obj.hitBox_width
	local oh = obj.hitBox_height

	if checkCollision(px, py, pw, ph, ox, oy, ow, oh) then
		player.level = player.level + 1
		just_loaded = true
		print("Objet ramassé !")
	end
end

shader_effect_timer = 0
shader_duration = 0.3



function activateShaderEffect()
    shader_effect_timer = shader_duration
end

function isShaderActive()
    return shader_effect_timer > 0
end

