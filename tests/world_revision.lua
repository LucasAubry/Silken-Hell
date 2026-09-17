local T={}
local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
function T.run()
    for n=1,10 do level(1,n)
        for _,m in ipairs(mobs) do if m.type=='piege' or m.type=='scie' then
            local r=m.type=='scie' and m.radius+22 or 32
            for _,p in ipairs(levels[n].larme_position) do assert((m.x-p.x-15)^2+(m.y-p.y-39)^2>=(r+26)^2,'Piège hors cercle '..n) end
        end end
    end
    level(1,2); local m={x=200,y=250,speed=2,hitBox_width=28,hitBox_height=42,hitBox_offset_x=-14,hitBox_offset_y=-21,imgs={}}
    player.x=450; player.y=250; player.has_moved=true; m.path={}; m.navTime=100
    move_when_player_moves(m,player,.02); assert(m.x>200,'Chemin épuisé : aucune pause artificielle')
    local x=m.x; player.has_moved=false; move_when_player_moves(m,player,.02); assert(m.x==x,'Arrêt seulement avec le joueur')
    for n=1,4 do level(6,n); Realms.rainClock=0; Realms.update(.1); assert(#Realms.rain==0,'Pas de pluie avant le niveau cinq') end
    level(6,5); Realms.rainClock=0; Realms.update(.01); assert(#Realms.rain>0)
    local p=Realms.rain[1]; player.x=p.x-15; player.y=p.y-12; p.age=.7; Realms.update(.01); assert(player.reset,'Pluie inflige un dégât mortel')
    level(6,5); m=mobs[1]; Realms.lightning={{x=m.x,y=m.y,age=.79,target=m}}; Realms.updateLightning(.02)
    assert(m.electric and Bestiary.seen.electric_gull,'Foudre transforme la mouette')
    player.x=m.x+25; player.y=m.y-12; Realms.moveGull(m,0); assert(not player.reset,'Ancien rayon désormais sûr')
    player.x=m.x+10; Realms.moveGull(m,0); assert(player.reset,'Petite aura électrique dangereuse')
    level(6,5); m=mobs[1]; m.x=80; m.y=300; objet.larme.x=500; objet.larme.y=300
    local old=(m.x-515)^2+(m.y-320)^2; Realms.moveGull(m,.2)
    assert((m.x-515)^2+(m.y-320)^2<old,'Mouette poursuit la larme')
    level(5,3); local earth={}; for _,v in ipairs(mobs) do earth[#earth+1]=v; v.x=Arena.width/2; v.y=300 end
    Realms.separateEarth()
    for i=1,#earth do for j=i+1,#earth do assert(math.abs(earth[i].x-earth[j].x)>=32 or math.abs(earth[i].y-earth[j].y)>=30,'Corps Terre séparés') end end
    level(5,10); assert(#Arena.interior==0); Hedgehog.fire(); assert(#Hedgehog.projectiles==12)
    level(7,1); local fish,jelly
    for _,v in ipairs(mobs) do assert(v.type~='fish','Aucun banc dans les Abysses'); if v.type=='abyss_fish' then fish=v elseif v.type=='light_jelly' then jelly=v end end
    assert(fish and jelly)
    player.x=Arena.width/2; player.y=450; fish.x=player.x-100; fish.y=462; local x=fish.x
    MobBehaviors.abyss_fish.update(fish,.1); assert(fish.x<x,'Le poisson fuit le joueur dans le noir')
    player.illuminated=6; x=fish.x; MobBehaviors.abyss_fish.update(fish,.1); assert(fish.x>x,'Le poisson charge le joueur éclairé')
    player.illuminated=0; Abyss.threads={{x=player.x+15,y=player.y+12,vx=0,vy=0,life=1,age=0,seed=0}}
    Abyss.update(.01); assert(player.illuminated==6 and not player.reset,'Fil lumineux révèle sans tuer')
    level(7,8); assert(Abyss.giant and #Abyss.bones>=11); Abyss.contact(); assert(not player.reset,'Départ loin du squelette')
    local first,second=Abyss.bones[1],Abyss.bones[4]; local gap=(first.x+second.x)/2
    player.x=gap-15
    for y=100,450,3 do player.y=y; Abyss.contact(); assert(not player.reset,'Passage réel entre les os') end
    local hit=false
    for _,b in ipairs(Abyss.bones) do
        for y=b.y-b.h/2,b.y+b.h/2,4 do for x=b.x-b.w/2,b.x+b.w/2,4 do
            if not hit and Abyss.boneTouches(b,x,y) then player.x=x-15; player.y=y-12; Abyss.contact(); hit=player.reset end
        end end
    end
    assert(hit,'Contact sur un os mortel')
    player.reset=false; player.x=Arena.width-75; player.y=505; Abyss.clock=5.49
    local x,y=player.x,player.y; local tx,ty=objet.larme.x,objet.larme.y; Abyss.update(.02)
    assert(Abyss.open and (player.x~=x or player.y~=y),'Bouche ouverte aspire le joueur')
    assert(objet.larme.x~=tx or objet.larme.y~=ty,'Aspiration de la larme')
    for _,key in ipairs({'skeleton_head','skeleton_open','skeleton_rib','skeleton_spine','skeleton_tail','abyss_fish'}) do
        local data=love.image.newImageData('assets/sprites/'..key..'.png'); local _,_,_,a=data:getPixel(0,0); assert(a==0,key..' transparent'); data:release()
    end
    print('PASS révision mondes: poursuite, pièges/cercles, météo niveau 5, foudre/mouettes, séparation Terre, hérisson, lumière/poissons, squelette et aspiration')
end
function T.visual()
    local tick=0
    love.update=function(dt)
        tick=tick+1
        if tick==1 then
            level(6,5); Realms.wind={x=20,y=3}; Realms.clock=2
            local m=mobs[1]; m.electric=true; Realms.lightning={{x=m.x,y=m.y,age=.9}}
            Realms.rain={{x=Arena.width*.6,y=400,age=.7},{x=Arena.width*.4,y=200,age=.9}}
            App.capture='world-revision-sky.png'
        elseif tick==5 then level(5,10); Hedgehog.fire(); App.capture='world-revision-earth.png'
        elseif tick==9 then level(7,8); Abyss.buildBones(); App.capture='world-revision-skeleton.png'
        elseif tick==13 then Abyss.clock=6; Abyss.open=true; Abyss.buildBones(); player.illuminated=6; player.x=Arena.width*.45; player.y=400; App.capture='world-revision-light.png'
        elseif tick==17 then level(4,10); Octopus.angle=.7; Octopus.releaseCrabs(); Octopus.updateCrabs(.91); App.capture='world-revision-octopus.png'
        elseif tick>=21 and tick<=41 and (tick-21)%4==0 then
            local worlds={1,6,5,4,7,2}; local w=worlds[(tick-21)/4+1]
            App.state='menu'; App.selectedWorld=w; UI.boardWorld=w; App.capture='world-revision-menu-'..w..'.png'
        elseif tick==45 then level(1,5); Campaign.carrier.dir='right'; Campaign.updateTear(0); App.capture='world-revision-carrier.png'
        elseif tick==49 then level(2,1); App.capture='world-revision-hell.png'
        elseif tick==53 then love.event.quit() end
    end
end
return T
