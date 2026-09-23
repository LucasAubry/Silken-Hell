local T={}
function T.run()
    LevelLayouts.disabled=true;Campaign.select(7);player.level=8;reset_level();App.state='playing'
    local layout={world=7,level=8,width=Arena.width,height=600,entities={
        {kind='spawn',x=80,y=520},{kind='tear',x=300,y=500},
        {kind='abyss_part',type='skeleton_tail',x=160,y=270,w=100,h=145,rotation=25},
        {kind='abyss_part',type='skeleton_rib',x=350,y=200,w=25,h=130,rotation=180},
        {kind='abyss_part',type='skeleton_spine',x=350,y=300,w=22,h=28,rotation=0}}}
    assert(LayoutSchema.validate(layout));LevelLayouts.apply(layout)
    assert(#AbyssTerrain.parts==3 and not Bosses.alive() and not Bosses.hud().active and not objet.larme.taken,'Terrain sans combat')
    assert(not Abyss.giant and #Abyss.bones==0,'Pas de squelette automatique')
    love.draw()
    local bone=AbyssTerrain.parts[1];local found=false
    for y=bone.y-90,bone.y+90,3 do for x=bone.x-90,bone.x+90,3 do
        if not found and Abyss.boneTouches(bone,x,y) then player.x=x-15;player.y=y-12;found=true end
    end end
    AbyssTerrain.contact();assert(found and player.reset,'Collision du terrain tournée')
    player.reset=false
    layout.entities[#layout.entities+1]={kind='boss',type='skeleton_head',x=650,y=260,movementRate=1,attackRate=1}
    assert(LayoutSchema.validate(layout));LevelLayouts.apply(layout)
    local boss=Bosses.items[1].boss
    assert(Bosses.alive() and boss.boss and boss.headOnly and #boss.bones==1,'La tête seule est le boss même au niveau 8')
    assert(boss.head.x==650 and boss.head.y==260,'Placement exact de la tête')
    local snap=LevelLayouts.snapshot();assert(LayoutSchema.validate(snap))
    LevelLayouts.apply(snap);boss=Bosses.items[1].boss
    assert(#Bosses.items==1 and #AbyssTerrain.parts==3 and boss.headOnly,'Aller-retour sauvegarde')
    local beforeHp=boss.hp;boss.open=true;boss.breathAt=boss.clock;boss.buildBones()
    local mx,my=boss.mouth();player.x=mx-15;player.y=my-12;Abyss.charge(6);boss.contact();boss.update(.61);assert(boss.swallowed,"Player waits until suction completes");for i=1,360 do boss.update(1/60);if not boss.open then break end end
    assert(boss.hp==beforeHp-1,'One stored charge damages the head after the full suction cycle')
    for i=1,boss.hp do boss.hurt() end
    assert(not Bosses.alive() and #AbyssTerrain.parts==3,'Le terrain reste après victoire')
    AbyssTerrain.resize(1.2);assert(AbyssTerrain.parts[1].x==192);love.draw()
    for n=8,10 do
        local old={world=7,level=n,width=960,height=600,entities={{kind='spawn',x=60,y=530},{kind='boss',type='skeleton_fish',x=480,y=280}}}
        LayoutSchema.splitAbyss(old);assert(LayoutSchema.validate(old))
        local heads,parts=0,0
        for _,e in ipairs(old.entities) do if e.kind=='boss' then heads=heads+1;assert(e.type=='skeleton_head') elseif e.kind=='abyss_part' then parts=parts+1 end end
        assert(heads==(n==10 and 1 or 0) and (n~=8 or parts==1) and (n~=9 or parts>1),'Conversion des anciens niveaux')
        local count=#old.entities;LayoutSchema.splitAbyss(old);assert(#old.entities==count,'Conversion idempotente')
    end
    local catalog=require('designer.catalog');local kinds={}
    for _,e in ipairs(catalog) do if e.type then kinds[e.type]=e.kind end end
    assert(kinds.skeleton_head=='boss' and kinds.skeleton_tail=='abyss_part' and kinds.skeleton_rib=='abyss_part' and kinds.skeleton_spine=='abyss_part')
    reset_level();assert(#AbyssTerrain.parts==0,'Terrain réinitialisé')
    print('PASS abyss editor: independent parts, head-only boss at exact position, terrain collisions, save roundtrip, suction, persistent terrain, resize, legacy conversion, palette')
end
return T
