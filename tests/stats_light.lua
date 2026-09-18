local T={}
function T.run()
    Online.start=function() end;Online.checkpoint=function() end
    Profile.name='QA';Profile.unlocked=7;Profile.stats={tears=0,deaths=0,attempts=0};Profile.scores={}
    LevelLayouts.disabled=true;Secret.duel=nil;App.sessionLayout=nil;App.singleLevel=false;Input.pad=nil
    App.start(1);assert(Profile.stats.attempts==1)
    Hazards.kill();Hazards.kill();assert(Profile.stats.deaths==1 and Profile.stats.attempts==2,'Une seule mort comptée')
    reset_level();mobs={};player.x=objet.larme.x;player.y=objet.larme.y
    love.update(0);assert(Profile.stats.tears==1 and player.level==2,'Collecte comptée une seule fois')
    App.restartCurrent();assert(Profile.stats.attempts==3)
    Profile.load();assert(Profile.stats.tears==1 and Profile.stats.deaths==1 and Profile.stats.attempts==3,'Totaux persistants')
    love.filesystem.write('profile.txt','name=QA\nprogressVersion=2\nunlocked=7')
    love.filesystem.write('scores.tsv','1\tQA\tFR\t100.000\t4\t1\n14\tQA\tFR\t200.000\t3\t1')
    Profile.load();assert(Profile.stats.tears==11 and Profile.stats.deaths==7 and Profile.stats.attempts==9,'Reprise des anciens records')
    Profile.load();assert(Profile.stats.tears==11 and Profile.stats.deaths==7 and Profile.stats.attempts==9,'Migration idempotente')
    Campaign.select(7);player.level=10;reset_level();App.state='playing'
    assert(Abyss.hp==10 and Abyss.maxHp==10)
    player.x=100;player.y=300
    for i=1,8 do Abyss.charge(6) end;assert(player.charges==3)
    player.charges=1;assert(Abyss.playerLightRadius()==150)
    player.charges=3;assert(Abyss.playerLightRadius()==240)
    Abyss.hurt(3);assert(Abyss.hp==7);Abyss.hurt(7);assert(Abyss.defeated and not objet.larme.taken)
    player.illuminated=0;player.electrified=0;player.charges=0
    local draw=love.graphics.draw;local seen=false
    love.graphics.draw=function(img,...) if img==objet.larme.img then seen=true end;return draw(img,...) end
    Campaign.drawTear();love.graphics.draw=draw;assert(seen and not Campaign.drawAbyssTear,'Larme dessinée avant le masque d’obscurité')
    local tick=0;love.focus=function() end
    love.update=function()
        tick=tick+1
        if tick==1 then App.capture='abyss-victory-tear.png'
        elseif tick==5 then App.state='achievements';App.capture='lifetime-stats.png'
        elseif tick==9 then Secret.hardcore=false;Secret.category='boss';Secret.open();UI.clock=1;App.capture='angelic-sanctuary.png'
        elseif tick==13 then Campaign.select(7);player.level=2;reset_level();App.state='playing';Abyss.charge(6);App.capture='abyss-charge-radius.png'
        elseif tick==17 then print('PASS stats/light: 3-charge cap, 10HP boss, dark blue masked tears, collection/death/retry persistence, legacy migration, sanctuary shader and achievements UI');love.event.quit() end
    end
end
return T
