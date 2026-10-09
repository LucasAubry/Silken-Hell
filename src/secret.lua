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
        elseif entry.type=='storm' then entry.name='Merle noir';entry.art='merle_flight_down'
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
    local list=S.hardcore and S.demonBosses or S.category=='mobs' and S.creatures or S.normalBosses
    S.portals={};for i,p in ipairs(list) do S.portals[i]=p end
    S.perPage=#list;S.pages=#list;S.page=math.max(1,math.min(S.page or 1,S.pages))
    S.positions={};local edge=0
    for i,p in ipairs(list) do local width=p.type=='skeleton_head' and 620 or p.type=='wasp' and 500 or 360;S.positions[i]=edge+width/2;edge=edge+width end
    S.hallWidth=math.max(Arena.width,edge)
    S.pending=nil;S.upReady=false
end
function S.turnPage(step)
    S.page=math.max(1,math.min(S.pages,(S.nearest or S.page)+step))
    S.x=S.position(S.page);S.y=510;S.cooldown=.2;S.upReady=false
end
function S.switchCategory()
    S.category=S.category=='mobs' and 'boss' or 'mobs';S.page=1;S.refresh();S.x=S.position(1);S.cameraX=0
end
function S.ask(index)
    S.pending=S.portals[index];S.confirmYes=false;S.upReady=false;S.confirmRepeat=0
end
function S.cancel()
    S.pending=nil;S.upReady=false;S.cooldown=.25
end
function S.confirm()
    local entry=S.pending;if not entry then return end
    if not S.confirmYes then S.cancel();return end
    S.pending=nil;S.launch(entry)
end
function S.key(key,isrepeat)
    if not S.pending then return false end
    if key=='escape' then S.cancel()
    elseif key=='left' or key==Profile.keys.left then S.confirmYes=true
    elseif key=='right' or key==Profile.keys.right then S.confirmYes=false
    elseif not isrepeat and (key=='return' or key=='space') then S.confirm() end
    return true
end
function S.launch(p)
    S.returnSelection={page=S.page,category=S.category,hardcore=S.hardcore,x=S.x}
    App.hardcore=false;Hardcore.notice=nil;App.practice=nil;App.workshopMap=nil;App.preview=false
    local function start(world)
        App.start(world)
        if App.state=='playing' and not Replay.playing then require('run_start').startCountdown() end
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
function S.position(i) return (S.positions and S.positions[i]) or 180,510 end
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
    Ending.active=false;require('final_spider').active=false;Replay.input=nil;S.facing='down'
    S.x=back and back.x or S.position(1);S.y=510;S.cameraX=math.max(0,math.min(S.hallWidth-Arena.width,S.x-Arena.width*.5));S.cooldown=.3;S.upReady=false;S.pending=nil;App.state='bossWorld'
end
function S.update(dt)
    local dx,dy=Input.move()
    if S.pending then
        if dx<-.5 then S.confirmYes=true elseif dx>.5 then S.confirmYes=false end
        return
    end
    S.cooldown=math.max(0,S.cooldown-dt)
    local speed=Input.slow() and 240 or 380
    S.x=math.max(55,math.min(S.hallWidth-55,S.x+dx*speed*math.min(dt,.05)));S.y=510
    if dx~=0 then S.facing=dx>0 and 'right' or 'left' end
    local camera=math.max(0,math.min(S.hallWidth-Arena.width,S.x-Arena.width*.5))
    S.cameraX=(S.cameraX or 0)+(camera-(S.cameraX or 0))*math.min(1,dt*9)
    local index=1
    for i=2,#S.portals do if math.abs(S.x-S.position(i))<math.abs(S.x-S.position(index)) then index=i end end
    S.nearest=index;S.page=index
    if dy>-.3 then S.upReady=true end
    if dy<-.55 and S.upReady and S.cooldown<=0 and math.abs(S.x-S.position(index))<58 then S.ask(index) end
end
function S.drawWorld() require('sanctuary_scene').draw(S) end
function S.draw()
    UI.text('LE SANCTUAIRE',300,24,'heading',{1,1,.94},600,'center')
    if S.pending then
        local g=love.graphics;g.push('all');g.origin();g.setColor(.005,.008,.015,.78);g.rectangle('fill',0,0,g.getWidth(),g.getHeight());g.pop()
        UI.panel(275,235,650,280)
        local L=require('localization')
        UI.text(L.text('Êtes-vous sûr de vouloir affronter %s ?',L.render(S.pending.name)),310,275,'medium',{1,.95,.8},580,'center')
        UI.button('Oui',325,419,255,50,function() S.confirmYes=true;S.confirm() end,false,S.confirmYes)
        UI.button('Non',620,419,255,50,S.cancel,false,not S.confirmYes)
        return
    end
    UI.button(S.category=='mobs' and 'Voir les boss' or 'Voir les créatures',100,78,260,40,S.switchCategory)
    UI.button('Classement hardcore',390,78,310,40,function() UI.boardReturn='bossWorld';UI.boardWorld=8;UI.boardHardcore=true;UI.boardPage=1;App.state='rankings' end)
    UI.button('Choix des mondes',730,78,350,40,function() WorldMap.hardcore=S.hardcore;WorldMap.open() end)
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
