local T={}
local function level(w,n)
    LevelLayouts.disabled=true;Campaign.select(w);player.level=n or 1;reset_level();App.state='playing'
end
function T.run()
    Profile.unlocked=7;Profile.name='QA'
    for id=9,14 do
        App.start(id);assert(App.state=='playing' and player.level==1 and Worlds.levelCount(id)==1 and not App.custom)
        local b=Bosses.any() and Bosses.items[1].boss or ({[9]=Raven,[10]=Storm,[11]=Hedgehog,[12]=Octopus,[13]=Abyss})[id]
        assert(b and b.active and not b.defeated,'Rencontre hardcore disponible')
        if id==14 then
            assert(b.hardcore and b.name=='Les Sœurs de lave');b.hp=3;b.bees[1].hp=0;b.bees[2].hp=0
            assert(math.abs(b.tempo()-1.55*1.8)<.0001,'Ancienne vitesse conservée')
        end
        love.draw()
        reset_level();assert(Campaign.world==id and player.level==1,'Mort relance le même défi')
    end
    level(2,10);local slow=Wasp.tempo();Wasp.hardcore=true;assert(slow<Wasp.tempo())
    Secret.open();assert(App.state=='bossWorld');love.draw()
    Profile.name='';Secret.cooldown=0;Secret.x,Secret.y=Secret.position(1);Secret.update(0);assert(App.state=='entry' and App.selectedWorld==9,'Miniature lance le bon défi')
    Profile.name='QA';Secret.open();Secret.cooldown=0;Secret.x,Secret.y=Secret.position(1);Secret.update(0);assert(App.state=='playing' and Campaign.world==9,'Entrée immédiate si pseudo connu')
    UI.boardWorld=14;App.state='rankings';love.draw()
    level(7,10)
    local jelly;for _,m in ipairs(mobs) do if m.type=='light_jelly' then jelly=m;break end end
    player.x=jelly.x-15;player.y=jelly.y-12;MobBehaviors.light_jelly.update(jelly,0)
    assert(player.charges==1 and not player.reset,'Contact pieuvre charge sans tuer')
    MobBehaviors.light_jelly.update(jelly,0);assert(player.charges==1,'Une charge par contact')
    Abyss.charge(6);Abyss.charge(6);assert(player.charges==3)
    Abyss.open=true;Abyss.breathAt=Abyss.clock;Abyss.buildBones()
    local x,y=Abyss.mouth();player.x=x-15;player.y=y-12;Abyss.contact()
    assert(player.charges==0 and Abyss.swallowed.charged==3)
    Abyss.update(.61);assert(Abyss.hp==5,'Trois charges retirent trois vies')
    level(7,10);Abyss.charge(6);Abyss.charge(6)
    local tail;for _,b in ipairs(Abyss.bones) do if b.key=='skeleton_tail' then tail=b end end
    local found=false
    for yy=tail.y-70,tail.y+70,2 do for xx=tail.x-50,tail.x+50,2 do
        if not found and Abyss.boneTouches(tail,xx,yy) then player.x=xx-15;player.y=yy-12;found=true end
    end end
    Abyss.contact();assert(found and Abyss.open and player.charges==1 and not player.reset,'Queue consomme une charge et force aspiration')
    Abyss.contact();assert(player.charges==1,'Pas de double consommation au contact continu')
    level(7,2);Abyss.charge(6);Abyss.charge(6);Abyss.update(6.01);assert(player.charges==0,'Expiration réinitialise les charges')
    local old=Profile.scores;Profile.scores={{world=14,name='same',country='FR',time=10,deaths=0},{world=14,name='same',country='FR',time=20,deaths=1}}
    assert(#Profile.ranking(14)==2,'Classement local conserve tous les records');Profile.scores=old
    print('PASS secret revision: 6 hardcore encounters, old wasp tuning, softened classic, corridor entry, charge stacking/contact/tail/damage/expiry, complete ranking')
    love.event.quit()
end
function T.visual()
    love.focus=function() end;local tick=0
    love.update=function()
        tick=tick+1
        if tick==1 then Secret.open();Secret.x=Arena.width*.5;App.capture='secret-hall.png'
        elseif tick==5 then Profile.unlocked=7;Profile.name='gillou';App.start(14);App.capture='secret-lava-wasps.png'
        elseif tick==9 then level(7,10);for i=1,4 do Abyss.charge(6) end;App.capture='abyss-four-charges.png'
        elseif tick==13 then love.event.quit() end
    end
end
return T
