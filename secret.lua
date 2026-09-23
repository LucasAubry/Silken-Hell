local S={x=90,returnX=90}
S.portals={}
function S.catalog()
    S.normalBosses={};S.creatures={}
    for _,e in ipairs(require('designer.catalog')) do
        if e.kind=='boss' or e.kind=='mob' then
            local entry={name=e.name,art=e.art,world=e.world,type=e.type,kind=e.kind,speed=e.speed,rota=e.rota,radius=e.radius}
            table.insert(e.kind=='boss' and S.normalBosses or S.creatures,entry)
        end
    end
end
function S.refresh()
    if not S.normalBosses then S.catalog() end
    local list=S.hardcore and {{world=14,name='Sœurs de lave',art='wasp_down',hardcore=true}} or S.category=='mobs' and S.creatures or S.normalBosses
    S.page=math.max(1,math.min(S.page or 1,math.ceil(#list/6)))
    S.pages=math.ceil(#list/6);S.portals={}
    for i=(S.page-1)*6+1,math.min(#list,S.page*6) do S.portals[#S.portals+1]=list[i] end
end
function S.turnPage(step) S.page=(S.page-1+step)%S.pages+1;S.refresh() end
function S.launch(p)
    App.hardcore=false;Hardcore.notice=nil
    if p.hardcore then S.duel=nil;App.start(14);return end
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
    return Arena.width*(.23+((i-1)%3)*.27),i<=3 and 175 or 425
end
function S.open()
    if Replay then Replay.recording=false end
    if not Worlds.canEnter(8) and os.getenv('SILKEN_TEST')~='1' then return end
    App.hardcore=false;Hardcore.notice=nil;App.practice=nil
    App.selectedWorld=8
    App.sessionLayout=nil;App.singleLevel=false;App.workshopMap=nil;App.custom=false
    S.duel=nil;S.page=1;S.category=S.category or 'boss';S.refresh()
    S.x=Arena.width*.5;S.y=300;S.cooldown=.6;App.state='bossWorld'
end
function S.update(dt)
    S.cooldown=math.max(0,S.cooldown-dt)
    local dx,dy=Input.move();local speed=Input.slow() and 300 or 540
    S.x=math.max(45,math.min(Arena.width-45,S.x+dx*speed*math.min(dt,.05)))
    S.y=math.max(50,math.min(550,S.y+dy*speed*math.min(dt,.05)))
    if dx~=0 then S.facing=dx>0 and 'right' or 'left' elseif dy~=0 then S.facing=dy>0 and 'down' or 'up' end
    if S.cooldown>0 then return end
    if S.x>Arena.width-65 and math.abs(S.y-300)<55 then S.hardcore=not S.hardcore;S.page=1;S.refresh();S.x=Arena.width-130;S.cooldown=.6;return end
    for i,p in ipairs(S.portals) do
        local x,y=S.position(i)
        if (S.x-x)^2+(S.y-y)^2<35^2 then
            S.launch(p);return
        end
    end
end
function S.drawWorld()
    local g=love.graphics
    BiomeFloor.draw(8,Arena.width,600,UI.clock)
    g.push('all');g.setBlendMode('add')
    for i=1,6 do local x,y=S.position(i)
        for r=5,1,-1 do g.setColor(.8,.85,1,.009);g.ellipse('fill',x,y+12,35+r*18,22+r*13) end
    end
    for i=1,30 do local x=(i*137)%Arena.width;local y=(i*83-UI.clock*5)%600
        g.setColor(1,1,.95,.18+.12*math.sin(UI.clock+i));g.circle('fill',x,y,1)
    end
    g.pop()
    g.setColor(.28,.26,.28)
    g.rectangle('fill',0,0,Arena.width,22);g.rectangle('fill',0,578,Arena.width,22)
    g.rectangle('fill',0,0,22,600);g.rectangle('fill',Arena.width-22,0,22,600)
    g.setColor(.72,.72,.69);g.rectangle('fill',Arena.width-42,240,42,120)
    g.setColor(.055,.025,.02);g.rectangle('fill',Arena.width-36,248,36,104)
    g.setColor(1,1,.94);g.line(Arena.width-30,260,Arena.width-15,260,Arena.width-15,340,Arena.width-30,340)
    g.circle('fill',Arena.width-24,300,3)
    UI.text(S.hardcore and 'Normal' or 'Mode démon',Arena.width-125,360,'small',{1,.7,.3},110,'center')
    for i,p in ipairs(S.portals) do local x,y=S.position(i)
        g.setColor(.1,.065,.075);g.ellipse('fill',x,y+18,65,31)
        g.setColor(.9,.9,.84);g.ellipse('line',x,y+18,65,31)
        g.setColor(1,1,1)
        if p.hardcore then g.setShader(Wasp.lavaMaterial(UI.clock)) end
        local breath=math.sin(UI.clock*1.7+i*.9)*.018
        local art=Art.images[p.art];local h=80*art.h/art.w
        -- Feet stay anchored: only the sprite's chest expands, no wandering.
        Art.draw(p.art,x,y-h*breath*.5,80*(1+breath*.35),0,h*(1+breath));g.setShader()
        UI.text(p.name,x-125,y+53,'body',{1,.8,.5},250,'center')
    end
    g.setColor(0,0,0,.4);g.ellipse('fill',S.x,S.y+22,22,10)
    g.setColor(1,1,1);Characters.draw(S.x,S.y,62,S.facing or 'down')
end
function S.draw()
    UI.text(S.hardcore and 'SANCTUAIRE · MODE DÉMON' or 'LE SANCTUAIRE',300,24,'heading',{1,1,.94},600,'center')
    UI.text('Approche une miniature pour entrer dans son duel.',300,68,'small',{.8,.85,.9},600,'center')
    if not S.hardcore then
        UI.button(S.category=='mobs' and 'Voir les boss' or 'Voir les créatures',100,655,240,40,function() S.category=S.category=='mobs' and 'boss' or 'mobs';S.page=1;S.refresh() end)
        UI.button('Page '..S.page..' / '..S.pages,350,655,190,40,function() S.turnPage(1) end)
    end
    UI.button('Classements',550,655,220,40,function() UI.boardWorld=14;UI.boardPage=1;App.state='rankings' end)
    UI.button('Choix des mondes',790,655,250,40,function() App.state='worlds' end)
end
function S.configure()
    if not Worlds.isSecret(Campaign.world) then return end
    if Campaign.world==14 then
        local layout=require('json').decode(assert(love.filesystem.read('assets/hardcore-wasp-layout.json')))
        LevelLayouts.apply(layout)
        for _,item in ipairs(Bosses.items) do if item.kind=='wasp' then item.boss.hardcore=true;item.boss.name='Les Sœurs de lave' end end
    else
        for _,b in ipairs({Raven,Storm,Hedgehog,Octopus,Abyss}) do if b.active then b.movementRate=1.35;b.attackRate=1.3 end end
    end
end
return S
