-- Infernal brood: authored nests and explosive pursuers.
local M={spawners={},pools={},bursts={}}
function M.reset()
    M.spawners={}; M.pools={}; M.bursts={}; M.clock=0
end
function M.addSpawner(x,y,delay,interval)
    local p={x=x,y=y,rx=31,ry=23,clock=delay or 1,interval=interval or 3,spawnDelay=delay or 1,spawnInterval=interval or 3}
    M.spawners[#M.spawners+1]=p; return p
end
function M.populate(n)
    -- Existing authored maps are left to their creator. Native levels gain 1–3 nests.
    local wanted=n<4 and 1 or n<8 and 2 or 3
    if n==10 then wanted=1 end
    local candidates={{.22,130},{.78,470},{.78,130},{.22,470},{.5,110},{.5,480}}
    local function clear(x,y)
        if Arena.blocked(x-48,y-39,96,78) or (x-player.x-15)^2+(y-player.y-12)^2<160^2 then return false end
        for _,p in ipairs(levels[player.level].larme_position) do if (x-p.x-15)^2+(y-p.y-39)^2<85^2 then return false end end
        for _,p in ipairs(Hazards.lava) do if ((x-p.x)/(p.rx+48))^2+((y-p.y)/(p.ry+39))^2<1 then return false end end
        for _,p in ipairs(M.spawners) do if (x-p.x)^2+(y-p.y)^2<145^2 then return false end end
        return true
    end
    for _,p in ipairs(candidates) do
        local x,y=p[1]*Arena.width,p[2]
        if clear(x,y) then M.addSpawner(x,y) end
        if #M.spawners>=wanted then return end
    end
    for y=105,495,45 do for x=90,Arena.width-90,60 do
        if clear(x,y) then M.addSpawner(x,y) end
        if #M.spawners>=wanted then return end
    end end
end
function M.spawn(x,y,speed)
    local m={type='magma_larva',x=x,y=y,speed=speed or 245,age=0,fuse=3.6,angle=0,dir='down',
        hitBox_width=18,hitBox_height=18,hitBox_offset_x=-9,hitBox_offset_y=-9}
    mobs[#mobs+1]=m
    if App.state=='playing' then Bestiary.discover('magma_larva') end
    return m
end
-- A nest is a traversable decoration; only its larvae deal contact damage.
function M.contact() end
function M.explode(m)
    if m.spent then return end
    m.spent=true
    -- A custom carrier must release its tear before its body is removed.
    if m.has_larme and not objet.larme_dropped then objet.larme_dropped=true; objet.larme.x=m.x-15; objet.larme.y=m.y+35 end
    M.bursts[#M.bursts+1]={x=m.x,y=m.y,age=0}
    if (player.x+15-m.x)^2+(player.y+12-m.y)^2<43^2 then Hazards.kill() end
end
function M.update(dt)
    if player.reset then return end
    M.clock=M.clock+dt
    local count=0
    for i=#mobs,1,-1 do local m=mobs[i]
        if m.type=='magma_larva' then
            if m.spent then table.remove(mobs,i) else count=count+1 end
        end
    end
    for _,p in ipairs(M.spawners) do
        p.clock=math.max(0,p.clock-dt)
        if p.clock==0 and count<24 then
            M.spawn(p.x,p.y); p.clock=p.interval; count=count+1
        end
    end
    for i=#M.bursts,1,-1 do local b=M.bursts[i]; b.age=b.age+dt; if b.age>.55 then table.remove(M.bursts,i) end end
    M.contact()
end
function M.drawGround()
    local g=love.graphics
    for _,p in ipairs(M.spawners) do
        -- A quiet hatch animation; the nest itself has no damaging collision.
        local hatch=p.clock<.8 and math.sin(M.clock*12)*.02 or 0
        g.setColor(1,1,1); Art.draw('magma_nest',p.x,p.y,(p.rx*2+10)*(1+hatch),0,(p.ry*2+10)*(1-hatch))
    end
    for _,b in ipairs(M.bursts) do
        local t=b.age/.55
        for i=1,12 do local a=i*math.pi/6
            g.setColor(i%2==0 and 1 or .55,i%2==0 and .15 or 1,.08,1-t)
            g.circle('fill',b.x+math.cos(a)*t*48,b.y+math.sin(a)*t*35,4*(1-t)+1)
        end
    end
    g.setColor(1,1,1)
end
function M.resize(ratio)
    for _,list in ipairs({M.spawners,M.bursts}) do for _,p in ipairs(list) do p.x=p.x*ratio end end

end
MobBehaviors.magma_larva={
    update=function(m,dt)
        if m.spent then return end
        Realms.capture(m)
        if m.tunnelTravel or m.is_frozen then return end
        m.age=m.age+dt
        if m.age>=m.fuse then M.explode(m); return end
        if not m.is_frozen then
            local dx,dy=player.x+15-m.x,player.y+12-m.y
            m.angle=math.atan2(dy,dx)-math.pi/2; m.dir=Art.direction(dx,dy,m.dir)
            Arena.navigate(m,player.x+15,player.y+12,m.speed,dt)
        end
        if isTouching(player,m) then M.explode(m) end
    end,
    draw=function(m)
        if m.spent then return end
        local g=love.graphics; local warning=m.fuse-m.age<.8
        g.setColor(1,warning and (.6+.4*math.sin(m.age*38)) or 1,warning and .55 or 1)
        local a=Art.images.magma_larva; local size=38+math.sin(m.age*22)*1.7
        Art.draw('magma_larva',m.x,m.y,size*a.w/math.max(a.w,a.h),m.angle,size*a.h/math.max(a.w,a.h))
        g.setColor(1,1,1)
    end
}
return M
