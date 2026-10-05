local die=require 'mobs.shared.infernal_contact'
function spawn_imp(x,y,speed,elite)
    mobs[#mobs+1]={type='imp',x=x,y=y,speed=speed,charge=1.5,dir='down',elite=elite,hitBox_width=30,hitBox_height=36,hitBox_offset_x=-15,hitBox_offset_y=-18}
end
MobBehaviors.imp={
    update=function(m,dt)
        for _,trap in ipairs(mobs) do
            if trap.type=='piege' and not trap.active and isTouching(m,trap) then
                freeze(m,2); trap.active=true
                if m.has_larme and not objet.larme_dropped then
                    objet.larme.x=m.x-15; objet.larme.y=m.y+25; objet.larme_dropped=true
                end
            end
        end
        if m.is_frozen then return end
        m.charge=m.charge-dt
        local dx,dy=player.x+15-m.x,player.y+12-m.y
        local a=math.atan2(dy,dx); m.dir=Art.direction(dx,dy,m.dir)
        local speed=m.speed
        if m.charge<0 then speed=speed*2.1 end
        if m.charge < -3 then m.charge=2.0 end
        Arena.navigate(m,player.x+15,player.y+12,speed,dt)
        if isTouching(player,m) then die() end
    end,
    draw=function(m)
        love.graphics.setColor(1,m.charge<0 and .7 or 1,1)
        Art.drawFacing('imp',m.dir,m.x,m.y,m.elite and 94 or 63); love.graphics.setColor(1,1,1)
    end
}
