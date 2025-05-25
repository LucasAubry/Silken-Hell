-- effect.lua

ghosts = {}
ghost_timer = 0

cameraShakeX = 0
cameraShakeY = 0
shake_timer = 0

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

function update_camera_shake(dt)
    if shake_timer > 0 then
        shake_timer = shake_timer - dt
        cameraShakeX = love.math.random(-3, 3)
        cameraShakeY = love.math.random(-3, 3)
    else
        cameraShakeX = 0
        cameraShakeY = 0
    end
end

function trigger_camera_shake(duration)
    shake_timer = duration or 0.2
end

--    trigger_camera_shake(0.15) // pour faire trambler la camera



function draw_glow(x, y, radius, r, g, b, strength)
    love.graphics.setColor(r, g, b, strength or 0.1)
    for i = 1, 4 do
        love.graphics.circle("fill", x, y, radius + i * 3)
    end
    love.graphics.setColor(1, 1, 1)
end


function add_ghost(dt)
    ghost_timer = ghost_timer or 0
    ghost_timer = ghost_timer + dt
    if ghost_timer >= 0.05 then
        table.insert(ghosts, {
            x = player.x,
            y = player.y,
            direction = direction,
            alpha = 0.4,
            time = 0
        })
        ghost_timer = 0
    end
end
