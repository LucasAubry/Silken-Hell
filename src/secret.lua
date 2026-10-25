local S={x=90,returnX=90}
S.portals={}
function S.inArena() return S.duel~=nil or (Campaign and (Campaign.world==8 or Worlds.isSecret(Campaign.world))) end
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
        elseif entry.type=='storm' then entry.name='L’Escargot d’orage';entry.art='cloud_snail_down'
        elseif entry.type=='skeleton_head' then entry.name='Le Monstre d’os' end
    end
    S.demonBosses={}
    local ids={[1]=9,[6]=10,[5]=11,[4]=12,[7]=13,[2]=14}
    for _,entry in ipairs(S.normalBosses) do
        local copy={};for k,v in pairs(entry) do copy[k]=v end
        if ids[entry.world] then copy.world=ids[entry.world];copy.hardcore=true;S.demonBosses[#S.demonBosses+1]=copy end
    end
end
function S.rushBoss(n)
    if not S.normalBosses then S.catalog() end
    return S.normalBosses[n]
end
function S.refresh()
    if not S.normalBosses then S.catalog() end
    local list=S.normalBosses
    S.portals={};for i,p in ipairs(list) do S.portals[i]=p end
    S.perPage=#list;S.pages=#list;S.page=math.max(1,math.min(S.page or 1,S.pages))
    S.hallWidth=Arena.width;S.pending=nil;S.upReady=false
end
function S.navigate(dx,dy)
    if math.abs(dx)>=math.abs(dy) and math.abs(dx)>.1 then
        local page=math.max(1,math.min(#S.portals,S.page+(dx>0 and 1 or -1)))
        if page~=S.page then S.page=page;S.nearest=page;Audio.play('selection') end
        return
    end
    local C=require('sanctuary_arrival');local x,y=C.bossPosition(S.page,#S.portals,Arena.width)
    local best,score
    for i=1,#S.portals do if i~=S.page then
        local bx,by=C.bossPosition(i,#S.portals,Arena.width);local vx,vy=bx-x,by-y
        local distance=math.sqrt(vx*vx+vy*vy);local alignment=(vx*dx+vy*dy)/distance
        if alignment>.12 then
            local cost=distance/(alignment*alignment)
            if not score or cost<score then best,score=i,cost end
        end
    end end
    if best then S.page=best;S.nearest=best;Audio.play('selection') end
end
function S.key(key,isrepeat)
    if S.intro then return key~='escape' end
    if key=='escape' then return false end
    if not isrepeat and (key=='return' or key=='space') then S.launch(S.portals[S.page]) end
    return true
end
function S.launch(p)
    S.returnSelection={page=S.page,category=S.category,hardcore=S.hardcore,x=S.x}
    App.hardcore=false;Hardcore.notice=nil;App.practice=nil;App.workshopMap=nil;App.preview=false
    local function start(world)
        App.start(world)
        if App.state=='playing' and not Replay.playing then require('run_start').waitForInput() end
    end
    if p.hardcore then S.duel=nil;App.singleLevel=false;App.sessionLayout=nil;start(p.world);return end
    if p.kind=='boss' then
        S.duel={kind='boss',name=p.name,time=0};App.sessionLayout=nil;App.singleLevel=true
        App.practice=p.world==3 and 1 or 10;LevelLayouts.disabled=false;start(p.world);return
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
    start(world)
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
function S.position(i) return require('sanctuary_arrival').bossPosition(i,#S.portals,Arena.width) end
function S.open(demon)
    if demon==true then App.openEntry(8,true);return end
    local back=demon==nil and S.returnSelection or nil
    S.hardcore=false

    if Replay then Replay.recording=false end
    if not Worlds.canEnter(8) and os.getenv('SILKEN_TEST')~='1' then return end
    App.hardcore=false;Hardcore.notice=nil;App.practice=nil
    App.selectedWorld=8;WorldMap.hardcore=false;UI.boardHardcore=false
    App.sessionLayout=nil;App.singleLevel=false;App.workshopMap=nil;App.custom=false
    S.duel=nil;S.page=back and back.page or 1;S.category=back and back.category or 'boss';S.charge=0;S.charging=nil;S.refresh()
    Ending.active=false;require('final_spider').active=false;Replay.input=nil;S.facing='up';S.walkMoving=false;S.walkPhase=0
    S.x=Arena.width*.5;S.y=485;S.cameraX=0;S.turn=0;S.navHeld=false;S.cooldown=.3;S.upReady=false;S.pending=nil;App.state='bossWorld'
    S.presentation=require('sanctuary_arrival').begin();S.intro=S.presentation
end
function S.update(dt)
    local C=require('sanctuary_arrival')
    if S.presentation then C.update(S.presentation,dt) end
    if S.intro then
        if S.intro.age>=C.duration then S.intro=nil;S.cooldown=.25;S.navHeld=true end
        return
    end
    local dx,dy=Input.move()
    -- Arrow keys remain available even when movement is remapped to ZQSD.
    if love.keyboard.isDown('left') then dx=-1 elseif love.keyboard.isDown('right') then dx=1 end
    if love.keyboard.isDown('up') then dy=-1 elseif love.keyboard.isDown('down') then dy=1 end
    S.cooldown=math.max(0,S.cooldown-dt)
    if math.abs(dx)+math.abs(dy)<.35 then S.navHeld=false;S.cooldown=0
    elseif not S.navHeld or S.cooldown<=0 then
        S.navigate(dx,dy);S.cooldown=S.navHeld and .18 or .35;S.navHeld=true
    end
    local bx,by=C.bossPosition(S.page,#S.portals,Arena.width)
    local facing=math.abs(bx-S.x)<Arena.width*.12 and 'up' or bx<S.x and 'left' or 'right'
    if S.facing~=facing then S.facing=facing;S.turnBlend=1 end
    S.turnBlend=(S.turnBlend or 0)*math.exp(-dt*12)
end
function S.mousepressed(x,y)
    if S.intro then return true end
    local scale,vx,vy=App.viewport(love.graphics.getDimensions())
    x,y=(x-vx)/scale,(y-vy)/scale
    local C=require('sanctuary_arrival');local best,distance
    for i,p in ipairs(S.portals) do
        local bx,by=C.bossPosition(i,#S.portals,Arena.width)
        local radius=p.type=='skeleton_head' and 108 or p.type=='wasp' and 98 or 82
        local groupScale=C.layoutScale(Arena.width)
        local d=((x-bx)/(radius*groupScale))^2+((y-by)/(112*groupScale))^2
        if d<=1 and (not distance or d<distance) then best,distance=i,d end
    end
    if best then S.page=best;S.nearest=best;Audio.play('selection');return true end
    return false
end
function S.drawWorld() require('sanctuary_arrival').draw(S) end
function S.draw()
    if S.intro then return end
    UI.text('LE SANCTUAIRE',300,30,'heading',{1,1,.94},600,'center')
    local boss=S.portals[S.page]
    UI.text(UI.ellipsize(require('localization').render(boss.name),'body',540),330,710,'body',{1,.85,.51},540,'center')
    UI.button('Mondes',65,642,220,48,function() WorldMap.hardcore=false;WorldMap.open() end)
    UI.button('Affronter',915,642,220,48,function() S.launch(boss) end)
end
function S.configure()
    if not Worlds.isSecret(Campaign.world) and Campaign.world~=8 then return end
    if Campaign.world==14 or Campaign.world==8 and Campaign.biome==2 then
        local layout=require('json').decode(assert(love.filesystem.read('assets/hardcore-wasp-layout.json')))
        LevelLayouts.apply(layout)
        for _,item in ipairs(Bosses.items) do if item.kind=='wasp' then item.boss.hardcore=true;item.boss.name='Les Guêpes brûlées · Hardcore' end end
    else
        for _,b in ipairs({Raven,Storm,Hedgehog,Octopus,Abyss}) do if b.active then b.movementRate=1.35;b.attackRate=1.3 end end
    end
end
return S
