-- effect.lua

ghosts = {}
ghost_timer = 0

function draw_shadow_dash()
    for _, g in ipairs(ghosts) do
        love.graphics.setColor(1, 1, 1, g.alpha)
	--	love.graphics.setColor(1, 0, 0, 1)
        if g.direction == "up" then
            love.graphics.draw(player.img_up, g.x, g.y, 0, player.size)
        elseif g.direction == "down" then
            love.graphics.draw(player.img_down, g.x, g.y, 0, player.size)
        elseif g.direction == "left" then
            love.graphics.draw(player.img_left, g.x, g.y, 0, player.size)
        elseif g.direction == "right" then
            love.graphics.draw(player.img_right, g.x, g.y, 0, player.size)
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function update_shadow_dash(dt)
    for i = #ghosts, 1, -1 do
        local g = ghosts[i]
        g.time = g.time + dt
        g.alpha = g.alpha - dt * 2
        if g.alpha <= 0 then
            table.remove(ghosts, i)
        end
    end
end

