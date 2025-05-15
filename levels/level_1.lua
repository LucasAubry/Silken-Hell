walls_1 = {
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

function draw_level_1()

-----------BACKGROUND-------------
 draw_background_1()

-----------WALL-------------------
draw_wall_1()

-----------OBJECT-----------------
draw_objet_1()
take_objet(objet.larme)
-----------MOB--------------------
-- draw_mob_1()

end



























function draw_background_1()
    local img = world.background_lv
    local imgW = img:getWidth()
    local imgH = img:getHeight()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    local scaleX = screenW / imgW
    local scaleY = screenH / imgH
    local scale = math.max(scaleX, scaleY)

    local finalW = imgW * scale
    local finalH = imgH * scale

    local offsetX = (screenW - finalW) / 2
    local offsetY = (screenH - finalH) / 2

    love.graphics.draw(img, offsetX, offsetY, 0, scale, scale)
end


function draw_wall_1()



    love.graphics.draw(world.lv_1.wall, -140, -565, 0, 0.7)
    love.graphics.draw(world.lv_1.wall, -230, 474, 0, 1)


    love.graphics.draw(world.lv_1.poto_2, -50, -25, 0, 0.5)
    love.graphics.draw(world.lv_1.poto_2, -50, 190, 0, 0.5)
    love.graphics.draw(world.lv_1.poto_2, -50, 408, 0, 0.5)

    love.graphics.draw(world.lv_1.poto_2, 720, -25, 0, 0.5)
    love.graphics.draw(world.lv_1.poto_2, 720, 190, 0, 0.5)
    love.graphics.draw(world.lv_1.poto_2, 720, 408, 0, 0.5)

 --   love.graphics.draw(world.lv_1.wall, -330, 400, 0, 1)
  --  love.graphics.draw(world.lv_1.wall, x, y, 0, 1)
 --  love.graphics.draw(world.lv_1.muret, x, y, 0, 0.5)

end

function draw_objet_1()
	love.graphics.draw(objet.aureole.img, x, y, 0, objet.aureole.size)

	local floatOffset = math.sin(larme_float_timer * 2) * 5
	draw_shadow(10, 10, objet.larme.x + 17, objet.larme.y + 43 + floatOffset)
	love.graphics.draw(particleSystem, objet.larme.x + 16, objet.larme.y + 25 + floatOffset)
	love.graphics.draw(objet.larme.img, objet.larme.x, objet.larme.y + floatOffset, 0, objet.larme.size)

end

function draw_mob_1()
--	love.graphics.draw(mob.pique_img, x, y, 0 , 0.2)
--	love.graphics.draw(mob.piege_img, x, y, 0 , 0.2)

--	love.graphics.draw(mob.ange_up_img, x, y, 0 , 0.2)
--	love.graphics.draw(mob.ange_down_img, x, y, 0 , 0.2)
--	love.graphics.draw(mob.ange_left_img, x, y, 0 , 0.2)
--	love.graphics.draw(mob.ange_right_img, x, y, 0 , 0.2)



--	love.graphics.draw(mob.crane_img, x, y, 0 , 0.2)
--	love.graphics.draw(mob.troll_img, x, y, 0 , 0.2)
end
