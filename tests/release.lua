local T={}
local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
function T.run()
    Profile.unlocked=6
    Campaign.starts={{},{},{},{},{},{}}
    for _,w in ipairs({4,5,6,7}) do for n=1,10 do
        level(w,n)
        assert(not Arena.blocked(player.x,player.y,30,24),'Spawn nouveau monde libre')
        assert((#mobs>=2 or Hedgehog.active or Octopus.active or Storm.active) and Realms.floor,'Rencontre et décor présents')
        local reachable=require('tests.gameplay_v5').reachable()
        for _,p in ipairs(levels[n].larme_position) do assert(reachable(p),'Larme accessible monde '..w..' niveau '..n) end
        love.draw()
        if Campaign.carrier then
            assert(not Campaign.canCollect())
            local carrier=Campaign.carrier; local trap
            for _,m in ipairs(mobs) do if m.capture then trap=m; break end end
            player.x=60; player.y=500; carrier.x=trap.x; carrier.y=trap.y
            MobBehaviors[carrier.type].update(carrier,0)
            assert(objet.larme_dropped and Campaign.canCollect(),'Piège libère la larme du monde '..w)
            local x,y=objet.larme.x,objet.larme.y; Campaign.updateTear(5)
            assert(x==objet.larme.x and y==objet.larme.y)
        end
    end end
    level(6,3); assert(#Realms.clouds==0 and Hazards.speed()==1,'Nuages ralentissants supprimés')
    Realms.rain={{x=player.x+15,y=player.y+12,age=.84}}; Realms.update(.02); assert(player.reset,'Pluie mortelle après avertissement')
    reset_level(); assert(#Realms.rain==0)
    level(2,10); Wasp.reset(true)
    for _,p in ipairs({{-40,0},{35,0},{0,-45},{0,35},{0,0}}) do
        Wasp.phase='landed'; player.x=Wasp.x+p[1]-15; player.y=Wasp.y+p[2]-12; player.dashing=false
        local hp=Wasp.hp; Wasp.contact(); assert(Wasp.hp==hp-1 and not player.reset,'Contact sûr partout au sol')
        Wasp.contact(); assert(Wasp.hp==hp-1,'Un seul dégât avant redécollage')
    end
    player.x=60; player.y=500; Wasp.phase='landed'; Wasp.phaseTime=.01; Wasp.shot=100; Wasp.update(.02)
    assert(Wasp.phase=='flying','Redécollage automatique')
    level(2,10); Wasp.reset(true); Wasp.phase='landed'; player.x=Wasp.x-15; player.y=Wasp.y-12
    Wasp.projectiles={{x=Wasp.x,y=Wasp.y,vx=0,vy=0,life=1,kind='sting'}}
    Wasp.update(.01); assert(Wasp.hp==9 and not player.reset,'Protection du contact réussi')
    Bestiary.seen={}; Bestiary.unread={}; Bestiary.discover('mole'); Bestiary.save(); Bestiary.load()
    assert(Bestiary.seen.mole and Bestiary.pending(),'Découverte persistante')
    App.state='playing'; Bestiary.open(); assert(not Bestiary.pending() and App.state=='bestiary' and UI.bestReturn=='playing')
    Bestiary.load(); assert(not Bestiary.pending()); love.keypressed('escape'); assert(App.state=='playing')
    assert(not Bestiary.discover('mole') and not Bestiary.pending(),'Pas de nouvelle notification pour un monstre connu')
    Profile.character=5; App.runSkin=3; Profile.complete(2,42,7); Profile.load()
    assert(Profile.scores[#Profile.scores].skin==3,'Skin de la partie conservé')
    assert(Worlds.next(4)==7 and Worlds.next(7)==2 and Worlds.next(2)==3,'Abysse avant Enfer, puis Renaissance')
    for _,w in ipairs({4,5,6,7}) do
        App.start(w)
        for n=1,10 do
            if Hedgehog.active then
                for stage=1,7 do Hedgehog.bounces=0; for bounce=1,Hedgehog.requiredBounces() do Hedgehog.impact() end end
            end
            if Storm.active then for _=1,8 do Storm.phase='rest'; Storm.hitGrace=0; player.x=Storm.x-15; player.y=Storm.y-12; Storm.contact() end end
            if Octopus.active then
                for _=1,8 do require('tests.octopus_revision').clearWave() end
            end
            if Abyss.boss then require('tests.expansion').defeatAbyss() end
            mobs={}; Campaign.carrier=nil; objet.larme_dropped=true
            Realms.rain={}; Realms.rainClock=100; Realms.current={}
            player.x=objet.larme.x; player.y=objet.larme.y; love.update(.001)
        end
        assert(App.state=='victory','Dix niveaux terminables monde '..w)
    end
    level(4,3); local w=Arena.width; love.resize(1600,900); assert(Realms.floor:getWidth()==Arena.width); love.resize(love.graphics.getDimensions())
    local scores=Online.scores
    Online.scores=function() local rows={}; for i=1,12 do rows[i]={name='Joueur '..i,time=30+i,deaths=i,skin=(i-1)%5+1} end; return rows,'online' end
    App.state='menu'; love.draw(); App.state='boards'; love.draw(); Online.scores=scores
    Profile.scores={}; Profile.character=1
    print('PASS release: 40 niveaux, porteurs, pluie/nuages, guêpe sûre, bestiaire persistant, skins des scores, progression, UI et redimensionnement')
end
return T
