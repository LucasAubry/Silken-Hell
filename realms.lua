local R={clouds={},rain={},current={},clock=0}
local function add(kind,x,y,speed,elite)
    mobs[#mobs+1]={type=kind,x=x,y=y,speed=speed,dir='down',age=0,phase=0,
        vx=math.cos(x*.01),vy=math.sin(y*.01),elite=elite,
        hitBox_width=32,hitBox_height=30,hitBox_offset_x=-16,hitBox_offset_y=-15}
end
function R.spawn(w,n)
    local a=(n*43)%200
    if w==4 then
        add('fish',110,130+a,90+n*6); add('jelly',650,450-a,48+n*2)
        if n>=3 then add('fish',650,110,110) end
        if n>=5 then add('jelly',180,470,55) end
        if n>=8 then add('fish',400,130,125) end
    elseif w==5 then
        add('worm',120,120+a,70+n*3); add('mole',650,450-a,90+n*3)
        if n>=3 then add('worm',650,120,90) end
        if n>=6 then add('mole',180,470,110) end
        if n>=8 then add('worm',400,100,110) end
    elseif w==6 then
        add('gull',110,110+a,110+n*4); add('gull',650,450-a,100+n*4)
        if n>=4 then add('gull',650,110,135) end
        if n>=7 then add('gull',160,470,150) end
    end
    spawn_piege(180,170); spawn_piege(610,470)
    if n>=4 then spawn_scie(390,135,1,1.2+n*.1,'left') end
    if n>=8 then spawn_scie(400,470,-1,1.8,'left') end
    if n==5 or n==7 or n==10 then
        for _,m in ipairs(mobs) do
            if (w==4 and m.type=='jelly') or (w==5 and m.type=='mole') or (w==6 and m.type=='gull') then
                m.has_larme=true; m.elite=n==10; break
            end
        end
    end
end
function R.reset(w,n)
    R.world=w; R.level=n; R.clock=0; R.clouds={}; R.rain={}; R.rainClock=1; R.current={}
    if w<4 then return end
    if R.floor then R.floor:release() end
    R.floor=love.graphics.newCanvas(Arena.width,600)
    local g=love.graphics; g.push('all'); g.setCanvas(R.floor); g.clear(Worlds.color(w).floor)
    if w==4 then
        for y=0,600,24 do for x=0,Arena.width,32 do
            local v=(x*7+y*3)%19/150
            g.setColor(.025,.18+v,.25+v); g.rectangle('fill',x+2,y+2,28,20)
        end end
        for i=1,48 do local x=(i*83)%Arena.width; local y=(i*61)%600
            g.setColor(.09,.4,.33); g.rectangle('fill',x,y,3,15); g.rectangle('fill',x+3,y+4,3,8)
            if i%3==0 then g.setColor(.7,.36,.4); g.rectangle('fill',x+7,y+8,6,5) end
        end
        for i=1,2 do R.current[i]={x=Arena.width*(i==1 and .28 or .72),y=300,rx=50,ry=200,dx=i==1 and 1 or -1} end
    elseif w==5 then
        for y=0,600,24 do for x=0,Arena.width,32 do
            local v=(x*11+y*7)%17/200
            g.setColor(.19+v,.105+v/2,.055); g.polygon('fill',x+2,y+3,x+29,y,x+30,y+20,x+4,y+22)
        end end
        for i=1,75 do local x=(i*139)%Arena.width; local y=(i*47)%600
            g.setColor(.36,.22,.1); g.rectangle('fill',x,y,5+i%5,3)
            if i%4==0 then g.setColor(.11,.065,.035); g.line(x,y,x+7,y+12,x+4,y+21) end
        end
    else
        for y=0,600,20 do g.setColor(.23+y/2800,.42+y/3000,.6+y/3500); g.rectangle('fill',0,y,Arena.width,20) end
        for i=1,45 do local x=(i*137)%Arena.width; local y=(i*71)%600
            g.setColor(.75,.86,.93,.18); g.rectangle('fill',x,y,65,12); g.rectangle('fill',x+12,y-8,38,8)
        end
        for i=1,math.min(5,2+math.floor(n/3)) do R.clouds[i]={x=Arena.width*(.15+i*.13),y=130+(i*113+n*37)%320,rx=48,ry=26} end
    end
    g.setCanvas(); g.pop()
end
function R.update(dt)
    if Campaign.world<4 then return end
    R.clock=R.clock+dt
    if Campaign.world==6 then
        R.rainClock=R.rainClock-dt
        if R.rainClock<=0 then
            R.rainClock=math.max(.35,1.3-R.level*.07)
            local x,y=player.x+15,player.y+12
            R.rain[#R.rain+1]={x=x,y=y,age=0}
            if R.level>=6 then R.rain[#R.rain+1]={x=50+love.math.random()*(Arena.width-100),y=80+love.math.random()*450,age=0} end
        end
        for i=#R.rain,1,-1 do local p=R.rain[i]; p.age=p.age+dt
            if p.age>=.85 and p.age<1.08 and (player.x+15-p.x)^2+(player.y+12-p.y)^2<24^2 then Hazards.kill() end
            if p.age>1.25 then table.remove(R.rain,i) end
        end
    elseif Campaign.world==4 then
        for _,c in ipairs(R.current) do if Hazards.inEllipse(player.x+15,player.y+12,c,0) then
            local x=player.x+c.dx*40*dt
            if not willCollide(x,player.y) then player.x=x end
        end end
    end
end
function R.speed()
    if Campaign.world==6 then for _,c in ipairs(R.clouds) do if Hazards.inEllipse(player.x+15,player.y+12,c,0) then return .4 end end end
    return 1
end
function R.drawGround()
    local g=love.graphics
    if Campaign.world==4 then
        for _,c in ipairs(R.current) do
            g.setColor(.2,.75,.85,.18)
            for i=1,12 do local y=c.y-170+i*28; local x=c.x+math.sin(R.clock*2+i)*15
                g.line(x-10*c.dx,y-3,x,y,x-10*c.dx,y+3)
            end
        end
        for i=1,25 do local x=(i*97)%Arena.width; local y=(i*59-R.clock*15)%600
            g.setColor(.55,.9,1,.22); g.circle('line',x,y,2+i%3)
        end
    elseif Campaign.world==6 then
        for _,c in ipairs(R.clouds) do
            g.setColor(.83,.91,.98,.8)
            g.rectangle('fill',c.x-c.rx,c.y-10,c.rx*2,28,10)
            g.circle('fill',c.x-15,c.y-7,21); g.circle('fill',c.x+13,c.y-12,25)
        end
        for _,p in ipairs(R.rain) do
            g.setColor(.22,.72,1,p.age<.85 and .45 or 1)
            g.circle('line',p.x,p.y,24); g.circle('line',p.x,p.y,math.max(2,24*(1-p.age/.85)))
            if p.age>=.65 and p.age<1.08 then g.setLineWidth(3); g.line(p.x-8,p.y-90*(1-math.min(1,(p.age-.65)/.2)),p.x,p.y); g.setLineWidth(1) end
        end
    end
    -- Pulse warnings and digging tracks stay below all creatures.
    for _,m in ipairs(mobs) do
        if m.type=='jelly' then
            local t=m.age%3.5; if t>2.3 then g.setColor(.25,.95,1,t>3 and .6 or .25); g.circle(t>3 and 'fill' or 'line',m.x,m.y,m.elite and 72 or 48) end
        elseif m.type=='mole' and m.age%5<2.5 then
            g.setColor(.5,.32,.15,.75); g.ellipse('fill',m.x,m.y,22,12)
            if m.age%5>1.7 then g.setColor(1,.68,.25); g.circle('line',m.x,m.y,25) end
        elseif m.type=='worm' and m.age%4<1.2 then
            g.setColor(.12,.065,.035,.85); g.ellipse('fill',m.x,m.y,25,8)
        end
    end
    g.setColor(1,1,1)
end
function R.drawWall(r)
    local g=love.graphics; local w=Campaign.world
    local c=w==4 and {.12,.42,.44} or w==5 and {.36,.22,.10} or {.75,.83,.89}
    g.setColor(c); g.rectangle('fill',r.x,r.y,r.w,r.h)
    g.setColor(c[1]*.6,c[2]*.6,c[3]*.6); g.rectangle('line',r.x+1,r.y+1,r.w-2,r.h-2)
    g.setColor(1,1,1,.16); g.line(r.x+2,r.y+2,r.x+r.w-2,r.y+2)
    g.setColor(1,1,1)
end
local function trap(m)
    for _,t in ipairs(mobs) do if t.type=='piege' and not t.active and isTouching(m,t) then
        freeze(m,2); t.active=true
        if m.has_larme and not objet.larme_dropped then objet.larme_dropped=true; objet.larme.x=m.x-15; objet.larme.y=m.y+35 end
    end end
end
local function update(m,dt)
    trap(m); if m.is_frozen then return end
    m.age=m.age+dt; local vx,vy=m.vx,m.vy; local speed=m.speed
    local dangerous=true
    if m.type=='fish' then if m.age%3>2 then speed=speed*2.4 end
    elseif m.type=='jelly' then
        vx,vy=math.cos(m.age*.7+m.x*.001),math.sin(m.age*.8); speed=speed*.65
        if m.age%3.5>3 and (player.x+15-m.x)^2+(player.y+12-m.y)^2<(m.elite and 72 or 48)^2 then Hazards.kill() end
    elseif m.type=='worm' then dangerous=m.age%4>=1.2; if not dangerous then speed=speed*1.3 end
    elseif m.type=='mole' then
        local t=m.age%5; dangerous=t>=2.5
        if t<.05 or not m.targetX then m.targetX=player.x+15; m.targetY=player.y+12 end
        if t<1.7 then
            local a=math.atan2(m.targetY-m.y,m.targetX-m.x); vx,vy=math.cos(a),math.sin(a); speed=140
        elseif t<2.5 then speed=0
        else local a=math.atan2(player.y+12-m.y,player.x+15-m.x); vx,vy=math.cos(a),math.sin(a) end
    elseif m.type=='gull' then vx,vy=math.cos(m.age*.6+m.phase),math.sin(m.age*.6+m.phase)*.7 end
    if m.has_larme and not objet.larme_dropped then
        local a=math.atan2(player.y+12-m.y,player.x+15-m.x)
        vx,vy=math.cos(a),math.sin(a); speed=math.min(speed,95)
    end
    m.dir=Art.direction(vx,vy,m.dir)
    local hx,hy=Arena.move(m,vx*speed*dt,vy*speed*dt)
    if hx then m.vx=-m.vx; m.phase=m.phase+math.pi end
    if hy then m.vy=-m.vy; m.phase=-m.phase+1 end
    if dangerous and isTouching(player,m) then Hazards.kill() end
end
local function draw(m)
    local hidden=(m.type=='mole' and m.age%5<2.5) or (m.type=='worm' and m.age%4<1.2)
    if hidden then return end
    love.graphics.setColor(m.is_frozen and {.55,.75,1} or {1,1,1})
    Art.drawFacing(m.type,m.dir,m.x,m.y,m.elite and 95 or m.type=='gull' and 75 or 62)
    love.graphics.setColor(1,1,1)
end
for _,kind in ipairs({'fish','jelly','worm','mole','gull'}) do MobBehaviors[kind]={update=update,draw=draw} end
return R
