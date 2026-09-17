local T={}
local function level(n)
    Campaign.select(7); player.level=n; reset_level(); App.state='playing'
end
local function mouth(b)
    b.open=true; b.breathAt=b.clock; b.buildBones()
    local x,y=b.mouth(); player.x=x-15; player.y=y-12; player.abyssGrace=0; player.abyssSpit=nil
    return x,y
end
function T.run()
    local disabled=LevelLayouts.disabled; LevelLayouts.disabled=true
    level(2); local p=levels[2].larme_position[1]
    player.x=p.x; player.y=p.y+27; Abyss.update(0)
    assert(player.circleLight and player.illuminated==6 and player.electrified==0,'Un cercle éclaire sans électrocuter')
    player.x=Arena.width*.5; player.y=510; Abyss.update(.01)
    assert(player.illuminated==0 and not player.circleLight,'Sortir du cercle éteint immédiatement la lumière')
    Abyss.threads={{x=player.x+15,y=player.y+12,vx=0,vy=0,life=1,age=0,seed=0}}
    Abyss.update(.01); assert(player.electrified==6 and player.illuminated==6,'Un courant charge le joueur')
    player.x=p.x; player.y=p.y+27; Abyss.update(.2)
    player.x=Arena.width*.5; player.y=510; Abyss.update(.2)
    assert(player.electrified>5 and player.illuminated>5,'Sortir du cercle conserve une charge électrique indépendante')
    Abyss.update(6); assert(player.illuminated==0,'Charge électrique limitée dans le temps')
    level(10); local old={}; for i,b in ipairs(Abyss.bones) do old[i]={x=b.x,y=b.y,angle=b.angle} end
    local hx,hy=Abyss.head.x,Abyss.head.y
    Abyss.update(.4)
    assert(Abyss.bones[1].y~=old[1].y,'Corps oscillant')
    assert(Abyss.head.x==hx and Abyss.head.y==hy,'Tête fixe attachée au squelette')
    -- A charged body cannot damage the boss by touching a rib.
    local b=Abyss.bones[1]; local found=false
    for y=b.y-14,b.y+14,2 do for x=b.x-11,b.x+11,2 do
        if not found and Abyss.boneTouches(b,x,y) then player.x=x-15; player.y=y-12; found=true end
    end end
    Abyss.charge(6); Abyss.contact(); assert(player.reset and Abyss.hp==8,'Toucher un os reste mortel et ne blesse plus le boss')
    level(10); mouth(Abyss); player.illuminated=6; player.electrified=0; Abyss.contact()
    assert(player.reset and not Abyss.swallowed and Abyss.hp==8,'La lumière seule ne protège pas dans la bouche')
    level(10); local mx,my=mouth(Abyss); player.x=mx+55; player.y=my-12; Abyss.charge(6)
    -- Natural approach via suction must reach the throat before skull collision.
    local startX=player.x
    for _=1,90 do Abyss.update(.01); if player.abyssHeld or player.reset then break end end
    assert(player.x<startX and player.abyssHeld==Abyss and not player.reset,'Aspiration jusqu’à la bouche accessible')
    assert(Abyss.hp==8 and player.electrified==0,'Charge consommée, dégâts différés au rejet')
    local deaths=player.death; Hazards.kill(); assert(player.death==deaths,'Protection pendant la déglutition')
    love.draw(); Abyss.update(.61)
    assert(Abyss.hp==7 and player.abyssSpit and not player.abyssHeld and not player.reset,'Rejet animé inflige exactement un dégât')
    Abyss.updatePlayer(.3); assert(not player.abyssSpit and not Arena.blocked(player.x,player.y,30,24),'Atterrissage libre')
    Abyss.update(.1); assert(Abyss.hp==7,'Pas de dégâts répétés')
    level(10); mx,my=mouth(Abyss); player.x=90; player.y=510
    local m=mobs[1]; m.x=mx-6; m.y=my; local count=#mobs
    Abyss.pullEntity(m,.03,m); assert(m.abyssHeld==Abyss and #Abyss.cargo==1,'Créature avalée')
    local fly={x=mx-8,y=my,angle=0,turn=1,phase=0,radius=1}; Realms.fireflies={fly}
    Abyss.pullEntity(fly,.03); Realms.updateFireflies(.1); assert(fly.abyssHeld==Abyss and #Realms.fireflies==1,'Lueur retenue intacte')
    local thread={x=mx-5,y=my,vx=20,vy=0,life=1,age=0,seed=0}; Abyss.threads={thread}; Abyss.pullEntity(thread,.03)
    Abyss.clock=Abyss.breathAt+3.49; Abyss.update(.02)
    assert(not Abyss.open and not m.abyssHeld and not fly.abyssHeld and not thread.abyssHeld and #mobs==count and #Abyss.cargo==0,'Tout est recraché si le joueur n’est pas capturé')
    assert(Abyss.hp==8,'Aucun dégât après aspiration ratée')
    -- Full new encounter and level reset.
    level(10); require('tests.expansion').defeatAbyss(); assert(Campaign.canCollect(),'Larme après huit électrocutions avalées')
    reset_level(); assert(not player.abyssHeld and not player.abyssSpit and player.electrified==0 and player.abyssGrace==0)
    -- Two custom Leviathans keep independent breath/cargo/health states.
    local snap=LevelLayouts.snapshot(); snap.entities[#snap.entities+1]={kind='boss',type='skeleton_fish',x=300,y=250}
    LevelLayouts.apply(snap); local first,last=Bosses.items[1].boss,Bosses.items[#Bosses.items].boss
    assert(first~=last); mouth(first); Abyss.charge(6); first.contact(); first.update(.61)
    assert(first.hp==7 and last.hp==8 and not last.swallowed,'Rencontres indépendantes')
    LevelLayouts.disabled=disabled; Campaign.select(1); player.level=1; reset_level()
    print('PASS abyss breath: transient circles, electric charge, oscillating bones, fixed head, suction, charged swallow/spit, cargo, defeat, reset, duplicate bosses')
end
function T.visual()
    local tick=0
    love.update=function()
        tick=tick+1
        if tick==1 then
            LevelLayouts.disabled=true; level(10); Abyss.motionTime=2; Abyss.buildBones(); mouth(Abyss)
            player.x=Abyss.head.x+110; player.y=Abyss.head.y+60; Abyss.charge(6); App.capture='abyss-breath-open.png'
        elseif tick==5 then
            mouth(Abyss); Abyss.charge(6); Abyss.contact(); Abyss.update(.15); App.capture='abyss-breath-swallow.png'
        elseif tick==9 then
            Abyss.update(.5); Abyss.updatePlayer(.16); App.capture='abyss-breath-spit.png'
        elseif tick==13 then love.event.quit() end
    end
end
return T
