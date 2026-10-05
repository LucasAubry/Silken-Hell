walls_2 = {
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


function draw_level_2()

	-----------BACKGROUND-------------
	draw_background_1()
	-----------WALL-------------------
	draw_wall_1()
	-----------OBJECT-----------------
	
	draw_objet_1()
	take_objet(objet.larme)
	
	-----------MOB--------------------
	
	
end

function mob_lv2()
	spawn_piege(520, 175)
	spawn_piege(260, 425)

	spawn_ange(405, 140)
	spawn_ange(240, 310)
	spawn_ange(630, 310)
	spawn_ange(325, 565)
	spawn_ange(95, 65)
end
		--spawn_scie(200, 200, -1, 3, "up")
		--spawn_scie(400, 400, 1, 7, "down")
		--spawn_scie(600, 300, 1, 2, "left")

        --spawn_piege(100, 100)
        --spawn_piege(600, 400)
        --spawn_ange(300, 300)


