local T={}
function T.hit(W,b)
    b=b or W.bees[1];b.phase='fatigued';b.time=2
    player.reset=false;player.x=b.x-15;player.y=b.y-12;W.contact()
end
function T.defeat(W)
    for _,b in ipairs(W.bees) do while b.hp>0 do T.hit(W,b) end end
end
function T.run()
    local disabled=LevelLayouts.disabled;LevelLayouts.disabled=true
    Campaign.select(2);player.level=10;reset_level();App.state='playing'
    local W=Wasp
    assert(#W.bees==3 and W.hp==9 and W.aliveCount()==3)
    local b=W.bees[1];player.x=b.x-15;player.y=b.y-12;W.contact();assert(W.hp==9 and not player.reset,'Invulnérable en vol')
    player.x=-1000;player.y=-1000;W.summon=0
    local phases={};local fatigue={};local chargeStarts={}
    for i=1,1600 do
        player.reset=false;W.hitGrace=100;W.update(.01)
        local count=0
        for _,bee in ipairs(W.bees) do
            if bee.phase=='fatigued' then count=count+1;fatigue[bee.id]=true end
            if bee.phase=='charge' and phases[bee.id]~='charge' then chargeStarts[#chargeStarts+1]={id=bee.id,time=i*.01} end
            phases[bee.id]=bee.phase
        end
        assert(count<=1,'Jamais deux abeilles fatiguées ensemble')
        assert(#W.minions==0,'Aucune invocation à trois')
    end
    assert(fatigue[1] and fatigue[2] and fatigue[3],'Chaque sœur offre une fenêtre de fatigue')
    assert(#chargeStarts>=3 and chargeStarts[2].time>chargeStarts[1].time,'Charges coordonnées et décalées')
    W.reset(true);local first=W.tempo();b=W.bees[1]
    for i=1,3 do local hp=W.hp;T.hit(W,b);assert(W.hp==hp-1);W.contact();assert(W.hp==hp-1,'Un seul coup par fatigue') end
    assert(W.aliveCount()==2 and W.tempo()>first and W.hp==6 and not W.defeated)
    W.summon=0;player.x=50;player.y=520;W.update(.01);assert(#W.minions==0,'Aucune invocation à deux')
    local second=W.tempo();for i=1,3 do T.hit(W,W.bees[2]) end
    assert(W.aliveCount()==1 and W.tempo()>second)
    W.summon=0;player.x=50;player.y=520;W.update(.01);assert(#W.minions==2,'Invocations uniquement à une')
    b=W.bees[3];b.phase='fatigued';b.time=.001;local x,y=b.x,b.y;W.update(.01)
    assert(b.phase=='cooldown' and b.x==x and b.y==y,'Fin fatigue sans téléportation')
    W.update(.01);assert((b.x-x)^2+(b.y-y)^2<3^2,'Redécollage continu')
    W.roundActive=true;b.phase='charge';b.x=100;b.y=100;b.tx=500;b.ty=100;W.hitGrace=0;player.x=150;player.y=88;player.reset=false
    W.update(.12);assert(player.reset,'Charge mortelle sans traverser le joueur')
    T.defeat(W);assert(W.defeated and Campaign.canCollect() and W.hp==0 and #W.projectiles==0 and #W.eruptions==0)
    assert(#W.minions==2,'Mini-abeilles persistantes');local mx=W.minions[1].x;player.x=-1000;player.y=-1000;W.update(.01);assert(W.minions[1].x~=mx)
    W.update(1);for _,bee in ipairs(W.bees) do assert(bee.deadTime>=.6,'Disparition des corps après victoire') end
    reset_level();assert(#W.bees==3 and W.hp==9 and #W.minions==0,'Mort réinitialise le trio')
    local x=W.bees[1].x;W.resize(1.1);assert(math.abs(W.bees[1].x-x*1.1)<.001);W.syncAnchor();assert(math.abs(W.bees[1].x-x*1.1)<.001,'Pas de double translation après resize')
    W.resize(1/1.1);love.draw()
    LevelLayouts.disabled=disabled;Campaign.select(1);player.level=1;reset_level()
    print('PASS wasp trio: staggered charges/fatigue, 3x3 HP, escalating tempo, last-survivor summons, safe hits, continuous takeoff, swept lethal charges, victory/reset/resize')
end
function T.visual()
    love.focus=function() end;local tick=0
    love.update=function()
        tick=tick+1
        if tick==1 then LevelLayouts.disabled=true;Campaign.select(2);player.level=10;reset_level();App.state='playing';Wasp.beginRound();Wasp.update(.01);App.capture='wasp-trio-formation.png'
        elseif tick==5 then Wasp.bees[1].phase='fatigued';Wasp.bees[1].time=2;Wasp.bees[1].x=350;Wasp.bees[1].y=370;Wasp.bees[2].phase='aim';Wasp.bees[2].tx=player.x;Wasp.bees[2].ty=player.y;App.capture='wasp-trio-fatigue.png'
        elseif tick==10 then T.hit(Wasp,Wasp.bees[1]);T.hit(Wasp,Wasp.bees[1]);T.hit(Wasp,Wasp.bees[1]);for i=1,3 do T.hit(Wasp,Wasp.bees[2]) end;player.x=60;player.y=500;Wasp.summon=0;Wasp.update(.02);App.capture='wasp-trio-last.png'
        elseif tick==15 then love.event.quit() end
    end
end
return T
