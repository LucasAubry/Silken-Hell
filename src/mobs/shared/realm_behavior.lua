return function(R,motion)
local function update(m,dt)
    R.capture(m); if m.is_frozen or m.tunnelTravel then return end
    local before=m.age
    m.age=m.age+dt; local vx,vy=m.vx,m.vy; local speed=m.speed
    local dangerous=true
    local handled
    vx,vy,speed,dangerous,handled=motion(m,dt,before)
    if handled then return end
    if m.has_larme and not objet.larme_dropped then
        local a=math.atan2(player.y+12-m.y,player.x+15-m.x)
        vx,vy=math.cos(a),math.sin(a); speed=math.min(speed,m.type=='mole' and 140 or 95)
    end
    m.dir=Art.direction(vx,vy,m.dir)
    local hx,hy=false,false
    if m.type=='mole' or m.type=='worm' or m.has_larme then
        local tx,ty=player.x+15,player.y+12
        if m.type=='mole' and m.age%5<1.7 then tx,ty=m.targetX,m.targetY end
        Arena.navigate(m,tx,ty,speed,dt)
    else
        hx,hy=Arena.move(m,vx*speed*dt,vy*speed*dt)
        if (hx or hy) and m.type~='fish' then
            Arena.navigate(m,m.x+vx*180,m.y+vy*180,speed,dt)
        end
    end
    if hx then m.vx=-m.vx; m.phase=m.phase+math.pi end
    if hy then m.vy=-m.vy; m.phase=-m.phase+1 end
    if dangerous and isTouching(player,m) then Hazards.kill() end
end
local function draw(m)
    local phase,amount=R.molePhase(m.age)
    if m.type=='gull' and m.electric then
        local g=love.graphics; g.setColor(1,.78,.05,.18); g.circle('fill',m.x,m.y,30)
        g.setColor(1,.92,.2,.95); g.setLineWidth(2)
        for j=0,23 do local a=j*math.pi/12; local b=(j+1)*math.pi/12; local r=28+math.sin(m.age*30+j)*2
            g.line(m.x+math.cos(a)*r,m.y+math.sin(a)*r,m.x+math.cos(b)*30,m.y+math.sin(b)*30) end
        g.setLineWidth(1)
    end
    if m.type=='worm' then phase,amount=R.wormPhase(m.age) end
    if m.tunnelTravel then
        local scale,dy=R.travelPose(m); love.graphics.setColor(1,1,1,scale)
        Art.drawFacing(m.type,m.dir,m.x,m.y+dy,62*scale); love.graphics.setColor(1,1,1); return
    end
    local hidden=(m.type=='mole' and (phase=='hidden' or phase=='warning')) or (m.type=='worm' and m.age%4<1.2)
    if hidden then return end
    if m.type=='fish' and m.school.age%3>2.05 then
        love.graphics.setColor(1,.5,.15,.5); love.graphics.circle('line',m.x,m.y,20)
    end
    love.graphics.setColor(m.is_frozen and {.55,.75,1} or {1,1,1})
    if Campaign.biome==7 and not m.is_frozen then love.graphics.setColor(.75,.62,1) end
    if m.type=='gull' and m.electric then love.graphics.setColor(1,.88,.15) end
    local size=m.elite and 95 or m.type=='gull' and 75 or 62
    if (m.type=='worm' or m.type=='mole') and (phase=='dig' or phase=='emerge') then
        Art.drawBurrowing(m.type,m.dir,m.x+math.sin(m.age*35)*(phase=='dig' and 2 or .7),m.y,size,amount)
    elseif m.type=='worm' then Art.drawWorm(m.dir,m.x,m.y,size,m.age)
    else Art.drawFacing(m.type,m.dir,m.x,m.y,size) end
    love.graphics.setColor(1,1,1)
end
return {update=update,draw=draw}
end
