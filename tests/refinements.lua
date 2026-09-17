local T={}
local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
function T.run()
    level(1,10)
    local previous=1
    for hp=12,1,-1 do
        Raven.hp=hp; local interval=Raven.interval()
        assert(interval<=previous,'Cadence du Merle croissante')
        if hp%2==1 then assert(interval==previous,'Cadence stable entre deux PV perdus') end
        previous=interval; Raven.projectiles={}; Raven.fire()
        assert(#Raven.projectiles==(hp<=4 and 3 or 1),'Salve triple à quatre PV')
    end
    local old=Art.draw; local rings=0
    Art.draw=function(name,...) if name=='tear_ring' then rings=rings+1 end; return old(name,...) end
    for _,w in ipairs({1,2,4,5}) do level(w,10); Campaign.drawCircles(); assert(rings==0,'Aucun cercle sous les boss') end
    level(1,1); Campaign.drawCircles(); assert(rings>0); Art.draw=old
    level(6,1); Realms.wind={x=100,y=20,tx=0,ty=0,time=3,stage=3}
    local x,y=player.x,player.y; Realms.updateWind(.1)
    assert(player.x==x and player.y==y and Realms.wind.x==0 and Realms.wind.y==0,'Accalmie sans dérive résiduelle')
    level(5,3); local a,b=Realms.tunnels[1],Realms.tunnels[2]
    for _,kind in ipairs({'mole','worm'}) do
        local m; for _,v in ipairs(mobs) do if v.type==kind then m=v; break end end
        m.x,m.y=a.x,a.y; Realms.traverse(m,.01,false)
        assert(m.tunnelTravel and m.x==a.x,'Entrée animée du monstre')
        MobBehaviors[kind].update(m,.1); assert(m.x==a.x,'Monstre immobile pendant le passage')
        Realms.traverse(m,.23,false); assert(m.x==b.x and m.y==b.y,'Monstre téléporté')
        Realms.traverse(m,.23,false); assert(not m.tunnelTravel and m.tunnelLock)
        Realms.traverse(m,.5,false); assert(m.x==b.x,'Pas de boucle dans le tunnel')
    end
    player.x,player.y=a.x-15,a.y-12; Realms.traverse(player,.01,true)
    local deaths=player.death; Hazards.kill(); assert(not player.reset and deaths==player.death,'Passage protégé')
    level(5,10); assert(Hedgehog.phaseTime<=1.35)
    Hedgehog.roll(); assert(Hedgehog.hp==7 and Hedgehog.bounces==0 and #mobs==1)
    Hedgehog.roll(); assert(math.sqrt(Hedgehog.vx^2+Hedgehog.vy^2)>=409.999)
    Hedgehog.impact(); assert(#mobs==2 and Hedgehog.phaseTime<=1.15)
    level(7,1); assert(#Realms.fireflies==150)
    local p=Realms.fireflies[1]; player.x=p.x-15; player.y=p.y-12
    Realms.updateFireflies(0); assert(#Realms.fireflies<150,'Lueurs retirées au contact')
    player.x=-1000; player.y=-1000; p=Realms.fireflies[1]; x,y=p.x,p.y
    Realms.updateFireflies(.1); assert(p.x~=x or p.y~=y,'Lueurs mobiles')
    print('PASS refinements: Merle salves/cadence, cercles, accalmie, tunnels animés joueur/mobs, hérisson accéléré, lueurs Abysses')
end
function T.visual()
    local tick=0
    love.update=function(dt)
        tick=tick+1
        if tick==1 then
            level(5,8)
            for _,m in ipairs(mobs) do if m.type=='mole' then m.age=4.6 elseif m.type=='worm' then m.age=3.7 end end
            local a=Realms.tunnels[1]; player.x=a.x-15; player.y=a.y-12
            Realms.traverse(player,0,true); Realms.traverse(player,.1,true)
            App.capture='refinements-earth.png'
        elseif tick==5 then level(6,8); App.capture='refinements-sky.png'
        elseif tick==9 then level(7,5); App.capture='refinements-abyss.png'
        elseif tick==13 then
            level(1,10); Raven.hp=4; Raven.fire()
            for _,p in ipairs(Raven.projectiles) do p.x=p.x+p.vx*.4; p.y=p.y+p.vy*.4 end
            App.capture='refinements-merle.png'
        elseif tick==17 then love.event.quit() end
    end
end
return T
