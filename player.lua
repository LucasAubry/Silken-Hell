function load_player()
	player = {}
	player.level = 1
	player.death = 0
	player.x = 0--init dans levle
	player.y = 0--idem
	player.size = 0.14
	player.speed = 1
	player.has_moved = true
	player.last_mouve = "player.y+"
	player.img_up = love.graphics.newImage("texture/spider_up.png")
	player.img_down = love.graphics.newImage("texture/spider_down.png")
	player.img_left = love.graphics.newImage("texture/spider_left.png")
	player.img_right = love.graphics.newImage("texture/spider_right.png")
	player.hitBox_width = 60
	player.hitBox_height = 30
	player.hitBox_offset_x = 5
	player.hitBox_offset_y = 10
	player.reset = false

end


function draw_player(direction)
    if player.abyssHeld then
        local s=player.abyssHeld.swallowed; local scale=math.max(0,1-(s and s.time or 0)/.25)
        love.graphics.setColor(.5,.9,1,scale); Characters.draw(player.x+15,player.y+8,62*scale,direction)
        love.graphics.setColor(1,1,1); return
    end
    if player.tunnelTravel then
        local scale,dy=Realms.travelPose(player); love.graphics.setColor(1,1,1,scale)
        Characters.draw(player.x+15,player.y+8+dy,62*scale,direction)
        love.graphics.setColor(1,1,1); return
    end
    if player.whirl then
        local g=love.graphics; g.push(); g.translate(player.x+15,player.y+12); g.rotate(Realms.clock*18)
        g.setColor(1,1,1); Characters.draw(0,0,62,direction); g.pop(); return
    end
    if player.falling then
        local scale=math.max(.05,(player.fallTimer or .32)/.32)
        love.graphics.setColor(.45,.55,.7,scale)
        Characters.draw(player.x+15,player.y+8+(1-scale)*20,62*scale,direction)
        love.graphics.setColor(1,1,1); return
    end
    draw_shadow(22,10,player.x+15,player.y+27)
    if (player.venom or 0)>0 then
        love.graphics.setColor(.24,1,.14,.2+.1*math.sin(larme_float_timer*10))
        love.graphics.ellipse('fill',player.x+15,player.y+14,34,22)
        love.graphics.setColor(.42,1,.32)
    else love.graphics.setColor(1,1,1) end
    Characters.draw(player.x+15,player.y+8,62,direction)
    love.graphics.setColor(1,1,1)
end

return player
