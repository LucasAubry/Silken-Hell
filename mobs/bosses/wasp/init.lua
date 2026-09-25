local W={active=false,projectiles={},minions={}}
function W.reset(active)
    W.hardcore=false; W.active=active; W.name='Les Trois Sœurs de braise'; W.hp=9; W.maxHp=9; W.defeated=false; W.flash=0
    W.x=Arena.width/2; W.y=180; W.anchorX=W.x; W.anchorY=W.y; W.elapsed=0
    W.combo=nil; W.bees={}; W.round=0; W.roundClock=0; W.roundActive=false; W.rest=.25
    for i=1,3 do W.bees[i]={id=i,x=W.x+(i-2)*150,y=W.y+(i==2 and -35 or 25),hp=3,phase='ready',dir='down',flash=0} end
    W.eruptions={}; W.lavaClock=1.4; W.lavaIndex=0
    W.projectiles={}; W.minions={}; W.blasts={}; W.summon=1.4; W.hitGrace=0
end
function W.aliveCount()
    local n=0; for _,b in ipairs(W.bees) do if b.hp>0 then n=n+1 end end; return n
end
function W.stage() return W.hp<=3 and 3 or W.hp<9 and 2 or 1 end
function W.tempo()
    local speed=({1,1.25,1.55})[W.stage()]*(1+.4*(3-W.aliveCount()))
    return speed*(W.hardcore and 1 or (W.aliveCount()==1 and .88 or .96))
end
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
        if b.hp>0 and b.phase=='fatigued' and W.touches(b) then
            if not W.combo then
                local all=true;for _,sister in ipairs(W.bees) do if sister.hp<=0 or sister.phase~='fatigued' then all=false end end
                if all then W.combo={hits={},round=W.round} end
            end
            if W.combo then
                W.combo.hits[b.id]=true
                if W.combo.hits[1] and W.combo.hits[2] and W.combo.hits[3] then
                    Profile.achievements.gillou=true;Profile.save()
                end
            end
            b.hp=b.hp-1; W.hp=W.hp-1; b.flash=.3;W.flash=.3;b.contactGrace=.85;W.hitGrace=.85
            b.phase=b.hp==0 and 'dead' or 'cooldown';b.deadTime=0
            Audio.play('pick');BossFX.burst(b.x,b.y,{1,.25,.06},b.hp==0 and 4 or 2)
            if b.hp==0 then W.rest=math.min(W.rest,.08);W.summon=1.4 end
            if W.hp==0 then
                W.defeated=true;W.projectiles={};W.eruptions={};objet.larme.taken=false
                W.dropTear()
            end
            return
        end
        W.chargeContact(b)
        if player.reset then return end
    end
end
function W.dropTear()
    local best,bx,by=math.huge,Arena.width/2,300
    for y=75,525,30 do for x=65,Arena.width-65,30 do
        local safe=not Arena.blocked(x-20,y-24,40,48)
        for _,b in ipairs(W.bees) do if (x-b.x)^2+(y-b.y)^2<100^2 then safe=false end end
        for _,p in ipairs(Hazards.lava) do if Hazards.inEllipse(x,y,p,30) then safe=false end end
        local d=(player.x+15-x)^2+(player.y+12-y)^2
        if safe and d<best then best,bx,by=d,x,y end
    end end
    objet.larme.x=bx-15;objet.larme.y=by-20
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
    W.combo=nil;W.round=W.round+1;W.roundClock=0;W.roundActive=true
    local alive={};for _,b in ipairs(W.bees) do if b.hp>0 then alive[#alive+1]=b end end
    local attack=(W.round-1)%3+1
    for slot,b in ipairs(alive) do
        b.dashesLeft=4-#alive;b.phase='queued';b.delay=(slot-1)*.035;b.attack=attack
        b.launchLarva=slot<=W.stage()
    end
end
-- Reserve a direction throughout repositioning, aiming and the charge itself.
function W.directionAvailable(bee,vx,vy)
    for _,other in ipairs(W.bees) do
        if other~=bee and other.hp>0 and other.attack~=3
            and (other.phase=='position' or other.phase=='aim' or other.phase=='charge')
            and other.vx==vx and other.vy==vy then return false end
    end
    return true
end
function W.positionAttack(b)
    local px,py=player.x+15,player.y+12
    if b.attack~=3 then
        local horizontal=b.x<px and 1 or -1
        local vertical=b.y<py and 1 or -1
        local choices=b.attack==1 and {{horizontal,0},{-horizontal,0},{0,vertical},{0,-vertical}}
            or {{0,vertical},{0,-vertical},{horizontal,0},{-horizontal,0}}
        local chosen
        for _,v in ipairs(choices) do if W.directionAvailable(b,v[1],v[2]) then chosen=v;break end end
        if not chosen then return end
        b.vx,b.vy=chosen[1],chosen[2];b.attack=b.vx~=0 and 1 or 2
        if b.attack==1 then
            b.tx=b.vx>0 and 65 or Arena.width-65;b.ty=math.max(65,math.min(535,py))
        else
            b.tx=math.max(65,math.min(Arena.width-65,px));b.ty=b.vy>0 and 65 or 535
        end
        b.dir=Art.direction(b.vx,b.vy,b.dir)
    else
        b.vx,b.vy=nil,nil
        local corners={{65,65},{Arena.width-65,65},{Arena.width-65,535},{65,535}}
        local c=corners[(b.id+W.round-2)%4+1];b.tx,b.ty=c[1],c[2]
    end
    local x,y=Arena.clearSpot(b.tx-24,b.ty-24,48,48);b.tx,b.ty=x+24,y+24
    b.phase='position'
end
function W.fireLarva(b)
    local x,y=Arena.clearSpot(b.x-9,b.y-9,18,18)
    return Magma.spawn(x+9,y+9)
end
function W.soloLarvae(b)
    if W.aliveCount()~=1 then return end
    W.fireLarva({x=b.x-20,y=b.y});W.fireLarva({x=b.x+20,y=b.y})
end
function W.releaseLarvae()
    -- The whole corner volley fires together, once every surviving sister is ready.
    local ready=false
    for _,b in ipairs(W.bees) do if b.hp>0 then
        if b.attack~=3 or b.phase~='aim' or b.time>0 then return end
        ready=true
    end end
    if not ready then return end
    for _,b in ipairs(W.bees) do if b.hp>0 then
        if W.aliveCount()==1 then W.soloLarvae(b) elseif b.launchLarva then W.fireLarva(b) end
        b.phase='hiding';b.time=.22
    end end
end
function W.approach(b,x,y,speed,dt)
    local dx,dy=x-b.x,y-b.y;local d=math.sqrt(dx*dx+dy*dy)
    local step=math.min(d,speed*dt)
    if d>.01 then
        b.dir=Art.direction(dx,dy,b.dir)
        local steps=math.max(1,math.ceil(step/4))
        for _=1,steps do
            b.x=b.x+dx/d*step/steps;b.y=b.y+dy/d*step/steps
            W.chargeContact(b);if player.reset then return false end
        end
    end
    return d<=speed*dt+.01
end
function W.touches(b)
    local grounded=b.hp<=0 or b.phase=='fatigued'
    local y=b.y+(grounded and 0 or -10)
    return checkCollision(player.x,player.y,30,24,b.x-26,y-32,52,64)
end
function W.chargeContact(b)
    if b.hp<=0 or b.phase=='fatigued' then return end
    if W.hitGrace<=0 and (b.contactGrace or 0)<=0 and W.touches(b) then Hazards.kill() end
end
function W.updateBees(dt)
    local tempo=W.tempo();local cadence=tempo*(W.attackRate or 1);local move=W.movementRate or 1
    if not W.roundActive then
        W.rest=W.rest-dt*cadence
        if W.rest<=0 then W.beginRound() end
    end
    W.roundClock=W.roundClock+dt*cadence
    for _,b in ipairs(W.bees) do
        b.flash=math.max(0,b.flash-dt);b.contactGrace=math.max(0,(b.contactGrace or 0)-dt)
        if b.hp<=0 then b.deadTime=(b.deadTime or 0)+dt
        elseif b.phase=='queued' then
            if W.roundClock>=b.delay then W.positionAttack(b) end
        elseif b.phase=='position' then
            if W.approach(b,b.tx,b.ty,1165*tempo*move,dt) then
                b.phase='aim';b.time=b.attack==3 and .5 or .23
            end
        elseif b.phase=='aim' then
            b.time=b.time-dt*(b.attack==3 and cadence or 1)
            if b.time<=0 then
                if b.attack==3 then
                    W.releaseLarvae()
                else W.soloLarvae(b);b.phase='charge' end
            end
        elseif b.phase=='charge' then
            local speed=1510*tempo*move;local steps=math.max(1,math.ceil(speed*dt/4))
            for _=1,steps do
                local x,y=b.x+b.vx*speed*dt/steps,b.y+b.vy*speed*dt/steps
                if Arena.blocked(x-24,y-24,48,48) then
                    b.dashesLeft=(b.dashesLeft or 1)-1
                    if b.dashesLeft>0 then
                        b.vx,b.vy=-b.vx,-b.vy;b.dir=Art.direction(b.vx,b.vy,b.dir)
                        b.phase='aim';b.time=.20
                    else b.phase='fatigued';b.time=1.65 end
                    BossFX.burst(b.x,b.y,{1,.7,.2},2);break
                end
                b.x,b.y=x,y;W.chargeContact(b)
                if player.reset then break end
            end
        elseif b.phase=='fatigued' then
            b.time=b.time-dt;if b.time<=0 then b.phase='cooldown';W.combo=nil end
        elseif b.phase=='hiding' then
            b.time=b.time-dt*cadence;if b.time<=0 then b.phase='cooldown' end
        end
    end
    W.contact()
    local complete=W.roundActive
    for _,b in ipairs(W.bees) do if b.hp>0 and b.phase~='cooldown' then complete=false end end
    if complete then W.roundActive=false;W.rest=.04 end
end
function W.update(dt)
    if not W.active then return end
    W.syncAnchor();W.hitGrace=math.max(0,W.hitGrace-dt);W.elapsed=W.elapsed+dt;W.flash=math.max(0,W.flash-dt)
    if not W.defeated then W.updateBees(dt);W.updateLava(dt)
    else
        for _,b in ipairs(W.bees) do b.deadTime=(b.deadTime or 0)+dt;b.contactGrace=math.max(0,(b.contactGrace or 0)-dt) end
        W.contact()
    end
    for i=#W.blasts,1,-1 do local p=W.blasts[i];p.life=p.life-dt;if p.life<=0 then table.remove(W.blasts,i) end end
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
    for _,b in ipairs(W.bees) do
        if b.hp>0 and (b.phase=='position' or b.phase=='aim') and ((b.attack==3 and b.launchLarva) or W.aliveCount()==1) then
            local x,y=b.tx or b.x,b.ty or b.y
            g.setColor(1,.55,.12,.55+.25*math.sin(W.elapsed*12));g.setLineWidth(2)
            g.circle('line',x,y,38);g.line(x-10,y,x+10,y);g.line(x,y-10,x,y+10)
            g.setFont(UI.fonts.small);g.printf(require('localization').text('INVOCATION'),x-65,y+42,130,'center')
        end
    end
    for _,p in ipairs(W.eruptions) do
        g.setColor(1,.7,.12,.45+p.age*.4);g.setLineWidth(2)
        g.ellipse('line',p.x,p.y,p.rx+8+p.age*8,p.ry+8+p.age*8)
    end
    g.pop()
end
function W.lavaMaterial(time)
    local g=love.graphics
                W.lavaShader=W.lavaShader or g.newShader([[
                    extern float pulse;
                    vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen) {
                        vec4 p=Texel(tex,uv);float light=max(p.r,max(p.g,p.b));
                        float seam=smoothstep(.18,.7,light)*(.75+.25*sin(uv.y*75.0+uv.x*31.0));
                        vec3 lava=mix(vec3(.025,.012,.018),vec3(1.0,.09,.008),seam);
                        lava+=vec3(.3,.16,.015)*pow(seam,3.0)*pulse;
                        return vec4(lava,p.a)*color;
                    }
                ]])
                W.lavaShader:send('pulse',.8+.2*math.sin((time or W.elapsed)*6))
    return W.lavaShader
end
function W.draw(airborne)
    if not W.active then return end
    local g=love.graphics
    for _,b in ipairs(W.bees) do
        local flying=b.phase~='fatigued' and b.phase~='dead'
        if airborne==flying then
            local alpha=b.hp>0 and (b.phase=='hiding' and .28 or 1) or 1
            g.setColor(b.hp<=0 and .55 or 1,b.hp<=0 and .3 or 1-b.flash*.6,b.hp<=0 and .25 or 1-b.flash*.6,alpha)
            local previous=g.getShader()
            if W.hardcore then
                g.setColor(1,1,1,alpha);g.setShader(W.lavaMaterial())
            end
            Art.drawFacing(flying and 'wasp' or 'wasp_ground',b.dir,b.x,b.y+(flying and -10+math.sin(W.elapsed*36+b.id)*2 or 0),flying and 96 or 80)
            g.setShader(previous)
            if W.hardcore and b.hp>0 then
                g.push('all');g.setBlendMode('add')
                for i=1,4 do local y=b.y-22+i*9
                    g.setColor(1,.18,.015,.12);g.circle('fill',b.x,y,8)
                    g.setColor(1,.55,.08,.85);g.circle('fill',b.x,y,2)
                end
                g.pop()
            end
            if b.hp>0 then
                if b.phase=='fatigued' then
                    g.setColor(1,.9,.4);for i=1,3 do local a=W.elapsed*3+i*math.pi*2/3;g.circle('fill',b.x+math.cos(a)*21,b.y-37+math.sin(a)*5,2) end
                end
            end
        end
    end
    if airborne then
        for _,p in ipairs(W.blasts) do g.setColor(1,.45,.1,p.life/.35);g.circle('line',p.x,p.y,48*(1-p.life/.35)) end
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
