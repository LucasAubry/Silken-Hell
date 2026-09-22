local mobImage=require 'mobs.shared.images'
function spawn_piege(x, y)
    local piege = {
        type = "piege",
        x = x, y = y,
        active = false,
        size = 0.3,
        speed = 0,
        float = false,
        dir = "up",
        img = nil,
        imgs = {
            up = mobImage("texture/mob/piege.png"),
            active = mobImage("texture/mob/piege_active.png")
        },
        hitBox_width = 20,
        hitBox_height = 20,
        hitBox_offset_x = -10,
        hitBox_offset_y = -10
    }
    table.insert(mobs, piege)
end

MobBehaviors.piege = {
    update = function(m, dt)
        if m.active then
            m.rearm=(m.rearm or 0)+dt
            if m.rearm>=6 then m.active=false; m.rearm=0 end
        end
        static_mob(m)
        if isTouching(player, m) and not m.active and not player.reset then
            freeze(player, 2)
            m.active = true
        end
    end,

    draw = function(m)
        draw_mob(m)
    end
}
