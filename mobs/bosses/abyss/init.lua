local Cycle=require 'mobs.bosses.abyss.pattern_cycle'
local BoneCage=require 'bone_cage'
local A={threads={},bones={},clock=0,active=false}
local function add(kind,x,y,speed)
    local offset=0
    if kind=='light_jelly' then for _,m in ipairs(mobs) do if m.type==kind then offset=offset+1.5 end end end
    mobs[#mobs+1]={type=kind,x=x,y=y,speed=speed,age=0,shotOffset=offset,dir='right',heading=love.math.random()*math.pi*2,turn=0,
        hitBox_width=32,hitBox_height=26,hitBox_offset_x=-16,hitBox_offset_y=-13}
end
A.add=add
function A.spawn(n,withoutOctopuses)
    if not withoutOctopuses then
        add('light_jelly',Arena.width*.7,160,40)
        if n>=4 then add('light_jelly',Arena.width*.3,430,38) end
        if n>=8 then add('light_jelly',Arena.width*.5,110,42) end
    end
    add('lanternfish',Arena.width*.22,220,55); add('lanternfish',Arena.width*.75,410,55)
    for i=1,2+math.floor(n/4) do add('abyss_fish',Arena.width*(.15+(i-1)*.2),i%2==0 and 420 or 140,70) end
end
function A.reset(w,n)
    A.swimHead=nil;A.chain=nil;A.waves={};A.lightTrail={};A.lumenParticles={};A.debris={};A.vacuumCargo={}
    A.active=w==7; A.clock=0; A.threads={}; A.bones={}; A.open=false; A.head=nil; A.swallowed=nil; A.cargo={}; A.ejected={}; A.spitFlash=0; A.breathAt=5.5; A.motionTime=0; A.spinTime=0; A.spinAngle=0
    A.tailTouch=false; A.tailSafe=false; A.headOnly=false; A.skeletonStage=n; A.giant=A.active and n>=8; A.boss=A.active and n==10; A.origin={x=Arena.width/2,y=280}; player.illuminated=0; player.electrified=0; player.charges=0; player.abyssHeld=nil; player.abyssKnock=nil; player.abyssSpit=nil; player.abyssGrace=0
    A.hp=10; A.maxHp=10; A.defeated=false; A.flash=0; A.hitGrace=0; A.lightLock=false; A.name="Le Léviathan des Abysses"
    A.lightSites={{x=Arena.width*.12,y=105},{x=Arena.width*.88,y=495},{x=Arena.width*.12,y=495},{x=Arena.width*.88,y=105}}
    A.laserHeadY=nil;A.eyeFrom=nil;A.eyeBlend=1;A.phase=nil;A.phaseTime=0;A.plankton={};A.nextShot=1.1;A.volley=0;A.lightMotes={};A.pressure=nil;A.nextPressure=1.35;A.pressureCount=0;A.recoil=0;A.mines={};A.mineSerial=0;A.nextMine=0
    if A.boss then A.setupEncounter() end
    if A.boss then objet.larme.taken=true end
    if not A.giant then return end
    A.buildBones()
    player.x=Arena.width*.5-15; player.y=515
    Bestiary.discover('skeleton_fish'); Bestiary.save()
end
function A.setupEncounter() Cycle.setup(A) end
function A.eyeColor()
    if A.boss and A.phase=='fire' then return {1,1,1} end
    local colors={fire={.3,.85,1},recover={1,.8,.25},gap={.2,.5,.7},head={.3,.65,1},inhaleTell={1,.45,.2},spit={.7,.35,1},lightning={.8,.3,.65},circle={.65,.25,.8},zigzag={1,.35,.45},suction={1,.35,.15},rest={.6,.85,1},closed={.2,.55,.75},tell={1,.75,.25},open={.45,1,.8},recoil={1,1,1}}
    local source=A.boss and (colors[A.phase] or colors.closed) or {.2,.8,1}
    if A.boss and A.phase=='open' and A.duration-A.phaseTime<.6 then source={1,.12,.06} end
    local target={source[1],source[2],source[3]}
    if A.boss and A.eyeFrom and (A.eyeBlend or 1)<1 then
        local t=A.eyeBlend;t=t*t*(3-2*t)
        for i=1,3 do target[i]=A.eyeFrom[i]+(target[i]-A.eyeFrom[i])*t end
    end
    return target
end
function A.encounterActive()
    if A.active and A.boss and not A.defeated then return true end
    if Bosses then for _,item in ipairs(Bosses.items) do
        if item.kind=='skeleton_fish' and item.boss.boss and not item.boss.defeated then return true end
    end end
    return false
end
-- Reserve the full left column occupied by the giant head, including its tips.
function A.playerMinX(y)
 local x=23
 if A.active and A.boss then x=math.max(x,Cycle.playerMinX(A,y)) end
 if Bosses then for _,item in ipairs(Bosses.items) do
  if item.kind=='skeleton_fish' and item.boss.boss then x=math.max(x,Cycle.playerMinX(item.boss,y)) end
 end end
 return x
end
function A.blockedPlayer(x,y)
 if A.active and A.boss and Cycle.blockedPlayer(A,x,y) then return true end
 if Bosses then for _,item in ipairs(Bosses.items) do
  if item.kind=='skeleton_fish' and item.boss.boss and Cycle.blockedPlayer(item.boss,x,y) then return true end
 end end
 return false
end
function A.cagePlayer()
 local locked=false
 if A.active and A.boss then locked=Cycle.lockPlayer(A) end
 if Bosses then for _,item in ipairs(Bosses.items) do if item.kind=='skeleton_fish' and item.boss.boss then locked=Cycle.lockPlayer(item.boss) or locked end end end
 return locked
end
function A.attackSpeed() return (A.hp<=A.maxHp*.5 and 1.35 or 1)*(A.attackRate or 1) end
function A.fireBlue()
    if not A.head or A.open or A.defeated then return end
    local x,y=A.mouth();local aim=math.atan2(player.y+12-y,player.x+15-x)
    A.volley=A.volley+1
    local spread=A.volley%2==0 and .46 or .22
    for _,offset in ipairs({-spread,0,spread}) do
        local a=aim+offset
        A.threads[#A.threads+1]={x=x,y=y,vx=math.cos(a)*190,vy=math.sin(a)*190,life=5,age=0,seed=A.volley+offset,tooth=A.boss}
    end

end
function A.buildBones()
    A.bones={}
    local function bone(key,x,y,w,h,angle)
        local spot=Art.images[key].glow or {u=.5,v=.5}; local a=angle or 0
        local dx,dy=(spot.u-.5)*w,(spot.v-.5)*h
        A.bones[#A.bones+1]={key=key,x=x,y=y,w=w,h=h,angle=a,gx=x+math.cos(a)*dx-math.sin(a)*dy,gy=y+math.sin(a)*dx+math.cos(a)*dy}
    end
    if A.boss then
        Cycle.build(A);return
    end
    if A.headOnly then
        A.head={x=A.origin.x,y=A.origin.y+math.sin(A.motionTime*1.7)*7,w=170,h=150}
        bone(A.open and 'skeleton_open' or 'skeleton_head',A.head.x,A.head.y,A.head.w,A.head.h)
        return
    end
    local span=Arena.width*.48; local count=math.max(3,math.floor(span/205)+1)
    local shift=A.origin.x-Arena.width/2
    local swim=A.origin.y-280
    for i=1,(A.skeletonStage>=9 and count or 0) do
        local x=Arena.width*.2+(i-1)*span/(count-1)+shift; local y=280+swim+math.sin(A.motionTime*1.3+i*.8)*(1-i/(count+1))*16
        local h=95+18*math.sin(i/count*math.pi)
        bone('skeleton_spine',x,y,22,28,A.spinAngle or 0)
        bone('skeleton_rib',x,y-h/2-20,18,h,-.12+(A.spinAngle or 0))
        bone('skeleton_rib',x,y+h/2+20,18,h,math.pi+.12-(A.spinAngle or 0))
    end
    bone('skeleton_tail',Arena.width*.095+shift,280+swim+math.sin(A.motionTime*1.3)*12,100,145)
    A.head=nil
    if A.skeletonStage<10 then return end
    -- The skull is anchored to the same skeleton origin; only the body undulates.
    A.head={x=math.max(115,math.min(Arena.width-145,Arena.width*.79+shift)),
        y=math.max(125,math.min(455,280+swim+math.sin(A.motionTime*1.7)*7)),w=170,h=150}
    bone(A.open and 'skeleton_open' or 'skeleton_head',A.head.x,A.head.y,A.head.w,A.head.h)
end
function A.boneTouches(b,x,y)
    local a=Art.images[b.key]; if not a or not a.mask then return false end
    local dx,dy=x-b.x,y-b.y; local c,s=math.cos(b.angle),math.sin(b.angle)
    local u=(c*dx+s*dy)/b.w+.5; local v=(-s*dx+c*dy)/b.h+.5
    if b.flip then u=1-u end
    if u<0 or u>=1 or v<0 or v>=1 then return false end
    return a.mask[math.floor(v*192)*192+math.floor(u*192)] or false
end
function A.mouth()
    if A.boss then return Cycle.mouth(A) end
    return A.head.x+65,A.head.y+15
end
local function onSites(boss)
    if not boss.active or boss.defeated then return false end
    local special=#boss.lightSites>0 and (boss.boss or Realms.custom)
    local sites=special and boss.lightSites or (levels[player.level] and levels[player.level].larme_position or {})
    for i,p in ipairs(sites) do
        local x,y=special and p.x or p.x+15,special and p.y or p.y+39
        if not p.cage and (not boss.boss or boss.lightParity==nil or i%2==boss.lightParity) and (player.x+15-x)^2+(player.y+12-y)^2<24^2 then return true end
    end
    return false
end
function A.playerHidden()
 local function hidden(b) return b.active and b.boss and not b.defeated and b.lightOnlySuction and b.phase=='suction' end
 if hidden(A) then return true end
 if Bosses then for _,item in ipairs(Bosses.items) do if item.kind=='skeleton_fish' and hidden(item.boss) then return true end end end
 return false
end
function A.refreshLight()
    if A.playerHidden() or player.abyssSpit or player.abyssHeld then player.circleLight=false;player.illuminated=0;return end
    local onSite=not player.abyssHeld and onSites(A)
    if Bosses then for _,item in ipairs(Bosses.items) do if not player.abyssHeld and item.kind=='skeleton_fish' and onSites(item.boss) then onSite=true end end end
    player.circleLight=onSite
    player.illuminated=math.max(onSite and 6 or 0,player.electrified or 0)
end
function A.charge(seconds)
    player.charges=math.min(A.encounterActive() and 3 or 5,(player.charges or 0)+1)
    player.electrified=math.max(player.electrified or 0,seconds or 6); A.refreshLight()
end
function A.isPulling()
    local function pulling(b) return b.active and b.giant and (not b.boss or not b.lightOnlySuction) and b.open and (not b.phase or b.phase=='suction') and not b.defeated end
    if pulling(A) then return true end
    if Bosses then for _,item in ipairs(Bosses.items) do
        if item.kind=='skeleton_fish' and pulling(item.boss) then return true end
    end end
    return false
end
function A.inSuctionShelter(x,y)
    local function protected(b) return b.active and b.boss and not b.defeated and b.phase=='suction' and Cycle.sheltered(b,x,y) end
    if protected(A) then return true end
    if Bosses then for _,item in ipairs(Bosses.items) do if item.kind=='skeleton_fish' and protected(item.boss) then return true end end end
    return false
end
function A.overlapsBone(b)
    local radius=math.sqrt(b.w*b.w+b.h*b.h)/2+30
    if (player.x+15-b.x)^2+(player.y+12-b.y)^2>=radius^2 then return false end
    for y=player.y+2,player.y+22,4 do for x=player.x+2,player.x+28,4 do
        if A.boneTouches(b,x,y) then return true end
    end end
    return false
end
function A.triggerTail(owner,b)
    local touching=A.overlapsBone(b)
    if not touching then owner.tailTouch=false;owner.tailSafe=false;return false end
    if not owner.boss and not owner.tailTouch and (player.charges or 0)>0 then
        local target,distance
        local function consider(boss)
            if boss.active and boss.boss and boss.head and not boss.defeated then
                local d=(b.x-boss.head.x)^2+(b.y-boss.head.y)^2
                if not distance or d<distance then target,distance=boss,d end
            end
        end
        consider(A)
        if Bosses then for _,item in ipairs(Bosses.items) do if item.kind=='skeleton_fish' then consider(item.boss) end end end
        if target then
            player.charges=player.charges-1
            if player.charges==0 then player.electrified=0 end
            target.open=true;target.breathAt=target.clock;target.buildBones();owner.tailSafe=true;A.refreshLight()
        end
    end
    owner.tailTouch=true
    return owner.tailSafe
end
function A.contact()
    if not A.giant or A.defeated or player.reset or player.abyssHeld or (player.abyssGrace or 0)>0 then return end
    if A.boss then Cycle.contact(A);return end
    for _,bone in ipairs(A.bones) do if bone.key=='skeleton_tail' and A.triggerTail(A,bone) then return end end
    local mouthX,mouthY=0,0
    if A.head then mouthX,mouthY=A.mouth() end
    local inMouth=A.open and (player.x+15-mouthX)^2+(player.y+12-mouthY)^2<34^2
    for _,b in ipairs(A.bones) do
        -- The open mouth has an accessible throat; the skull and teeth remain solid.
        local throat=A.boss and A.open and b==A.bones[#A.bones] and player.x+15>A.head.x+24 and math.abs(player.y+12-mouthY)<85
        if not throat and math.abs(player.x+15-b.x)<math.sqrt(b.w*b.w+b.h*b.h)/2+40 and math.abs(player.y+12-b.y)<math.sqrt(b.w*b.w+b.h*b.h)/2+40 then
            for y=player.y+2,player.y+22,4 do for x=player.x+2,player.x+28,4 do
                if A.boneTouches(b,x,y) then Hazards.kill('bone'); return end
            end end
        end
    end
end
function A.hurt(amount,quiet)
    A.hp=math.max(0,A.hp-(amount or 1)); A.flash=quiet and .08 or .35;if not quiet then Audio.play('pick') end
    if A.hp==0 then
        if A.swallowed then A.spit() end
        A.defeated=true; A.giant=false; A.open=false; A.bones={}; A.threads={}; A.plankton={};A.pressure=nil;A.lightMotes={};A.mines={};A.beam=nil;A.beams={}
        objet.larme.taken=false; objet.larme.x=Arena.width/2-15; objet.larme.y=280
    end
end
function A.emit(m)
    local aim=math.atan2(player.y+12-m.y,player.x+15-m.x)
    for _,offset in ipairs({-.48,0,.48}) do local a=aim+offset
        A.threads[#A.threads+1]={x=m.x,y=m.y,vx=math.cos(a)*165,vy=math.sin(a)*165,life=4,age=0,seed=m.age+offset}
    end
end
function A.pullEntity(m,dt,body)
    if m.abyssHeld or (m==player and player.abyssSpit) then return end
    if A.boss and Cycle.sheltered(A,m.x+(m==player and 15 or 0),m.y+(m==player and 12 or 0)) then return end
    local tx,ty=A.mouth()
    local dx,dy=tx-(m.x+(body==player and 15 or 0)),ty-(m.y+(body==player and 12 or 0))
    local d=math.max(.001,math.sqrt(dx*dx+dy*dy))
    local speed=A.boss and (180+d*.18+math.min(1,(A.phaseTime or 0)/2.8)*140) or (360+d*.7+math.max(0,A.clock-A.breathAt-2)*220)
    if A.boss and m==player then speed=speed*(A.pullStrength or 1)*.9 end
    local step=math.min(d,speed*dt)
    -- Suction lifts creatures above terrain instead of trapping them against walls.
    m.x=m.x+dx/d*step; m.y=m.y+dy/d*step
    if m==player then A.contact() end
    if m~=player and not m.abyssHeld then
        local distance=(m.x-tx)^2+(m.y-ty)^2
        if distance<30^2 then
            m.abyssHeld=A; A.cargo[#A.cargo+1]={entity=m,body=body,dx=dx,dy=dy}
        end
    end
end
function A.safeExit()
    local mx,my=A.mouth(); local choices,bx,by=0,Arena.width-80,510
    -- Choose a safe landing across the arena, rather than directly in front of the mouth.
    for y=85,535,18 do for x=55,Arena.width-55,18 do
        local d=(x-mx)^2+(y-my)^2
        if d>=150^2 and not Arena.blocked(x-17,y-14,34,28) then
            local safe=true
            for _,b in ipairs(A.bones) do if math.abs(x-b.x)<b.w/2+36 and math.abs(y-b.y)<b.h/2+32 then safe=false; break end end
            for _,p in ipairs(A.lightSites) do if (x-p.x)^2+(y-p.y)^2<45^2 then safe=false;break end end
            for _,m in ipairs(mobs) do if not m.abyssHeld and (x-m.x)^2+(y-m.y)^2<75^2 then safe=false; break end end
            for _,p in ipairs(Magma and Magma.pools or {}) do if Hazards.inEllipse(x,y,p,25) then safe=false; break end end
            if safe then choices=choices+1; if love.math.random(choices)==1 then bx,by=x,y end end
        end
    end end
    return bx,by
end
function A.spit()
    local mx,my=A.mouth(); local targetX,targetY
    local captured=A.swallowed~=nil
    local charged=captured and A.swallowed.charged
    if captured then targetX,targetY=A.safeExit(); player.abyssHeld=nil; player.abyssGrace=1.25 end
    for i,c in ipairs(A.cargo) do
        local m=c.entity; m.abyssHeld=nil
        -- Stratified full-arena scatter, including the far side of the skeleton.
        local u=love.math.random()
        local v=love.math.random()
        local x,y=55+u*(Arena.width-110),85+v*450
        if captured and (x-targetX)^2+(y-targetY)^2<90^2 then y=85+(y+180-85)%450 end
        local angle=math.atan2(y-my,x-mx)
        if c.body then local xx,yy=Arena.clearSpot(x-16,y-13,32,26); x,y=xx+16,yy+13 end
        m.x=x; m.y=y
        if m.life then m.life=math.max(m.life,1.5) end
        if m.vx then local speed=math.sqrt(m.vx*m.vx+(m.vy or 0)^2); m.vx=math.cos(angle)*speed; m.vy=math.sin(angle)*speed end
        A.ejected[#A.ejected+1]={x=mx,y=my,tx=x,ty=y,age=0}
    end
    A.cargo={}; A.swallowed=nil; A.open=false; A.breathAt=A.clock+5.5; A.spitFlash=.55; A.spinTime=3.2; A.spinAngle=0
    if captured then
        player.electrified=0;player.charges=0;player.illuminated=0;player.circleLight=false
        player.abyssSpit={fromX=mx-15,fromY=my-12,toX=targetX-15,toY=targetY-12,time=0}
        -- Light damage is applied on capture, before the safe ejection.
    end
end
function A.update(dt)
    if not A.active then return end
    if A.boss then Cycle.update(A,dt);return end
    A.motionTime=A.motionTime+dt*(A.movementRate or 1)
    A.spinTime=math.max(0,(A.spinTime or 0)-dt)
    local spin=1-A.spinTime/3.2
    A.spinAngle=A.spinTime>0 and (spin*spin*(3-2*spin)*math.pi*2) or 0
    A.clock=A.clock+dt*(A.attackRate or 1); A.flash=math.max(0,A.flash-dt); A.spitFlash=math.max(0,A.spitFlash-dt)
    A.hitGrace=math.max(0,A.hitGrace-dt)
    if not A.instance and not A.encounterActive() then
        player.electrified=math.max(0,(player.electrified or 0)-dt)
        if player.electrified==0 then player.charges=0 end
    end
    A.refreshLight()
    for i=#A.threads,1,-1 do local p=A.threads[i]
        if not p.abyssHeld then
            p.age=p.age+dt; p.life=p.life-dt; local dead=p.life<=0
            local steps=math.max(1,math.ceil(math.sqrt(p.vx*p.vx+p.vy*p.vy)*dt/5))
            for _=1,steps do
                p.x=p.x+p.vx*dt/steps; p.y=p.y+p.vy*dt/steps
                if not player.abyssHeld and (player.x+15-p.x)^2+(player.y+12-p.y)^2<23^2 then
                    if p.tooth then Hazards.kill('abyss_tooth') else A.charge(6) end
                    dead=true
                end
                if Arena.blocked(p.x-2,p.y-2,4,4) then dead=true end
                if dead then break end
            end
            if dead then table.remove(A.threads,i) end
        end
    end
    for i=#A.ejected,1,-1 do local p=A.ejected[i]; p.age=p.age+dt; if p.age>.4 then table.remove(A.ejected,i) end end
    if A.giant and not A.boss then A.open=false; A.buildBones(); A.contact(); A.refreshLight(); return end
    A.refreshLight()
end
function A.drawLightMask()
    if A.boss then Cycle.drawMask(A) end
end
function A.resize(ratio)
    A.origin.x=A.origin.x*ratio
    if A.swimHead then
        A.swimHead.x=A.swimHead.x*ratio
        for _,p in ipairs(A.chain or {}) do p.x=p.x*ratio end
    end
    for _,list in ipairs({A.threads,A.plankton,A.lightSites,A.lightMotes,A.ejected,A.waves or {},A.lightTrail or {},A.lumenParticles or {},A.debris or {},A.octopuses or {}}) do
        for _,p in ipairs(list or {}) do
            p.x=p.x*ratio;if p.tx then p.tx=p.tx*ratio end;if p.homeX then p.homeX=p.homeX*ratio end;if p.vx then p.vx=p.vx*ratio end
        end
    end
    if A.aim then A.aim.x=A.aim.x*ratio end
    if A.lastLightX then A.lastLightX=A.lastLightX*ratio end
    for _,c in ipairs(A.vacuumCargo or {}) do if c.kind=='trail' or c.kind=='mote' or c.kind=='bolt' then c.item.x=c.item.x*ratio end end
    if A.giant then A.buildBones() end
end
function A.updatePlayer(dt)
    if A.encounterActive() and (player.charges or 0)>0 then
        player.electrified=math.max(1,player.electrified or 0)
    end
    local knock=player.abyssKnock
    if knock then
        local step=math.min(dt,knock.time);knock.time=knock.time-dt
        Arena.move(player,knock.vx*step,knock.vy*step)
        if knock.time<=0 then player.abyssKnock=nil end
    end
    player.abyssGrace=math.max(0,(player.abyssGrace or 0)-dt)
    local s=player.abyssSpit
    if s then
        s.time=s.time+dt; local t=math.min(1,s.time/.28); local eased=1-(1-t)^2
        player.x=s.fromX+(s.toX-s.fromX)*eased; player.y=s.fromY+(s.toY-s.fromY)*eased
        if t==1 then player.abyssSpit=nil;player.abyssGrace=math.max(player.abyssGrace or 0,.25) end
    end
end
function A.siteVisibility(x,y)
    local visibility=0
    local function light(lx,ly,r)
        local d=math.sqrt((x-lx)^2+(y-ly)^2)
        visibility=math.max(visibility,math.max(0,math.min(1,(r-d)/35)))
    end
    if (player.illuminated or 0)>0 and not player.abyssHeld then light(player.x+15,player.y+12,A.playerLightRadius()) end
    for _,m in ipairs(mobs) do if not m.abyssHeld and m.type=='lanternfish' then light(m.x,m.y-15,145) end end
    local function cages(boss)
        for _,p in ipairs(boss.lightSites or {}) do if p.cage and (p.light or 0)>0 then light(p.x,p.y,95+25*p.light) end end
    end
    cages(A)
    if Bosses then for _,item in ipairs(Bosses.items) do if item.kind=='skeleton_fish' then cages(item.boss) end end end
    return visibility
end
function A.drawSites()
    if A.boss then return end -- Encounter runes are drawn above the darkness.
    if (not A.boss and not (Realms.custom and #A.lightSites>0)) or A.defeated then return end
    local g=love.graphics
    for _,p in ipairs(A.lightSites) do
        if p.cage then BoneCage.draw(p,A.clock) else
        local alpha=A.siteVisibility(p.x,p.y)
        g.setColor(.3,.7,1,alpha); Art.drawTinted('tear_ring',p.x,p.y,44)
        g.setColor(.2,.5,1,.15*alpha); g.circle('fill',p.x,p.y,23)
        end
    end
    g.setColor(1,1,1)
end
function A.attractLight(p,dt)
    if p.abyssHeld or player.abyssHeld or player.abyssSpit or not A.encounterActive() or A.isPulling() then return end
    local dx,dy=player.x+15-p.x,player.y+12-p.y
    local distance=math.sqrt(dx*dx+dy*dy)
    if distance<=1 or distance>=80 then return end
    local step=math.min(distance,55*(1-distance/80)*dt)
    local x,y=p.x+dx/distance*step,p.y+dy/distance*step
    if not Arena.blocked(x-2,y-2,4,4) then p.x,p.y=x,y end
end
function A.playerBrightness()
    if A.playerHidden() then return 0 end
    local charge=math.max(0,player.charges or 0)
    return math.sqrt(charge/(charge+3))
end
function A.playerLightRadius()
    if A.playerHidden() then return 0 end
    if A.encounterActive() then return 38+380*A.playerBrightness() end
    return player.circleLight and 240 or 150+45*math.max(0,(player.charges or 0)-1)
end
function A.gazeDirection(b)
    local ox,oy=b.gx,b.gy
    local tx,ty=player.x+15,player.y+12
    if A.playerHidden() then tx,ty=Arena.width/2,300 end
    if A.aim then
        ox,oy=A.mouth();tx,ty=A.aim.x,A.aim.y
    end
    local dx,dy=tx-ox,ty-oy;local d=math.max(.001,math.sqrt(dx*dx+dy*dy))
    return dx/d,dy/d
end
function A.drawBossEye(b,overlay)
    local g=love.graphics;local ex,ey=b.gx,b.gy
    local dx,dy=A.gazeDirection(b)
    local aimed=A.phase=='open' or A.phase=='tell'
    local glow=overlay and (aimed and .45 or .18+.12*(A.energy or 0)) or 1
    local c=A.eyeColor()
    local px,py=ex+dx*14,ey+dy*14
    g.push('all');g.setBlendMode('alpha')
    -- Preserve the painted eye; only its iris/pupil follows the exact beam angle.
    g.setColor(.005,.025,.04,.3);g.circle('fill',ex,ey,16)
    g.setColor(c[1]*glow,c[2]*glow,c[3]*glow,.4);g.circle('fill',px,py,9)
    g.setColor(c[1]*glow,c[2]*glow,c[3]*glow,.95);g.ellipse('fill',px,py,6.5,7.5)
    g.setColor(.002,.015,.025,.95);g.ellipse('fill',px,py,2.2,5)
    g.setColor(.8*glow,.97*glow,glow,.95);g.circle('fill',px-1.5,py-2.5,1.7)
    g.pop()
end
function A.drawBones(overlay)
    if not A.giant or A.defeated then return end
    local g=love.graphics
    for _,b in ipairs(A.bones) do
        local previous=g.getShader()
        if A.boss and (b.key=='skeleton_head' or b.key=='skeleton_open') then
            local sprite=Art.images[b.key];local spot=sprite.glow or {u=.5,v=.5}
            local qx,qy,qw,qh=sprite.quad:getViewport();local iw,ih=sprite.image:getDimensions()
            A.eyeShader=A.eyeShader or g.newShader([[extern vec2 eyeCenter;extern vec2 eyeSize;extern vec3 eyeTint;
                vec4 effect(vec4 color,Image image,vec2 uv,vec2 px) {
                    vec4 t=Texel(image,uv);
                    float mask=1.0-smoothstep(.09,.17,length((uv-eyeCenter)/eyeSize));
                    float cyan=smoothstep(.03,.18,min(t.g-t.r,t.b-t.r));
                    float v=max(t.g,t.b);
                    t.rgb=mix(t.rgb,eyeTint*v,mask*cyan);
                    return t*color;
                }]])
            A.eyeShader:send('eyeCenter',{(qx+spot.u*qw)/iw,(qy+spot.v*qh)/ih})
            A.eyeShader:send('eyeTint',A.eyeColor())
            A.eyeShader:send('eyeSize',{qw/iw,qh/ih});g.setShader(A.eyeShader)
            local visibility=.22
            if overlay then
                local d=math.sqrt((player.x+15-b.x)^2+(player.y+12-b.y)^2)
                local charge=A.playerBrightness()
                visibility=.18+(A.open and .025 or 0)+.025*(A.energy or 0)+A.flash*.3
            end
            g.setColor(visibility,visibility,visibility)
        else g.setColor(1,1-A.flash,1-A.flash) end
        Art.draw(b.key,b.x,b.y,(b.flip and -b.w or b.w),b.angle,b.h);g.setShader(previous)
        if A.boss and (b.key=='skeleton_head' or b.key=='skeleton_open') then A.drawBossEye(b,overlay)
        elseif b.key=='skeleton_head' or b.key=='skeleton_open' then
            local ex,ey=b.gx,b.gy;local target=A.boss and A.aim;local dx,dy=(target and target.x or player.x+15)-ex,(target and target.y or player.y+12)-ey;local d=math.max(1,math.sqrt(dx*dx+dy*dy))
            local c=A.eyeColor()
            if overlay then local glow=A.phase=='aim' and 1 or .18+.7*(A.energy or 0);for i=1,3 do c[i]=c[i]*glow end end
            g.setColor(c[1]*.16,c[2]*.16,c[3]*.16,.9);g.circle('fill',ex,ey,A.boss and 14 or 5)
            g.setColor(c[1],c[2],c[3],.95);g.circle('fill',ex+dx/d*(A.boss and 9 or 2.5),ey+dy/d*(A.boss and 9 or 2.5),A.boss and 6 or 2.4)
            g.setColor(c[1],c[2],c[3]);g.circle('fill',ex+dx/d*(A.boss and 9 or 2.5),ey+dy/d*(A.boss and 9 or 2.5),1)
        end
    end
end
function A.addLights(lights)
    if A.boss and not A.defeated then
        for _,p in ipairs(A.plankton or {}) do if p.lethal and #lights<24 then lights[#lights+1]={p.x,p.y,135,.95} end end
    end
    if A.playerHidden() then return end
    if not A.giant then return end
    -- Ground motes glow by themselves without illuminating the whole arena.
    for i,p in ipairs(A.lightSites or {}) do if #lights<24 then lights[#lights+1]={p.x,p.y,110,A.boss and (i%2==A.lightParity and .7 or .12) or .55} end end
    for _,p in ipairs(A.octopuses or {}) do if not p.abyssHeld and #lights<24 then lights[#lights+1]={p.x,p.y,90,.6} end end
    for i=#A.bones,#A.bones-1,-1 do local b=A.bones[i]; if b then lights[#lights+1]={b.gx,b.gy,A.boss and (45+65*(A.energy or 0)) or 120,A.boss and (.04+.18*(A.energy or 0)) or .85} end end
    for i=1,#A.bones-2 do local b=A.bones[i]; if #lights<24 then lights[#lights+1]={b.gx,b.gy,80,.65} end end
end
function A.eyePosition(m)
    local a=Art.images.abyss_fish; local x,y=85*.3,-85*(a.h/a.w)*.09
    local angle=m.angle or 0
    return m.x+math.cos(angle)*x-math.sin(angle)*y,m.y+math.sin(angle)*x+math.cos(angle)*y
end
function A.drawLights()
    if not A.active then return end

    local g=love.graphics; g.push('all'); g.setBlendMode('add')
    for _,b in ipairs(A.bones) do if not A.boss then
        local c=A.eyeColor()
        g.setColor(c[1],c[2],c[3],.2);g.circle('fill',b.gx,b.gy,17)
        if A.boss and (A.phase=='warning' or A.phase=='suction') then
            local pulse=.5+.5*math.sin(A.clock*13)
            g.setColor(.08,.5,1,.08+pulse*.09);g.circle('fill',b.gx,b.gy,24+pulse*6)
            for i=1,12 do
                local t=(A.clock*1.3+i/12)%1;local angle=i*2.4+A.clock*1.7;local radius=17+(1-t)*27
                g.setColor(.12,.5+.2*t,1,.6*t);g.circle('fill',b.gx+math.cos(angle)*radius,b.gy+math.sin(angle)*radius,1.2+1.4*t)
            end
        end
        local ex,ey=b.gx,b.gy
        if b.key=='skeleton_head' or b.key=='skeleton_open' then local target=A.boss and A.aim;local dx,dy=(target and target.x or player.x+15)-ex,(target and target.y or player.y+12)-ey;local d=math.max(1,math.sqrt(dx*dx+dy*dy));ex,ey=ex+dx/d*(A.boss and 9 or 2.5),ey+dy/d*(A.boss and 9 or 2.5) end
        g.setColor(c[1],c[2],c[3],.8); g.circle('fill',ex,ey,1.8)
    end end
    for _,p in ipairs(A.threads) do if not p.abyssHeld then
        local a=math.atan2(p.vy,p.vx); g.push(); g.translate(p.x,p.y); g.rotate(a)
        if p.tooth then
            g.setColor(.75,.22,.55,.2);g.setLineWidth(5);g.line(-35,0,5,0)
            g.setBlendMode('alpha');g.setColor(.18,.07,.18);g.polygon('fill',-17,-5,12,0,-17,5,-11,0)
            g.setColor(.92,.78,.88);g.polygon('fill',-14,-3,12,0,-14,3,-8,0)
            g.setColor(1,.94,1);g.setLineWidth(1);g.line(-10,0,10,0);g.setBlendMode('add')
        else
        g.setColor(.2,.65,1,.3); g.setLineWidth(7)
        g.line(-32,math.sin(p.age*12+p.seed)*4,-20,-4,-10,3,0,0)
        g.setColor(.65,.95,1,1); g.setLineWidth(2); g.line(-32,math.sin(p.age*12+p.seed)*4,-20,-4,-10,3,0,0)
        end;g.pop()
    end end
    if (player.illuminated or 0)>0 and not player.abyssHeld then
        for _,m in ipairs(mobs) do if m.type=='abyss_fish' then
            local x,y=A.eyePosition(m)
            g.setColor(.3,.75,1,.14); g.circle('fill',x,y,4)
            g.setColor(.65,.9,1,.8); g.circle('fill',x,y,1.4)
        end end
        for r=4,1,-1 do local glow=A.playerBrightness();g.setColor(.15,.65,1,.022*glow);g.ellipse('fill',player.x+15,player.y+12,23+r*13+20*glow,18+r*10+16*glow) end
        local brightness=player.circleLight and .7 or A.playerBrightness()
        g.setColor(.35,.9,1,.38*brightness); g.ellipse('fill',player.x+15,player.y+12,35,27)
        g.setColor(.75,1,1,.95*brightness); g.setLineWidth(2); g.ellipse('line',player.x+15,player.y+12,31,24); g.setLineWidth(1)
        for i=1,8 do local a=i*math.pi/4+A.clock; g.setColor(.5,.9,1,.8*brightness)
            g.circle('fill',player.x+15+math.cos(a)*29,player.y+12+math.sin(a)*20,1.5)
        end
    end
    for _,p in ipairs(A.ejected) do
        local t=p.age/.4; g.setColor(.4,.8,1,(1-t)*.6)
        g.circle('fill',p.x+(p.tx-p.x)*t,p.y+(p.ty-p.y)*t,3)
    end
    if A.boss then
        Cycle.draw(A)
        -- Keep the charged silhouette readable above darkness; the jaws occlude the beam origin.
        g.setBlendMode('alpha');A.drawBones(true);Cycle.drawOverlay(A);g.setBlendMode('add')
    end
    if A.head then
        local mx,my=A.mouth()
        for _,p in ipairs(A.lightMotes or {}) do
            local t=math.min(1,p.age/.85);local ease=t*t
            local x=p.x+(mx-p.x)*ease;local y=p.y+(my-p.y)*ease+math.sin(t*math.pi)*p.bend
            g.setColor(.15,.55,1,.18*(1-t));g.circle('fill',x,y,8)
            g.setColor(.5,.9,1,.85*(1-t*.5));g.circle('fill',x,y,2.5)
            g.setColor(.8,.97,1,.55);g.line(x,y,x-(mx-p.x)*.025*t,y-(my-p.y)*.025*t)
        end
    end
    if not A.boss and A.giant and A.open and (not A.phase or A.phase=='suction') then
        for i=1,40 do
            local t=(A.clock*.7+i/40)%1; local a=i*2.4; local r=(1-t)*350
            local mx,my=A.mouth();local x=mx+math.cos(a)*r; local y=my+math.sin(a)*r*.6
            g.setColor(.35,.75,1,.25*t); g.line(x,y,x-math.cos(a)*14,y-math.sin(a)*9)
        end
    end
    g.pop()
end
MobBehaviors.abyss_fish=require('mobs.abyss_fish')(A)
MobBehaviors.light_jelly=require('mobs.light_jelly')(A)
MobBehaviors.lanternfish=require('mobs.lanternfish.abyss')(A)
return A
