walls_6 = {
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


function draw_level_6()

	-----------BACKGROUND-------------
--	love.graphics.setColor(255,0,0)
	draw_background_1()
	love.graphics.setColor(1,1,1)
	-----------WALL-------------------
	draw_wall_1()
	-----------OBJECT-----------------
	
	draw_objet_6()
	take_objet(objet.larme)
	
	-----------MOB--------------------
	
	
end

function mob_lv6()
	spawn_snake(110, 560, 5)
	spawn_snake(600, 430, 5)
	spawn_snake(300, 370, 5)
	spawn_snake(200, 210, 5)
--	spawn_ange(200, 200)
--	spaw_scie(200, 400, -1, 1, "left")

--	155
--	135
end

function draw_objet_6()
	if not objet or not objet.larme or not objet.larme.x or not objet.larme.y then
		return
	end

	-- aureoles
	love.graphics.draw(objet.aureole.img, 30, 105, 0, objet.aureole.size)

	local floatOffset = math.sin(larme_float_timer * 2) * 5
	draw_shadow(10, 10, objet.larme.x + 17, objet.larme.y + 43 + floatOffset)
	love.graphics.draw(particleSystem, objet.larme.x + 16, objet.larme.y + 25 + floatOffset)
	love.graphics.draw(objet.larme.img, objet.larme.x, objet.larme.y + floatOffset, 0, objet.larme.size)


end
