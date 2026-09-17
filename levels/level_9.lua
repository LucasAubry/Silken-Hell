walls_9 = {
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


function draw_level_9()

	-----------BACKGROUND-------------
	draw_background_1()
	-----------WALL-------------------
	draw_wall_1()
	-----------OBJECT-----------------
	
	draw_objet_5()
	take_objet(objet.larme)
	
	-----------MOB--------------------
	
	
end

function mob_lv9()
    -- Final trial before the Merle: lure the carrier through two rotating lanes.
    spawn_ange(635,115,2.9,true)
    spawn_ange(150,440,2.2,false)
    spawn_snake(160,115,2.4)
    spawn_snake(630,455,2.2)
    spawn_scie(255,205,1,1.9,'down')
    spawn_scie(545,385,-1,2,'up')
    spawn_piege(400,105)
end
