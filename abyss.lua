local A={threads={},bones={},clock=0,active=false}
local function add(kind,x,y,speed)
    mobs[#mobs+1]={type=kind,x=x,y=y,speed=speed,age=0,dir='right',heading=love.math.random()*math.pi*2,turn=0,
        hitBox_width=32,hitBox_height=26,hitBox_offset_x=-16,hitBox_offset_y=-13}
end
A.add=add
function A.spawn(n)
    add('light_jelly',Arena.width*.7,160,40)
    if n>=4 then add('light_jelly',Arena.width*.3,430,38) end
    if n>=8 then add('light_jelly',Arena.width*.5,110,42) end
    add('lanternfish',Arena.width*.22,220,55); add('lanternfish',Arena.width*.75,410,55)
    for i=1,2+math.floor(n/4) do add('abyss_fish',Arena.width*(.15+(i-1)*.2),i%2==0 and 420 or 140,70) end
end
function A.reset(w,n)
    A.active=w==7; A.clock=0; A.threads={}; A.bones={}; A.open=false; A.head=nil; A.swallowed=nil; A.cargo={}; A.ejected={}; A.spitFlash=0; A.breathAt=5.5; A.motionTime=0
    A.giant=A.active and n>=7; A.boss=A.active and n==10; A.origin={x=Arena.width/2,y=280}; player.illuminated=0; player.electrified=0; player.abyssHeld=nil; player.abyssSpit=nil; player.abyssGrace=0
    A.hp=8; A.maxHp=8; A.defeated=false; A.flash=0; A.hitGrace=0; A.lightLock=false; A.name="Le Léviathan des Abysses"
    A.lightSites={{x=Arena.width*.12,y=105},{x=Arena.width*.88,y=495},{x=Arena.width*.12,y=495},{x=Arena.width*.88,y=105}}
    if A.boss then A.spawn(2); objet.larme.taken=true end
    if not A.giant then return end
    A.buildBones()
    player.x=Arena.width*.5-15; player.y=515
    Bestiary.discover('skeleton_fish'); Bestiary.save()
end
function A.buildBones()
    A.bones={}
    local function bone(key,x,y,w,h,angle)
        local spot=Art.images[key].glow or {u=.5,v=.5}; local a=angle or 0
        local dx,dy=(spot.u-.5)*w,(spot.v-.5)*h
        A.bones[#A.bones+1]={key=key,x=x,y=y,w=w,h=h,angle=a,gx=x+math.cos(a)*dx-math.sin(a)*dy,gy=y+math.sin(a)*dx+math.cos(a)*dy}
    end
    local span=Arena.width*.55; local count=math.max(3,math.floor(span/145))
    local shift=A.origin.x-Arena.width/2
    local swim=A.origin.y-280
    for i=1,count do
        local x=Arena.width*.2+(i-1)*span/count+shift; local y=280+swim
        local h=105+25*math.sin(i/count*math.pi)
        bone('skeleton_spine',x,y,22,28)
        bone('skeleton_rib',x,y-h/2-20,22,h,-.12)
        bone('skeleton_rib',x,y+h/2+20,22,h,math.pi+.12)
    end
    bone('skeleton_tail',Arena.width*.095+shift,280+swim,110,160)
    if not A.head or (not A.open and not A.swallowed) then
        A.head={x=math.max(115,math.min(Arena.width-145,Arena.width*.79+shift+math.sin(A.motionTime*.7)*Arena.width*.07)),
            y=math.max(125,math.min(455,280+swim+math.sin(A.motionTime*.9)*135)),w=170,h=150}
    end
    bone(A.open and 'skeleton_open' or 'skeleton_head',A.head.x,A.head.y,A.head.w,A.head.h)
end
function A.boneTouches(b,x,y)
    local a=Art.images[b.key]; if not a or not a.mask then return false end
    local dx,dy=x-b.x,y-b.y; local c,s=math.cos(b.angle),math.sin(b.angle)
    local u=(c*dx+s*dy)/b.w+.5; local v=(-s*dx+c*dy)/b.h+.5
    if u<0 or u>=1 or v<0 or v>=1 then return false end
    return a.mask[math.floor(v*192)*192+math.floor(u*192)] or false
end
function A.mouth() return A.head.x+65,A.head.y+15 end
local function onSites(boss)
    if not boss.active or boss.defeated then return false end
    local special=boss.boss or (Realms.custom and #boss.lightSites>0)
    local sites=special and boss.lightSites or (levels[player.level] and levels[player.level].larme_position or {})
    for _,p in ipairs(sites) do
        local x,y=special and p.x or p.x+15,special and p.y or p.y+39
        if (player.x+15-x)^2+(player.y+12-y)^2<24^2 then return true end
    end
    return false
end
function A.refreshLight()
    local onSite=not player.abyssHeld and onSites(A)
    if Bosses then for _,item in ipairs(Bosses.items) do if not player.abyssHeld and item.kind=='skeleton_fish' and onSites(item.boss) then onSite=true end end end
    player.circleLight=onSite
    player.illuminated=math.max(onSite and 6 or 0,player.electrified or 0)
end
function A.charge(seconds)
    player.electrified=math.max(player.electrified or 0,seconds or 6); A.refreshLight()
end
function A.contact()
    if not A.giant or A.defeated or player.reset or player.abyssHeld or (player.abyssGrace or 0)>0 then return end
    local mouthX,mouthY=A.mouth()
    local inMouth=A.open and (player.x+15-mouthX)^2+(player.y+12-mouthY)^2<34^2
    if inMouth and A.boss then
        if (player.electrified or 0)>0 then
            A.swallowed={time=0}; player.abyssHeld=A; player.electrified=0
            player.dashing=false; player.has_moved=false; player.whirl=nil; player.throw=nil; player.tunnelTravel=nil
            player.x=mouthX-15; player.y=mouthY-12; A.refreshLight()
        else Hazards.kill() end
        return
    end
    for _,b in ipairs(A.bones) do
        -- The open mouth has an accessible throat; the skull and teeth remain solid.
        local throat=A.boss and A.open and b==A.bones[#A.bones] and player.x+15>A.head.x+24 and math.abs(player.y+12-mouthY)<46
        if not throat and math.abs(player.x+15-b.x)<b.w/2+40 and math.abs(player.y+12-b.y)<b.h/2+40 then
            for y=player.y+2,player.y+22,4 do for x=player.x+2,player.x+28,4 do
                if A.boneTouches(b,x,y) then Hazards.kill(); return end
            end end
        end
    end
end
function A.hurt()
    A.hp=math.max(0,A.hp-1); A.flash=.35; Audio.play('pick')
    if A.hp==0 then
        A.defeated=true; A.giant=false; A.open=false; A.bones={}; A.threads={}
        objet.larme.taken=false; objet.larme.x=Arena.width/2-15; objet.larme.y=280
    end
end
function A.emit(m)
    local aim=math.atan2(player.y+12-m.y,player.x+15-m.x)
    for _,offset in ipairs({-.48,0,.48}) do local a=aim+offset
        A.threads[#A.threads+1]={x=m.x,y=m.y,vx=math.cos(a)*165,vy=math.sin(a)*165,life=4,age=0,seed=m.age+offset}
    end
end
function A.pullEntity(m,dt,body)
    if m.abyssHeld or (m==player and player.abyssSpit) then return end
    local tx,ty=A.mouth()
    local dx,dy=tx-(m.x+(body==player and 15 or 0)),ty-(m.y+(body==player and 12 or 0))
    local d=math.sqrt(dx*dx+dy*dy); if d<1 then return end
    local step=math.min(d,(180+210*math.max(0,1-d/Arena.width))*dt)
    if body then
        local steps=math.max(1,math.ceil(step/5))
        for _=1,steps do
            Arena.move(m,dx/d*step/steps,dy/d*step/steps)
            if m==player then A.contact(); if player.reset or player.abyssHeld then break end end
        end
    else m.x=m.x+dx/d*step; m.y=m.y+dy/d*step end
    if m~=player and not m.abyssHeld then
        local distance=(m.x-tx)^2+(m.y-ty)^2
        if distance<30^2 then
            m.abyssHeld=A; A.cargo[#A.cargo+1]={entity=m,body=body,dx=dx,dy=dy}
        end
    end
end
function A.safeExit()
    local mx,my=A.mouth(); local best,bx,by=math.huge,Arena.width-80,510
    -- Find a nearby spit landing clear of walls, bones, enemies and permanent pools.
    for y=85,535,18 do for x=55,Arena.width-55,18 do
        local d=(x-mx)^2+(y-my)^2
        if d>=95^2 and d<best and not Arena.blocked(x-17,y-14,34,28) then
            local safe=true
            for _,b in ipairs(A.bones) do if math.abs(x-b.x)<b.w/2+36 and math.abs(y-b.y)<b.h/2+32 then safe=false; break end end
            for _,m in ipairs(mobs) do if not m.abyssHeld and (x-m.x)^2+(y-m.y)^2<75^2 then safe=false; break end end
            for _,p in ipairs(Magma and Magma.pools or {}) do if Hazards.inEllipse(x,y,p,25) then safe=false; break end end
            if safe then best,bx,by=d,x,y end
        end
    end end
    return bx,by
end
function A.spit()
    local mx,my=A.mouth(); local targetX,targetY
    local captured=A.swallowed~=nil
    if captured then targetX,targetY=A.safeExit(); player.abyssHeld=nil; player.abyssGrace=1.25 end
    for i,c in ipairs(A.cargo) do
        local m=c.entity; m.abyssHeld=nil
        -- Expel captured entities in a fan, away from the player's landing.
        local angle=-math.pi*.8+(i%7)*math.pi*.23
        local x,y=mx+math.cos(angle)*110,my+math.sin(angle)*110
        x=math.max(40,math.min(Arena.width-40,x)); y=math.max(70,math.min(540,y))
        if c.body then local xx,yy=Arena.clearSpot(x-16,y-13,32,26); x,y=xx+16,yy+13 end
        m.x=x; m.y=y
        if m.life then m.life=math.max(m.life,1.5) end
        if m.vx then local speed=math.sqrt(m.vx*m.vx+(m.vy or 0)^2); m.vx=math.cos(angle)*speed; m.vy=math.sin(angle)*speed end
        A.ejected[#A.ejected+1]={x=mx,y=my,tx=x,ty=y,age=0}
    end
    A.cargo={}; A.swallowed=nil; A.open=false; A.breathAt=A.clock+5.5; A.spitFlash=.55
    if captured then
        player.abyssSpit={fromX=mx-15,fromY=my-12,toX=targetX-15,toY=targetY-12,time=0}
        A.hurt()
    end
end
function A.update(dt)
    if not A.active then return end
    if not A.open then A.motionTime=A.motionTime+dt end
    A.clock=A.clock+dt; A.flash=math.max(0,A.flash-dt); A.spitFlash=math.max(0,A.spitFlash-dt)
    A.hitGrace=math.max(0,A.hitGrace-dt)
    if not A.instance then player.electrified=math.max(0,(player.electrified or 0)-dt) end
    A.refreshLight()
    for i=#A.threads,1,-1 do local p=A.threads[i]
        if not p.abyssHeld then
            p.age=p.age+dt; p.life=p.life-dt; local dead=p.life<=0
            local steps=math.max(1,math.ceil(165*dt/5))
            for _=1,steps do
                p.x=p.x+p.vx*dt/steps; p.y=p.y+p.vy*dt/steps
                if not player.abyssHeld and (player.x+15-p.x)^2+(player.y+12-p.y)^2<23^2 then A.charge(6); dead=true end
                if Arena.blocked(p.x-2,p.y-2,4,4) then dead=true end
                if dead then break end
            end
            if dead then table.remove(A.threads,i) end
        end
    end
    for i=#A.ejected,1,-1 do local p=A.ejected[i]; p.age=p.age+dt; if p.age>.4 then table.remove(A.ejected,i) end end
    if A.giant then
        local wasOpen=A.open
        if A.swallowed then
            A.swallowed.time=A.swallowed.time+dt
            if A.swallowed.time>=.6 then A.spit() end
        else
            A.open=A.clock>=A.breathAt
            if wasOpen and A.clock>=A.breathAt+3.5 then A.spit() end
        end
        if not A.giant then A.refreshLight(); return end
        A.buildBones()
        if A.open then
            A.pullEntity(player,dt,player)
            for _,m in ipairs(mobs) do A.pullEntity(m,dt,m) end
            for _,list in ipairs({A.threads,Realms.fireflies,Ocean.bubbles,Realms.bolts}) do for _,m in ipairs(list) do A.pullEntity(m,dt) end end
            if not objet.larme.taken then A.pullEntity(objet.larme,dt) end
        end
        A.contact()
    end
    A.refreshLight()
end
function A.updatePlayer(dt)
    player.abyssGrace=math.max(0,(player.abyssGrace or 0)-dt)
    local s=player.abyssSpit
    if s then
        s.time=s.time+dt; local t=math.min(1,s.time/.28); local eased=1-(1-t)^2
        player.x=s.fromX+(s.toX-s.fromX)*eased; player.y=s.fromY+(s.toY-s.fromY)*eased
        if t==1 then player.abyssSpit=nil end
    end
end
function A.drawSites()
    if (not A.boss and not (Realms.custom and #A.lightSites>0)) or A.defeated then return end
    local g=love.graphics
    for _,p in ipairs(A.lightSites) do
        g.setColor(Worlds.color(7).tear); Art.drawTinted('tear_ring',p.x,p.y,44)
        g.setColor(.2,.5,1,.15); g.circle('fill',p.x,p.y,23)
    end
    g.setColor(1,1,1)
end
function A.drawBones()
    if not A.giant or A.defeated then return end
    local g=love.graphics
    for _,b in ipairs(A.bones) do
        g.setColor(.015,.025,.05,.55); Art.draw(b.key,b.x+7,b.y+10,b.w,b.angle,b.h)
        g.setColor(1,1-A.flash,1-A.flash); Art.draw(b.key,b.x,b.y,b.w,b.angle,b.h)
    end
end
function A.addLights(lights)
    if not A.giant then return end
    for i=#A.bones,#A.bones-1,-1 do local b=A.bones[i]; if b then lights[#lights+1]={b.gx,b.gy,120,.85} end end
    for i=1,#A.bones-2 do local b=A.bones[i]; if #lights<24 then lights[#lights+1]={b.gx,b.gy,80,.65} end end
end
function A.eyePosition(m)
    local a=Art.images.abyss_fish; local x,y=85*.3,-85*(a.h/a.w)*.09
    local angle=m.angle or 0
    return m.x+math.cos(angle)*x-math.sin(angle)*y,m.y+math.sin(angle)*x+math.cos(angle)*y
end
function A.drawLights()
    if not A.active then return end
    local g=love.graphics; g.push('all'); g.setBlendMode('add')
    for _,b in ipairs(A.bones) do
        g.setColor(.04,.55,1,.12); g.circle('fill',b.gx,b.gy,7)
        g.setColor(.25,.85,1,.8); g.circle('fill',b.gx,b.gy,1.8)
    end
    for _,p in ipairs(A.threads) do if not p.abyssHeld then
        local a=math.atan2(p.vy,p.vx); g.push(); g.translate(p.x,p.y); g.rotate(a)
        g.setColor(.2,.65,1,.3); g.setLineWidth(5)
        g.line(-32,math.sin(p.age*12+p.seed)*4,-20,-4,-10,3,0,0)
        g.setColor(.65,.95,1,1); g.setLineWidth(1); g.line(-32,math.sin(p.age*12+p.seed)*4,-20,-4,-10,3,0,0); g.pop()
    end end
    if (player.illuminated or 0)>0 and not player.abyssHeld then
        for _,m in ipairs(mobs) do if m.type=='abyss_fish' then
            local x,y=A.eyePosition(m)
            g.setColor(.3,.75,1,.14); g.circle('fill',x,y,4)
            g.setColor(.65,.9,1,.8); g.circle('fill',x,y,1.4)
        end end
        for r=4,1,-1 do g.setColor(.15,.65,1,.045); g.ellipse('fill',player.x+15,player.y+12,23+r*13,18+r*10) end
        g.setColor(.35,.9,1,.38); g.ellipse('fill',player.x+15,player.y+12,35,27)
        g.setColor(.75,1,1,.95); g.setLineWidth(2); g.ellipse('line',player.x+15,player.y+12,31,24); g.setLineWidth(1)
        for i=1,8 do local a=i*math.pi/4+A.clock; g.setColor(.5,.9,1,.8)
            g.circle('fill',player.x+15+math.cos(a)*29,player.y+12+math.sin(a)*20,1.5)
        end
    end
    if A.head and (A.swallowed or A.spitFlash>0) then
        local mx,my=A.mouth(); g.setColor(.3,.85,1,.65); g.setLineWidth(2)
        for i=1,7 do local a=i*math.pi*2/7+A.clock*3
            g.line(mx+math.cos(a)*12,my+math.sin(a)*12,mx+math.cos(a+.2)*24,my+math.sin(a+.2)*24)
        end
    end
    for _,p in ipairs(A.ejected) do
        local t=p.age/.4; g.setColor(.4,.8,1,(1-t)*.6)
        g.circle('fill',p.x+(p.tx-p.x)*t,p.y+(p.ty-p.y)*t,3)
    end
    if A.giant and A.open then
        for i=1,40 do
            local t=(A.clock*.7+i/40)%1; local a=i*2.4; local r=(1-t)*350
            local x=A.head.x+65+math.cos(a)*r; local y=A.head.y+15+math.sin(a)*r*.6
            g.setColor(.35,.75,1,.25*t); g.line(x,y,x-math.cos(a)*14,y-math.sin(a)*9)
        end
    end
    g.pop()
end
local function update(m,dt)
    if m.is_frozen or m.abyssHeld then return end
    local before=m.age; m.age=m.age+dt
    if m.type=='light_jelly' then
        local vx,vy=math.cos(m.age*.6),math.sin(m.age*.7)
        Arena.move(m,vx*m.speed*dt,vy*m.speed*dt); m.angle=math.atan2(vy,vx)-math.pi/2
        if math.floor(before/3)<math.floor(m.age/3) then A.emit(m) end
    else
        local dx,dy=player.x+15-m.x,player.y+12-m.y; local d=math.max(1,math.sqrt(dx*dx+dy*dy))
        local vx,vy,speed
        if (player.illuminated or 0)>0 then vx,vy,speed=dx/d,dy/d,285
        elseif d<240 then vx,vy,speed=-dx/d,-dy/d,m.speed*1.4
        else
            m.turn=m.turn-dt; if m.turn<=0 then m.heading=love.math.random()*math.pi*2; m.turn=1+love.math.random()*2 end
            vx,vy,speed=math.cos(m.heading),math.sin(m.heading),m.speed*.6
        end
        local hx,hy=Arena.move(m,vx*speed*dt,vy*speed*dt)
        if hx or hy then m.heading=m.heading+math.pi/2 end
        m.angle=math.atan2(vy,vx); m.dir=Art.direction(vx,vy,m.dir)
    end
    if isTouching(player,m) then Hazards.kill() end
end
local function draw(m)
    if m.abyssHeld then return end
    local g=love.graphics; g.setColor(1,1,1)
    if m.type=='abyss_fish' then Art.draw('abyss_fish',m.x,m.y,85,m.angle or 0)
    elseif m.type=='light_jelly' then
        g.setColor(1,1,1); Art.drawSwimmer('abyss_octopus',m.x,m.y,78,m.angle or 0,m.age)
        g.setColor(.4,.85,1,.35); g.circle('line',m.x,m.y,27+math.sin(m.age*3)*3)
    else Art.drawFacing('lanternfish',m.dir,m.x,m.y,68) end
    g.setColor(1,1,1)
end
for _,kind in ipairs({'abyss_fish','light_jelly','lanternfish'}) do MobBehaviors[kind]={update=update,draw=draw} end
return A
