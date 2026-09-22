local mobImage=require 'mobs.shared.images'
function spawn_boss(x, y, speed)
    local boss = {
        type = "boss",
        x = x, y = y,
        size = 0.3,
        speed = speed,
        float = true,
        dir = "up",
        img = nil,
        imgs = {
            up = mobImage("texture/mob/boss_up.png"),
            down = mobImage("texture/mob/boss_down.png"),
            left = mobImage("texture/mob/boss_left.png"),
            right = mobImage("texture/mob/boss_right.png"),
        },
        hitBox_width = 40,
        hitBox_height = 40,
        offset_fix_x = 0,
		offset_fix_y = 0
    }
    boss.img = boss.imgs.up
    table.insert(mobs, boss)
end

MobBehaviors.boss = {
    update = function(m, dt)
        move_mob_towards_player(m, player, dt)
        if isTouching(player, m) and not m.active and not player.reset then
		player.reset = true -- die (le reset et dans update pour eviter les bug
			player.death = player.death +1
            activateShaderEffect()
            m.active = true
        end
    end,

    draw = function(m)
        draw_mob(m)
    end
}
