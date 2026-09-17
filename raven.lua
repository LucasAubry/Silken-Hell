local B={active=false,projectiles={},eggs={},nests={},chicks={},name='Le Merle noir'}
local function hitPlayer()
    if not player.reset then player.reset=true; player.death=player.death+1; activateShaderEffect(); Audio.play('death') end
end
function B.reset(active)
    B.active=active; B.projectiles={}; B.eggs={}; B.nests={}; B.chicks={}; B.hp=12; B.maxHp=12; B.elapsed=0; B.shot=0.24; B.flash=0; B.defeated=false
    B.x=Arena.width/2; B.y=300; B.relocations=0
    if not active then return end
    for _,p in ipairs({{.14,135},{.38,125},{.62,125},{.86,135},{.13,380},{.87,380},{.3,495},{.7,495}}) do
        B.nests[#B.nests+1]={x=Arena.width*p[1],y=p[2],rx=34,ry=25}
    end
    local p=B.nests[1]; B.eggs={{x=p.x,y=p.y,spot=1,glow=.35}}
end
function B.interval()
    return math.max(.08,.24-math.floor((B.maxHp-B.hp)/2)*.026)
end
function B.relocate(f)
    local candidates={}
    for i,p in ipairs(B.nests) do
        if i~=f.spot and (p.x-f.x)^2+(p.y-f.y)^2>200^2 then candidates[#candidates+1]=i end
    end
    if #candidates==0 then for i in ipairs(B.nests) do if i~=f.spot then candidates[#candidates+1]=i end end end
    if #candidates==0 then return end
    local choice=candidates[love.math.random(#candidates)]
    f.spot=choice; f.x=B.nests[choice].x; f.y=B.nests[choice].y; f.glow=0.35
    B.relocations=B.relocations+1
end
function B.fire()
    local angle=math.atan2(player.y+12-B.y,player.x+15-B.x)
    local speed=285+70*(1-B.hp/B.maxHp)
    -- The final four HP widen each continuous salvo.
    local angles=B.hp<=4 and {angle-.14,angle,angle+.14} or {angle}
    for _,a in ipairs(angles) do B.projectiles[#B.projectiles+1]={x=B.x+math.cos(a)*44,y=B.y+math.sin(a)*44,vx=math.cos(a)*speed,vy=math.sin(a)*speed,life=6} end
end
function B.update(dt)
    if not B.active or B.defeated then return end
    B.elapsed=B.elapsed+dt; B.flash=math.max(0,B.flash-dt); B.shot=B.shot-dt*(B.attackRate or 1)
    if B.shot<=0 then B.fire(); B.shot=B.interval() end
    for _,f in ipairs(B.eggs) do f.glow=math.max(0,f.glow-dt) end
    for _,m in ipairs(B.chicks) do
        m.angle=m.angle+dt*1.6
        m.x=m.cx+math.cos(m.angle)*48; m.y=m.cy+math.sin(m.angle)*36
        m.dir=Art.direction(-math.sin(m.angle),math.cos(m.angle))
        if (player.x+15-m.x)^2+(player.y+12-m.y)^2<22^2 then hitPlayer() end
    end
    if (player.x+15-B.x)^2+(player.y+12-B.y)^2<48^2 then hitPlayer(); return end
    local fragments={}
    for i=#B.projectiles,1,-1 do
        local p=B.projectiles[i]; p.life=p.life-dt; local dead=p.life<=0
        local steps=math.max(1,math.ceil(math.sqrt(p.vx^2+p.vy^2)*dt/4))
        for _=1,steps do
            if dead then break end
            p.x=p.x+p.vx*dt/steps; p.y=p.y+p.vy*dt/steps
            for _,f in ipairs(B.eggs) do
                if not dead and (p.x-f.x)^2+(p.y-f.y)^2<18^2 then
                    B.hp=math.max(0,B.hp-1); B.flash=.18
                    B.chicks[#B.chicks+1]={cx=f.x,cy=f.y,x=f.x,y=f.y,angle=0,dir='down'}
                    Bestiary.discover('blackbird_chick'); Bestiary.save()
                    if B.hp>0 then B.relocate(f) end
                    Audio.play('pick'); dead=true; break
                end
            end
            if not dead and not p.split then
                for _,nest in ipairs(B.nests) do
                    if Hazards.inEllipse(p.x,p.y,nest,0) then
                        local a=math.atan2(p.vy,p.vx); local speed=math.sqrt(p.vx*p.vx+p.vy*p.vy)
                        for _,side in ipairs({-1,1}) do local angle=a+side*0.12
                            fragments[#fragments+1]={x=p.x-math.sin(a)*side*5,y=p.y+math.cos(a)*side*5,
                                vx=math.cos(angle)*speed,vy=math.sin(angle)*speed,life=p.life,split=true,half=side}
                        end
                        dead=true; break
                    end
                end
            end
            if not dead and checkCollision(p.x-6,p.y-6,12,12,player.x,player.y,30,24) then hitPlayer(); dead=true end
            if not dead and Arena.blocked(p.x-4,p.y-4,8,8) then dead=true end
        end
        if dead then table.remove(B.projectiles,i) end
        if B.hp==0 then
            B.defeated=true; B.projectiles={}; B.eggs={}; B.chicks={}
            objet.larme.x=B.x-15; objet.larme.y=B.y-20
            objet.larme.taken=false; break
        end
    end
    if not B.defeated then for _,p in ipairs(fragments) do B.projectiles[#B.projectiles+1]=p end end
end
function B.drawGround()
    local g=love.graphics
    for _,n in ipairs(B.nests) do g.setColor(1,1,1); Art.draw('nest',n.x,n.y,80,0,60) end
    for _,f in ipairs(B.eggs) do
        g.setColor(1,.8,.3,.35+f.glow); g.ellipse('line',f.x,f.y+6,25,16)
        g.setColor(.12,.09,.06); g.ellipse('fill',f.x,f.y+2,12,16)
        g.setColor(.66,.85,.76); g.ellipse('fill',f.x,f.y,10,14)
        g.setColor(.93,.97,.80); g.ellipse('fill',f.x-3,f.y-4,5,8)
        g.setColor(.23,.29,.21); g.circle('fill',f.x+4,f.y+4,2); g.circle('fill',f.x-3,f.y+7,1.5)
    end
end
function B.draw()
    if not B.active then return end
    local g=love.graphics
    for _,m in ipairs(B.chicks) do g.setColor(1,1,1); Art.drawFacing('merle',m.dir,m.x,m.y,35) end
    if not B.defeated then
        g.setColor(0,0,0,0.25); g.ellipse('fill',B.x,B.y+40,66,21)
        g.setColor(1,1-B.flash*2,1-B.flash*3)
        Art.drawFacing('merle',Art.direction(player.x+15-B.x,player.y+12-B.y),B.x,B.y-8+math.sin(B.elapsed*2)*3,150)
    end
    for _,p in ipairs(B.projectiles) do
        g.setColor(1,1,1)
        if p.split then
            -- Render each fragment as a distinct longitudinal half of the original feather.
            local a=Art.images.black_feather
            local q=p.half==1 and B.upperQuad or B.lowerQuad
            if not q then
                local x,y,w,h=a.quad:getViewport(); local iw,ih=a.image:getDimensions()
                B.upperQuad=love.graphics.newQuad(x,y,w,h/2,iw,ih)
                B.lowerQuad=love.graphics.newQuad(x,y+h/2,w,h/2,iw,ih)
                q=p.half==1 and B.upperQuad or B.lowerQuad
            end
            g.draw(a.image,q,p.x,p.y,math.atan2(p.vy,p.vx),30/a.w,30/a.w,a.w/2,a.h/4)
        else Art.draw('black_feather',p.x,p.y,34,math.atan2(p.vy,p.vx)) end
    end
    g.setColor(1,1,1)
end
return B
