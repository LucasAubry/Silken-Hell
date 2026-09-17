local O={active=false,projectiles={},blots={},crabs={}}
function O.reset(active)
    O.active=active; O.name='Le Poulpe des marées'; O.hp=8; O.maxHp=8; O.flash=0; O.defeated=false
    O.x=Arena.width/2; O.y=300; O.angle=0; O.faceAngle=0; O.spin=1; O.clock=0
    O.angularVelocity=.32; O.shot=2; O.summon=1.2; O.extension=1
    O.rider=nil; O.escape=nil; O.grace=0; O.waveActive=false; O.waveId=0; O.dashHeld=false
    O.inkPools={}; O.blasts={}; O.inkCount=0; O.poolCooldown=0
    O.projectiles={}; O.blots={}; O.crabs={}; O.wounds={}; player.ink=0
    O.arms={8,8,8,8,8,8,8,8}
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
    if not O.rider then return end
    local a=O.angle+O.rider.angle
    O.escape={vx=math.cos(a)*320,vy=math.sin(a)*320,time=.2}
    O.rider=nil; O.grace=.8
end
function O.riderInput(dx,dy,dash,dt)
    local pressed=dash and not O.dashHeld; O.dashHeld=dash
    if O.rider and pressed and (dx~=0 or dy~=0) then O.detach() end
    if O.escape then
        local e=O.escape; local step=math.min(dt,e.time)
        local steps=math.max(1,math.ceil(step*320/4))
        for _=1,steps do
            local x,y=player.x+e.vx*step/steps,player.y+e.vy*step/steps
            if not willCollide(x,player.y) then player.x=x end
            if not willCollide(player.x,y) then player.y=y end
            for _,c in ipairs(O.crabs) do O.crabContact(c) end
            if player.reset then break end
        end
        e.time=e.time-dt; if e.time<=0 then O.escape=nil end
        return true
    end
    return O.rider~=nil
end
function O.moveRider()
    if not O.rider then return end
    local a=O.angle+O.rider.angle
    player.x=O.x+math.cos(a)*O.rider.radius-15
    player.y=O.y+math.sin(a)*O.rider.radius-12
end
function O.armAt(x,y)
    if (x-O.x)^2+(y-O.y)^2<=65^2 then return nil end
    local angle=(math.atan2(y-O.y,x-O.x)-O.angle)%(2*math.pi)
    return math.floor(angle/(math.pi/4))+1
end
function O.touches(x,y)
    local arm=O.armAt(x,y)
    if arm and O.arms[arm]==0 then return false end
    local key,angle,size=O.sprite(); local a=Art.images[key]
    if not a.mask then return false end
    local scale=size/math.max(a.w,a.h); local dx,dy=x-O.x,y-O.y
    -- The whole creature rotates together.
    local xx=(math.cos(angle)*dx+math.sin(angle)*dy)/scale+a.w/2
    local yy=(-math.sin(angle)*dx+math.cos(angle)*dy)/scale+a.h/2
    if xx<0 or yy<0 or xx>=a.w or yy>=a.h then return false end
    return a.mask[math.floor(yy/a.h*192)*192+math.floor(xx/a.w*192)] or false
end
function O.ink()
    O.inkCount=O.inkCount+1
    local a=O.inkCount*2.39996323
    local radius=215+(O.inkCount%3)*25
    local x=math.max(55,math.min(Arena.width-55,O.x+math.cos(a)*radius))
    local y=math.max(70,math.min(530,O.y+math.sin(a)*radius))
    x,y=Arena.clearSpot(x-20,y-15,40,30)
    O.projectiles[#O.projectiles+1]={x=O.x,y=O.y,fromX=O.x,fromY=O.y,tx=x+20,ty=y+15,age=0,life=.85}
end
function O.explodeCrab(c)
    if c.dead then return end
    c.dead=0; c.frenzy=nil
    O.blasts[#O.blasts+1]={x=c.x,y=c.y,age=0}
    BossFX.burst(c.x,c.y,{.5,.3,.8},3)
    for _,other in ipairs(O.crabs) do
        if other~=c and not other.dead and not other.launch then
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
                if #O.inkPools>=12 then table.remove(O.inkPools,1) end
                O.inkPools[#O.inkPools+1]={x=p.tx,y=p.ty,rx=38,ry=27,life=6,seed=O.inkCount}
                table.remove(O.projectiles,i)
            end
        else table.remove(O.projectiles,i) end
    end
    for i=#O.inkPools,1,-1 do local p=O.inkPools[i]; p.life=p.life-dt
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
        g.setColor(.45,.2,.65,.35);g.ellipse('line',p.x,p.y,p.rx,p.ry)
    end
    for _,p in ipairs(O.projectiles) do if p.tx then
        g.setColor(.35,.1,.55,.5);g.ellipse('line',p.tx,p.ty,38,27)
    end end
    for _,p in ipairs(O.blasts) do g.setColor(.7,.4,1,1-p.age*2);g.ellipse('line',p.x,p.y,185*p.age*2,130*p.age*2) end
    g.pop()
end
function O.splash()
    O.blots={}; player.ink=4
    -- Broad irregular overlapping stains cover most of the view, then fade.
    for i=1,7 do O.blots[i]={x=.12+(i-1)%3*.37,y=.14+math.floor((i-1)/3)*.34,r=Arena.width*.32,life=4,seed=i} end
end
function O.hurt(crab,arm)
    if O.defeated or crab.dead or crab.launch or not O.waveActive then return end
    arm=arm or O.armAt(crab.x,crab.y)
    if not arm or O.arms[arm]<=0 then return end
    local registered=false
    for _,c in ipairs(O.crabs) do if c==crab then registered=true; break end end
    if not registered then return end
    crab.dead=0; O.arms[arm]=O.arms[arm]-1
    O.wounds[#O.wounds+1]={x=crab.x,y=crab.y,life=.55}
    if O.arms[arm]==0 then
        O.hp=O.hp-1; O.flash=.25
        O.spin=-O.spin; O.angularVelocity=O.spin*math.abs(O.angularVelocity)
        if O.rider and O.rider.arm==arm then O.detach() end
        Audio.play('pick')
    end
    if O.liveCrabs()==0 then O.waveActive=false end
    if O.hp==0 then
        O.defeated=true; O.projectiles={}; O.blots={}; O.inkPools={}; O.blasts={}; O.rider=nil; O.escape=nil
        for _,c in ipairs(O.crabs) do if not c.dead then c.dead=0 end end
        objet.larme.taken=false; objet.larme.x=O.x-15; objet.larme.y=O.y-20
    end
end
function O.releaseCrabs()
    if O.defeated or O.liveCrabs()>=32 then return end
    O.waveActive=true; O.waveId=O.waveId+1
    local aim=math.atan2(player.y+12-O.y,player.x+15-O.x)
    local distance=math.max(205,math.min(310,math.sqrt((player.x+15-O.x)^2+(player.y+12-O.y)^2)))
    local count=math.min(32-O.liveCrabs(),O.hp<=4 and 12 or 8)
    for i=1,count do
        local a=aim+(i-(count+1)/2)*.16
        local tx=math.max(45,math.min(Arena.width-45,O.x+math.cos(a)*distance))
        local ty=math.max(50,math.min(550,O.y+math.sin(a)*distance))
        local x,y=Arena.clearSpot(tx-14,ty-12,28,24)
        O.crabs[#O.crabs+1]={x=O.x,y=O.y,tx=x+14,ty=y+12,launch=0,angle=a,age=i*.2,
            wave=O.waveId,speed=170+(8-O.hp)*6,vx=math.cos(a),vy=math.sin(a),
            hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
    end
    Bestiary.discover('crab'); Bestiary.save()
end
function O.crabContact(c)
    if c.dead or c.launch or O.defeated or player.reset then return end
    -- The rider's body is vulnerable even when a tentacle also overlaps the crab.
    if (player.x+15-c.x)^2+(player.y+12-c.y)^2<23^2 then Hazards.kill(); return end
    for _,p in ipairs({{0,0},{-10,0},{10,0},{0,-8},{0,8}}) do
        local x,y=c.x+p[1],c.y+p[2]
        if (x-O.x)^2+(y-O.y)^2>65^2 and O.touches(x,y) then O.hurt(c,O.armAt(x,y)); return end
    end
end
function O.updateCrabs(dt)
    for i=#O.crabs,1,-1 do local c=O.crabs[i]
        c.age=c.age+dt
        if c.dead then
            c.dead=c.dead+dt
            if c.dead>=1.2 then table.remove(O.crabs,i) end
        elseif c.launch then
            c.launch=c.launch+dt; local t=math.min(1,c.launch/.9)
            c.x=O.x+(c.tx-O.x)*t; c.y=O.y+(c.ty-O.y)*t
            if t==1 then c.launch=nil; O.crabContact(c) end
        else
            if not c.frenzy then for _,p in ipairs(O.inkPools) do if Hazards.inEllipse(c.x,c.y,p,0) then c.frenzy=.85;break end end end
            if c.frenzy then c.frenzy=c.frenzy-dt;if c.frenzy<=0 then O.explodeCrab(c) end end
            if not c.dead and c.fling then
                local f=c.fling;local steps=math.max(1,math.ceil(580*dt/4))
                for _=1,steps do
                    local hx,hy=Arena.move(c,f.vx*dt/steps,f.vy*dt/steps)
                    if hx then f.vx=-f.vx*.65 end;if hy then f.vy=-f.vy*.65 end
                    O.crabContact(c);if c.dead or player.reset then break end
                end
                f.time=f.time-dt;if f.time<=0 then c.fling=nil end
            elseif not c.dead then O.walkCrab(c,dt,function() O.crabContact(c) end) end
        end
        if player.reset then return end
    end
end
function O.walkCrab(c,dt,contact)
    if not O.rider then
        local dx,dy=player.x+15-c.x,player.y+12-c.y
        local length=math.sqrt(dx*dx+dy*dy)
        if length>0 then c.vx,c.vy=dx/length,dy/length end
    end
    c.vx,c.vy=c.vx or 0,c.vy or 1
    -- Bend the pursuit around the body; a fast rotating arm can still catch them.
    if O.active and not O.defeated then
        local dx,dy=c.x-O.x,c.y-O.y; local distance=math.sqrt(dx*dx+dy*dy)
        if distance>1 and distance<285 then
            local nx,ny=dx/distance,dy/distance
            local inward=c.vx*nx+c.vy*ny
            if inward<0 then
                c.orbitSide=c.orbitSide or ((c.vx*(-ny)+c.vy*nx)>=0 and 1 or -1)
                local strength=math.min(1,(285-distance)/75)
                c.vx=c.vx-nx*inward*strength-ny*c.orbitSide*strength*.8
                c.vy=c.vy-ny*inward*strength+nx*c.orbitSide*strength*.8
            end
            if distance<210 then c.vx=c.vx+nx*2; c.vy=c.vy+ny*2 end
            local n=math.sqrt(c.vx*c.vx+c.vy*c.vy)
            if n>0 then c.vx,c.vy=c.vx/n,c.vy/n end
        else c.orbitSide=nil end
    end
    c.angle=math.atan2(c.vy,c.vx); c.dir=Art.direction(c.vx,c.vy,c.dir)
    local speed=c.speed*(c.frenzy and 1.4 or 1)*((player.ink or 0)>0 and 1.75 or 1)
    local steps=math.max(1,math.ceil(speed*dt/4))
    for _=1,steps do
        local hx,hy=Arena.move(c,c.vx*speed*dt/steps,c.vy*speed*dt/steps)
        if hx then c.vx=-c.vx end; if hy then c.vy=-c.vy end
        if O.active and not O.defeated then
            local dx,dy=c.x-O.x,c.y-O.y;local d=math.sqrt(dx*dx+dy*dy)
            if d>0 and d<205 then
                local tx,ty=O.x+dx/d*205,O.y+dy/d*205
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
MobBehaviors.crab={
    update=function(c,dt)
        c.age=c.age+dt; Realms.capture(c)
        if c.is_frozen then return end
        local controller=Bosses and Bosses.octopusFor(c) or O
        controller.walkCrab(c,dt,function() if isTouching(player,c) then Hazards.kill() end end)
    end,
    draw=function(c)
        local g=love.graphics; g.setColor(1,1,1)
        Art.draw(math.floor(c.age*6)%2==0 and 'crab_open' or 'crab_closed',c.x,c.y,46,(c.angle or 0)-math.pi/2)
    end
}
function O.contact()
    if Bosses and Bosses.otherRider(O) then return end
    if not O.active or O.defeated or O.rider or O.grace>0 then return end
    for y=player.y+2,player.y+22,5 do for x=player.x+2,player.x+28,5 do
        if O.touches(x,y) then
            local dx,dy=player.x+15-O.x,player.y+12-O.y
            local radius=math.sqrt(dx*dx+dy*dy)
            if radius<65 then Hazards.kill(); return end
            O.rider={arm=O.armAt(player.x+15,player.y+12),angle=math.atan2(dy,dx)-O.angle,radius=radius,time=1.6}
            player.dashing=false; player.has_moved=false
            return
        end
    end end
end
function O.update(dt)
    if not O.active then return end
    if O.defeated then O.updateCrabs(dt); return end
    O.clock=O.clock+dt; O.flash=math.max(0,O.flash-dt); O.grace=math.max(0,O.grace-dt)
    O.faceAngle=O.angle
    local speed=O.rider and O.maxSpin() or .32+(1-O.hp/O.maxHp)*.24
    local target=O.spin*speed*(O.movementRate or 1); local acceleration=(O.rider and 7 or 4)*dt
    O.angularVelocity=O.angularVelocity+math.max(-acceleration,math.min(acceleration,target-O.angularVelocity))
    O.angularVelocity=math.max(-O.maxSpin(),math.min(O.maxSpin(),O.angularVelocity))
    O.shot=O.shot-dt*(O.attackRate or 1)
    if O.shot<=0 then O.ink(); O.shot=2.6-(1-O.hp/O.maxHp)*.5 end
    O.summon=O.summon-dt*(O.attackRate or 1)
    if O.summon<=0 then O.releaseCrabs(); O.summon=5 end
    local steps=math.max(1,math.ceil(dt/.006))
    for _=1,steps do
        O.angle=O.angle+O.angularVelocity*dt/steps; O.moveRider(); O.contact()
        for _,c in ipairs(O.crabs) do O.crabContact(c); if player.reset then break end end
        if O.defeated or player.reset then break end
    end
    if player.reset then return end
    if O.rider then
        O.rider.time=O.rider.time-dt
        if O.rider.time<=0 then O.detach() end
    end
    O.updateCrabs(dt)
    O.updateInk(dt)
    for _,list in ipairs({O.blots,O.wounds}) do for i=#list,1,-1 do
        list[i].life=list[i].life-dt; if list[i].life<=0 then table.remove(list,i) end
    end end
end
function O.drawCrabs()
    local g=love.graphics
    for _,c in ipairs(O.crabs) do
        if c.launch then
            g.setColor(1,.65,.25,.6); g.setLineWidth(1.5); g.circle('line',c.tx,c.ty,20)
            g.setColor(1,.65,.25,.09); g.circle('fill',c.tx,c.ty,20)
        end
        local bob=c.launch and -math.sin(math.min(1,c.launch/.9)*math.pi)*50 or math.sin(c.age*23)*1.2
        g.push('all'); g.translate(c.x,c.y+bob)
        -- The sprite faces its walking direction.
        g.rotate(c.angle-math.pi/2+(c.dead and math.min(1,c.dead/.18)*.3 or 0))
        if c.dead then
            local a=Art.images.crab_dead; local amount=math.max(0,1-math.max(0,c.dead-.22)/.98)
            local qx,qy,qw,qh=a.quad:getViewport(); local iw,ih=a.image:getDimensions()
            a.sink=a.sink or g.newQuad(qx,qy,qw,qh,iw,ih); a.sink:setViewport(qx,qy,qw,math.max(1,qh*amount),iw,ih)
            local scale=46/math.max(qw,qh); g.setColor(1,1,1,amount)
            g.draw(a.image,a.sink,-qw*scale/2,qh*scale/2-qh*amount*scale,0,scale,scale)
        else g.setColor(1,c.frenzy and .3 or 1,c.frenzy and .5 or 1); Art.draw(math.floor(c.age*(c.frenzy and 24 or 6))%2==0 and 'crab_open' or 'crab_closed',0,0,46) end
        g.pop()
    end
end
function O.draw()
    if not O.active then return end
    local g=love.graphics
    if not O.defeated then
        local key,angle,size=O.sprite(); local a=Art.images[key]; local scale=size/math.max(a.w,a.h)
        O.armShader=O.armShader or g.newShader([[
            extern vec2 center;
            extern float rotation;
            extern float health[8];
            vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
                vec4 pixel=Texel(tex,uv)*color;
                vec2 d=screen-center;
                if (length(d)>65.0) {
                    float a=mod(atan(d.y,d.x)-rotation,6.2831853);
                    int index=int(floor(a/0.78539816));
                    float hp=health[index];
                    if (hp<0.5) return vec4(0.0);
                    float damage=1.0-hp/8.0;
                    pixel.rgb=mix(pixel.rgb,pixel.rgb*vec3(0.8,0.25,0.3),damage*0.8);
                }
                return pixel;
            }
        ]])
        O.armShader:send('center',{O.x,O.y}); O.armShader:send('rotation',angle)
        O.armShader:send('health',unpack(O.arms))
        local previous=g.getShader(); g.setShader(O.armShader)
        g.setColor(1,1-O.flash,1-O.flash)
        g.draw(a.image,a.quad,O.x,O.y,angle,scale,scale,a.w/2,a.h/2)
        g.setShader(previous)
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
