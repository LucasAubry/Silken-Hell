local T={}
function T.run()
    local function layout(world)
        local entities={{kind='spawn',x=80,y=520},{kind='tear',x=850,y=520},{kind='light',x=100,y=100},
            {kind='tunnel',x=100,y=430},{kind='tunnel',x=800,y=430},{kind='rain',x=400,y=400,phase=1},
            {kind='current',x=500,y=300,rx=30,ry=90,dx=1},{kind='hole',x=600,y=480,rx=20,ry=15},
            {kind='tornado',x=300,y=490},{kind='vent',x=750,y=250,rx=30,ry=20},
            {kind='lava',x=780,y=370,rx=25,ry=20}}
        for i,kind in ipairs({'merle','wasp','wasp','hellserpent','hedgehog','octopus','skeleton_fish'}) do entities[#entities+1]={kind='boss',type=kind,x=150+i*85,y=180} end
        for i,kind in ipairs({'fish','light_jelly','abyss_fish','lanternfish','worm','mole','gull','jelly','crab','imp','spinner'}) do entities[#entities+1]={kind='mob',type=kind,x=100+i*65,y=350,speed=50,electric=kind=='gull'} end
        return {world=world,level=1,width=960,height=600,entities=entities}
    end
    local kill=Hazards.kill
    for _,world in ipairs({1,2,4,5,6,7}) do
        local l=layout(world); assert(LayoutSchema.validate(l)); assert(Workshop.playLayout(l))
        assert(Bosses.items[4].kind=='wasp','Ancien serpent importé comme abeille')
        assert(#Bosses.items==7 and Realms.custom and #Realms.schools==1,'Toutes les rencontres importées')
        local first,second=Bosses.items[2].boss,Bosses.items[3].boss
        first.hp=4; assert(second.hp==9 and first.projectiles~=second.projectiles,'Boss identiques indépendants')
        Hazards.kill=function() end
        for _=1,12 do love.update(.016) end
        love.draw()
        assert(Realms.schools[1].age>0,'Poissons actifs dans chaque biome')
        assert(#Realms.electricTrails>0,'Traînées hors Ciel')
        for _,item in ipairs(Bosses.items) do item.boss.defeated=true; item.boss.hp=0 end
        objet.larme.taken=false; assert(Campaign.canCollect(),'Victoire après tous les boss')
        local b=Bosses.items[1].boss; b.defeated=false; b.hp=1; assert(not Campaign.canCollect(),'Un boss vivant bloque la sortie')
        Hazards.kill=kill
        local deaths=player.death; Hazards.kill(); love.update(.016)
        assert(player.death==deaths+1 and #Bosses.items==7 and Bosses.items[2].boss.hp==9,'Recommencement complet des rencontres')
    end
    Hazards.kill=kill
    -- Reuse resources and load the newest preview request without restarting LÖVE.
    local previous=love.filesystem.read('preview-request.json'); local heartbeat=love.filesystem.read('preview-heartbeat.txt')
    local image=Art.images.abyss_octopus.image
    App.preview=true
    love.filesystem.write('preview-request.json',require('json').encode({ticket='test-reload-'..love.timer.getTime(),layout=layout(1)}))
    local started=love.timer.getTime(); PreviewBridge.update(.2)
    print(string.format('PREVIEW_RELOAD_SECONDS=%.3f',love.timer.getTime()-started))
    assert(Campaign.world==1 and App.singleLevel and #Bosses.items==7 and Art.images.abyss_octopus.image==image,'Rechargement à chaud sans recharger les images')
    if previous then love.filesystem.write('preview-request.json',previous) else love.filesystem.remove('preview-request.json') end
    if heartbeat then love.filesystem.write('preview-heartbeat.txt',heartbeat) else love.filesystem.remove('preview-heartbeat.txt') end
    App.preview=false; App.leaveCustom()
    local oldRequest=Online.request; local row={id='id',title='Carte de test',author='QA',world=1,stars=1,starred=false}
    Online.request=function(path,body,cb) if body then cb({stars=2,starred=true},200) else cb({maps={row}},200) end end
    Workshop.star(row); assert(row.starred and row.stars==2)
    Online.request=oldRequest
    for _,state in ipairs({'menu','workshop','achievements','customVictory'}) do App.state=state; love.draw() end
    App.leaveCustom()
    print('PASS workshop/editor: mixed biomes, duplicate bosses, all deaths/reset, completion gate, hot reload, stars and menus')
end
function T.visual()
    local tick=0
    love.update=function()
        tick=tick+1
        if tick==1 then App.leaveCustom(); App.capture='menu-workshop.png'
        elseif tick==5 then App.state='workshop'; Workshop.rows={{id='sample',title='Les gardiens oubliés',author='Exemple local',world=5,stars=12,starred=true}}; Workshop.status='Aperçu de présentation · données de test locales'; App.capture='workshop-preview.png'
        elseif tick==9 then App.state='achievements'; App.capture='achievements-empty.png'
        elseif tick==13 then Campaign.select(7); player.level=2; reset_level(); App.state='playing'; player.illuminated=6; App.capture='abyss-strong-light.png'
        elseif tick==17 then love.event.quit() end
    end
end
return T
