-- Fixed three-phase encounter. Early abyss levels still use the skeleton hazards.
return function(A)
local C={}
function C.enabled() return A.boss end
function C.build()
    A.phase=A.phase or 'lightning';A.phaseTime=A.phaseTime or 0;A.volley=A.volley or 0;A.nextShot=A.nextShot or .65
    A.plankton=A.plankton or {};A.open=A.phase~='rest'
    A.head={x=Arena.width-155,y=300,w=285,h=255}
    local key=A.open and 'skeleton_open' or 'skeleton_head';local spot=Art.images[key].glow or {u=.5,v=.5}
    A.bones={{key=key,x=A.head.x,y=A.head.y,w=285,h=255,angle=0,flip=true,gx=A.head.x-(spot.u-.5)*285,gy=A.head.y+(spot.v-.5)*255}}
end
function C.mouth() return A.head.x-109,A.head.y+25 end
function C.enter(phase)
    A.phase=phase;A.phaseTime=0;A.nextShot=.6;A.volley=0;A.buildBones()
end
function C.contact()
    if not A.active or A.defeated or player.reset or player.abyssHeld or player.abyssSpit or (player.abyssGrace or 0)>0 then return end
    local mx,my=C.mouth();local px,py=player.x+15,player.y+12
    if A.phase=='suction' and (px-mx)^2+(py-my)^2<38^2 then
        if (player.charges or 0)==0 then Hazards.kill('bone');return end
        A.swallowed={time=0,charged=player.charges};player.abyssHeld=A;player.charges=0;player.electrified=0
        player.dashing=false;player.has_moved=false;player.whirl=nil;player.throw=nil;player.tunnelTravel=nil
        player.x=mx-15;player.y=my-12;A.refreshLight();return
    end
    -- Keep the left-facing throat reachable during aspiration.
    if A.phase=='suction' and px<A.head.x-25 and math.abs(py-my)<70 then return end
    for _,b in ipairs(A.bones) do if A.overlapsBone(b) then Hazards.kill('bone');return end end
end
function C.spit()
    local charged=A.swallowed and A.swallowed.charged or 0;local mx,my=C.mouth()
    player.abyssHeld=nil;A.swallowed=nil;player.abyssGrace=1.25
    local x,y=Arena.clearSpot(Arena.width*.3-15,313,30,24)
    player.abyssSpit={fromX=mx-15,fromY=my-12,toX=x,toY=y,time=0}
    A.spitFlash=.5;A.hurt(charged)
    if not A.defeated then C.enter('rest') end
end
function C.fire()
    local x,y=C.mouth();A.volley=A.volley+1
    if A.phase=='lightning' then
        -- Same five lanes, with a blue lane moving across them each volley.
        for lane=1,5 do
            local angle=math.pi+(lane-3)*.23
            local blue=(lane+A.volley)%3==0
            local speed=blue and 210 or 245
            A.threads[#A.threads+1]={x=x,y=y,vx=math.cos(angle)*speed,vy=math.sin(angle)*speed,life=5,age=0,seed=lane,red=not blue}
        end
    elseif A.phase=='plankton' then
        for lane=1,4 do
            local angle=math.pi+(lane-2.5)*.33+(A.volley%2==0 and .1 or -.1)
            A.plankton[#A.plankton+1]={x=x,y=y,vx=math.cos(angle)*135,vy=math.sin(angle)*135,life=6,age=0,seed=lane+A.volley*4}
        end
    end
end
function C.update(dt)
    if not A.active or A.defeated or player.reset then return end
    A.clock=A.clock+dt;A.motionTime=A.motionTime+dt;A.flash=math.max(0,A.flash-dt);A.spitFlash=math.max(0,A.spitFlash-dt)
    if not A.instance then player.electrified=math.max(0,(player.electrified or 0)-dt);if player.electrified==0 then player.charges=0 end end
    if A.swallowed then
        A.swallowed.time=A.swallowed.time+dt;if A.swallowed.time>=.5 then C.spit() end
        A.refreshLight();return
    end
    A.phaseTime=A.phaseTime+dt*(A.attackRate or 1)
    local durations={lightning=5.2,plankton=3.8,suction=4.2,rest=1.1}
    local nextPhase={lightning='plankton',plankton='suction',suction='rest',rest='lightning'}
    if A.phaseTime>=durations[A.phase] then C.enter(nextPhase[A.phase]) end
    if A.phase=='lightning' or A.phase=='plankton' then
        A.nextShot=A.nextShot-dt*(A.attackRate or 1)
        if A.nextShot<=0 then C.fire();A.nextShot=A.phase=='lightning' and .7 or .85 end
    elseif A.phase=='suction' then A.pullEntity(player,dt,player) end
    if player.reset then return end
    for _,list in ipairs({A.threads,A.plankton}) do for i=#list,1,-1 do
        local p=list[i];p.age=p.age+dt;p.life=p.life-dt;local dead=p.life<=0
        local speed=math.sqrt(p.vx*p.vx+p.vy*p.vy);local steps=math.max(1,math.ceil(speed*dt/5))
        for _=1,steps do
            if dead then break end
            p.x=p.x+p.vx*dt/steps;p.y=p.y+p.vy*dt/steps
            if Arena.blocked(p.x-3,p.y-3,6,6) then dead=true end
            if not dead and not player.abyssHeld and not player.abyssSpit and (player.abyssGrace or 0)<=0 and (p.x-player.x-15)^2+(p.y-player.y-12)^2<22^2 then
                if list==A.plankton or p.red then Hazards.kill('bone') else A.charge(20) end
                dead=true
            end
        end
        if dead then table.remove(list,i) end
    end end
    C.contact();A.refreshLight()
end
function C.draw()
    local g=love.graphics
    for _,p in ipairs(A.plankton or {}) do
        g.setColor(.13,.8,.68,.18);g.circle('fill',p.x,p.y,14)
        g.setColor(.45,1,.68,.9);g.ellipse('fill',p.x,p.y,7,5)
        g.setColor(.025,.2,.23);g.circle('fill',p.x-2,p.y,2)
        g.setColor(.45,1,.68,.7);g.setLineWidth(1)
        for j=-1,1 do g.line(p.x+5,p.y+j*3,p.x+12,p.y+j*5+math.sin(p.age*7+p.seed)*3) end
    end
    if not A.head or A.defeated then return end
    local mx,my=C.mouth()
    local labels={lightning='ÉCLAIRS',plankton='PLANCTON',suction='ASPIRATION',rest=''}
    g.setColor(.7,.9,1,.9);g.setFont(UI.fonts.small);g.printf(labels[A.phase] or '',A.head.x-130,A.head.y-155,260,'center')
    if A.phase=='suction' then
        g.setColor(.35,.8,1,.38);g.setLineWidth(1.5)
        for i=1,24 do local t=(A.phaseTime*.6+i/24)%1;local x=mx-(1-t)*450;local y=my+math.sin(i*2.4)*(1-t)*180
            g.line(x-14,y,x,y+(my-y)*.04)
        end
    end
end
return C
end
