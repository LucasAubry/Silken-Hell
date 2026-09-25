local N={active=false,soil={},blasts={},eggs={}}
local function body(kind,x,y,size)
    local m={type=kind,x=x,y=y,age=0,dir='down',hitBox_width=size,hitBox_height=size,
        hitBox_offset_x=-size/2,hitBox_offset_y=-size/2}
    mobs[#mobs+1]=m
    return m
end
function N.bush(x,y,mini)
    local size=mini and 16 or 32
    x,y=Arena.clearSpot(x-size/2,y-size/2,size,size)
    local m=body('rebirth_bush',x+size/2,y+size/2,size)
    m.mini=mini; m.fuse=mini and 2.2 or 4; m.speed=mini and 145 or 78+player.level*3
    return m
end
function N.reset()
    N.active=Campaign.world==3; N.soil={}; N.blasts={}; N.eggs={}; N.clock=0; N.spawnClock=8
    if not N.active then return end
    N.remaining=2
    for i,p in ipairs({{.22,160},{.78,430}}) do
        N.eggs[i]={x=Arena.width*p[1]-15,y=p[2],brown=i==2}
    end
    N.syncEgg()
    N.follower=body('white_spider',player.x+15,player.y+68,24)
    N.tree=body('walking_tree',Arena.width*.66,145,40)
    N.tree.vx=-.8;N.tree.vy=.6;N.tree.trail=0
    N.bush(Arena.width*.18,440,false)
    if player.level>=3 then N.bush(Arena.width*.84,110,false) end
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
local function removeSoil(i)
    local s=N.soil[i]
    for j=#Arena.walls,1,-1 do if Arena.walls[j]==s then table.remove(Arena.walls,j);break end end
    table.remove(N.soil,i);Arena.navigationVersion=Arena.navigationVersion+1
end
function N.addSoil(x,y)
    local s={x=x-15,y=y-15,w=30,h=30,life=7,renaissanceSoil=true}
    -- Never raise a barrier through a creature or an egg's approach area.
    if checkCollision(player.x-8,player.y-8,46,40,s.x,s.y,s.w,s.h) then return end
    for _,m in ipairs(mobs) do
        if checkCollision(m.x-22,m.y-22,44,44,s.x,s.y,s.w,s.h) then return end
    end
    for _,e in ipairs(N.eggs) do
        if checkCollision(e.x-35,e.y-35,100,110,s.x,s.y,s.w,s.h) then return end
    end
    if Arena.blocked(s.x,s.y,s.w,s.h) then return end
    N.soil[#N.soil+1]=s;Arena.walls[#Arena.walls+1]=s
    Arena.navigationVersion=Arena.navigationVersion+1
end
function N.explode(m)
    local radius=m.mini and 43 or 76
    N.blasts[#N.blasts+1]={x=m.x,y=m.y,radius=radius,age=0}
    local px=math.max(player.x,math.min(player.x+30,m.x))
    local py=math.max(player.y,math.min(player.y+24,m.y))
    if (px-m.x)^2+(py-m.y)^2<radius^2 then Hazards.kill() end
    if not m.mini then
        for i=1,3 do local a=i*math.pi*2/3
            N.bush(m.x+math.cos(a)*30,m.y+math.sin(a)*30,true)
        end
    end
end
function N.update(dt)
    if not N.active then return end
    N.clock=N.clock+dt
    for i=#N.soil,1,-1 do local s=N.soil[i];s.life=s.life-dt;if s.life<=0 then removeSoil(i) end end
    for i=#N.blasts,1,-1 do local b=N.blasts[i];b.age=b.age+dt;if b.age>.45 then table.remove(N.blasts,i) end end
    -- Reverse iteration ensures newborn bushes start moving on the next frame.
    for i=#mobs,1,-1 do local m=mobs[i]
        if m.type=='rebirth_bush' and not m.is_frozen then
            m.age=m.age+dt
            Arena.navigate(m,player.x+15,player.y+12,m.speed,dt)
            if m.age>=m.fuse then table.remove(mobs,i);N.explode(m) end
        elseif m.type=='white_spider' then
            local dx,dy=player.x+15-m.x,player.y+12-m.y
            local d=math.sqrt(dx*dx+dy*dy)
            if d>48 then Arena.navigate(m,player.x+15-dx/d*46,player.y+12-dy/d*46,190,dt) end
        elseif m.type=='walking_tree' and not m.is_frozen then
            m.age=m.age+dt;local speed=52
            -- The tree steps over its own freshly overturned soil.
            local x,y=m.x+m.vx*speed*dt,m.y+m.vy*speed*dt
            if x<60 or x>Arena.width-60 then m.vx=-m.vx else m.x=x end
            if y<100 or y>510 then m.vy=-m.vy else m.y=y end
            m.trail=m.trail+dt
            if m.trail>=.65 then m.trail=0;N.addSoil(m.x-m.vx*62,m.y-m.vy*62) end
            if isTouching(player,m) then Hazards.kill() end
        end
    end
    N.spawnClock=N.spawnClock-dt
    if N.spawnClock<=0 then
        N.spawnClock=8
        local x=player.x<Arena.width/2 and Arena.width-95 or 95
        N.bush(x,player.y<300 and 470 or 110,false)
    end
end
-- All creatures and collectibles use authored transparent PNG sprites.
local function sprite(key,x,y,size,angle)
    local a=assert(Art.images['rebirth_'..key],key)
    local scale=size/math.max(a.w,a.h)
    local g=love.graphics
    g.draw(a.image,a.quad,x,y,angle or 0,scale,scale,a.w/2,a.h/2)
end
function N.drawSoil(s)
    local g=love.graphics;g.push('all');g.setColor(1,1,1,math.min(1,s.life))
    sprite('soil',s.x+s.w/2,s.y+s.h/2,math.max(s.w,s.h)+8)
    g.pop()
end
function N.drawBush(m)
    local g=love.graphics;g.push('all')
    local urgent=m.fuse-m.age<1
    local pulse=urgent and (1+math.sin(m.age*28)*.07) or 1
    local bob=m.is_frozen and 0 or math.sin(m.age*(m.mini and 20 or 12))*1.5
    g.setColor(1,urgent and .78 or 1,urgent and .65 or 1)
    sprite(m.mini and 'mini_bush' or 'bush',m.x,m.y+bob,(m.mini and 32 or 60)*pulse)
    g.setColor(1,.63,.16,urgent and .75 or .22);g.setLineWidth(2)
    g.circle('line',m.x,m.y,m.mini and 43 or 76)
    if m.age>0 then
        g.arc('line','open',m.x,m.y,m.mini and 19 or 35,-math.pi/2,-math.pi/2+math.pi*2*math.min(.999,m.age/m.fuse))
    end
    g.pop()
end
function N.drawTree(m)
    local g=love.graphics;g.push('all');g.setColor(1,1,1)
    local sway=m.is_frozen and 0 or math.sin(m.age*6)*.035
    sprite('walking_tree',m.x,m.y-22,116,sway)
    g.pop()
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
function N.drawBlasts()
    if not N.active then return end
    local g=love.graphics;g.push('all')
    for _,b in ipairs(N.blasts) do
        local t=b.age/.45;g.setColor(1,.73,.22,(1-t)*.65);g.circle('fill',b.x,b.y,b.radius*(.5+t*.5))
        g.setColor(.82,1,.32,1-t);g.setLineWidth(3);g.circle('line',b.x,b.y,b.radius)
        for j=1,14 do local a=j*2.4;local r=b.radius*t
            g.setColor(.30,.53,.08,1-t);g.ellipse('fill',b.x+math.cos(a)*r,b.y+math.sin(a)*r,5,3)
        end
    end
    g.pop()
end
function N.resize(ratio)
    if not N.active then return end
    for _,e in ipairs(N.eggs) do e.x=e.x*ratio end
    for _,b in ipairs(N.blasts) do b.x=b.x*ratio end
    for _,s in ipairs(N.soil) do s.x=s.x*ratio;s.w=s.w*ratio;Arena.walls[#Arena.walls+1]=s end
    Arena.navigationVersion=Arena.navigationVersion+1;N.syncEgg()
end
MobBehaviors.rebirth_bush={draw=N.drawBush}
MobBehaviors.walking_tree={draw=N.drawTree}
MobBehaviors.white_spider={draw=N.drawSpider}
return N
