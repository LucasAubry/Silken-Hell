local B={active=false,projectiles={},eggs={},nests={},chicks={},name='L’Œuf du Merle'}
local function hitPlayer() Hazards.kill() end
function B.reset(active)
    B.active=active;B.corpses={};B.projectiles={};B.eggs={};B.nests={};B.chicks={};B.hp=10;B.maxHp=10;B.elapsed=0;B.flash=0;B.defeated=false;B.broken=false;B.name="L’Œuf du Merle";B.inside=false;B.relocations=0;B.shooterCursor=0;B.shotClock=.22;B.featherSpeed=440
    B.x=Arena.width/2;B.y=300
    if not active then return end
    B.setupNests()
    player.x=B.x-15;player.y=B.y+240-65-12
end
function B.setupNests(nests)
    B.nests=nests or {};B.chicks={}
    if not nests then
        for i=1,6 do local a=-math.pi/2+(i-1)*math.pi/3
            B.nests[i]={x=B.x+math.cos(a)*math.min(320,Arena.width/2-65),y=B.y+math.sin(a)*240,rx=34,ry=25}
        end
    end
    for i,n in ipairs(B.nests) do
        n.shooter=i%2==1
        if n.shooter then B.chicks[#B.chicks+1]={x=n.x,y=n.y-10,cx=n.x,cy=n.y-10,slot=i,age=0,dir='down',kind='shooter',shot=B.interval()+i*.16} end
    end
end
function B.touchesEgg(x,y,radius)
    return (x-B.x)^2/(45+radius)^2+(y-(B.y-5))^2/(60+radius)^2<=1
end
function B.interval() return .32-.10*(1-B.hp/B.maxHp) end
function B.chaseSpeed() return (125+60*(1-B.hp/B.maxHp))*(B.movementRate or 1) end
function B.finish()
    B.defeated=true;B.chicks={};B.projectiles={};B.eggs={}
    objet.larme.x=B.x-15;objet.larme.y=B.y-20;objet.larme.taken=false
end
function B.breakEgg()
    B.broken=true;B.projectiles={};B.eggs={};objet.larme.taken=true
    for _,m in ipairs(B.chicks) do
        m.stunned=true;m.phase='stunned';m.vx=0;m.vy=0
        local x,y=Arena.clearSpot(m.x-27,m.y-27,54,54);m.x=x+27;m.y=y+27
    end
    B.name='Œuf brisé · '..#B.chicks..' oiseaux étourdis'
    if #B.chicks==0 then B.finish() end
end
function B.fireNext()
    if B.broken or B.defeated then return end
    local shooters={};for _,m in ipairs(B.chicks) do if m.kind=='shooter' then shooters[#shooters+1]=m end end
    if #shooters==0 then return end
    B.shooterCursor=B.shooterCursor%#shooters+1
    B.fire(shooters[B.shooterCursor]);B.shotClock=B.interval()
end
function B.fire(m)
    if B.broken or B.defeated or #B.projectiles>=256 then return end
    m=m or {x=B.x,y=B.y}
    local a=math.atan2(player.y+12-m.y,player.x+15-m.x)
    B.projectiles[#B.projectiles+1]={x=m.x,y=m.y,vx=math.cos(a)*B.featherSpeed,vy=math.sin(a)*B.featherSpeed,life=3.5,sourceSlot=m.slot}
end
function B.hatch()
    local wave=B.maxHp-B.hp
    local chargers={};for i,m in ipairs(B.chicks) do if m.kind=='charger' then chargers[#chargers+1]=i end end
    if #chargers>=3 then table.remove(B.chicks,chargers[1]) end
    local sites={};for i,n in ipairs(B.nests) do if not n.shooter then sites[#sites+1]=i end end
    if #sites>0 then
        local i=sites[(wave-1)%#sites+1];local n=B.nests[i]
        B.chicks[#B.chicks+1]={x=n.x,y=n.y,cx=n.x,cy=n.y,slot=i,wave=wave,age=0,dir='down',kind='charger',phase='chase'}
    end
    if Bestiary.discover('blackbird_chick') then Bestiary.save() end
end
function B.contact()
    if not B.active or B.defeated or player.reset then return end
    if B.broken then
        if player.dashing then
            for i=#B.chicks,1,-1 do local m=B.chicks[i]
                if (player.x+15-m.x)^2+(player.y+12-m.y)^2<35^2 then
                    BossFX.burst(m.x,m.y,{.45,.65,1},2);Audio.play('pick');table.remove(B.chicks,i)
                end
            end
            B.name='Œuf brisé · '..#B.chicks..' oiseaux étourdis'
            if #B.chicks==0 then B.finish() end
        end
        return
    end
    local inside=(player.x+15-B.x)^2+(player.y+12-B.y)^2<58^2
    if inside and not B.inside and player.dashing then
        B.hp=B.hp-1;B.flash=.25;Audio.play('pick');BossFX.burst(B.x,B.y,{.76,.87,.63},3)
        if B.hp<=0 then B.breakEgg() else B.hatch() end
    end
    B.inside=inside
end
function B.update(dt)
    if not B.active or player.reset then return end
    for _,m in ipairs(B.corpses) do m.fall=math.min(1,m.fall+dt/.28) end
    if B.defeated then return end
    B.elapsed=B.elapsed+dt;B.flash=math.max(0,B.flash-dt);B.contact()
    if B.defeated then return end
    if B.broken then
        for _,m in ipairs(B.chicks) do m.age=m.age+dt end
        return
    end
    B.shotClock=B.shotClock-dt*(B.attackRate or 1)
    if B.shotClock<=0 then B.fireNext() end
    for _,m in ipairs(B.chicks) do
        m.age=m.age+dt
        m.hitBox_width=54;m.hitBox_height=54;m.hitBox_offset_x=-27;m.hitBox_offset_y=-27
        if m.kind=='shooter' then
            local nest=B.nests[m.slot]
            if nest then m.x=nest.x;m.y=nest.y-10 end
            m.dir=Art.direction(player.x+15-m.x,player.y+12-m.y)
        else
            local dx,dy=player.x+15-m.x,player.y+12-m.y
            local distance=math.sqrt(dx*dx+dy*dy)
            if distance>0 then
                local step=math.min(distance,B.chaseSpeed()*dt)
                m.x=m.x+dx/distance*step;m.y=m.y+dy/distance*step
            end
            m.dir=Art.direction(dx,dy,m.dir);m.phase='chase'
        end
    end
    for i=#B.projectiles,1,-1 do
        local p=B.projectiles[i];p.life=p.life-dt;local dead=p.life<=0
        for _=1,math.max(1,math.ceil(B.featherSpeed*dt/5)) do
            if dead then break end
            local step=dt/math.max(1,math.ceil(B.featherSpeed*dt/5));p.x=p.x+p.vx*step;p.y=p.y+p.vy*step
            if Arena.blocked(p.x-3,p.y-3,6,6) then dead=true end
            if not dead then
                for j=#B.chicks,1,-1 do local m=B.chicks[j]
                    if m.kind=='charger' and (p.x-m.x)^2+(p.y-m.y)^2<26^2 then
                        B.corpses[#B.corpses+1]={x=m.x,y=m.y,dir=m.dir,fall=0,side=m.slot%4==0 and -1 or 1}
                        table.remove(B.chicks,j);BossFX.burst(m.x,m.y,{.35,.4,.57},1);dead=true;break
                    end
                end
            end
            if not dead and checkCollision(p.x-4,p.y-4,8,8,player.x,player.y,30,24) then hitPlayer();dead=true end
        end
        if dead then table.remove(B.projectiles,i) end
    end
    for _,m in ipairs(B.chicks) do if (player.x+15-m.x)^2+(player.y+12-m.y)^2<25^2 then hitPlayer() end end
end
local function drawCorpses()
    local g=love.graphics
    for _,m in ipairs(B.corpses) do
        local t=m.fall;local y=m.y+8*t*t
        g.setColor(0,0,0,.22);g.ellipse('fill',m.x,y+8,20,6)
        g.push('all');g.translate(m.x,y);g.rotate(m.side*.9*t);g.scale(1,1-.38*t)
        g.setColor(.58,.57,.62);Art.drawFacing('merle',m.dir,0,0,50);g.pop()
    end
    g.setColor(1,1,1)
end
local egg=require('mobs.bosses.raven.egg').draw
B.eggPositions={{-12,-8,-.34},{6,-10,.23},{17,-1,.58},{-18,4,-.5},{-3,5,.14},{10,10,.39}}
function B.drawGround()
    if not B.active then return end
    drawCorpses()
    local g=love.graphics
    for _,n in ipairs(B.nests) do
        g.setColor(1,1,1);Art.draw('nest',n.x,n.y,80,0,60)
        if not n.shooter then for i=1,math.ceil(B.hp/B.maxHp*#B.eggPositions) do local p=B.eggPositions[i];egg(n.x+p[1],n.y+p[2],8,0,p[3]) end end
    end
end
function B.draw()
    if not B.active then return end
    local g=love.graphics
    if not B.broken and not B.defeated then
        g.setColor(0,0,0,.25);g.ellipse('fill',B.x,B.y+47,47,15)
        egg(B.x+math.sin(B.elapsed*65)*B.flash*7,B.y-5,60,B.maxHp-B.hp)
    end
    if B.broken then
        g.push('all');g.setColor(.83,.84,.8)
        for i=1,9 do local a=i*2.399;local x,y=B.x+math.cos(a)*30,B.y+math.sin(a)*20
            g.polygon('fill',x-7,y+5,x-2,y-8,x+8,y+2);g.setColor(.65,.73,.82)
        end
        if not B.defeated then g.setColor(.9,.94,1);g.setFont(UI.fonts.small);g.printf('Fonce sur les oiseaux étourdis',B.x-150,B.y+52,300,'center') end
        g.pop()
    end
    for _,m in ipairs(B.chicks) do
        local previous=g.getShader()
        if m.kind~='charger' then
            B.whiteShader=B.whiteShader or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px){
                vec4 t=Texel(tex,uv);float l=max(t.r,max(t.g,t.b));
                if(t.b>t.r*1.08 && t.b>t.g*1.03) t.rgb=mix(vec3(.32,.36,.42),vec3(1.,.99,.94),smoothstep(.04,.42,l));
                return t*color;
            }]])
            g.setShader(B.whiteShader)
        end
        g.setColor(m.stunned and {.65,.8,1} or {1,1,1});Art.drawFacing('merle',m.dir,m.x,m.y+(not m.stunned and m.kind=='shooter' and math.sin(m.age*2)*1.2 or 0),54)
        g.setShader(previous)
        if m.stunned then for i=1,3 do local a=m.age*2+i*math.pi*2/3;g.setColor(1,.87,.35);g.circle('fill',m.x+math.cos(a)*20,m.y-31+math.sin(a)*5,2) end end
    end
    for _,p in ipairs(B.projectiles) do g.setColor(1,1,1);Art.draw('black_feather',p.x,p.y,30,math.atan2(p.vy,p.vx)) end
    g.setColor(1,1,1)
end
return B
