local S={x=90,returnX=90}
S.portals={}
function S.inArena() return S.duel~=nil or (Campaign and Worlds.isSecret(Campaign.world)) end
function S.returnToSanctuary()
 if Replay and Replay.playing then Replay.stop() end
 S.open()
end
function S.catalog()
    S.normalBosses={};S.creatures={}
    for _,e in ipairs(require('designer.catalog')) do
        if e.kind=='boss' or e.kind=='mob' then
            local entry={name=e.name,art=e.art,world=e.world,type=e.type,kind=e.kind,speed=e.speed,rota=e.rota,radius=e.radius}
            table.insert(e.kind=='boss' and S.normalBosses or S.creatures,entry)
        end
    end
    S.normalBosses[#S.normalBosses+1]={kind='boss',type='final_spider',name='La Gardienne de la Soie',art='final_queen',world=3}
    table.sort(S.normalBosses,function(a,b) return Worlds.rank(a.world)<Worlds.rank(b.world) end)
    for _,entry in ipairs(S.normalBosses) do
        if entry.type=='merle' then entry.art='merle_egg';entry.name='L’Œuf du Merle'
        elseif entry.type=='storm' then entry.name='Merle noir';entry.art='merle_flight_down' end
    end
    S.demonBosses={}
    local ids={[1]=9,[6]=10,[5]=11,[4]=12,[7]=13,[2]=14}
    for _,entry in ipairs(S.normalBosses) do
        local copy={};for k,v in pairs(entry) do copy[k]=v end
        if ids[entry.world] then copy.world=ids[entry.world];copy.hardcore=true;S.demonBosses[#S.demonBosses+1]=copy end
    end
end
function S.refresh()
    if not S.normalBosses then S.catalog() end
    local list=S.hardcore and S.demonBosses or S.category=='mobs' and S.creatures or S.normalBosses
    S.perPage=(S.hardcore or S.category~='mobs') and 1 or 6
    S.page=math.max(1,math.min(S.page or 1,math.ceil(#list/S.perPage)))
    S.pages=math.ceil(#list/S.perPage);S.portals={}
    for i=(S.page-1)*S.perPage+1,math.min(#list,S.page*S.perPage) do S.portals[#S.portals+1]=list[i] end
end
function S.turnPage(step)
    local page=math.max(1,math.min(S.pages,S.page+step))
    if page==S.page then return end
    S.page=page;S.refresh();S.cooldown=.6;S.charge=0;S.charging=nil
    S.x=Arena.width*(step>0 and .15 or .85);S.y=478
end
function S.launch(p)
    S.returnSelection={page=S.page,category=S.category,hardcore=S.hardcore}
    App.hardcore=false;Hardcore.notice=nil;App.practice=nil;App.workshopMap=nil;App.preview=false
    if p.hardcore then S.duel=nil;App.singleLevel=false;App.sessionLayout=nil;App.start(p.world);return end
    if p.kind=='boss' then
        S.duel={kind='boss',name=p.name,time=0};App.sessionLayout=nil;App.singleLevel=true
        App.practice=p.world==3 and 1 or 10;LevelLayouts.disabled=false;App.start(p.world);return
    end
    local world=p.world;local kind=p.type
    if kind=='skeleton_head' then kind='skeleton_fish' end
    local enemy={kind=p.kind,type=kind,x=480,y=p.kind=='boss' and 250 or 170,speed=p.speed,rota=p.rota or 1,radius=p.radius or 60}
    local entities={{kind='spawn',x=480,y=510},enemy,{kind='tear',x=480,y=300}}
    if kind=='skeleton_fish' then entities[#entities+1]={kind='light',x=100,y=480} end
    S.duel={kind=p.kind,name=p.name,time=0}
    App.sessionLayout={world=world,level=1,width=960,height=600,entities=entities}
    App.singleLevel=true;App.workshopMap=nil;LevelLayouts.disabled=false
    if Profile.name=='' then Profile.name='Joueur' end
    App.start(world)
end
function S.updateDuel(dt)
    if not S.duel or App.state~='playing' then return end
    if player.abyssSpit or player.abyssHeld then return end
    if Campaign.biome==7 and player.circleLight and (player.charges or 0)==0 then Abyss.charge(6) end
    if S.duel.kind=='mob' then
        S.duel.time=S.duel.time+dt;objet.larme.taken=true
        if S.duel.time>=20 then App.state='customVictory';if Replay and not Replay.playing then Replay.finish() end end
    end
end
function S.position(i)
    if S.perPage==1 then return Arena.width*.5,478 end
    return Arena.width*(.23+((i-1)%3)*.27),i<=3 and 220 or 450
end
function S.open(demon)
    local back=demon==nil and S.returnSelection or nil
    if back then S.hardcore=back.hardcore end
    if demon~=nil then S.hardcore=demon==true end
    if Replay then Replay.recording=false end
    if not Worlds.canEnter(8) and os.getenv('SILKEN_TEST')~='1' then return end
    App.hardcore=false;Hardcore.notice=nil;App.practice=nil
    App.selectedWorld=8
    App.sessionLayout=nil;App.singleLevel=false;App.workshopMap=nil;App.custom=false
    S.duel=nil;S.page=back and back.page or 1;S.category=back and back.category or 'boss';S.charge=0;S.charging=nil;S.refresh()
    Ending.active=false;require('final_spider').active=false;Replay.input=nil;S.facing='down'
    S.x=Arena.width*.15;S.y=470;S.cooldown=.6;App.state='bossWorld'
end
function S.update(dt)
    S.cooldown=math.max(0,S.cooldown-dt)
    local dx,dy=Input.move();local norm=math.max(1,math.sqrt(dx*dx+dy*dy));dx,dy=dx/norm,dy/norm;local speed=Input.slow() and 300 or 540
    S.x=math.max(45,math.min(Arena.width-45,S.x+dx*speed*math.min(dt,.05)))
    S.y=math.max(50,math.min(550,S.y+dy*speed*math.min(dt,.05)))
    if dx~=0 then S.facing=dx>0 and 'right' or 'left' elseif dy~=0 then S.facing=dy>0 and 'down' or 'up' end
    if S.cooldown>0 then return end
    if dx<0 and S.x<65 then S.turnPage(-1);return end
    if dx>0 and S.x>Arena.width-65 then S.turnPage(1);return end
    local selected
    for i,p in ipairs(S.portals) do
        local x,y=S.position(i)
        if ((S.x-x)/38)^2+((S.y+22-y)/17)^2<=1 then selected=i;break end
    end
    if not selected then S.charging=nil;S.charge=0;return end
    if S.charging~=selected then S.charging=selected;S.charge=0 end
    S.charge=math.min(1.4,(S.charge or 0)+dt)
    if S.charge>=1.4 then S.launch(S.portals[selected]);S.charge=0;S.charging=nil end
end
function S.drawWorld() require('sanctuary_scene').draw(S) end
function S.draw()
    UI.text(S.hardcore and 'SANCTUAIRE · MODE DÉMON' or 'LE SANCTUAIRE',300,24,'heading',{1,1,.94},600,'center')
    if S.hardcore and S.portals[1] then
        local index=Characters.crownedByWorld[Worlds.biome(S.portals[1].world)]
        if index then
            love.graphics.setColor(1,1,1);Characters.portrait(index,1070,590,55,'down',not Characters.unlocked(index))
            UI.text(Characters.unlocked(index) and 'Couronne obtenue' or 'Récompense Démon',950,622,'small',{1,.84,.4},240,'center')
        end
    end
    if not S.hardcore then
        UI.button(S.category=='mobs' and 'Voir les boss' or 'Voir les créatures',100,655,240,40,function() S.category=S.category=='mobs' and 'boss' or 'mobs';S.page=1;S.charge=0;S.charging=nil;S.refresh() end)
    end
        UI.button('‹',350,655,45,40,function() S.turnPage(-1) end)
        UI.text(S.page..' / '..S.pages,403,666,'body',{.75,.81,.88},80,'center')
        UI.button('›',490,655,45,40,function() S.turnPage(1) end)
    UI.button('Classements',550,655,220,40,function() UI.boardReturn='bossWorld';UI.boardWorld=S.hardcore and S.portals[1].world or S.portals[1].world;UI.boardPage=1;App.state='rankings' end)
    UI.button('Choix des mondes',790,655,250,40,function() WorldMap.hardcore=S.hardcore;WorldMap.open() end)
end
function S.configure()
    if not Worlds.isSecret(Campaign.world) then return end
    if Campaign.world==14 then
        local layout=require('json').decode(assert(love.filesystem.read('assets/hardcore-wasp-layout.json')))
        LevelLayouts.apply(layout)
        for _,item in ipairs(Bosses.items) do if item.kind=='wasp' then item.boss.hardcore=true;item.boss.name='Les Guêpes brûlées · Démon' end end
    else
        for _,b in ipairs({Raven,Storm,Hedgehog,Octopus,Abyss}) do if b.active then b.movementRate=1.35;b.attackRate=1.3 end end
    end
end
return S
