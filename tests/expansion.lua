local T={}
local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
local function bonePoint()
    for _,b in ipairs(Abyss.bones) do
        for y=b.y-b.h/2,b.y+b.h/2,3 do for x=b.x-b.w/2,b.x+b.w/2,3 do
            if Abyss.boneTouches(b,x,y) then return x,y end
        end end
    end
    error('No bone pixel')
end
function T.defeatAbyss()
    for _=1,8 do
        player.reset=false; player.abyssGrace=0; player.abyssSpit=nil
        Abyss.open=true; Abyss.breathAt=Abyss.clock; Abyss.buildBones()
        local x,y=Abyss.mouth(); player.x=x-15; player.y=y-12; Abyss.charge(6)
        local hp=Abyss.hp; Abyss.contact()
        assert(Abyss.swallowed and Abyss.hp==hp and player.electrified==0 and not player.reset)
        Abyss.update(.61); Abyss.updatePlayer(.3)
        assert(Abyss.hp==hp-1 and not player.abyssHeld and not player.reset)
    end
    assert(Abyss.defeated and Campaign.canCollect())
end
function T.run()
    for n=1,10 do level(7,n); assert(#Realms.vents==0,'Aucun piège électrique dans les Abysses') end
    level(7,2); local swimmer
    for _,m in ipairs(mobs) do if m.type=='light_jelly' then swimmer=m end end
    assert(swimmer and Art.images.abyss_octopus)
    MobBehaviors.light_jelly.update(swimmer,.1); MobBehaviors.light_jelly.draw(swimmer)
    local mesh=Art.images.abyss_octopus.swimMesh; local x,y=mesh:getVertex(1)
    swimmer.age=swimmer.age+.4; MobBehaviors.light_jelly.draw(swimmer)
    local xx,yy=mesh:getVertex(1); assert(x~=xx or y~=yy,'Animation ondulante')
    level(6,3); local gull
    for _,m in ipairs(mobs) do if m.type=='gull' then gull=m; break end end
    gull.electric=true; gull.x=200; gull.y=250; player.x=700; player.y=500
    Realms.moveGull(gull,.1); assert(#Realms.electricTrails>0)
    local trace=Realms.electricTrails[1]; player.x=(trace.x+trace.tx)/2-15; player.y=(trace.y+trace.ty)/2-12
    gull.x=600; gull.y=100; player.reset=false
    Realms.updateElectricTrails(.1); assert(player.reset,'La traînée tue même loin de la mouette')
    player.reset=false; Realms.updateElectricTrails(3); assert(#Realms.electricTrails==0 and not player.reset,'Traînée expirée inoffensive')
    reset_level(); assert(#Realms.electricTrails==0,'Traînées effacées au recommencement')
    level(4,4); local crab
    for _,m in ipairs(mobs) do if m.type=='crab' then crab=m end end
    assert(crab,'Crabes dans les niveaux Océan')
    crab.x=150; crab.y=250; player.x=500; player.y=238; crab.vx=1; crab.vy=0
    local x=crab.x; MobBehaviors.crab.update(crab,.1); local normal=crab.x-x
    crab.x=x; player.ink=4; MobBehaviors.crab.update(crab,.1); assert(crab.x-x>normal*1.6,'Encre accélère les crabes')
    Octopus.rider={}; crab.vx=1; crab.vy=0; player.x=40
    local x=crab.x; MobBehaviors.crab.update(crab,.1); assert(crab.x>x,'Pas de poursuite du joueur pendant la rotation')
    Octopus.rider=nil
    level(7,2); local p=levels[2].larme_position[1]; player.x=p.x; player.y=p.y+27; Abyss.update(0)
    assert(player.illuminated==6,'Cercle illumine le joueur')
    level(7,10); assert(Abyss.boss and not Campaign.canCollect())
    local x,y=Abyss.bones[1].x,Abyss.bones[1].y; local hx,hy=Abyss.head.x,Abyss.head.y; Abyss.motionTime=2; Abyss.buildBones(); assert(Abyss.bones[1].x==x and Abyss.bones[1].y==y and (Abyss.head.x~=hx or Abyss.head.y~=hy),'Os fixes, tête mobile')
    assert(Abyss.bones[4].x-Abyss.bones[1].x>=130,'Os suffisamment espacés')
    T.defeatAbyss()
    for _,w in ipairs({1,2,4,5,6,7}) do for n=1,10 do
        level(w,n)
        local imported=LevelLayouts.snapshot(); local expected=#mobs
        assert(LevelLayouts.apply(imported) and #mobs==expected,'Import complet '..w..':'..n)
        love.draw()
        local sites=Abyss.boss and Abyss.lightSites or levels[n].larme_position
        for _,list in ipairs({Realms.vents,Realms.holes,Hazards.lava,Realms.tornadoes}) do for _,h in ipairs(list) do
            for _,s in ipairs(sites) do
                local sx,sy=Abyss.boss and s.x or s.x+15,Abyss.boss and s.y or s.y+39
                local r=math.max(h.rx or 45,h.ry or 30)+26
                assert((h.x-sx)^2+(h.y-sy)^2>=r*r,'Cercle hors piège '..w..':'..n)
            end
        end end
    end end
    level(4,3); local layout=LevelLayouts.snapshot(); local count=#mobs
    layout.entities[#layout.entities+1]={kind='mob',type='crab',x=80,y=300,speed=177}
    local original=love.filesystem.read('custom_levels.json')
    love.filesystem.write('custom_levels.json',require('json').encode({version=1,levels={['4:3']=layout}}))
    local ok,err=pcall(function()
        reset_level(); assert(#mobs==count+1 and mobs[#mobs].type=='crab' and mobs[#mobs].speed==177,'Éditeur appliqué au moteur')
        local currents=#Realms.current; love.resize(1600,900); assert(#Realms.current==currents and #mobs==count+1,'Édition conservée au redimensionnement')
        love.resize(love.graphics.getDimensions())
    end)
    if original then love.filesystem.write('custom_levels.json',original) else love.filesystem.remove('custom_levels.json') end
    assert(ok,err)
    for _,key in ipairs({'luminous_jelly','electric_vent_idle','electric_vent_charge','electric_vent_active','electric_vent_spent'}) do
        local d=love.image.newImageData('assets/sprites/'..key..'.png'); local _,_,_,a=d:getPixel(0,0); assert(a==0,'PNG alpha '..key); d:release()
    end
    print('PASS expansion: crabes/encre, cercles lumineux, Léviathan, protection pièges, chargement éditeur')
end
function T.visual()
    local tick=0
    love.update=function()
        tick=tick+1
        if tick==1 then level(7,2); player.illuminated=6; for _,m in ipairs(mobs) do if m.type=='light_jelly' then m.x=player.x+100; m.y=player.y; m.age=1 elseif m.type=='abyss_fish' then m.x=player.x+180; m.y=player.y+40 end end; App.capture='abyss-swimmer-eyes.png'
        elseif tick==5 then level(6,3); player.x=700; player.y=500; for _,m in ipairs(mobs) do if m.type=='gull' then m.electric=true; for _=1,70 do Realms.moveGull(m,.016) end end end; App.capture='sky-electric-trails.png'
        elseif tick==9 then level(7,10); player.illuminated=6; App.capture='expansion-abyss.png'
        elseif tick==13 then love.event.quit() end
    end
end
return T
