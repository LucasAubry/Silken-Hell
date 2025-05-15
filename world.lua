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
	}
end
