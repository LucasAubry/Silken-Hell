local T={}
function T.defeat()
    if Raven.active then
        while not Raven.defeated do local e=Raven.eggs[1]; Raven.shot=100; Raven.projectiles={{x=e.x,y=e.y,vx=0,vy=0,life=1}}; Raven.update(.01) end
    elseif Storm.active then
        for _=1,Storm.maxHp do Storm.hitGrace=0; Storm.phase='rest'; player.x=Storm.x-15; player.y=Storm.y-12; Storm.contact() end
    elseif Hedgehog.active then for _=1,Hedgehog.maxHp do Hedgehog.finishRound() end
    elseif Octopus.active then for _=1,8 do require('tests.octopus_revision').clearWave() end
    elseif Abyss.boss then require('tests.expansion').defeatAbyss()
    elseif Wasp.active then require('tests.wasp_trio').defeat(Wasp) end
end
function T.run()
    local disabled=LevelLayouts.disabled; LevelLayouts.disabled=true; Profile.unlocked=7
    for n=1,10 do
        Campaign.select(5); player.level=n; reset_level(); App.state='playing'
        for _,m in ipairs(mobs) do
            if m.type=='mole' then assert(Realms.molePhase(m.age)=='surface','Taupe visible au début') end
            if m.type=='worm' then assert(Realms.wormPhase(m.age)=='surface','Ver visible au début') end
        end
    end
    assert(Hedgehog.maxHp==7 and Hedgehog.hp==7)
    Hedgehog.roll(); assert(math.abs(math.sqrt(Hedgehog.vx^2+Hedgehog.vy^2)-410)<.01)
    Hedgehog.vx=410; Hedgehog.vy=0; player.x=Hedgehog.x-150; player.y=Hedgehog.y-100
    Hedgehog.update(.05); assert(math.abs(math.atan2(Hedgehog.vy,Hedgehog.vx))<=.068,'Virage élargi')
    for stage=1,7 do Hedgehog.stage=stage; assert(Hedgehog.requiredBounces()<=2) end
    for n=1,10 do
        Campaign.select(6); player.level=n; reset_level(); App.state='playing'
        assert(Realms.lightningClock<.5,'Orage dès le début')
        Realms.updateLightning(.36); assert(#Realms.lightning>=1,'Foudre présente dès le niveau un')
        for _=1,4 do Realms.lightningClock=0; Realms.updateLightning(.01) end
        assert(#Realms.lightning>=5,'Orage récurrent')
        if n<10 then assert(#mobs>=3,'Ciel plus peuplé') end
    end
    assert(Storm.active and not Campaign.canCollect(),'Boss du Ciel bloque la larme')
    local hp=Storm.hp; player.x=Storm.x-15; player.y=Storm.y-12; Storm.contact(); assert(Storm.hp==hp,'Invulnérable en vol')
    player.x=100; player.y=510; Storm.phaseTime=0; Storm.update(.01); assert(Storm.phase=='rest','Accalmie vulnérable')
    player.x=Storm.x-15; player.y=Storm.y-12; Storm.contact(); assert(Storm.hp==hp-1 and not player.reset and Storm.phase=='storm')
    BossFX.update(.01); assert(BossFX.power>0 and #BossFX.events>0,'Impacts et secousse du boss')
    local x,y=BossFX.offset(); assert(math.abs(x)<=6 and math.abs(y)<=6,'Secousse bornée')
    BossFX.update(1); assert(BossFX.power==0,'Secousse amortie')
    local phase=Storm.phase; local oldhp=Storm.hp; love.resize(1600,900); assert(Storm.hp==oldhp and Storm.phase==phase); love.resize(love.graphics.getDimensions())
    for _,dir in ipairs({'down','up','left','right'}) do
        local d=love.image.newImageData('assets/sprites/directional/storm_'..dir..'.png'); local _,_,_,a=d:getPixel(0,0); assert(a<=1/255+.0001,'Fond transparent à un niveau alpha sur 255 près'); d:release()
    end
    -- A complete six-boss run keeps its world ID, timer and deaths between biomes.
    Profile.scores={}; App.start(3); local ordered={Raven,Storm,Hedgehog,Octopus,Abyss,Wasp}
    for stage,biome in ipairs(Worlds.rush) do
        assert(Campaign.world==3 and Campaign.biome==biome and player.level==stage,'Ordre Renaissance')
        assert(ordered[stage].active and not Campaign.canCollect(),'Boss attendu actif')
        local snapshot=LevelLayouts.snapshot(); assert(LayoutSchema.validate(snapshot),'Export Renaissance valide')
        love.draw()
        if stage==3 then
            local oldDeaths=player.death; Hazards.kill(); love.update(.01)
            assert(player.level==stage and player.death==oldDeaths+1 and Hedgehog.hp==7,'Mort : même combat réinitialisé')
            assert(Realms.molePhase(mobs[1].age)=='surface')
        end
        T.defeat(); assert(Campaign.canCollect(),'Combat terminé')
        mobs={}; Magma.reset(); Raven.chicks={}; Wasp.minions={}; Octopus.crabs={}; Realms.rain={}; Realms.lightning={}; Realms.lightningClock=100; Realms.current={}; Realms.tornadoes={}
        player.reset=false; player.x=objet.larme.x; player.y=objet.larme.y; timer=stage*20
        love.update(.001)
        if stage<6 then assert(timer>=stage*20 and App.state=='playing','Chrono commun sans retour au menu') end
    end
    assert(App.state=='victory' and #Profile.scores==1 and Profile.scores[1].world==3 and Profile.scores[1].deaths==1,'Score Renaissance après six boss')
    assert(Worlds.next(2)==3 and Worlds.levelCount(3)==6 and Worlds.canEnter(3))
    -- New boss can be placed independently in every editor biome.
    local l={world=3,level=2,width=Arena.width,height=600,entities={{kind='spawn',x=80,y=510},{kind='boss',type='storm',x=400,y=210}}}
    assert(LayoutSchema.validate(l)); LevelLayouts.apply(l); assert(Bosses.items[1].kind=='storm'); Bosses.update(.01); love.draw()
    LevelLayouts.disabled=disabled; Campaign.select(1); player.level=1; reset_level(); Profile.unlocked=7
    print('PASS renaissance: six ordered bosses, timer/deaths/score, death reset, surface mobs, 7 HP/2 rebounds/wide turns, early lightning, storm boss, effects, resize and custom maps')
end
function T.visual()
    love.focus=function() end
    local tick=0
    love.update=function()
        tick=tick+1; UI.clock=UI.clock+.016
        if tick==1 then LevelLayouts.disabled=true; Profile.unlocked=7; App.start(3); App.capture='renaissance-merle.png'
        elseif tick==5 then player.level=2; reset_level(); Storm.fire(); Storm.summon(); App.capture='renaissance-storm.png'
        elseif tick==9 then Storm.phase='rest'; BossFX.burst(Storm.x,Storm.y,{1,.2,.2},4); BossFX.update(.12); App.capture='renaissance-rest.png'
        elseif tick==13 then App.state='menu'; App.selectedWorld=3; App.capture='renaissance-menu.png'
        elseif tick==17 then App.start(6); Realms.updateLightning(.36); App.capture='sky-early-storm.png'
        elseif tick==21 then player.level=10; reset_level(); Storm.fire(); Storm.summon(); for _,p in ipairs(Storm.strikes) do p.age=1 end; App.capture='sky-boss.png'
        elseif tick==25 then love.event.quit() end
    end
end
return T
