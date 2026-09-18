local R={clouds={},rain={},current={},clock=0,schools={},bolts={},eggs={},larvae={},holes={},rainSites={}}
local function add(kind,x,y,speed,elite)
    if kind=='fish' then
        local school={age=#R.schools*.45,angle=0,members={}}
        R.schools[#R.schools+1]=school
        for i=1,3 do
            local m={type='fish',x=x+(i-2)*29,y=y+math.abs(i-2)*24,speed=speed,dir='down',age=0,
                school=school,slot=i,hitBox_width=24,hitBox_height=24,hitBox_offset_x=-12,hitBox_offset_y=-12}
            mobs[#mobs+1]=m; school.members[#school.members+1]=m
        end
        return
    end
    if kind=='mole' then speed=speed*1.4 end
    mobs[#mobs+1]={type=kind,x=x,y=y,speed=speed,dir='down',age=kind=='mole' and 2.7 or kind=='worm' and 1.6 or 0,phase=0,
        vx=math.cos(x*.01),vy=math.sin(y*.01),elite=elite,
        hitBox_width=32,hitBox_height=30,hitBox_offset_x=-16,hitBox_offset_y=-15}
end
R.add=add
function R.spawnMole(x,y)
    local index=#mobs
    local angle=index*2.4
    local xx,yy=Arena.clearSpot(x+math.cos(angle)*48-16,y+math.sin(angle)*48-15,32,30)
    add('mole',xx+16,yy+15,100)
    Bestiary.discover('mole'); Bestiary.save()
end
function R.spawn(w,n)
    R.schools={}
    local a=(n*43)%200
    if w==7 then
        Abyss.spawn(n)
    elseif w==4 then
        for i=1,2+math.floor(n/3) do Octopus.spawnCrab(100+i*105,i%2==0 and 440 or 150,90+n*3) end
        add('fish',110,130+a,90+n*6); add('jelly',650,450-a,48+n*2)
        if n>=3 then add('fish',650,110,110) end
        if n>=5 then add('jelly',180,470,55) end
        if n>=8 then add('fish',400,130,125) end
        if w==7 then
            add('lanternfish',220,240,42); add('lanternfish',570,350,48)
            if n>=5 then add('lanternfish',390,130,46) end
        end
    elseif w==5 then
        add('worm',120,120+a,78+n*3.5); add('mole',650,450-a,98+n*3.5)
        if n>=3 then add('worm',650,120,90) end
        if n>=4 then add('mole',180,470,116) end
        if n>=7 then add('worm',400,100,110) end
    elseif w==6 then
        add('gull',110,110+a,122+n*5); add('gull',650,450-a,115+n*5)
        add('gull',400,100,115+n*4)
        if n>=4 then add('gull',650,110,135) end
        if n>=7 then add('gull',160,470,150) end
    end
end
function R.reset(w,n)
    R.custom=false; R.world=w; R.level=n; R.clock=0; R.tunnels={}; R.tornadoes={}; player.whirl=nil; player.throw=nil; player.tunnelLock=false; player.tunnelTravel=nil; R.fireflies={}; R.wind={x=0,y=0,time=0,stage=0,tx=0,ty=0}; R.clouds={}; R.rain={}; R.rainClock=.25; R.current={}
    R.electricTrails={}; R.bolts={}; R.eggs={}; R.larvae={}; R.holes={}; R.rainSites={}; R.rainWave=0; R.vents={}; R.lightning={}; R.lightningClock=.35; player.illuminated=0
    if w<4 then return end
    -- Reuse the ocean floor across deaths instead of releasing a GPU canvas
    -- that may still be referenced by the previous frame.
    if not R.floor or R.floor:getWidth()~=Arena.width then
        R.floor=love.graphics.newCanvas(Arena.width,600)
    end
    local g=love.graphics; g.push('all'); g.setCanvas(R.floor); g.clear(Worlds.color(w).floor)
    if w==4 or w==7 then
        for y=0,600,24 do for x=0,Arena.width,32 do
            local v=(x*7+y*3)%19/150
            g.setColor(w==7 and {.035+v*.3,.055+v*.4,.16+v} or {.025,.18+v,.25+v}); g.rectangle('fill',x+2,y+2,28,20)
        end end
        for i=1,48 do local x=(i*83)%Arena.width; local y=(i*61)%600
            g.setColor(w==7 and {.23,.32,.7} or {.09,.4,.33}); g.rectangle('fill',x,y,3,15); g.rectangle('fill',x+3,y+4,3,8)
            if i%3==0 then g.setColor(.7,.36,.4); g.rectangle('fill',x+7,y+8,6,5) end
        end
        for i=1,2 do R.current[i]={x=Arena.width*(i==1 and .28 or .72),y=300,rx=50,ry=200,dx=i==1 and 1 or -1} end
        if w==7 then
            for i=1,150 do R.fireflies[i]={x=32+love.math.random()*(Arena.width-64),y=32+love.math.random()*536,
                angle=love.math.random()*math.pi*2,turn=love.math.random()*2,radius=.7+love.math.random()*.6,phase=love.math.random()*6} end
        end
    elseif w==5 then
        R.makeTunnels()
        for y=0,600,24 do for x=0,Arena.width,32 do
            local v=(x*11+y*7)%17/200
            g.setColor(.19+v,.105+v/2,.055); g.polygon('fill',x+2,y+3,x+29,y,x+30,y+20,x+4,y+22)
        end end
        for i=1,75 do local x=(i*139)%Arena.width; local y=(i*47)%600
            g.setColor(.36,.22,.1); g.rectangle('fill',x,y,5+i%5,3)
            if i%4==0 then g.setColor(.11,.065,.035); g.line(x,y,x+7,y+12,x+4,y+21) end
        end
    else
        for _,p in ipairs({{.24,220},{.76,405}}) do R.tornadoes[#R.tornadoes+1]={x=Arena.width*p[1],y=p[2],cooldown=0} end
        g.clear(.055,.10,.20)
        g.setColor(.40,.57,.72); g.rectangle('fill',28,28,Arena.width-56,544,22)
        -- Overlapping cloud banks, with broad highlights instead of a tile grid.
        g.setScissor(28,28,Arena.width-56,544)
        for i=1,160 do
            local u=math.sin(i*127.1)*43758.5453; local v=math.sin(i*311.7)*19341.371
            local x=28+(u-math.floor(u))*(Arena.width-56); local y=28+(v-math.floor(v))*544
            local rx=45+i%5*11; local ry=24+i%3*8
            g.setColor(.33,.42,.68,.32); g.ellipse('fill',x+8,y+12,rx,ry)
            local warm=(math.sin(i*2.1+n*.7)+1)*.5
            g.setColor(.55+warm*.2,.66-warm*.08,.81+warm*.04,.4); g.ellipse('fill',x,y,rx,ry)
            g.setColor(.83,.80,.94,.17); g.ellipse('fill',x-12,y-8,rx*.65,ry*.7)
        end
        g.setScissor()
        for x=46,Arena.width-35,43 do
            g.setColor(.62,.74,.86); g.ellipse('fill',x,36,30,13); g.ellipse('fill',x,564,30,13)
        end
        for y=48,559,38 do
            g.setColor(.62,.74,.86); g.ellipse('fill',35,y,14,28); g.ellipse('fill',Arena.width-35,y,14,28)
        end
        for i=1,math.min(6,2+math.floor(n/2)) do
            local p={x=Arena.width*(i%2==0 and .68 or .32),y=145+math.floor((i-1)/2)*145+(n%3-1)*15,rx=39,ry=28,seed=i*1.7+n}
            local safe=true
            if (p.x-player.x-15)^2+(p.y-player.y-12)^2<100^2 then safe=false end
            for _,t in ipairs(levels[player.level].larme_position) do if (p.x-t.x-15)^2+(p.y-t.y-20)^2<85^2 then safe=false end end
            for _,t in ipairs(R.tornadoes) do if (p.x-t.x)^2+(p.y-t.y)^2<110^2 then safe=false end end
            for _,m in ipairs(mobs) do if (m.type=='piege' or m.capture) and (p.x-m.x)^2+(p.y-m.y)^2<85^2 then safe=false end end
            if safe then R.holes[#R.holes+1]=p end
        end
        for row=1,4 do for col=1,6 do
            R.rainSites[#R.rainSites+1]={x=Arena.width*(.12+(col-1)*.15),y=95+(row-1)*130,phase=(row+col+n)%3}
        end end
    end
    if w==6 and n==10 then R.holes={}; R.rainSites={} end
    g.setCanvas(); g.pop()
end
function R.makeTunnels()
    for _,p in ipairs({{.2,325},{.8,235}}) do
        local best,bx,by=math.huge,nil,nil
        for y=115,495,20 do for x=80,Arena.width-80,20 do
            local valid=not Arena.blocked(x-52,y-38,104,76)
            for _,q in ipairs(levels[player.level].larme_position) do if (x-q.x-15)^2+(y-q.y-20)^2<85^2 then valid=false end end
            if Hedgehog.active and (x-Hedgehog.x)^2+(y-Hedgehog.y)^2<110^2 then valid=false end
            for _,t in ipairs(R.tunnels) do if (x-t.x)^2+(y-t.y)^2<180^2 then valid=false end end
            local d=(x-Arena.width*p[1])^2+(y-p[2])^2
            if valid and d<best then best,bx,by=d,x,y end
        end end
        assert(bx,'Pas de place pour un tunnel Terre')
        R.tunnels[#R.tunnels+1]={x=bx,y=by}
    end
end
function R.traverse(m,dt,isPlayer)
    local ox,oy=isPlayer and 15 or 0,isPlayer and 12 or 0
    local travel=m.tunnelTravel
    if travel then
        travel.time=travel.time+dt
        if travel.time>=.22 and not travel.arrived then
            m.x,m.y=travel.to.x-ox,travel.to.y-oy; travel.arrived=true
            m.path=nil; m.navTime=0
        end
        if travel.time>=.44 then m.tunnelTravel=nil end
        return
    end
    local entrance
    for i,t in ipairs(R.tunnels) do if ((m.x+ox-t.x)/38)^2+((m.y+oy-t.y)/25)^2<1 then entrance=i; break end end
    if not entrance then m.tunnelLock=false
    elseif not m.tunnelLock and not m.reset then
        m.tunnelLock=true; m.tunnelTravel={time=0,to=R.tunnels[entrance%2==1 and entrance+1 or entrance-1] or R.tunnels[entrance]}
        if isPlayer then m.dashing=false; Audio.play('pick') end
    end
end
function R.travelPose(m)
    local t=m.tunnelTravel.time
    local scale=t<.22 and 1-t/.22 or (t-.22)/.22
    return math.max(.02,scale),18*(1-scale)
end
function R.updateTraversal(dt)
    if Campaign.biome==5 or R.custom then
        R.traverse(player,dt,true)
        for _,m in ipairs(mobs) do if not m.ground and m.type~='piege' then R.traverse(m,dt,false) end end
        for _,m in ipairs(R.larvae) do R.traverse(m,dt,false) end
    end
    if Campaign.biome==6 or R.custom then
        for _,t in ipairs(R.tornadoes) do t.cooldown=math.max(0,t.cooldown-dt) end
        if player.whirl then
            local w=player.whirl; w.time=w.time-dt; local a=R.clock*18
            player.x=w.tornado.x+math.cos(a)*15-15; player.y=w.tornado.y+math.sin(a)*10-12
            if w.time<=0 then
                player.whirl=nil; player.throw={vx=w.dx*1050,vy=w.dy*1050,time=1.5}
                w.tornado.cooldown=1.5
            end
        elseif player.throw then
            local t=player.throw; local step=math.min(dt,t.time)
            local steps=math.max(1,math.ceil(1050*step/6))
            for _=1,steps do
                local hx,hy=Arena.move(player,t.vx*step/steps,t.vy*step/steps)
                R.contact(); if hx or hy or player.reset then t.time=0; break end
            end
            t.time=t.time-dt
            if t.time<=0 then player.throw=nil end
        elseif not player.reset then
            for _,t in ipairs(R.tornadoes) do
                if t.cooldown==0 and (player.x+15-t.x)^2+(player.y+12-t.y)^2<32^2 then
                    local dx,dy=player.lastMoveX or 0,player.lastMoveY or 1
                    local d=math.max(.001,math.sqrt(dx*dx+dy*dy))
                    player.whirl={tornado=t,time=.65,dx=-dy/d,dy=dx/d}; player.dashing=false; break
                end
            end
        end
    end
end
function R.update(dt)
    if Campaign.biome<4 and not R.custom then return end
    R.clock=R.clock+dt
    R.updateTraversal(dt)
    if Campaign.biome==5 or R.custom then R.separateEarth() end
    if Abyss.active then Abyss.update(dt) end
    if Campaign.biome==6 or R.custom then
        R.updateElectricTrails(dt)
        R.updateLightning(dt)
        if Campaign.biome==6 then R.updateWind(dt) end
        R.rainClock=R.rainClock-dt
        if (R.level>=5 or R.custom) and R.rainClock<=0 then
            R.rainClock=math.max(.55,.95-R.level*.035); R.rainWave=R.rainWave+1
            for _,p in ipairs(R.rainSites) do if p.phase==R.rainWave%3 then
                R.rain[#R.rain+1]={x=p.x,y=p.y,age=0}
            end end
        end
        for i=#R.rain,1,-1 do local p=R.rain[i]; p.age=p.age+dt
            if p.age>=.62 and p.age<1.12 and ((player.x+15-p.x)/24)^2+((player.y+12-p.y)/12)^2<1 then Hazards.kill() end
            if p.age>1.25 then table.remove(R.rain,i) end
        end
    end
    if Campaign.biome==4 or Campaign.biome==7 or R.custom then
        for _,school in ipairs(R.schools) do
            local before=school.age%3; school.age=school.age+dt; local phase=school.age%3
            if before<2.3 and phase>=2.3 then
                local x,y=0,0; for _,m in ipairs(school.members) do x=x+m.x; y=y+m.y end
                school.angle=math.atan2(player.y+12-y/#school.members,player.x+15-x/#school.members)
            end
        end
        for _,c in ipairs(R.current) do if Hazards.inEllipse(player.x+15,player.y+12,c,0) then
            local x=player.x+c.dx*40*dt
            if not willCollide(x,player.y) then player.x=x end
        end end
    end
    R.updateProjectiles(dt)
    R.updateFireflies(dt)
    R.contact()
end
function R.updateLightning(dt)
    if Campaign.biome~=6 then R.lightning={}; return end
    R.lightningClock=R.lightningClock-dt
    if R.lightningClock<=0 then
        R.lightningClock=math.max(1.25,2.5-R.level*.085)+love.math.random()*.35
        local gulls={}; for _,m in ipairs(mobs) do if m.type=='gull' then gulls[#gulls+1]=m end end
        if #gulls>0 then local m=gulls[love.math.random(#gulls)]; R.lightning[#R.lightning+1]={x=m.x,y=m.y,age=0,target=m} end
        if not (Storm.active and Storm.phase=='rest') then
            R.lightning[#R.lightning+1]={x=player.x+15,y=player.y+12,age=0}
            if R.level>=6 then R.lightning[#R.lightning+1]={x=math.max(65,math.min(Arena.width-65,player.x+115)),y=math.max(75,math.min(525,player.y-70)),age=0} end
        end
    end
    for i=#R.lightning,1,-1 do local p=R.lightning[i]; p.age=p.age+dt
        if p.age<.8 and p.target then p.x,p.y=p.target.x,p.target.y end
        if p.age>=.8 and not p.struck then
            p.struck=true
            for _,m in ipairs(mobs) do if m.type=='gull' and (m.x-p.x)^2+(m.y-p.y)^2<45^2 then
                m.electric=true; Bestiary.discover('electric_gull'); Bestiary.save()
            end end
            if (player.x+15-p.x)^2+(player.y+12-p.y)^2<34^2 then Hazards.kill() end
        end
        if p.age>1.15 then table.remove(R.lightning,i) end
    end
end
function R.separateEarth()
    for pass=1,8 do
        for i=1,#mobs do local a=mobs[i]
            if (a.type=='mole' or a.type=='worm') and not a.tunnelTravel then
                for j=i+1,#mobs do local b=mobs[j]
                    if (b.type=='mole' or b.type=='worm') and not b.tunnelTravel then
                        local dx,dy=b.x-a.x,b.y-a.y; local d=math.sqrt(dx*dx+dy*dy)
                        if d<46 then
                            if d<.001 then dx,dy,d=math.cos(j*2.4),math.sin(j*2.4),1 end
                            local step=(46-d)/2+.1
                            Arena.move(a,-dx/d*step,-dy/d*step); Arena.move(b,dx/d*step,dy/d*step)
                        end
                    end
                end
            end
        end
    end
end
function R.updateWind(dt)
    local w=R.wind; w.time=w.time-dt
    if w.time<=0 then
        w.stage=w.stage+1
        local strength=({45,115,0,75,150,0})[(w.stage-1)%6+1]
        local angle=love.math.random()*math.pi*2
        w.tx,w.ty=math.cos(angle)*strength,math.sin(angle)*strength
        w.time=3+love.math.random()*3
    end
    local blend=1-math.exp(-dt*1.7)
    if w.tx==0 and w.ty==0 then w.x,w.y=0,0
    else w.x=w.x+(w.tx-w.x)*blend; w.y=w.y+(w.ty-w.y)*blend end
    if not player.is_frozen and not player.reset and not player.whirl then Arena.move(player,w.x*dt,w.y*dt) end
    for _,m in ipairs(mobs) do if not m.ground and m.type~='piege' and not m.is_frozen then
        Arena.move(m,w.x*dt*.85,w.y*dt*.85)
        if m.type=='gull' then R.containGull(m) end
    end end
end
function R.containGull(m)
    local lo,hi,top,bottom=48,Arena.width-48,48,552
    -- Clamp once and keep an inward heading; never flip it on every blocked frame.
    if m.x<=lo then m.x=lo; m.vx=math.abs(m.vx or 1)+.3
    elseif m.x>=hi then m.x=hi; m.vx=-math.abs(m.vx or 1)-.3 end
    if m.y<=top then m.y=top; m.vy=math.abs(m.vy or 1)+.3
    elseif m.y>=bottom then m.y=bottom; m.vy=-math.abs(m.vy or 1)-.3 end
end
function R.moveGull(m,dt)
    local previousX,previousY=m.x,m.y
    local tx,ty=objet.larme.x+15,objet.larme.y+20
    tx=math.max(80,math.min(Arena.width-80,tx)); ty=math.max(80,math.min(520,ty))
    local dx,dy=tx-m.x,ty-m.y; local d=math.sqrt(dx*dx+dy*dy)
    if d<85 then
        m.orbit=(m.orbit or math.atan2(m.y-ty,m.x-tx))+dt*m.speed/65
        tx,ty=tx+math.cos(m.orbit)*65,ty+math.sin(m.orbit)*52
        dx,dy=tx-m.x,ty-m.y; d=math.sqrt(dx*dx+dy*dy)
    else m.orbit=nil end
    if d>.1 then m.vx,m.vy=dx/d,dy/d; Arena.move(m,m.vx*math.min(d,m.speed*dt),m.vy*math.min(d,m.speed*dt)) end
    R.containGull(m); m.dir=Art.direction(m.vx,m.vy,m.dir)
    if m.electric then
        R.electricTrails[#R.electricTrails+1]={x=previousX,y=previousY,tx=m.x,ty=m.y,life=2.2,seed=m.age*11}
        if (player.x+15-m.x)^2+(player.y+12-m.y)^2<30^2 then Hazards.kill() end
    end
end
function R.trailTouches(p,x,y)
    local dx,dy=p.tx-p.x,p.ty-p.y; local d=dx*dx+dy*dy
    local t=d>0 and math.max(0,math.min(1,((x-p.x)*dx+(y-p.y)*dy)/d)) or 0
    return (x-p.x-t*dx)^2+(y-p.y-t*dy)^2<14^2
end
function R.updateElectricTrails(dt)
    for i=#R.electricTrails,1,-1 do
        local p=R.electricTrails[i]; p.life=p.life-dt
        if p.life<=0 then table.remove(R.electricTrails,i)
        elseif R.trailTouches(p,player.x+15,player.y+12) then Hazards.kill() end
    end
end
function R.drawWind(width,height)
    if Campaign.biome~=6 then return end
    width=width or Arena.width; height=height or 600
    local w=R.wind; local strength=math.sqrt(w.x*w.x+w.y*w.y)
    if strength<4 then return end
    local dx,dy=w.x/strength,w.y/strength; local g=love.graphics
    g.push('all'); g.setColor(.30,.48,.60,.30); g.setLineWidth(.8)
    local count=math.floor(width*height/11000)
    for i=1,count do
        local u=math.sin(i*127.1)*43758.5453; local v=math.sin(i*311.7)*19341.371
        local x=((u-math.floor(u))*width+R.clock*w.x*1.4)%width
        local y=((v-math.floor(v))*height+R.clock*w.y*1.4)%height
        local length=4+math.min(strength,150)*.025
        g.line(x-dx*length,y-dy*length,x,y)
    end
    g.pop()
end
function R.speed()
    return 1
end
function R.fallAt(x,y)
    if Campaign.biome~=6 and not R.custom then return false end
    if Campaign.biome==6 and (x<=40 or x>=Arena.width-40 or y<=38 or y>=562) then return true end
    for _,p in ipairs(R.holes) do
        local dx,dy=(x-p.x)/p.rx,(y-p.y)/p.ry
        if math.sqrt(dx*dx+dy*dy)<R.holeRadius(p,math.atan2(dy,dx))-.07 then return true end
    end
    return false
end
function R.holeRadius(p,a)
    return 1+.22*math.sin(a*3+(p.seed or 0))+.13*math.sin(a*7-(p.seed or 0))
end
function R.drawHole(p,scale)
    local g=love.graphics
    for j=0,47 do
        local a,b=j*math.pi/24,(j+1)*math.pi/24
        local ra,rb=R.holeRadius(p,a)*scale,R.holeRadius(p,b)*scale
        g.polygon('fill',p.x,p.y,p.x+math.cos(a)*p.rx*ra,p.y+math.sin(a)*p.ry*ra,p.x+math.cos(b)*p.rx*rb,p.y+math.sin(b)*p.ry*rb)
    end
end
function R.wormPhase(age)
    local t=age%4
    if t<1.2 then return 'hidden',0
    elseif t<1.6 then return 'emerge',(t-1.2)/.4
    elseif t<3.5 then return 'surface',1
    else return 'dig',(4-t)/.5 end
end
function R.molePhase(age)
    local t=age%5
    if t<1.7 then return 'hidden',0
    elseif t<2.15 then return 'warning',(t-1.7)/.45
    elseif t<2.7 then return 'emerge',(t-2.15)/.55
    elseif t<4.3 then return 'surface',1
    else return 'dig',1-(t-4.3)/.7 end
end
function R.contact()
    if R.fallAt(player.x+15,player.y+12) then Hazards.kill(); if player.reset then player.falling=true end end
    if Campaign.biome==7 or R.custom then for _,p in ipairs(R.vents) do
        local t=(R.clock+p.phase)%6
        if t>=3 and t<4.2 and Hazards.inEllipse(player.x+15,player.y+12,p,4) then Hazards.kill() end
    end end
end
function R.zap(m)
    for i=0,11 do local a=i*math.pi/6+m.age*.3
        R.bolts[#R.bolts+1]={x=m.x,y=m.y,vx=math.cos(a)*175,vy=math.sin(a)*175,life=2.7,seed=i}
    end
end
function R.spit(m)
    local a=math.atan2(player.y+12-m.y,player.x+15-m.x)
    for _,offset in ipairs({-.3,0,.3}) do
        R.eggs[#R.eggs+1]={x=m.x,y=m.y,vx=math.cos(a+offset)*185,vy=math.sin(a+offset)*185,life=8}
    end
end
function R.updateProjectiles(dt)
    for _,list in ipairs({R.bolts,R.eggs}) do for i=#list,1,-1 do
        local p=list[i]; if not p.abyssHeld then
        p.life=p.life-dt; local dead=p.life<=0
        local steps=math.max(1,math.ceil(math.sqrt(p.vx^2+p.vy^2)*dt/4))
        for _=1,steps do if not dead then
            local x,y=p.x+p.vx*dt/steps,p.y+p.vy*dt/steps
            if Arena.blocked(x-4,y-4,8,8) then
                if list==R.eggs and #R.larvae<36 then
                    local sx,sy=Arena.clearSpot(p.x-8,p.y-8,16,16)
                    for j=1,3 do R.larvae[#R.larvae+1]={x=sx+8,y=sy+8,age=j*.8,life=16,dir='down',
                        hitBox_width=16,hitBox_height=16,hitBox_offset_x=-8,hitBox_offset_y=-8} end
                    Bestiary.discover('larva'); Bestiary.save()
                end
                dead=true
            else
                p.x=x; p.y=y
                local radius=list==R.bolts and 5 or 3
                if checkCollision(x-radius,y-radius,radius*2,radius*2,player.x,player.y,30,24) then Hazards.kill(); dead=true end
            end
        end end
        if dead then table.remove(list,i) end
    end end end
    for i=#R.larvae,1,-1 do local m=R.larvae[i]; m.age=m.age+dt; m.life=m.life-dt
        R.capture(m)
        if m.is_frozen then m.freeze_timer=m.freeze_timer-dt; if m.freeze_timer<=0 then m.is_frozen=false end end
        local a=math.atan2(player.y+12-m.y,player.x+15-m.x)
        if not m.tunnelTravel then
            m.dir=Art.direction(math.cos(a),math.sin(a)); Arena.navigate(m,player.x+15,player.y+12,72,dt)
            if isTouching(player,m) then Hazards.kill() end
        end
        if m.life<=0 then table.remove(R.larvae,i) end
    end
end
function R.drawCreatures()
    local g=love.graphics
    for _,m in ipairs(R.larvae) do
        local scale,dy=1,0; if m.tunnelTravel then scale,dy=R.travelPose(m) end
        g.setColor(1,1,1,scale); Art.drawFacing('worm',m.dir,m.x,m.y+dy,26*scale)
    end
    for _,p in ipairs(R.eggs) do
        g.setColor(.24,.12,.09); g.ellipse('fill',p.x,p.y,6,5)
        g.setColor(.96,.72,.53); g.ellipse('fill',p.x,p.y-1,4,4)
        g.setColor(1,.94,.75); g.circle('fill',p.x-1,p.y-2,1.5)
    end
    for _,p in ipairs(R.bolts) do if not p.abyssHeld then
        local a=math.atan2(p.vy,p.vx); g.push(); g.translate(p.x,p.y); g.rotate(a); g.scale(1.35)
        local bend=math.sin(R.clock*42+p.seed)*3
        g.setColor(.1,.5,1,.22); g.setLineWidth(4); g.line(-19,0,-13,bend,-7,-bend,0,0)
        g.setColor(.3,.8,1); g.setLineWidth(1); g.line(-19,0,-13,bend,-7,-bend,0,0)
        g.setColor(.85,1,1); g.circle('fill',0,0,1.3); g.pop()
    end end
    g.setLineWidth(1); g.setColor(1,1,1)
end
function R.updateFireflies(dt)
    for i=#R.fireflies,1,-1 do
        local p=R.fireflies[i]; if not p.abyssHeld then
        p.turn=p.turn-dt
        if p.turn<=0 then p.angle=p.angle+(love.math.random()-.5)*2; p.turn=.6+love.math.random()*1.8 end
        p.x=p.x+math.cos(p.angle)*12*dt; p.y=p.y+math.sin(p.angle)*12*dt
        if p.x<28 or p.x>Arena.width-28 then p.angle=math.pi-p.angle; p.x=math.max(28,math.min(Arena.width-28,p.x)) end
        if p.y<28 or p.y>572 then p.angle=-p.angle; p.y=math.max(28,math.min(572,p.y)) end
        if (p.x-player.x-15)^2+(p.y-player.y-12)^2<18^2 then table.remove(R.fireflies,i) end
    end end
end
function R.drawFireflies()
    if Campaign.biome~=7 then return end
    local g=love.graphics; g.push('all'); g.setBlendMode('add')
    for _,p in ipairs(R.fireflies) do if not p.abyssHeld then
        local alpha=.65+.25*math.sin(R.clock*2+p.phase)
        g.setColor(.08,.35,1,alpha*.10); g.circle('fill',p.x,p.y,4)
        g.setColor(.18,.62,1,alpha); g.circle('fill',p.x,p.y,p.radius)
        g.setColor(.65,.92,1,alpha); g.circle('fill',p.x,p.y,p.radius*.4)
    end end
    g.pop()
end
function R.drawDarkness()
    if Campaign.biome~=7 then return end
    local g=love.graphics
    R.darkShader=R.darkShader or g.newShader('assets/abyss-darkness.glsl')
    local exposed=(player.illuminated or 0)>0
    local lights={{player.x+15,player.y+12,exposed and Abyss.playerLightRadius() or 52,exposed and (player.circleLight and .8 or .65+.12*math.max(0,(player.charges or 0)-1)) or .23}}
    for _,m in ipairs(mobs) do if m.type=='lanternfish' then lights[#lights+1]={m.x,m.y-15,145,1} end end
    Abyss.addLights(lights); Bosses.addLights(lights); AbyssTerrain.addLights(lights)
    while #lights>24 do table.remove(lights) end
    for _,m in ipairs(mobs) do if m.type=='light_jelly' and #lights<24 then lights[#lights+1]={m.x,m.y,60,.5} end end
    for _,b in ipairs(Ocean.bubbles) do
        if #lights<24 then lights[#lights+1]={b.x,b.y,26,b.cooldown==0 and .42 or .1} end
    end
    while #lights<24 do lights[#lights+1]={-1000,-1000,1,0} end
    R.darkShader:send('lights',unpack(lights)); g.setShader(R.darkShader); g.setColor(1,1,1)
    g.rectangle('fill',0,0,Arena.width,600); g.setShader()
    g.setBlendMode('add')
    for _,m in ipairs(mobs) do if m.type=='lanternfish' then
        for i=4,1,-1 do g.setColor(1,.72,.25,.03); g.circle('fill',m.x,m.y-15,i*9) end
    end end
    g.setBlendMode('alpha'); g.setColor(1,1,1)
end
function R.drawGround()
    local g=love.graphics
    for _,p in ipairs(R.electricTrails or {}) do
        local alpha=math.min(1,p.life/.4)
        local mx,my=(p.x+p.tx)/2,(p.y+p.ty)/2
        local j=math.sin(R.clock*24+p.seed)*2
        g.setColor(1,.74,.08,.2*alpha); g.setLineWidth(7); g.line(p.x,p.y,mx+j,my-j,p.tx,p.ty)
        g.setColor(1,.94,.35,.95*alpha); g.setLineWidth(1.5); g.line(p.x,p.y,mx+j,my-j,p.tx,p.ty)
    end
    g.setLineWidth(1)
    if Campaign.biome==6 and R.level>=5 then g.setColor(.19,.24,.31,.28); g.rectangle('fill',28,28,Arena.width-56,544) end
    for _,p in ipairs(R.lightning or {}) do
        if p.age<.8 then g.setColor(.25,.48,.8,.3); g.ellipse('line',p.x,p.y,30,15)
        elseif p.age<1.05 then
            g.setColor(.65,.87,1,.95); g.setLineWidth(4)
            g.line(p.x-24,30,p.x+13,110,p.x-8,175,p.x+18,p.y-55,p.x,p.y)
            g.setColor(1,1,1,.9); g.setLineWidth(1); g.line(p.x-24,30,p.x+13,110,p.x-8,175,p.x+18,p.y-55,p.x,p.y)
        end
    end
    g.setLineWidth(1)
    for _,t in ipairs(R.tunnels) do
        g.setColor(1,1,1); Art.draw('earth_tunnel',t.x,t.y,100,0,72)
        g.setColor(.9,.64,.3,.45); g.ellipse('line',t.x,t.y+4,21,10)
    end
    for _,t in ipairs(R.tornadoes) do
        g.setColor(1,1,1,.7); Art.draw('cloud_snare',t.x,t.y,90,R.clock*3.8)
        g.setColor(1,1,1,.85); Art.draw('cloud_snare',t.x,t.y-13,62,-R.clock*5.4)
        g.setColor(1,1,1); Art.draw('cloud_snare',t.x,t.y-23,37,R.clock*7)
    end
    if Campaign.biome==4 or Campaign.biome==7 or R.custom then
        for _,c in ipairs(R.current) do
            g.setColor(.2,.75,.85,.18)
            for i=1,12 do local y=c.y-170+i*28; local x=c.x+math.sin(R.clock*2+i)*15
                g.line(x-10*c.dx,y-3,x,y,x-10*c.dx,y+3)
            end
        end
        for i=1,25 do local x=(i*97)%Arena.width; local y=(i*59-R.clock*15)%600
            g.setColor(.55,.9,1,.22); g.circle('line',x,y,2+i%3)
        end
        for _,p in ipairs(R.vents) do
            local t=(R.clock+p.phase)%6
            local phase=t<2 and 'idle' or t<3 and 'charge' or t<4.2 and 'active' or 'spent'
            g.setColor(1,1,1); Art.draw('electric_vent_'..phase,p.x,p.y,p.rx*2+14,0,p.ry*2+24)
        end
    end
    if Campaign.biome==6 or R.custom then
        for _,p in ipairs(R.holes) do
            g.setColor(.78,.87,.94); R.drawHole(p,1.19)
            g.setColor(.36,.49,.64); R.drawHole(p,1.08)
            -- Receding irregular ledges darken toward the bottom of the chasm.
            for depth=0,10 do
                local t=depth/10; g.setColor(.25*(1-t)+.015,.35*(1-t)+.025,.47*(1-t)+.065)
                g.push(); g.translate(0,t*7); R.drawHole(p,1-t*.48); g.pop()
            end
        end
        for _,p in ipairs(R.rain) do
            g.setColor(.12,.32,.55,p.age<.85 and .24 or .5); g.ellipse('fill',p.x,p.y,23,10)
            if p.age<.85 then
                g.setColor(.2,.55,.8,.6); g.ellipse('line',p.x,p.y,24,11)
                for j=-2,2 do
                    local progress=math.min(1,p.age/.85); local y=p.y-(1-progress)*155+j%2*5
                    local x=p.x+j*8
                    g.setColor(.27,.62,.9,.5); g.setLineWidth(2); g.line(x-6,y-20,x,y)
                    g.setColor(.7,.92,1); g.ellipse('fill',x,y,2,5)
                end
            else
                local r=8+(p.age-.85)*65; g.setColor(.35,.72,1,math.max(0,1-(p.age-.85)*2.5))
                g.ellipse('line',p.x,p.y,r,r*.4)
                for j=0,5 do local a=j*math.pi/3; g.circle('fill',p.x+math.cos(a)*r,p.y+math.sin(a)*r*.4,2) end
            end
            g.setLineWidth(1)
        end
    end
    -- Pulse warnings and digging tracks stay below all creatures.
    for _,m in ipairs(mobs) do
        if m.type=='jelly' then
            local t=m.age%3.5; if t>2.3 then g.setColor(.25,.95,1,.3); g.circle('line',m.x,m.y,26+math.sin(t*18)*3) end
        elseif m.type=='mole' then
            local phase,t=R.molePhase(m.age)
            if phase=='warning' or phase=='emerge' or phase=='dig' then
                g.setColor(.085,.04,.025); g.ellipse('fill',m.x,m.y+10,23,11)
                g.setColor(.52,.33,.16); g.ellipse('line',m.x,m.y+10,25,12)
                for j=1,9 do
                    local a=j*2.4; local travel=(m.age*2+j*.13)%1
                    local r=phase=='dig' and 12+travel*23 or 27*(1-travel)
                    local y=m.y+10+math.sin(a)*r*.5-(phase=='emerge' and math.sin(travel*math.pi)*20 or 0)
                    g.setColor(.4+j%3*.07,.23,.1); g.rectangle('fill',m.x+math.cos(a)*r,y,3+j%3,3)
                end
                if phase=='warning' then g.setColor(.9,.62,.25,.6); g.ellipse('line',m.x,m.y+10,20+t*6,10+t*3) end
            end
        elseif m.type=='worm' then
            local phase=R.wormPhase(m.age)
            if phase=='hidden' then
                g.setColor(.025,.015,.01,.45); g.ellipse('fill',m.x,m.y,9,3)
            elseif phase=='dig' or phase=='emerge' then
                g.setColor(.08,.035,.018,.7); g.ellipse('fill',m.x,m.y+12,19,7)
                for j=1,7 do local a=j*2.4; local r=8+(m.age*3+j*.17)%1*17
                    g.setColor(.47,.28,.13,.8); g.circle('fill',m.x+math.cos(a)*r,m.y+12+math.sin(a)*r*.4,2)
                end
            end
        end
    end
    g.setColor(1,1,1)
end
function R.drawWall(r)
    local g=love.graphics; local w=Campaign.biome
    if w==6 then return end
    local c=w==7 and {.15,.12,.34} or w==4 and {.12,.42,.44} or w==5 and {.36,.22,.10} or {.75,.83,.89}
    g.setColor(c); g.rectangle('fill',r.x,r.y,r.w,r.h)
    g.setColor(c[1]*.6,c[2]*.6,c[3]*.6); g.rectangle('line',r.x+1,r.y+1,r.w-2,r.h-2)
    g.setColor(1,1,1,.16); g.line(r.x+2,r.y+2,r.x+r.w-2,r.y+2)
    g.setColor(1,1,1)
end
function R.capture(m)
    for _,t in ipairs(mobs) do if (t.type=='piege' or t.capture) and not t.active and isTouching(m,t) then
        freeze(m,2); t.active=true
        if m.has_larme and not objet.larme_dropped then objet.larme_dropped=true; objet.larme.x=m.x-15; objet.larme.y=m.y+35 end
    end end
end
local function update(m,dt)
    R.capture(m); if m.is_frozen or m.tunnelTravel then return end
    local before=m.age
    m.age=m.age+dt; local vx,vy=m.vx,m.vy; local speed=m.speed
    local dangerous=true
    if m.type=='fish' then
        local s=m.school; local dash=s.age%3>=2.3
        vx,vy=math.cos(s.angle),math.sin(s.angle); speed=dash and 440 or 13
        if not dash then
            local leaderIndex=s.members[2] and 2 or 1
            local leader=s.members[leaderIndex] or m; local offset=(m.slot-leaderIndex)*29
            vx=vx+(leader.x+offset-m.x)*.12; vy=vy+(leader.y+math.abs(m.slot-leaderIndex)*24-m.y)*.12
            local length=math.max(1,math.sqrt(vx*vx+vy*vy)); vx=vx/length; vy=vy/length
        end
    elseif m.type=='jelly' then
        vx,vy=math.cos(m.age*.7+m.x*.001),math.sin(m.age*.8); speed=speed*.65
        if math.floor((before+.5)/3.5)<math.floor((m.age+.5)/3.5) then R.zap(m) end
    elseif m.type=='worm' then
        local a=math.atan2(player.y+12-m.y,player.x+15-m.x)
        vx,vy=math.cos(a),math.sin(a)
        dangerous=m.age%4>=1.2
        if not dangerous then speed=speed*1.3 else speed=speed*.3 end
        if math.floor((before+2.8)/4)<math.floor((m.age+2.8)/4) then R.spit(m) end
    elseif m.type=='lanternfish' then
        vx,vy=math.cos(m.age*.45+m.phase),math.sin(m.age*.6+m.phase)*.65
    elseif m.type=='mole' then
        local t=m.age%5; local phase,amount=R.molePhase(m.age); dangerous=phase=='surface' or (phase=='emerge' and amount>.65)
        if t<.05 or not m.targetX then m.targetX=player.x+15; m.targetY=player.y+12 end
        if t<1.7 then
            local a=math.atan2(m.targetY-m.y,m.targetX-m.x); vx,vy=math.cos(a),math.sin(a); speed=196
        elseif phase~='surface' then speed=0
        else local a=math.atan2(player.y+12-m.y,player.x+15-m.x); vx,vy=math.cos(a),math.sin(a) end
    elseif m.type=='gull' then
        R.moveGull(m,dt)
        if dangerous and isTouching(player,m) then Hazards.kill() end
        return
    end
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
for _,kind in ipairs({'fish','jelly','worm','mole','gull','lanternfish'}) do MobBehaviors[kind]={update=update,draw=draw} end
return R
