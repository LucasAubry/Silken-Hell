local T={}
local function level(w,n,custom)
    LevelLayouts.disabled=not custom;Campaign.select(w);player.level=n;reset_level();App.state='playing'
    if custom and not Bosses.any() then
        local layout=LevelLayouts.snapshot()
        for _,e in ipairs(layout.entities) do if e.type=='skeleton_fish' then e.skeletonStage=nil end end
        LevelLayouts.apply(layout)
    end
end
function T.run()
    level(4,10);local O=Octopus
    for _,hp in ipairs(O.arms) do assert(hp==3) end
    O.summon=100;O.shot=100;O.hp=4;O.update(.3);assert(math.abs(O.angularVelocity)>1)
    require('tests.octopus_revision').clearWave();assert(#O.blasts>0,'Crabe explose sur tentacule')
    love.draw()
    for _,custom in ipairs({false,true}) do
        for n=8,10 do
            level(7,n,custom)
            local b=Bosses.any() and Bosses.items[1].boss or Abyss
            assert(b.skeletonStage==n and (b.head~=nil)==(n==10),'Progression squelette')
            assert(n~=8 or #b.bones==1,'Queue seule au niveau 8')
            assert(n~=9 or #b.bones>1,'Queue et os au niveau 9')
            love.draw()
        end
        level(7,10,custom)
        local b=Bosses.any() and Bosses.items[1].boss or Abyss
        local jelly={};for _,m in ipairs(mobs) do if m.type=='light_jelly' then jelly[#jelly+1]=m end end
        assert(#jelly>=2 and jelly[1].shotOffset~=jelly[2].shotOffset,'Deux pieuvres décalées')
        Abyss.threads={};jelly[1].age=1.49;jelly[2].age=1.49
        MobBehaviors.light_jelly.update(jelly[1],.02);MobBehaviors.light_jelly.update(jelly[2],.02)
        assert(#Abyss.threads==3,'Une seule pieuvre tire')
        local site=b.lightSites[1];player.x=site.x-15;player.y=site.y-12;Abyss.refreshLight()
        assert(player.circleLight and player.illuminated==6,'Cercle fonctionnel')
        b.open=true;b.breathAt=b.clock;b.buildBones();local mx,my=b.mouth()
        player.x=mx-15;player.y=my-12;player.electrified=0;Hazards.kill('bone');assert(not player.reset,'Invincible pendant aspiration')
        b.contact();assert(player.abyssHeld==b,'Avalé sans mourir même sans charge')
        b.update(.61);assert(not player.abyssHeld and b.hp==8,'Recraché sans charge ne blesse pas le boss')
        player.abyssSpit=nil;player.abyssGrace=0;b.open=true;b.breathAt=b.clock;b.buildBones();mx,my=b.mouth()
        player.x=mx-15;player.y=my-12;Abyss.charge(6);b.contact();b.update(.61);assert(b.hp==7,'Charge électrique blesse au rejet')
        love.draw()
    end
    level(7,2);local p=levels[2].larme_position[1];mobs={};player.illuminated=0
    assert(Abyss.siteVisibility(p.x+15,p.y+39)==0,'Cercle invisible sans lumière')
    player.x=p.x;player.y=p.y+27;Abyss.refreshLight();assert(Abyss.siteVisibility(p.x+15,p.y+39)==1)
    player.x=500;player.y=500;Abyss.refreshLight();Abyss.add('lanternfish',p.x+15,p.y+54,0)
    assert(Abyss.siteVisibility(p.x+15,p.y+39)==1,'Poisson révèle le cercle')
    level(2,10);local W=Wasp
    for stage,hp in ipairs({9,8,3}) do
        W.reset(true);W.hp=hp;W.round=2;W.rest=0;player.x=400;player.y=300
        W.hitGrace=100
        local fired=0;local fire=W.fireLarva;W.fireLarva=function(b) fired=fired+1;fire(b) end
        for i=1,400 do W.update(.01);if fired==stage then break end end
        W.fireLarva=fire
        assert(W.stage()==stage)
        local count=0;for _,p in ipairs(W.projectiles) do if p.kind=='larva' then count=count+1 end end
        assert(fired==stage,'Nombre de larves par phase: '..stage..' reçu '..fired)
    end
    W.reset(true);player.x=400;player.y=300;W.hitGrace=100
    for _,attack in ipairs({1,2}) do
        W.reset(true);W.rest=100;W.hitGrace=100
        local b=W.bees[1];b.attack=attack;b.x=200;b.y=200;W.positionAttack(b)
        for i=1,500 do W.updateBees(.01);if b.phase=='charge' then break end end
        assert(b.phase=='charge' and ((attack==1 and b.vy==0) or (attack==2 and b.vx==0)),'Charge axiale')
        for i=1,500 do W.updateBees(.01);if b.phase=='fatigued' then break end end
        assert(b.phase=='fatigued','Mur met KO')
        local hp=W.hp;player.x=b.x-15;player.y=b.y-12;W.contact();W.contact();assert(W.hp==hp-1,'Un seul PV par KO')
        player.x=400;player.y=300
    end
    local larva=W.fireLarva({x=player.x+15,y=player.y+12})
    assert(larva.type=='magma_larva' and larva.fuse==3.6,'Même larve que les nids')
    Magma.explode(larva);assert(player.reset and #Magma.bursts>0,'Explosion magma mortelle')
    level(2,10,true);assert(Bosses.hud().bees,'HUD trio personnalisé');love.draw()
    require('tests.wasp_speed').run()
    require('tests.wasp_contact').run()
    print('PASS requested bosses: tentacles, explosions, rage, stages 8/9/10, circles, staggered octopuses, suction, bee axes/wall KO/larvae/health HUD')
    love.event.quit()
end
function T.visual()
    love.focus=function() end
    local tick=0
    love.update=function()
        tick=tick+1
        if tick==1 then level(4,10);Octopus.hp=4;Octopus.angle=.4;App.capture='request-octopus.png'
        elseif tick==5 then level(2,10,true);local b=Bosses.items[1].boss;b.bees[1].hp=1;b.hp=7;b.bees[2].phase='fatigued';App.capture='request-bees.png'
        elseif tick==9 then level(7,8,true);App.capture='request-tail.png'
        elseif tick==13 then level(7,10,true);local b=Bosses.items[1].boss;local p=b.lightSites[1];player.x=p.x-15;player.y=p.y-12;Abyss.refreshLight();App.capture='request-abyss.png'
        elseif tick==17 then love.event.quit() end
    end
end
return T
