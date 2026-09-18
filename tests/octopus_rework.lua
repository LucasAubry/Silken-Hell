local T={}
function T.run()
    Online.start=function() end;Online.checkpoint=function() end
    Profile.name='QA';Profile.unlocked=7;App.sessionLayout=nil;App.singleLevel=false;Secret.duel=nil
    Input.move=function() return 0,0 end;Input.slow=function() return false end
    local function level(n) Campaign.select(4);player.level=n;reset_level();App.state='playing' end
    local update=love.update
    -- Exercise the real death -> reset -> draw path, with and without authored maps.
    for _,disabled in ipairs({false,true}) do
        LevelLayouts.disabled=disabled
        for n=1,10 do level(n)
            for i=1,12 do
                Hazards.kill();update(.016);love.draw()
                assert(not player.reset,'Reprise après mort océan '..n)
            end
        end
    end
    LevelLayouts.disabled=true;level(10);local O=Octopus
    local floor=Realms.floor;Hazards.kill();update(.016);assert(Realms.floor==floor,'Décor GPU réutilisé après mort')
    local move=App.move;local old=MobBehaviors.crab.update;local ran=false
    App.move=function() Hazards.kill() end;MobBehaviors.crab.update=function() ran=true end
    Octopus.spawnCrab(100,100,100);update(.016)
    App.move=move;MobBehaviors.crab.update=old;assert(not ran,'Aucune simulation des mobs après une mort')
    -- Replay a custom ocean boss after dying while towing a tentacle.
    App.sessionLayout={world=4,level=10,width=Arena.width,entities={{kind='spawn',x=70,y=500},{kind='boss',type='octopus',x=Arena.width/2,y=300},{kind='tear',x=70,y=100}}}
    LevelLayouts.disabled=false;reset_level();local custom=Bosses.items[1].boss
    custom.stun=2;custom.rider={arm=1};Hazards.kill();update(.016)
    assert(#Bosses.items==1 and not Bosses.items[1].boss.rider and Bosses.items[1].boss.stun==0,'Mort en tirant un boss personnalisé')
    App.sessionLayout=nil;LevelLayouts.disabled=true;level(10)
    local function crab(x,y,black)
        return {x=x,y=y,speed=150,age=0,angle=0,vx=1,vy=0,inked=black,hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
    end
    player.x=70;player.y=420
    local c=crab(170,400);O.crabs={c};O.inkPools={{x=170,y=400,rx=38,ry=27,life=7}}
    O.inkCrab(c,.01);assert(c.inked,'Encre noircit')
    O.inkPools={};O.inkCrab(c,10);assert(c.inked,'Ne reprend jamais la poursuite')
    player.x=c.x-35;player.y=c.y-12;player.dashing=true;O.crabContact(c)
    assert(c.fling and c.fling.vx>700 and math.abs(c.fling.vy)<.01 and not player.reset,'Propulsion opposée au contact')
    c.x=Arena.width-40;c.y=400;player.x=70;player.y=420
    O.moveFlungCrab(c,.1,function() O.crabContact(c) end);assert(c.dead,'Explosion au mur')
    level(10);O=Octopus;player.x=70;player.y=420
    local tx,ty=O.tip(1);c=crab(tx,ty,true);O.crabs={c};O.crabContact(c)
    assert(c.dead and O.stun==3 and O.hp==8,'Impact étourdit sans retirer de vie')
    local angle=O.angle;O.update(.1);assert(O.angle==angle,'Rotation stoppée')
    player.x=tx-15;player.y=ty-12;player.dashing=true;O.contact();assert(O.rider and O.rider.arm==1,'Accroche à une extrémité')
    assert(not O.riderInput(1,0,false,.01),'Déplacement libre pour tirer')
    Input.move=function() return 1,0 end;local x=player.x;App.move(.02);assert(player.x-x>8,'Vitesse de déplacement conservée en tirant');Input.move=function() return 0,0 end
    player.x=45;player.y=45;O.contact();assert(O.hp==7 and O.arms[1]==0 and not O.rider,'Arrachage dans un coin')
    local t2x,t2y=O.tip(2);c=crab(t2x,t2y,true);O.crabs={c};O.crabContact(c)
    player.x=t2x-15;player.y=t2y-12;player.dashing=true;O.contact();assert(O.rider)
    player.x=70;player.y=420;O.update(3.01);assert(not O.rider and O.stun==0 and O.hp==7,'Réveil après 3 secondes sans dégât')
    for arm=2,4 do O.tearArm(arm) end
    assert(O.hp==4 and O.enraged and O.barrage==3,'Rage à mi-vie')
    O.summon=100;local shots=O.inkCount
    for i=1,40 do O.update(.05) end
    assert(O.inkCount-shots>=10 and math.abs(O.angularVelocity)>1,'Rafale courte et rotation rapide')
    O.updateInk(8);assert(#O.inkPools==0,'Flaques temporaires')
    for arm=5,8 do O.tearArm(arm) end;assert(O.defeated and not objet.larme.taken,'Victoire après huit arrachages')
    level(10);player.x=O.x-15;player.y=O.y-12;O.contact();assert(player.reset,'Corps mortel')
    -- Rendering a dead crab must also be safe during death frames.
    level(10);O.releaseCrabs();for _,cr in ipairs(O.crabs) do cr.launch=nil;O.explodeCrab(cr) end;love.draw();Hazards.kill();update(.016);love.draw()
    local deaths=player.death
    for n=1,10 do
        level(n)
        for i=1,200 do
            local angle=i*.17+n
            Input.move=function() return math.cos(angle),math.sin(angle) end
            update(.05)
            if i%40==0 then love.draw() end
        end
    end
    Input.move=function() return 0,0 end
    assert(player.death>deaths,'Morts naturelles pendant les déplacements et les collisions')
    print('Ocean live simulation deaths: '..(player.death-deaths))
    Campaign.select(7);player.level=2;reset_level();App.state='playing'
    assert(Worlds.color(7).tear[3]<.6 and Worlds.color(7).tear[1]<.15,'Larme bleu sombre')
    assert(not Campaign.drawAbyssTear,'Pas de rendu de larme au-dessus de l’obscurité')
    local tick=0;love.focus=function() end
    love.update=function()
        tick=tick+1
        if tick==1 then shader_effect_timer=0;App.capture='abyss-hidden-tear.png'
        elseif tick==5 then level(10);shader_effect_timer=0;O.stun=2.6;local x,y=O.tip(2);player.x=x+100;player.y=y-12;O.rider={arm=2};App.capture='octopus-towing.png'
        elseif tick==9 then O.rider=nil;O.stun=0;for arm=1,4 do O.tearArm(arm) end;player.x=65;player.y=460;O.ink();O.updateInk(1);O.releaseCrabs();App.capture='octopus-rage.png'
        elseif tick==13 then print('PASS octopus rework: 240 ocean deaths/reset/draw, inked crab kick, wall blast, stun, tow, corner tear, timeout, rage, victory, hidden abyss tear');love.event.quit() end
    end
end
return T
