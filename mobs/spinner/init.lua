local die=require 'mobs.shared.infernal_contact'
function spawn_spinner(x,y,speed)
    mobs[#mobs+1]={type='spinner',x=x,y=y,speed=speed,rotation=(x+y)*.017,
        hitBox_width=40,hitBox_height=40,hitBox_offset_x=-20,hitBox_offset_y=-20}
end
function setup_spinner(m)
    local angle=(m.x+m.y)*.017
    m.vx=math.cos(angle); m.vy=math.sin(angle)
end
MobBehaviors.spinner={
    update=function(m,dt)
        m.rotation=m.rotation+dt*8
        local hitX,hitY=Arena.move(m,m.vx*m.speed*dt,m.vy*m.speed*dt)
        if hitX then m.vx=-m.vx end; if hitY then m.vy=-m.vy end
        m.dir=Art.direction(math.cos(m.rotation),math.sin(m.rotation))
        if isTouching(player,m) then die() end
    end,
    draw=function(m)
        love.graphics.setColor(1,1,1); Art.drawFacing('serpent',m.dir or 'down',m.x,m.y,58)
    end
}
