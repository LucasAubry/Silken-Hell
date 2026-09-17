local T={}
local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
function T.run()
    local order={1,6,5,4,7,2,3}
    for i,id in ipairs(order) do assert(Worlds.order[i]==id and Worlds.rank(id)==i) end
    Profile.unlocked=1; assert(Worlds.canEnter(1) and not Worlds.canEnter(6))
    Profile.complete(1,40,0); assert(Profile.unlocked==2 and Worlds.canEnter(6) and not Worlds.canEnter(5))
    -- Migrate an existing pre-reorder profile without locking its old worlds.
    local saved=love.filesystem.read('profile.txt')
    love.filesystem.write('profile.txt','unlocked=2\nname=Migration'); Profile.load()
    assert(Worlds.canEnter(2) and Worlds.canEnter(6) and Profile.unlocked==6)
    love.filesystem.write('profile.txt',saved); Profile.load(); Profile.unlocked=6; Profile.scores={}
    level(1,1); mobs={}; local isDown=love.keyboard.isDown; local keys={}
    love.keyboard.isDown=function(key) return keys[key] or false end
    local y=player.y; keys[Profile.keys.dash]=true; App.move(.02)
    assert(player.y==y and not player.has_moved and not player.dashing,'Boost seul inactif')
    keys[Profile.keys.right]=true; keys[Profile.keys.up]=true; App.move(.02)
    keys[Profile.keys.right]=nil; keys[Profile.keys.up]=nil; local x=player.x; y=player.y; App.move(.02)
    assert(player.x==x and player.y==y and not player.dashing,'Arrêt du boost sans direction')
    keys={}; x,y=player.x,player.y; App.move(.02); assert(player.x==x and player.y==y)
    love.keyboard.isDown=isDown
    level(1,10); player.x=80; player.y=500; local fire=Raven.fire; local shots=0
    Raven.fire=function() shots=shots+1 end; Raven.hp=3
    for _=1,10 do Raven.shot=0; Raven.update(.001) end
    assert(shots==10 and Raven.shot<.24)
    Raven.update(Raven.shot+.001); assert(shots==11,'Tir continu après dix plumes'); Raven.fire=fire
    for _,n in ipairs({8,9}) do level(1,n)
        assert(#mobs>=7 and Campaign.carrier and not objet.larme_dropped and #levels[n].larme_position==8)
    end
    for _,w in ipairs({4,7}) do for n=1,10 do level(w,n)
        assert(Ocean.active and #Ocean.bubbles==0 and player.oxygen==nil)
        Ocean.update(120); assert(not player.reset,'Aucune mort par manque oxygène')
    end end
    App.state='pause'; local clock=Ocean.clock; love.update(1); assert(Ocean.clock==clock)
    level(4,10); assert(Octopus.active and not Campaign.canCollect()); player.x=70; player.y=500
    local cx,cy=Octopus.x,Octopus.y; local spin=Octopus.spin
    Octopus.update(.01); assert(Octopus.spin==spin and Octopus.x==cx and Octopus.y==cy)
    Octopus.inkPools={{x=player.x+15,y=player.y+12,rx=38,ry=27,life=6,seed=1}}; Octopus.update(.01)
    assert(#Octopus.blots==7 and not player.reset,'Encre obscurcit sans tuer')
    local hit=false; for yy=Octopus.y-200,Octopus.y+200,6 do for xx=Octopus.x-200,Octopus.x+200,6 do if not hit and (xx-Octopus.x)^2+(yy-Octopus.y)^2>100^2 and Octopus.touches(xx,yy) then player.x=xx-15; player.y=yy-12; hit=true end end end; assert(hit); Octopus.contact(); assert(Octopus.rider and not player.reset,'Tentacules accrochent le joueur')
    reset_level()
    player.x=70; player.y=500
    for _=1,8 do require('tests.octopus_revision').clearWave() end
    assert(Octopus.defeated and Campaign.canCollect()); love.draw()
    level(4,10); Octopus.splash(); local hp=Octopus.hp
    love.resize(1600,900); assert(player.oxygen==nil and Octopus.hp==hp and #Octopus.blots==7)
    love.resize(love.graphics.getDimensions())
    reset_level(); assert(#Octopus.blots==0 and player.oxygen==nil)
    assert(Realms.molePhase(1)=='hidden' and Realms.molePhase(1.9)=='warning' and Realms.molePhase(2.4)=='emerge' and Realms.molePhase(3)=='surface' and Realms.molePhase(4.6)=='dig')
    level(6,5); local p=Realms.holes[1]; local min,max=10,0
    for i=0,47 do local a=i*math.pi/24; local r=Realms.holeRadius(p,a); min=math.min(min,r); max=math.max(max,r)
        assert(Realms.fallAt(p.x+math.cos(a)*p.rx*(r-.1),p.y+math.sin(a)*p.ry*(r-.1)))
        assert(not Realms.fallAt(p.x+math.cos(a)*p.rx*(r+.15),p.y+math.sin(a)*p.ry*(r+.15)))
    end
    assert(max-min>.4,'Contours irréguliers du Ciel')
    for _,d in ipairs({'down'}) do local img=Art.imageData('assets/sprites/directional/octopus_extended_'..d..'.png')
        local _,_,_,a=img:getPixel(0,0); assert(a==0,'Poulpe alpha '..d); img:release()
    end
    Profile.scores={}; Profile.unlocked=6
    print('PASS océan/progression : boost directionnel, plumes continues, Paradis 8/9, six biomes, migration, bulle sans oxygène, poulpe, animations et trous irréguliers')
end
return T
