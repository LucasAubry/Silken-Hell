local W={active=false,projectiles={},minions={}}
function W.reset(active)
    W.active=active; W.name='Les Trois Sœurs de braise'; W.hp=9; W.maxHp=9; W.defeated=false; W.flash=0
    W.x=Arena.width/2; W.y=180; W.anchorX=W.x; W.anchorY=W.y; W.elapsed=0
    W.bees={}; W.round=0; W.roundClock=0; W.roundActive=false; W.rest=.9
    for i=1,3 do W.bees[i]={id=i,x=W.x+(i-2)*150,y=W.y+(i==2 and -35 or 25),hp=3,phase='ready',dir='down',flash=0} end
    W.eruptions={}; W.lavaClock=1.4; W.lavaIndex=0
    W.projectiles={}; W.minions={}; W.summon=1.4; W.hitGrace=0
end
function W.aliveCount()
    local n=0; for _,b in ipairs(W.bees) do if b.hp>0 then n=n+1 end end; return n
end
function W.tempo() return ({[3]=1,[2]=1.4,[1]=2.05,[0]=2.05})[W.aliveCount()] end
function W.interval() return 1/W.tempo() end
function W.syncAnchor()
    local dx,dy=W.x-W.anchorX,W.y-W.anchorY
    if dx~=0 or dy~=0 then
        for _,b in ipairs(W.bees) do b.x=b.x+dx;b.y=b.y+dy;if b.tx then b.tx=b.tx+dx;b.ty=b.ty+dy end end
        W.anchorX,W.anchorY=W.x,W.y
    end
end
function W.resize(ratio)
    W.x=W.x*ratio;W.anchorX=W.anchorX*ratio
    for _,list in ipairs({W.bees,W.projectiles,W.minions,W.eruptions}) do for _,b in ipairs(list) do
        b.x=b.x*ratio;if b.tx then b.tx=b.tx*ratio end
    end end
end
function W.contact()
    if not W.active or W.defeated or player.reset then return end
    W.syncAnchor()
    for _,b in ipairs(W.bees) do
        if b.hp>0 and b.phase=='fatigued' and checkCollision(player.x,player.y,30,24,b.x-32,b.y-35,64,70) then
            b.hp=b.hp-1; W.hp=W.hp-1; b.flash=.3;W.flash=.3;W.hitGrace=.5
            b.phase=b.hp==0 and 'dead' or 'cooldown';b.deadTime=0
            Audio.play('pick');BossFX.burst(b.x,b.y,{1,.25,.06},b.hp==0 and 4 or 2)
            if b.hp==0 then W.rest=math.min(W.rest,.3);W.summon=1.4 end
            if W.hp==0 then
                W.defeated=true;W.projectiles={};W.eruptions={};objet.larme.taken=false
                objet.larme.x=b.x-15;objet.larme.y=b.y-20
            end
            return
        end
    end
end
function W.fire(kind)
    local a=math.atan2(player.y+12-W.y,player.x+15-W.x)
    local speed=kind=='venom' and 175 or 295+65*(1-W.hp/W.maxHp)
    local spread=kind=='venom' and {-0.22,0,0.22} or (W.hp<=5 and {-.15,0,.15} or {0})
    for _,offset in ipairs(spread) do local angle=a+offset
        W.projectiles[#W.projectiles+1]={x=W.x,y=W.y,vx=math.cos(angle)*speed,vy=math.sin(angle)*speed,kind=kind,life=7}
    end
end
function W.updateLava(dt)
    if W.defeated then W.eruptions={}; return end
    W.lavaClock=W.lavaClock-dt*(W.attackRate or 1)
    if W.lavaClock<=0 and #Hazards.lava>0 then
        W.lavaIndex=W.lavaIndex%#Hazards.lava+1
        local p=Hazards.lava[W.lavaIndex]
        W.eruptions[#W.eruptions+1]={x=p.x,y=p.y,rx=p.rx,ry=p.ry,age=0,aim=math.atan2(player.y+12-p.y,player.x+15-p.x)}
        W.lavaClock=3.1-(1-W.hp/W.maxHp)*.9
    end
    for i=#W.eruptions,1,-1 do local p=W.eruptions[i]; p.age=p.age+dt
        if p.age>=1 then
            for j=-2,2 do local a=p.aim+j*.3
                W.projectiles[#W.projectiles+1]={x=p.x,y=p.y,vx=math.cos(a)*205,vy=math.sin(a)*205,kind='ember',life=3}
            end
            BossFX.burst(p.x,p.y,{1,.25,.02},2); table.remove(W.eruptions,i)
        end
    end
end
function W.landingSpot(bee)
    local origin=bee or W
    local best,bx,by=math.huge,origin.x,origin.y
    for y=90,515,30 do for x=75,Arena.width-75,30 do
        if not Arena.blocked(x-55,y-55,110,110) then
            local clear=true
            for _,p in ipairs(Hazards.lava) do if Hazards.inEllipse(x,y,p,65) then clear=false;break end end
            local d=(x-origin.x)^2+(y-origin.y)^2
            if clear and d<best then best,bx,by=d,x,y end
        end
    end end
    return bx,by
end
function W.beginRound()
    W.round=W.round+1;W.roundClock=0;W.roundActive=true
    local alive={};for _,b in ipairs(W.bees) do if b.hp>0 then alive[#alive+1]=b end end
    for slot=1,#alive do
        local b=alive[(slot+W.round-2)%#alive+1]
        b.phase='queued';b.delay=(slot-1)*.8
    end
end
function W.approach(b,x,y,speed,dt)
    local dx,dy=x-b.x,y-b.y;local d=math.sqrt(dx*dx+dy*dy)
    local step=math.min(d,speed*dt)
    if d>.01 then b.x=b.x+dx/d*step;b.y=b.y+dy/d*step;b.dir=Art.direction(dx,dy,b.dir) end
    return d<=speed*dt+.01
end
function W.chargeContact(b)
    if W.hitGrace<=0 and (player.x+15-b.x)^2+(player.y+12-b.y)^2<30^2 then Hazards.kill() end
end
function W.updateBees(dt)
    local tempo=W.tempo();local cadence=tempo*(W.attackRate or 1);local move=W.movementRate or 1
    if not W.roundActive then
        W.rest=W.rest-dt*cadence
        if W.rest<=0 then W.beginRound() end
    end
    W.roundClock=W.roundClock+dt*cadence
    local resting=false
    for _,b in ipairs(W.bees) do if b.hp>0 and (b.phase=='landing' or b.phase=='fatigued') then resting=true end end
    for _,b in ipairs(W.bees) do
        b.flash=math.max(0,b.flash-dt)
        if b.hp<=0 then b.deadTime=(b.deadTime or 0)+dt
        else
            if b.phase=='queued' and W.roundClock>=b.delay then
                b.phase='aim';b.time=.78
                local a=math.atan2(player.y+12-b.y,player.x+15-b.x)
                local d=math.sqrt((player.x+15-b.x)^2+(player.y+12-b.y)^2)+90
                b.tx=math.max(55,math.min(Arena.width-55,b.x+math.cos(a)*d))
                b.ty=math.max(75,math.min(525,b.y+math.sin(a)*d))
                b.dir=Art.direction(b.tx-b.x,b.ty-b.y,b.dir)
            elseif b.phase=='aim' then
                b.time=b.time-dt*cadence
                if b.time<=0 then b.phase='charge';BossFX.burst(b.x,b.y,{1,.4,.1},1) end
            elseif b.phase=='charge' then
                local speed=430*tempo*move;local steps=math.max(1,math.ceil(speed*dt/4))
                for _=1,steps do
                    local arrived=W.approach(b,b.tx,b.ty,speed,dt/steps);W.chargeContact(b)
                    if arrived then b.phase='waiting';break end
                    if player.reset then break end
                end
            elseif b.phase=='waiting' and not resting then
                -- A shared slot guarantees that only one sister can be vulnerable.
                resting=true;b.phase='landing';b.tx,b.ty=W.landingSpot(b)
            elseif b.phase=='landing' then
                if W.approach(b,b.tx,b.ty,300*move,dt) then b.phase='fatigued';b.time=math.max(1.4,2.8/tempo) end
            elseif b.phase=='fatigued' then
                b.time=b.time-dt
                if b.time<=0 then b.phase='cooldown' end
            elseif b.phase=='ready' or b.phase=='queued' or b.phase=='cooldown' or b.phase=='waiting' then
                local tx=math.max(65,math.min(Arena.width-65,W.x+(b.id-2)*150+math.sin(W.elapsed*.65+b.id)*35))
                local ty=math.max(85,math.min(500,W.y+(b.id==2 and -35 or 25)+math.cos(W.elapsed+b.id)*25))
                W.approach(b,tx,ty,105*tempo*move,dt)
            end
        end
    end
    W.contact()
    local complete=W.roundActive
    for _,b in ipairs(W.bees) do if b.hp>0 and b.phase~='cooldown' then complete=false end end
    if complete then W.roundActive=false;W.rest=.65 end
    if W.aliveCount()==1 then
        W.summon=W.summon-dt*cadence
        if W.summon<=0 then
            if #W.minions<6 then
                local last;for _,b in ipairs(W.bees) do if b.hp>0 then last=b end end
                W.minions[#W.minions+1]={x=last.x-40,y=last.y,dir='down'}
                W.minions[#W.minions+1]={x=last.x+40,y=last.y,dir='down'}
                Bestiary.discover('waspling');Bestiary.save()
            end
            W.summon=5
        end
    end
end
function W.update(dt)
    if not W.active then return end
    W.syncAnchor();W.hitGrace=math.max(0,W.hitGrace-dt);W.elapsed=W.elapsed+dt;W.flash=math.max(0,W.flash-dt)
    if not W.defeated then W.updateBees(dt);W.updateLava(dt)
    else for _,b in ipairs(W.bees) do b.deadTime=(b.deadTime or 0)+dt end end
    for i=#W.projectiles,1,-1 do
        local p=W.projectiles[i]; p.life=p.life-dt; local dead=p.life<=0
        local steps=math.max(1,math.ceil(math.sqrt(p.vx*p.vx+p.vy*p.vy)*dt/4))
        for _=1,steps do
            if dead then break end
            p.x=p.x+p.vx*dt/steps; p.y=p.y+p.vy*dt/steps
            if checkCollision(p.x-5,p.y-5,10,10,player.x,player.y,30,24) then
                if p.kind=='venom' then player.venom=3 elseif W.hitGrace<=0 then Hazards.kill() end; dead=true
            elseif Arena.blocked(p.x-4,p.y-4,8,8) then dead=true end
        end
        if dead then table.remove(W.projectiles,i) end
    end
    for i=#W.minions,1,-1 do local m=W.minions[i]
        local a=math.atan2(player.y+12-m.y,player.x+15-m.x)
        m.dir=Art.direction(math.cos(a),math.sin(a))
        m.x=m.x+math.cos(a)*95*dt; m.y=m.y+math.sin(a)*95*dt
        if (player.x+15-m.x)^2+(player.y+12-m.y)^2<20^2 and W.hitGrace<=0 then Hazards.kill() end
    end
end
function W.drawGround()
    if not W.active or W.defeated then return end
    W.syncAnchor()
    local g=love.graphics;g.push('all')
    for _,b in ipairs(W.bees) do if b.hp>0 then
        g.setColor(0,0,0,.23);g.ellipse('fill',b.x,b.y+20,32,14)
        if b.phase=='aim' then
            g.setColor(1,.45,.12,.65);g.setLineWidth(2);g.line(b.x,b.y,b.tx,b.ty)
            g.circle('line',b.tx,b.ty,18)
        elseif b.phase=='fatigued' then
            g.setColor(1,.85,.3,.35+.2*math.sin(W.elapsed*7));g.ellipse('fill',b.x,b.y,39,28)
        end
    end end
    for _,p in ipairs(W.eruptions) do
        g.setColor(1,.7,.12,.45+p.age*.4);g.setLineWidth(2)
        g.ellipse('line',p.x,p.y,p.rx+8+p.age*8,p.ry+8+p.age*8)
    end
    g.pop()
end
function W.draw(airborne)
    if not W.active then return end
    local g=love.graphics
    for _,b in ipairs(W.bees) do
        local flying=b.phase~='fatigued' and b.phase~='dead'
        if airborne==flying and (b.hp>0 or (b.deadTime or 0)<.6) then
            local alpha=b.hp>0 and 1 or math.max(0,1-(b.deadTime or 0)/.6)
            g.setColor(1,1-b.flash*.6,1-b.flash*.6,alpha)
            Art.drawFacing(flying and 'wasp' or 'wasp_ground',b.dir,b.x,b.y+(flying and -10+math.sin(W.elapsed*36+b.id)*2 or 0),flying and 96 or 80)
            if b.hp>0 then
                for i=1,3 do g.setColor(i<=b.hp and 1 or .25,i<=b.hp and .55 or .1,.1,.9);g.circle('fill',b.x+(i-2)*10,b.y+38,3) end
                if b.phase=='fatigued' then
                    g.setColor(1,.9,.4);for i=1,3 do local a=W.elapsed*3+i*math.pi*2/3;g.circle('fill',b.x+math.cos(a)*21,b.y-37+math.sin(a)*5,2) end
                end
            end
        end
    end
    if airborne then
        for _,m in ipairs(W.minions) do g.setColor(1,1,1); Art.drawFacing('waspling',m.dir,m.x,m.y,34) end
        for _,p in ipairs(W.projectiles) do
            if p.kind=='ember' then
                g.setColor(1,.18,.01,.3); g.circle('fill',p.x,p.y,12)
                g.setColor(1,.62,.08); g.circle('fill',p.x,p.y,5)
            elseif p.kind=='venom' then
                g.setColor(0.2,0.9,0.13,0.3); g.circle('fill',p.x,p.y,12)
                g.setColor(0.55,1,0.12); g.circle('fill',p.x,p.y,6)
            else
                g.push(); g.translate(p.x,p.y); g.rotate(math.atan2(p.vy,p.vx)); g.setColor(0.2,0.13,0.03)
                g.polygon('fill',-12,-5,13,0,-12,5); g.setColor(1,0.8,0.25); g.line(-9,0,10,0); g.pop()
            end
        end
    end
    g.setColor(1,1,1)
end
return W
