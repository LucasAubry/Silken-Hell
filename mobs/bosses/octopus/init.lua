local TentacleVector=require 'mobs.bosses.octopus.tentacle'
local Head=require 'mobs.bosses.octopus.head'
local O={active=false,projectiles={},blots={},crabs={},crabProbes={{0,0},{-10,0},{10,0},{0,-8},{0,8}}}
function O.reset(active)
    O.active=active; O.name='Le Poulpe des marées'; O.hp=8; O.maxHp=8; O.flash=0; O.defeated=false
    O.x=Arena.width/2; O.y=300; O.angle=0; O.faceAngle=0; O.spin=1; O.clock=0
    O.angularVelocity=.32; O.shot=2; O.summon=1.2; O.extension=1
    O.rider=nil; O.escape=nil; O.grace=0; O.waveActive=false; O.waveId=0; O.dashHeld=false
    O.inkPools={}; O.blasts={}; O.inkCount=0; O.poolCooldown=0;O.inkRotation=0;O.crabRage=0
    O.projectiles={}; O.blots={}; O.crabs={}; O.wounds={}; player.ink=0
    O.arms={3,3,3,3,3,3,3,3}
    O.stun=0;O.enraged=false;O.barrage=0;O.barrageShot=0;O.tipOffsets=nil;O.tether=nil;O.restCurves=nil;O.pullCurve=nil;O.restSpines=nil
    if active then player.x=O.x-15; player.y=535; player.lastMoveX=0; player.lastMoveY=-1 end
end
function O.sprite()
    return 'octopus_extended_down',O.angle,360
end
function O.maxSpin()
    return 2.4
end
function O.liveCrabs()
    local count=0
    for _,c in ipairs(O.crabs) do if not c.dead then count=count+1 end end
    return count
end
function O.detach()
    O.rider=nil; O.escape=nil
end
function O.riderInput(dx,dy,slow,dt)
    -- Towing uses ordinary player movement, including the slow control.
    return false
end
function O.moveRider() end
function O.tip(arm)
    if not O.tipOffsets then
        O.tipOffsets={}
        local key,_,size=O.sprite();local a=Art.images[key];local scale=size/math.max(a.w,a.h)
        for y=0,191 do for x=0,191 do if a.mask and a.mask[y*192+x] then
            local dx,dy=((x+.5)/192-.5)*a.w*scale,((y+.5)/192-.5)*a.h*scale
            local index=math.floor((math.atan2(dy,dx)%(2*math.pi))/(math.pi/4))+1
            local d=dx*dx+dy*dy;local old=O.tipOffsets[index]
            if not old or d>old.d then O.tipOffsets[index]={x=dx,y=dy,d=d} end
        end end end
        -- The grasp point is inside the curled tip, not its outer silhouette.
        -- Keep the outside of the new curled arm within the original reach.
        for _,tip in pairs(O.tipOffsets) do tip.x=tip.x*.82;tip.y=tip.y*.82;tip.d=tip.d*.82*.82 end
    end
    local p=O.tipOffsets[arm] or {x=math.cos((arm-.5)*math.pi/4)*170,y=math.sin((arm-.5)*math.pi/4)*170}
    return O.x+math.cos(O.angle)*p.x-math.sin(O.angle)*p.y,O.y+math.sin(O.angle)*p.x+math.cos(O.angle)*p.y
end
function O.inCorner()
    local x,y=player.x+15,player.y+12
    return (x<105 or x>Arena.width-105) and (y<105 or y>495)
end
function O.tearArm(arm)
    if O.defeated or O.arms[arm]==0 then return end
    O.arms[arm]=0;O.hp=O.hp-1;O.flash=.3;O.rider=nil;O.stun=0;O.spin=-O.spin
    O.wounds[#O.wounds+1]={x=player.x+15,y=player.y+12,life=.55};Audio.play('pick')
    if O.hp<=O.maxHp/2 and not O.enraged then
        O.enraged=true;O.barrage=3;O.barrageShot=0
    end
    if O.hp==0 then
        O.defeated=true;O.projectiles={};O.blots={};O.inkPools={};O.blasts={}
        for _,c in ipairs(O.crabs) do if not c.dead then c.dead=0 end end
        objet.larme.taken=false;objet.larme.x=O.x-15;objet.larme.y=O.y-20
    end
end
function O.armAt(x,y)
    local dx,dy=x-O.x,y-O.y
    if dx*dx+dy*dy<=65^2 then return nil end
    local xx=math.cos(O.angle)*dx+math.sin(O.angle)*dy
    local yy=-math.sin(O.angle)*dx+math.cos(O.angle)*dy
    for arm=1,8 do if O.arms[arm]>0 then
        local points=O.armCurve(arm);local bounds=points.bounds
        if not bounds then
            bounds={minX=math.huge,minY=math.huge,maxX=-math.huge,maxY=-math.huge,segments={}}
            for i=1,#points-1,2 do
                local a,b=points[i],points[math.min(#points,i+2)];local width=math.max(a.width,b.width)
                local minX,maxX=math.min(a.x,b.x)-width,math.max(a.x,b.x)+width
                local minY,maxY=math.min(a.y,b.y)-width,math.max(a.y,b.y)+width
                bounds.minX=math.min(bounds.minX,minX);bounds.maxX=math.max(bounds.maxX,maxX)
                bounds.minY=math.min(bounds.minY,minY);bounds.maxY=math.max(bounds.maxY,maxY)
                local vx,vy=b.x-a.x,b.y-a.y
                bounds.segments[#bounds.segments+1]={minX,maxX,minY,maxY,a.x,a.y,vx,vy,1/math.max(.001,vx*vx+vy*vy),a.width,b.width-a.width}
            end
            points.bounds=bounds
        end
        if xx>=bounds.minX and xx<=bounds.maxX and yy>=bounds.minY and yy<=bounds.maxY then
            for _,p in ipairs(bounds.segments) do
                if xx>=p[1] and xx<=p[2] and yy>=p[3] and yy<=p[4] then
                    local t=math.max(0,math.min(1,((xx-p[5])*p[7]+(yy-p[6])*p[8])*p[9]))
                    local cx,cy=p[5]+p[7]*t,p[6]+p[8]*t;local r=p[10]+p[11]*t
                    if (xx-cx)^2+(yy-cy)^2<=r*r then return arm end
                end
            end
        end
    end end
end
function O.touches(x,y)
    return O.armAt(x,y)~=nil
end
function O.ink()
    O.inkCount=O.inkCount+1
    local px,py=player.x+15,player.y+12
    local dx,dy=px-O.x,py-O.y;local d=math.sqrt(dx*dx+dy*dy)
    local ux,uy=0,1;if d>1 then ux,uy=dx/d,dy/d end
    local x,y
    if O.inkCount%2==1 then
        x,y=O.x-ux*225,O.y-uy*225
        x=math.max(55,math.min(Arena.width-55,x));y=math.max(70,math.min(530,y))
        x,y=Arena.clearSpot(x-20,y-15,40,30);x=x+20;y=y+15
    else
        -- A fixed 95px radius around the player; rotate only to avoid walls.
        local start=math.atan2(uy,ux)+math.pi/2
        for i=0,23 do local angle=start+i*math.pi/12
            local cx,cy=px+math.cos(angle)*95,py+math.sin(angle)*95
            if cx>=45 and cx<=Arena.width-45 and cy>=65 and cy<=535 and not Arena.blocked(cx-20,cy-15,40,30) then x,y=cx,cy;break end
        end
        if not x then return end
    end
    O.projectiles[#O.projectiles+1]={x=O.x,y=O.y,fromX=O.x,fromY=O.y,tx=x,ty=y,age=0,life=.85}
end
function O.explodeCrab(c)
    if c.dead then return end
    c.dead=0; c.frenzy=nil
    O.blasts[#O.blasts+1]={x=c.x,y=c.y,age=0}
    BossFX.burst(c.x,c.y,{.5,.3,.8},3)
    local neighbors={};for _,other in ipairs(O.crabs) do neighbors[#neighbors+1]=other end
    for _,other in ipairs(mobs) do if other.type=='crab' then neighbors[#neighbors+1]=other end end
    for _,other in ipairs(neighbors) do
        if other~=c and not other.dead and not other.emerge then
            local dx,dy=other.x-c.x,other.y-c.y; local d=math.sqrt(dx*dx+dy*dy)
            if d<185 then
                if d<1 then dx,dy,d=math.cos(other.age or 0),math.sin(other.age or 0),1 end
                other.fling={vx=dx/d*580,vy=dy/d*580,time=.65}
            end
        end
    end
end
function O.updateInk(dt)
    O.poolCooldown=math.max(0,O.poolCooldown-dt)
    for i=#O.projectiles,1,-1 do local p=O.projectiles[i]
        p.age=(p.age or 0)+dt
        if p.tx then
            local t=math.min(1,p.age/.85);p.x=p.fromX+(p.tx-p.fromX)*t;p.y=p.fromY+(p.ty-p.fromY)*t
            if t==1 then
                O.inkPools[#O.inkPools+1]={x=p.tx,y=p.ty,rx=38,ry=27,life=7,seed=O.inkCount}
                table.remove(O.projectiles,i)
            end
        else table.remove(O.projectiles,i) end
    end
    for i=#O.inkPools,1,-1 do local p=O.inkPools[i]
        p.life=p.life-dt
        if p.life<=0 then table.remove(O.inkPools,i)
        elseif O.poolCooldown==0 and Hazards.inEllipse(player.x+15,player.y+12,p,0) then O.splash();O.poolCooldown=4 end
    end
    for i=#O.blasts,1,-1 do local p=O.blasts[i];p.age=p.age+dt;if p.age>.5 then table.remove(O.blasts,i) end end
end
function O.drawGround()
    if not O.active then return end
    local g=love.graphics;g.push('all')
    for _,p in ipairs(O.inkPools) do
        g.setColor(.07,.015,.1,math.min(1,p.life));Art.drawTinted('ink_splatter',p.x,p.y,p.rx*2.5,p.seed)
    end
    for _,p in ipairs(O.blasts) do g.setColor(.7,.4,1,1-p.age*2);g.ellipse('line',p.x,p.y,185*p.age*2,130*p.age*2) end
    for _,c in ipairs(O.crabs) do if c.emerge and c.emerge>=0 and not c.dead then
        local u=math.min(1,c.emerge/.8);local fade=1-math.max(0,(c.emerge-.8)/.25)
        g.setColor(.025,.07,.08,.65*fade);g.ellipse('fill',c.x,c.y+13,22,8)
        for i=1,7 do local a=i*2.4+c.age;local r=12+u*18
            g.setColor(.22,.34,.31,(1-u)*.55);g.ellipse('fill',c.x+math.cos(a)*r,c.y+12+math.sin(a)*r*.3-u*9,2.5,1.5)
        end
    end end
    g.pop()
end
function O.splash()
    O.blots={}; player.ink=4
    -- Broad irregular overlapping stains cover most of the view, then fade.
    for i=1,7 do O.blots[i]={x=.12+(i-1)%3*.37,y=.14+math.floor((i-1)/3)*.34,r=Arena.width*.32,life=4,seed=i} end
end
function O.hurt(crab,arm)
    if O.defeated or crab.dead or crab.emerge then return end
    arm=arm or O.armAt(crab.x,crab.y)
    if not arm or O.arms[arm]<=0 then return end
    O.explodeCrab(crab)
    -- Extra impacts cannot extend the three-second opportunity indefinitely.
    if O.stun<=0 then O.stun=3;O.angularVelocity=0 end
end
function O.crabPathClear(x,y)
    if Arena.blocked(x-14,y-12,28,24) then return false end
    if not O.active or O.defeated then return true end
    if (x-O.x)^2+(y-O.y)^2<185^2 then return false end
    for _,p in ipairs(O.crabProbes) do if O.armAt(x+p[1],y+p[2]) then return false end end
    return true
end
function O.spawnClear(x,y)
    if not O.crabPathClear(x,y) then return false end
    for _,p in ipairs(O.inkPools) do if Hazards.inEllipse(x,y,p,20) then return false end end
    for _,c in ipairs(O.crabs) do if not c.dead and (c.x-x)^2+(c.y-y)^2<30^2 then return false end end
    return true
end
function O.releaseCrabs()
    if O.defeated or O.liveCrabs()>=32 then return end
    O.waveActive=true;O.waveId=O.waveId+1
    local count=math.min(O.enraged and 8 or 6,32-O.liveCrabs())
    local px,py=player.x+15,player.y+12
    for i=1,count do
        local x,y
        for j=0,71 do
            local a=O.waveId*.41+(i-1)*math.pi*2/count+j*2.399963
            local r=125+(j%3)*30
            local cx,cy=px+math.cos(a)*r,py+math.sin(a)*r
            if O.spawnClear(cx,cy) then x,y=cx,cy;break end
        end
        -- If ink/walls cover every nearby site, wait for the next wave.
        if x then O.crabs[#O.crabs+1]={x=x,y=y,tx=x,ty=y,emerge=-(i-1)*.025,angle=math.pi/2,age=i*.2,
            wave=O.waveId,speed=195+(8-O.hp)*8,vx=0,vy=1,
            hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12} end
    end
    if Bestiary.discover('crab') then Bestiary.save() end
end
function O.crabContact(c)
    if c.dead or c.emerge or c.is_frozen or c.tunnelTravel or O.defeated or player.reset then return end
    if (player.x+15-c.x)^2+(player.y+12-c.y)^2<27^2 then
        if c.inked and player.dashing then
            if not c.kickGrace or c.kickGrace<=0 then
                local dx,dy=c.x-player.x-15,c.y-player.y-12;local d=math.sqrt(dx*dx+dy*dy)
                if d<1 then dx,dy=player.moveX or player.lastMoveX or 0,player.moveY or player.lastMoveY or 1;d=math.max(.001,math.sqrt(dx*dx+dy*dy)) end
                c.fling={vx=dx/d*760,vy=dy/d*760,time=1.6};c.kickGrace=.22
                BossFX.burst(c.x,c.y,{.2,.6,.7},1)
            end
        elseif (c.kickGrace or 0)<=0 then Hazards.kill();return end
    end
    if not O.active then return end
    for _,p in ipairs(O.crabProbes) do
        local x,y=c.x+p[1],c.y+p[2]
        local arm=O.armAt(x,y)
        if arm then O.hurt(c,arm);return end
    end
end
function O.moveFlungCrab(c,dt,contact)
    local f=c.fling;local speed=math.sqrt(f.vx*f.vx+f.vy*f.vy)
    local steps=math.max(1,math.ceil(speed*dt/4))
    for _=1,steps do
        local hx,hy=Arena.move(c,f.vx*dt/steps,f.vy*dt/steps)
        if hx or hy then O.explodeCrab(c);break end
        contact();if c.dead or player.reset then break end
    end
    f.time=f.time-dt;if f.time<=0 then c.fling=nil end
end
function O.inkCrab(c,dt)
    c.kickGrace=math.max(0,(c.kickGrace or 0)-dt)
    if not c.inked then for _,p in ipairs(O.inkPools or {}) do
        if Hazards.inEllipse(c.x,c.y,p,0) then c.inked=true;c.frenzy=true;c.frenzyTurn=0;break end
    end end
end
function O.updateCrabs(dt)
    for i=#O.crabs,1,-1 do local c=O.crabs[i]
        c.age=c.age+dt
        if c.dead then
            c.dead=c.dead+dt
            if c.dead>=1.2 then table.remove(O.crabs,i) end
        elseif c.emerge then
            local covered=false
            for _,p in ipairs(O.inkPools) do if Hazards.inEllipse(c.x,c.y,p,20) then covered=true;break end end
            if covered then table.remove(O.crabs,i)
            else c.emerge=c.emerge+dt;if c.emerge>=1.05 then c.emerge=nil end end
        elseif c.emerge then
            c.emerge=c.emerge+dt; local t=math.min(1,c.emerge/.9)
            c.x=O.x+(c.tx-O.x)*t; c.y=O.y+(c.ty-O.y)*t
            if t==1 then c.emerge=nil; O.crabContact(c) end
        else
            O.inkCrab(c,dt)
            if c.fling then O.moveFlungCrab(c,dt,function() O.crabContact(c) end)
            else O.walkCrab(c,dt,function() O.crabContact(c) end) end
        end
        if player.reset then return end
    end
end
function O.crabSpeed(c)
    return c.speed*1.3*(c.frenzy and 1.4 or 1)*((player.ink or 0)>0 and 1.75 or 1)*((O.rider or O.crabRage>0) and 1.45 or 1)
end
function O.walkCrab(c,dt,contact)
    if c.inked then
        c.frenzyTurn=(c.frenzyTurn or 0)-dt
        if c.frenzyTurn<=0 then c.frenzyStep=(c.frenzyStep or 0)+1;local a=(c.wave or 0)*.71+(c.age or 0)*.3+c.frenzyStep*2.399963;c.vx,c.vy=math.cos(a),math.sin(a);c.frenzyTurn=.22 end
    else
        local dx,dy=player.x+15-c.x,player.y+12-c.y
        local length=math.sqrt(dx*dx+dy*dy)
        if length>0 then c.vx,c.vy=dx/length,dy/length end
    end
    c.vx,c.vy=c.vx or 0,c.vy or 1
    -- Walk around the whole resting boss; only a player kick may cross it.
    if O.active and not O.defeated then
        local dx,dy=c.x-O.x,c.y-O.y;local d=math.sqrt(dx*dx+dy*dy)
        local tx,ty=player.x+15-O.x,player.y+12-O.y
        local desired=math.atan2(ty,tx);local angle=math.atan2(dy,dx)
        local delta=(desired-angle+math.pi)%(math.pi*2)-math.pi
        if d<230 and (c.vx*dx+c.vy*dy<0 or math.abs(delta)>.35) then
            c.orbitSide=c.orbitSide or (delta>=0 and 1 or -1)
            local target=angle+c.orbitSide*.32
            local gx,gy=O.x+math.cos(target)*210,O.y+math.sin(target)*210
            local vx,vy=gx-c.x,gy-c.y;local length=math.sqrt(vx*vx+vy*vy)
            if length>0 then c.vx,c.vy=vx/length,vy/length end
        elseif d>=230 then c.orbitSide=nil end
    end
    if O.active and not O.defeated then
        local wanted=math.atan2(c.vy,c.vx);local found=false
        for _,offset in ipairs({0,.55,-.55,1.1,-1.1,1.65,-1.65,2.2,-2.2,math.pi}) do
            local vx,vy=math.cos(wanted+offset),math.sin(wanted+offset);local clear=true
            for r=6,24,6 do if not O.crabPathClear(c.x+vx*r,c.y+vy*r) then clear=false;break end end
            if clear then c.vx,c.vy=vx,vy;found=true;break end
        end
        if not found then return end
    end
    c.angle=math.atan2(c.vy,c.vx); c.dir=Art.direction(c.vx,c.vy,c.dir)
    local speed=O.crabSpeed(c)
    local steps=math.max(1,math.ceil(speed*dt/4))
    for _=1,steps do
        local nx,ny=c.x+c.vx*speed*dt/steps,c.y+c.vy*speed*dt/steps
        if not O.crabPathClear(nx,ny) then break end
        local hx,hy=Arena.move(c,c.vx*speed*dt/steps,c.vy*speed*dt/steps)
        if hx or hy then O.explodeCrab(c);break end
        if O.active and not O.defeated and not c.inked then
            local dx,dy=c.x-O.x,c.y-O.y;local d=math.sqrt(dx*dx+dy*dy)
            if d>0 and d<185 then
                local tx,ty=O.x+dx/d*185,O.y+dy/d*185
                if not Arena.blocked(tx-14,ty-12,28,24) then c.x=tx;c.y=ty end
            end
        end
        contact(); if c.dead or player.reset then break end
    end
end
function O.spawnCrab(x,y,speed)
    mobs[#mobs+1]={type='crab',x=x,y=y,speed=speed or 95,age=0,angle=0,dir='down',vx=0,vy=1,
        hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
end
MobBehaviors.crab=require('mobs.crab')(O)

function O.contact()
    if not O.active or O.defeated or player.reset then return end
    for _,c in ipairs(O.crabs) do O.crabContact(c);if player.reset then return end end
    for _,c in ipairs(mobs) do if c.type=='crab' then O.crabContact(c);if player.reset then return end end end
    local cx=math.max(player.x,math.min(O.x,player.x+30))
    local cy=math.max(player.y,math.min(O.y,player.y+24))
    if (cx-O.x)^2+(cy-O.y)^2<65^2 then Hazards.kill();return end
    if O.rider then
        if O.inCorner() then O.tearArm(O.rider.arm) end
        return
    end
    if Bosses and Bosses.otherRider(O) then return end
    if O.stun>0 then
        if player.dashing then for arm=1,8 do if O.arms[arm]>0 then
            local x,y=O.tip(arm)
            if (player.x+15-x)^2+(player.y+12-y)^2<34^2 then O.rider={arm=arm};return end
        end end end
        return
    end
    for y=player.y+2,player.y+22,5 do for x=player.x+2,player.x+28,5 do
        if O.touches(x,y) then Hazards.kill();return end
    end end
end
function O.update(dt)
    if not O.active or player.reset then return end
    O.updateTether(dt)
    if O.defeated then O.updateCrabs(dt);return end
    O.clock=O.clock+dt;O.flash=math.max(0,O.flash-dt)
    if O.stun>0 then
        O.stun=math.max(0,O.stun-dt);O.angularVelocity=0
        if O.stun==0 then O.detach() end
    else
        local speed=O.enraged and 2.35 or .75
        O.angularVelocity=O.spin*speed*(O.movementRate or 1)
        local steps=math.max(1,math.ceil(dt/.006))
        for _=1,steps do
            O.angle=O.angle+O.angularVelocity*dt/steps;O.contact()
            if player.reset or O.stun>0 or O.defeated then break end
        end
        O.summon=O.summon-dt*(O.attackRate or 1)
        if O.summon<=0 then O.releaseCrabs();O.summon=O.enraged and 2.5 or 3.2 end
        O.shot=O.shot-dt*(O.attackRate or 1)
        if O.shot<=0 then O.ink();O.shot=O.enraged and .85 or 1.25 end
        if O.barrage>0 then
            O.barrage=math.max(0,O.barrage-dt);O.barrageShot=O.barrageShot-dt
            if O.barrageShot<=0 then O.ink();O.barrageShot=.16 end
        end
    end
    if player.reset then return end
    O.contact();if player.reset then return end
    O.updateCrabs(dt);if player.reset then return end
    O.updateInk(dt)
    for _,list in ipairs({O.blots,O.wounds}) do for i=#list,1,-1 do
        list[i].life=list[i].life-dt;if list[i].life<=0 then table.remove(list,i) end
    end end
end
function O.drawCrabs()
    local g=love.graphics
    for _,c in ipairs(O.crabs) do
        local bob=c.emerge and 0 or math.sin(c.age*23)*1.2
        g.push('all'); g.translate(c.x,c.y+bob)
        -- The sprite faces its walking direction.
        g.rotate(c.angle-math.pi/2+(c.dead and math.min(1,c.dead/.18)*.3 or 0))
        if c.emerge and not c.dead then
            local amount=math.max(0,math.min(1,(c.emerge-.15)/.65))
            if amount>0 then
                local a=Art.images.crab_open
                local qx,qy,qw,qh=a.quad:getViewport();local iw,ih=a.image:getDimensions()
                a.emerging=a.emerging or g.newQuad(qx,qy,qw,qh,iw,ih)
                a.emerging:setViewport(qx,qy,qw,math.max(1,qh*amount),iw,ih)
                local scale=46/math.max(qw,qh);g.setColor(1,1,1)
                g.draw(a.image,a.emerging,-qw*scale/2,qh*scale/2-qh*amount*scale,0,scale,scale)
            end
        elseif c.dead then
            local a=Art.images.crab_dead; local amount=math.max(0,1-math.max(0,c.dead-.22)/.98)
            local qx,qy,qw,qh=a.quad:getViewport(); local iw,ih=a.image:getDimensions()
            a.sink=a.sink or g.newQuad(qx,qy,qw,qh,iw,ih); a.sink:setViewport(qx,qy,qw,math.max(1,qh*amount),iw,ih)
            local scale=46/math.max(qw,qh); g.setColor(1,1,1,amount)
            g.draw(a.image,a.sink,-qw*scale/2,qh*scale/2-qh*amount*scale,0,scale,scale)
        else g.setColor(c.inked and .08 or 1,c.inked and .07 or 1,c.inked and .1 or 1); Art.draw(math.floor(c.age*(c.frenzy and 24 or 6))%2==0 and 'crab_open' or 'crab_closed',0,0,46) end
        g.pop()
    end
end
-- All eight arms share one vector skin and curve, at rest and under tension.
function O.updateTether(dt)
    if O.rider then
        O.tip(O.rider.arm)
        local tip=O.tipOffsets[O.rider.arm]
        local dx,dy=player.x+15-O.x,player.y+12-O.y
        local x=math.cos(O.angle)*dx+math.sin(O.angle)*dy
        local y=-math.sin(O.angle)*dx+math.cos(O.angle)*dy
        local t=O.tether
        if not t or t.arm~=O.rider.arm then t={arm=O.rider.arm,blend=0,x=tip.x,y=tip.y};O.tether=t end
        t.x,t.y=x,y
        local target=1
        t.blend=t.blend+(target-t.blend)*(1-math.exp(-18*dt))
    elseif O.tether then
        local t=O.tether
        if O.defeated or O.arms[t.arm]==0 then O.tether=nil;return end
        local tip=O.tipOffsets[t.arm];local ease=1-math.exp(-16*dt)
        t.x=t.x+(tip.x-t.x)*ease;t.y=t.y+(tip.y-t.y)*ease
        t.blend=t.blend*(1-ease)
        if t.blend<.005 then O.tether=nil end
    end
end
function O.restSpine(arm)
    O.restSpines=O.restSpines or {};if O.restSpines[arm] then return O.restSpines[arm] end
    O.tip(arm);local tip=O.tipOffsets[arm];local radius=math.sqrt(tip.d)
    local side=tip.x<0 and -1 or 1
    local rotation=math.atan2(tip.y,tip.x)-math.atan2(7*side,156)
    local scale=radius/math.sqrt(156*156+49)
    local knots={{40/scale*math.cos(math.atan2(7,156)),40/scale*math.sin(math.atan2(7,156))},{83,-9},{115,-18},{147,-13},{170,3},{173,21},{160,29},{150,19},{156,7}}
    for _,k in ipairs(knots) do k[2]=k[2]*side end
    local points={}
    for i=0,64 do
        local t=i/64*(#knots-1);local j=math.min(#knots-1,math.floor(t)+1);local u=t-(j-1)
        local a,b,c,d=knots[math.max(1,j-1)],knots[j],knots[j+1],knots[math.min(#knots,j+2)]
        local function spline(k) return .5*((2*b[k])+(-a[k]+c[k])*u+(2*a[k]-5*b[k]+4*c[k]-d[k])*u*u+(-a[k]+3*b[k]-3*c[k]+d[k])*u*u*u) end
        local x,y=spline(1)*scale,spline(2)*scale
        points[i+1]={x=math.cos(rotation)*x-math.sin(rotation)*y,y=math.sin(rotation)*x+math.cos(rotation)*y}
    end
    points[65]={x=tip.x,y=tip.y};O.restSpines[arm]=points;return points
end
function O.tetherCurve(arm,tx,ty)
    O.tip(arm);local tip=O.tipOffsets[arm]
    local radius=math.sqrt(tip.d);local ux,uy=tip.x/radius,tip.y/radius
    local bx,by=ux*40,uy*40
    local dx,dy=tx-bx,ty-by;local distance=math.max(1,math.sqrt(dx*dx+dy*dy))
    local nx,ny=-dy/distance,dx/distance
    local tension=math.max(0,math.min(1,(distance-110)/260))
    local slack=(1-tension)*22
    local c1x,c1y=bx+ux*62,by+uy*62
    local c2x,c2y=tx-dx/distance*math.min(65,distance*.3)+nx*slack,ty-dy/distance*math.min(65,distance*.3)+ny*slack
    local pull=math.sqrt((tx-tip.x)^2+(ty-tip.y)^2)
    local uncurl=math.min(1,pull/135)
    local rest=O.restSpine(arm)
    local points={};local length=0
    for i=0,64 do
        local t=i/64;local u=1-t
        local x=u*u*u*bx+3*u*u*t*c1x+3*u*t*t*c2x+t*t*t*tx
        local y=u*u*u*by+3*u*u*t*c1y+3*u*t*t*c2y+t*t*t*ty
        local resting=rest[i+1]
        local follow=t*t*(3-2*t)
        local rx,ry=resting.x+(tx-tip.x)*follow,resting.y+(ty-tip.y)*follow
        x=rx+(x-rx)*uncurl;y=ry+(y-ry)*uncurl
        if i==64 then x,y=tx,ty end
        local previous=points[#points]
        if previous then length=length+math.sqrt((x-previous.x)^2+(y-previous.y)^2) end
        points[#points+1]={x=x,y=y,width=(18*(1-t)^.65+2.4)*(1-.08*(1-uncurl))*(1-.18*tension*math.sin(t*math.pi/2)),distance=length}
    end
    for i,p in ipairs(points) do
        local a,b=points[math.max(1,i-1)],points[math.min(#points,i+1)]
        local dx,dy=b.x-a.x,b.y-a.y;local d=math.max(.001,math.sqrt(dx*dx+dy*dy))
        local facing=tip.x<0 and -1 or 1
        p.nx,p.ny=-dy/d*facing,dx/d*facing
    end
    return points,length
end
function O.armCurve(arm)
    O.tip(arm);local tip=O.tipOffsets[arm]
    local t=O.tether
    if t and t.arm==arm then
        local x=tip.x+(t.x-tip.x)*t.blend;local y=tip.y+(t.y-tip.y)*t.blend
        local cache=O.pullCurve
        if not cache or cache.arm~=arm or cache.x~=x or cache.y~=y then
            cache={arm=arm,x=x,y=y,points=O.tetherCurve(arm,x,y)};O.pullCurve=cache
        end
        return cache.points
    end
    O.restCurves=O.restCurves or {}
    if not O.restCurves[arm] then O.restCurves[arm]=O.tetherCurve(arm,tip.x,tip.y) end
    return O.restCurves[arm]
end
function O.drawArms()
    local g=love.graphics
    g.push('all');g.setShader();g.translate(O.x,O.y);g.rotate(O.angle)
    for arm=1,8 do if O.arms[arm]>0 then
        O.vectorMeshes=O.vectorMeshes or {}
        O.vectorMeshes[arm]=TentacleVector.draw(O.armCurve(arm),1,1-O.arms[arm]/3,O.vectorMeshes[arm])
    end end
    g.pop()
end
function O.draw()
    if not O.active then return end
    local g=love.graphics
    if not O.defeated then
        local angle=O.angle
        O.updateTether(0)
        O.drawArms()
        local key,_,size=O.sprite();local a=Art.images[key];local scale=size/math.max(a.w,a.h)
        Head.draw(a,O.x,O.y,angle,scale,O.flash)
        if O.stun>0 then
            g.push('all');g.setColor(.5,1,1,.75);g.setLineWidth(3)
            for _,corner in ipairs({{32,32},{Arena.width-102,32},{32,498},{Arena.width-102,498}}) do g.rectangle('line',corner[1],corner[2],70,70,10,10) end
            for arm=1,8 do if O.arms[arm]>0 then
                local x,y=O.tip(arm)
                if O.rider and O.rider.arm==arm then x,y=player.x+15,player.y+12 end
                g.circle('line',x,y,17+math.sin(O.clock*10)*2)
            end end
            g.setColor(1,.9,.3)
            for i=1,3 do local t=O.clock*4+i*math.pi*2/3;g.circle('fill',O.x+math.cos(t)*42,O.y-65+math.sin(t)*10,4) end
            g.printf(string.format('%.1f s',O.stun),O.x-60,O.y-105,120,'center');g.pop()
        end
        -- Pupils track the player in the rotating head's local coordinates.
        g.push('all'); g.translate(O.x,O.y); g.rotate(angle)
        local dx,dy=player.x+15-O.x,player.y+12-O.y
        local ex,ey=math.cos(angle)*dx+math.sin(angle)*dy,-math.sin(angle)*dx+math.cos(angle)*dy
        local d=math.max(1,math.sqrt(ex*ex+ey*ey))
        for _,x in ipairs({-20,20}) do
            g.setColor(1,.62,.12); g.ellipse('fill',x,39,6.5,9)
            g.setColor(.045,.025,.07); g.ellipse('fill',x+ex/d*2.5,39+ey/d*3,2.5,6)
            g.setColor(1,1,1); g.circle('fill',x+ex/d*2.5-1,37+ey/d*3,1.2)
        end
        g.pop()
        if O.hp<=O.maxHp/2 then
            g.push('all'); g.translate(O.x+32,O.y-49); g.scale(1+.08*math.sin(O.clock*8))
            g.setColor(1,.13,.16); g.setLineWidth(4)
            for i=0,3 do g.push(); g.rotate(i*math.pi/2); g.line(-14,-4,-7,-5,-5,-7,-4,-14); g.pop() end
            g.pop()
        end
    end
    O.drawCrabs()
    for _,p in ipairs(O.projectiles) do
        g.setColor(.65,.5,.85); Art.draw('ink_splatter',p.x,p.y-math.sin(math.min(1,(p.age or 0)/.85)*math.pi)*75,34,(p.age or 0)*4)
    end
    for _,p in ipairs(O.wounds) do
        for i=1,8 do local a=i*math.pi/4; local d=(.55-p.life)*48
            g.setColor(.45,.85,.9,p.life/.55); g.circle('fill',p.x+math.cos(a)*d,p.y+math.sin(a)*d,2)
        end
    end
    g.setLineWidth(1); g.setColor(1,1,1)
end
function O.drawInk(width,height)
    if not O.active then return end
    local g=love.graphics
    g.push('all'); g.scale((width or Arena.width)/Arena.width,(height or 600)/600)
    for _,b in ipairs(O.blots) do
        g.setColor(.025,.015,.04,math.min(.82,b.life*.28))
        Art.draw('ink_splatter',b.x*Arena.width,b.y*600,b.r*2.3,b.seed*2.4,600*.95)
    end
    g.pop(); g.setColor(1,1,1)
end
return O
