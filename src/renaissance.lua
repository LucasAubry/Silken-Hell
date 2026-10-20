local N={active=false,eggs={}}
local function body(kind,x,y,size)
    local m={type=kind,x=x,y=y,age=0,dir='down',hitBox_width=size,hitBox_height=size,
        hitBox_offset_x=-size/2,hitBox_offset_y=-size/2}
    mobs[#mobs+1]=m
    return m
end
function N.reset()
    N.active=Campaign.world==3 and not App.historyPreview and App.singleLevel and not Secret.duel and not App.sessionLayout; N.eggs={}; N.clock=0
    if not N.active then return end
    N.remaining=2
    for i,p in ipairs({{.22,160},{.78,430}}) do
        N.eggs[i]={x=Arena.width*p[1]-15,y=p[2],brown=i==2}
    end
    N.syncEgg()
    N.follower=body('white_spider',player.x+15,player.y+68,24)

end
function N.syncEgg()
    for _,e in ipairs(N.eggs) do if not e.taken then
        objet.larme.x=e.x;objet.larme.y=e.y;objet.larme.taken=false;return
    end end
    objet.larme.taken=true
end
function N.collect()
    for _,e in ipairs(N.eggs) do
        if not e.taken and checkCollision(player.x,player.y,30,24,e.x,e.y,30,40) then
            e.taken=true;N.remaining=N.remaining-1;N.syncEgg();Profile.record('eggs')
            if N.remaining==0 then return true end
            Audio.play('pick')
        end
    end
    return false
end
function N.update(dt)
    if not N.active then return end
    N.clock=N.clock+dt
    for _,m in ipairs(mobs) do
        if m.type=='white_spider' then
            local dx,dy=player.x+15-m.x,player.y+12-m.y
            local d=math.sqrt(dx*dx+dy*dy)
            if d>48 then Arena.navigate(m,player.x+15-dx/d*46,player.y+12-dy/d*46,190,dt) end
        end
    end
end
-- All creatures and collectibles use authored transparent PNG sprites.
local function sprite(key,x,y,size,angle)
    local a=assert(Art.images['rebirth_'..key],key)
    local scale=size/math.max(a.w,a.h)
    local g=love.graphics
    g.draw(a.image,a.quad,x,y,angle or 0,scale,scale,a.w/2,a.h/2)
    require('servant_art').web(a,a.image,a.quad,x,y,angle or 0,scale,scale,a.w/2,a.h/2)
end
function N.drawSpider(m)
    local g=love.graphics;g.push('all');g.setColor(1,1,1)
    local angle=({down=0,up=math.pi,left=math.pi/2,right=-math.pi/2})[m.dir] or 0
    local moving=(player.x+15-m.x)^2+(player.y+12-m.y)^2>48^2
    sprite('white_spider',m.x,m.y,55,angle+(moving and math.sin(N.clock*14)*.025 or 0))
    g.pop()
end
function N.drawEggs()
    local g=love.graphics;g.push('all');g.setColor(1,1,1)
    for _,e in ipairs(N.eggs) do if not e.taken then
        sprite(e.brown and 'brown_egg' or 'white_egg',e.x+15,e.y+20+math.sin(N.clock*2)*3,38)
    end end
    g.setFont(UI.fonts.body);g.setColor(1,.96,.81);g.printf(require('localization').text('ŒUFS ')..(2-N.remaining)..' / 2',Arena.width/2-80,58,160,'center');g.pop()
end
function N.resize(ratio)
    if not N.active then return end
    for _,e in ipairs(N.eggs) do e.x=e.x*ratio end
    Arena.navigationVersion=Arena.navigationVersion+1;N.syncEgg()
end
MobBehaviors.white_spider={draw=N.drawSpider}
return N
