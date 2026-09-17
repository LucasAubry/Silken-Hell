local S={active=false,projectiles={},strikes={}}
function S.reset(active)
    S.active=active; S.name='Le Séraphin des orages'; S.hp=8; S.maxHp=8; S.defeated=false
    S.x=Arena.width/2; S.y=190; S.dir='down'; S.clock=0; S.phase='storm'; S.phaseTime=5.4; S.shot=.9; S.bolt=.55; S.flash=0; S.hitGrace=0
    S.projectiles={}; S.strikes={}
end
function S.fire()
    local phase=S.clock*.37
    for i=0,9 do local a=phase+i*math.pi*2/10
        S.projectiles[#S.projectiles+1]={x=S.x,y=S.y,vx=math.cos(a)*185,vy=math.sin(a)*185,life=5}
    end
end
function S.summon()
    local px,py=player.x+15,player.y+12
    for _,offset in ipairs({-85,0,85}) do
        S.strikes[#S.strikes+1]={x=math.max(65,math.min(Arena.width-65,px+offset)),y=math.max(80,math.min(520,py)),age=0}
    end
end
function S.contact()
    if not S.active or S.defeated or player.abyssHeld or S.hitGrace>0 then return end
    if S.phase=='rest' and (player.x+15-S.x)^2+(player.y+12-S.y)^2<48^2 then
        S.hp=S.hp-1; S.flash=.3; S.hitGrace=.75; S.projectiles={}; S.strikes={}; Audio.play('pick')
        if S.hp==0 then
            S.defeated=true; objet.larme.taken=false; objet.larme.x=S.x-15; objet.larme.y=S.y-20
        else S.phase='storm'; S.phaseTime=5.4; S.shot=.8; S.bolt=.9 end
    end
end
function S.update(dt)
    if not S.active or S.defeated then return end
    S.clock=S.clock+dt; S.flash=math.max(0,S.flash-dt); S.hitGrace=math.max(0,S.hitGrace-dt); S.phaseTime=S.phaseTime-dt
    if S.phase=='storm' then
        local tx=Arena.width/2+math.sin(S.clock*.65)*Arena.width*.19; local ty=235+math.sin(S.clock*.9)*95
        local dx,dy=tx-S.x,ty-S.y; local step=math.min(1,90*dt/math.max(1,math.sqrt(dx*dx+dy*dy)))
        S.x=S.x+dx*step; S.y=S.y+dy*step; S.dir=Art.direction(dx,dy,S.dir)
        S.shot=S.shot-dt; S.bolt=S.bolt-dt
        if S.shot<=0 then S.fire(); S.shot=1.5-(S.maxHp-S.hp)*.07 end
        if S.bolt<=0 then S.summon(); S.bolt=2.1-(S.maxHp-S.hp)*.06 end
        if S.phaseTime<=0 then S.phase='rest'; S.phaseTime=3.2; S.projectiles={}; S.strikes={}; S.dir='down' end
    elseif S.phaseTime<=0 then S.phase='storm'; S.phaseTime=5.4; S.shot=.6; S.bolt=.7 end
    for i=#S.strikes,1,-1 do local p=S.strikes[i]; p.age=p.age+dt
        if p.age>=.9 and p.age<1.16 and (player.x+15-p.x)^2+(player.y+12-p.y)^2<26^2 then Hazards.kill() end
        if p.age>=.9 and not p.struck then p.struck=true; if BossFX then BossFX.burst(p.x,p.y,{.5,.8,1},2) end end
        if p.age>1.3 then table.remove(S.strikes,i) end
    end
    for i=#S.projectiles,1,-1 do local p=S.projectiles[i]; p.life=p.life-dt; local dead=p.life<=0
        local steps=math.max(1,math.ceil(185*dt/5))
        for _=1,steps do
            p.x=p.x+p.vx*dt/steps; p.y=p.y+p.vy*dt/steps
            if Arena.blocked(p.x-3,p.y-3,6,6) then dead=true end
            if (player.x+15-p.x)^2+(player.y+12-p.y)^2<17^2 then Hazards.kill(); dead=true end
            if dead then break end
        end
        if dead then table.remove(S.projectiles,i) end
    end
    S.contact()
end
function S.drawGround()
    if not S.active or S.defeated then return end
    local g=love.graphics
    for _,p in ipairs(S.strikes) do
        if p.age<.9 then
            g.setColor(.3,.7,1,.16); g.circle('fill',p.x,p.y,27)
            g.setColor(.65,.9,1,.8); g.circle('line',p.x,p.y,27*(1-p.age/.9)+3)
        else
            g.setColor(.35,.65,1,.5); g.setLineWidth(6); g.line(p.x-15,35,p.x+14,p.y*.45,p.x-7,p.y*.7,p.x,p.y)
            g.setColor(.9,1,1); g.setLineWidth(2); g.line(p.x-15,35,p.x+14,p.y*.45,p.x-7,p.y*.7,p.x,p.y)
        end
    end
    g.setLineWidth(1); g.setColor(1,1,1)
end
function S.draw()
    if not S.active or S.defeated then return end
    local g=love.graphics; local resting=S.phase=='rest'
    g.setColor(0,.04,.1,.15); g.ellipse('fill',S.x,S.y+24,52,16)
    g.setColor(1,1-S.flash*.5,1-S.flash*.5)
    local a=Art.images['storm_'..S.dir]; local width=resting and 132 or 146+math.sin(S.clock*18)*12
    Art.draw('storm_'..S.dir,S.x,S.y,width,math.sin(S.clock*2)*.035,width*a.h/a.w)
    if resting then
        g.setColor(1,.8,.35,.85)
        for i=1,5 do local t=i*math.pi*2/5+S.clock; g.circle('fill',S.x+math.cos(t)*53,S.y+math.sin(t)*32,2) end
    end
    for _,p in ipairs(S.projectiles) do
        g.setColor(.25,.65,1,.2); g.circle('fill',p.x,p.y,9)
        g.setColor(.8,.95,1); g.polygon('fill',p.x-5,p.y,p.x,p.y-7,p.x+5,p.y,p.x,p.y+7)
    end
    g.setColor(1,1,1)
end
return S
