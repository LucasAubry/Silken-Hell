walls_5 = {
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


function draw_level_5()

	-----------BACKGROUND-------------
	draw_background_1()
	-----------WALL-------------------
	draw_wall_1()
	-----------OBJECT-----------------
	
	draw_objet_5()
	take_objet(objet.larme)
	
	-----------MOB--------------------
	
	
end

function mob_lv5()

	spawn_piege(655, 70)
	spawn_piege(400, 400)
	spawn_ange(100, 500, 2)
	spawn_ange(400, 100, 3, true)
	spawn_ange(700, 500, 2)

end



		--spawn_scie(200, 200, -1, 3, "up")
		--spawn_scie(400, 400, 1, 7, "down")
		--spawn_scie(600, 300, 1, 2, "left")

        --spawn_piege(100, 100)
        --spawn_piege(600, 400)
        --spawn_ange(300, 300)


--	spawn_piege(500, 300)
--	spawn_ange(400, 400)
--	spawn_ange(200, 200)



function draw_objet_5()
	if not objet or not objet.larme or not objet.larme.x or not objet.larme.y then
		return
	end


	local floatOffset = math.sin(larme_float_timer * 2) * 5
	draw_shadow(10, 10, objet.larme.x + 17, objet.larme.y + 43 + floatOffset)
	love.graphics.draw(particleSystem, objet.larme.x + 16, objet.larme.y + 25 + floatOffset)
	love.graphics.draw(objet.larme.img, objet.larme.x, objet.larme.y + floatOffset, 0, objet.larme.size)


end

