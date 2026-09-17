local T={}
local function level(w,n)
    App.state='playing'; Campaign.select(w); player.level=n; reset_level()
end
local function find(kind)
    for _,m in ipairs(mobs) do if m.type==kind then return m end end
    error('Missing '..kind)
end
function T.run()
    level(4,1)
    local fish=find('fish'); local school=fish.school
    assert(#school.members==3,'Banc de trois poissons')
    player.x=60; player.y=500; school.age=1
    local x,y=fish.x,fish.y; MobBehaviors.fish.update(fish,.05)
    local slow=math.sqrt((fish.x-x)^2+(fish.y-y)^2)
    school.age=2.29; player.x=fish.x+100; player.y=fish.y+40
    Realms.update(.02); local angle=school.angle
    assert(school.age%3>=2.3)
    player.x=60; player.y=500; Realms.update(.01); assert(school.angle==angle,'Dash verrouillé au départ')
    x,y=fish.x,fish.y; MobBehaviors.fish.update(fish,.05)
    assert(math.sqrt((fish.x-x)^2+(fish.y-y)^2)>slow*8,'Déplacement surtout par dash')
    local jelly=find('jelly'); jelly.age=2.99; MobBehaviors.jelly.update(jelly,.02)
    assert(#Realms.bolts==12,'Décharge dans douze directions')
    local quadrants={}
    for _,p in ipairs(Realms.bolts) do quadrants[(p.vx>0 and 'r' or 'l')..(p.vy>0 and 'd' or 'u')]=true end
    local count=0; for _ in pairs(quadrants) do count=count+1 end; assert(count==4)
    Realms.bolts={{x=player.x+15,y=player.y+12,vx=1,vy=0,life=1,seed=0}}
    Realms.updateProjectiles(.01); assert(player.reset,'Fil électrique mortel')
    level(5,2)
    local worm=find('worm'); worm.age=1.19; MobBehaviors.worm.update(worm,.02)
    assert(#Realms.eggs==3,'Œufs crachés à l’émergence')
    player.x=Arena.width/2; player.y=500
    Realms.eggs={{x=28,y=90,vx=-185,vy=0,life=5}}
    Realms.updateProjectiles(.05); assert(#Realms.eggs==0 and #Realms.larvae==3,'Éclosion au mur')
    local larva=Realms.larvae[1]
    local before=(larva.x-player.x)^2+(larva.y-player.y)^2
    Realms.updateProjectiles(.1)
    assert((larva.x-player.x)^2+(larva.y-player.y)^2<before,'Petits vers poursuivent')
    reset_level(); assert(#Realms.larvae==0 and #Realms.eggs==0 and #Realms.bolts==0)
    level(1,10); player.x=Arena.width/2-15; player.y=510; Raven.shot=100
    assert(#Raven.eggs==1,'Un seul œuf')
    local egg=Raven.eggs[1]; local ex,ey,spot=egg.x,egg.y,egg.spot
    assert((ex-Raven.x)^2+(ey-Raven.y)^2>200^2,'Nid éloigné du boss')
    Raven.projectiles={{x=ex,y=ey,vx=0,vy=0,life=1}}; Raven.update(.01)
    assert(Raven.hp==11 and #Raven.eggs==1 and #Raven.chicks==1 and Raven.eggs[1].spot~=spot)
    local chick=Raven.chicks[1]; Raven.update(.1)
    assert(chick.cx==ex and chick.cy==ey and math.abs(chick.x-ex)<=48 and math.abs(chick.y-ey)<=36,'Petit merle autour du nid natal')
    for _=1,11 do local e=Raven.eggs[1]
        Raven.projectiles={{x=e.x,y=e.y,vx=0,vy=0,life=1}}; Raven.update(.001)
    end
    assert(Raven.defeated and #Raven.eggs==0 and #Raven.chicks==0 and Campaign.canCollect())
    level(1,10)
    local target=Raven.eggs[1]
    player.x=target.x-15+(target.x-Raven.x)*.12; player.y=target.y-12+(target.y-Raven.y)*.12
    Raven.fire(); Raven.shot=100
    for _=1,200 do Raven.update(.01); if Raven.hp<12 then break end end
    assert(Raven.hp==11,'Un tir réel atteint l’œuf malgré la division au nid')
    for n=1,10 do
        level(6,n)
        assert(#Realms.clouds==0 and (n==10 and #Realms.holes==0 and #Realms.rainSites==0 or n<10 and #Realms.holes>0 and #Realms.rainSites==24))
        assert(not Realms.fallAt(player.x+15,player.y+12),'Départ sur les nuages')
        for _,p in ipairs(levels[n].larme_position) do assert(not Realms.fallAt(p.x+15,p.y+20),'Larme hors du vide') end
        -- Reachability includes holes, not only physical walls.
        local queue={{player.x,player.y}}; local visited={}; local head=1
        local function key(x,y) return math.floor(x/8)..':'..math.floor(y/8) end
        visited[key(player.x,player.y)]=true
        while head<=#queue do local p=queue[head]; head=head+1
            for _,d in ipairs({{8,0},{-8,0},{0,8},{0,-8}}) do local x,y=p[1]+d[1],p[2]+d[2]; local k=key(x,y)
                if not visited[k] and not Realms.fallAt(x+15,y+12) and not Arena.blocked(x,y,30,24) then visited[k]=true; queue[#queue+1]={x,y} end
            end
        end
        for _,t in ipairs(levels[n].larme_position) do local reached=false
            for _,p in ipairs(queue) do if checkCollision(p[1],p[2],30,24,t.x,t.y,30,40) then reached=true; break end end
            assert(reached,'Chemin sans chute, Ciel '..n)
        end
    end
    level(6,5); Realms.rainClock=0; player.x=100; player.y=300; Realms.update(.01)
    local positions={}; for _,p in ipairs(Realms.rain) do positions[#positions+1]=p.x..':'..p.y end
    level(6,5); Realms.rainClock=0; player.x=700; player.y=400; Realms.update(.01)
    assert(#Realms.rain==8,'Averse dense')
    for i,p in ipairs(Realms.rain) do assert(positions[i]==p.x..':'..p.y,'Pluie indépendante du joueur') end
    local h=Realms.holes[1]; player.x=h.x-15; player.y=h.y-12; local deaths=player.death
    love.update(.01); assert(player.falling and player.death==deaths+1,'Chute dans un trou')
    love.update(.33); assert(not player.falling and not player.reset,'Retour au niveau après animation')
    player.x=23; player.y=300; Hazards.contact(); assert(player.falling,'Rebord mortel')
    local bosses=Bestiary.list('boss'); assert(#bosses==6)
    for _,row in ipairs(Bestiary.list('creatures')) do assert(not row.entry.boss and row.entry.id~='cloud') end
    Bestiary.seen.wasp=nil; Bestiary.discover('wasp'); Bestiary.open(); assert(UI.bestCategory=='boss'); love.draw()
    for _,dir in ipairs({'up','down','left','right'}) do
        local d=Art.imageData('assets/sprites/directional/waspling_'..dir..'.png')
        local _,_,_,a=d:getPixel(0,0); assert(a==0,'Transparence petite guêpe '..dir); d:release()
    end
    print('PASS rencontres : bancs/dash, éclairs, œufs/vers, nids/petits merles, Ciel et catégories boss')
end
return T
