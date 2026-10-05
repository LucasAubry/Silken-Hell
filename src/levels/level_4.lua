walls_4 = {
--left
   {x = 0, y = 35, w = 50, h = 150},
   {x = 0, y = 255, w = 50, h = 150},
   {x = 0, y = 457, w = 50, h = 150},

   {x = -30, y = 0, w = 100, h = 50},
   {x = -30, y = 215, w = 100, h = 50},
   {x = -30, y = 435, w = 100, h = 50},

   {x = -40, y = 390, w = 100, h = 50},
   {x = -40, y = 175, w = 100, h = 50},
   {x = -40, y = 390, w = 100, h = 50},

--right
   {x = 745, y = 35, w = 50, h = 150},
   {x = 745, y = 255, w = 50, h = 150},
   {x = 745, y = 475, w = 50, h = 150},

  {x = 725, y = 0, w = 100, h = 50},
  {x = 725, y = 215, w = 100, h = 50},
  {x = 725, y = 435, w = 100, h = 50},

  {x = 735, y = 175, w = 100, h = 50},
  {x = 735, y = 390, w = 100, h = 50},
  {x = 735, y = 390, w = 100, h = 50},
 --up and bot
  {x = -15, y = -40, w = 800, h = 50},
  {x = -15, y = 590, w = 800, h = 50},
}


function draw_level_4()

	-----------BACKGROUND-------------
	draw_background_1()
	-----------WALL-------------------
	draw_wall_1()
	-----------OBJECT-----------------
	
	draw_objet_4()
	take_objet(objet.larme)
	
	-----------MOB--------------------
	
	
end

function mob_lv4()
--	spawn_piege(405, 230)
--	spawn_piege(405, 355)
--	spawn_piege(335, 300)
	spawn_piege(413, 165)
	spawn_piege(625, 380)
	spawn_piege(205, 360)


	spawn_scie(590, 255, 1, 3, "left")
	spawn_scie(465, 450, -1, 1, "left")

	spawn_ange(505, 230)
	spawn_ange(310, 135)
	spawn_ange(300, 525)
end


		--spawn_scie(200, 200, -1, 3, "up")
		--spawn_scie(600, 300, 1, 2, "left")

        --spawn_piege(100, 100)
        --spawn_piege(600, 400)
        --spawn_ange(300, 300)
	

function draw_objet_4()
	if not objet or not objet.larme or not objet.larme.x or not objet.larme.y then
		return
	end

	-- aureoles
	love.graphics.draw(objet.aureole.img, 353, 80, 0, objet.aureole.size)
	love.graphics.draw(objet.aureole.img, 625, 285, 0, objet.aureole.size)
	love.graphics.draw(objet.aureole.img, 60, 285, 0, objet.aureole.size)
	love.graphics.draw(objet.aureole.img, 353, 500, 0, objet.aureole.size)

	love.graphics.draw(objet.aureole.img, 530, 430, 0, objet.aureole.size)
	love.graphics.draw(objet.aureole.img, 160, 430, 0, objet.aureole.size)
	love.graphics.draw(objet.aureole.img, 530, 140, 0, objet.aureole.size)
	love.graphics.draw(objet.aureole.img, 160, 140, 0, objet.aureole.size)

	local floatOffset = math.sin(larme_float_timer * 2) * 5
	draw_shadow(10, 10, objet.larme.x + 17, objet.larme.y + 43 + floatOffset)
	love.graphics.draw(particleSystem, objet.larme.x + 16, objet.larme.y + 25 + floatOffset)
	love.graphics.draw(objet.larme.img, objet.larme.x, objet.larme.y + floatOffset, 0, objet.larme.size)


end
