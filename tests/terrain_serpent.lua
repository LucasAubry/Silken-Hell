local T={}
local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
function T.run()
    for _,world in ipairs({1,2,4,5,6,7}) do for n=1,10 do
        level(world,n)
        if world==5 then assert(n==10 and #Arena.interior==0 or n<10 and #Arena.interior>=3,'Murs Terre sauf boss '..n) end
        for _,r in ipairs(Arena.interior) do
            for _,m in ipairs(mobs) do if m.type=='piege' or m.capture then
                assert(not checkCollision(r.x,r.y,r.w,r.h,m.x-32,m.y-32,64,64),'Mur sur capture')
            end end
            for _,p in ipairs(Hazards.lava) do
                assert(not checkCollision(r.x,r.y,r.w,r.h,p.x-p.rx-8,p.y-p.ry-8,p.rx*2+16,p.ry*2+16),'Mur sur lave')
            end
        end
    end end
    level(5,3)
    local saved=Arena.walls; local lava=Hazards.lava
    Arena.walls={{x=0,y=0,w=Arena.width,h=22},{x=0,y=578,w=Arena.width,h=22},{x=0,y=0,w=22,h=600},{x=Arena.width-22,y=0,w=22,h=600},{x=220,y=200,w=24,h=160}}
    Arena.navigationVersion=Arena.navigationVersion+1; Hazards.lava={}
    local m={x=150,y=280,hitBox_width=30,hitBox_height=30,hitBox_offset_x=-15,hitBox_offset_y=-15}
    for _=1,140 do
        Arena.navigate(m,340,280,90,.05)
        assert(not Arena.blocked(m.x-15,m.y-15,30,30),'Navigation sans traverser les murs')
    end
    assert(math.abs(m.x-340)<3 and math.abs(m.y-280)<3,'Contournement complet du mur')
    m.x=150; m.y=280; m.path=nil; m.is_frozen=true
    Arena.navigate(m,340,280,90,1); assert(m.x==150,'Un piège immobilise encore')
    Arena.walls=saved; Hazards.lava=lava
    level(2,10); assert(Wasp.active and not Campaign.canCollect(),'Abeille native dans l’Enfer')
    require('tests.wasp_trio').defeat(Wasp)
    assert(Wasp.defeated and Campaign.canCollect(),'Abeille vaincue libère la larme')
    for _,entry in ipairs(require('designer.catalog')) do assert(entry.type~='hellserpent','Boss retiré du catalogue') end
    for _,entry in ipairs(Bestiary.entries) do assert(entry.id~='hellserpent','Boss retiré du bestiaire') end
    local layout=LevelLayouts.snapshot(); local found=false
    for _,e in ipairs(layout.entities) do if e.kind=='boss' then assert(e.type=='wasp'); e.type='hellserpent'; found=true end end
    assert(found and LayoutSchema.validate(layout)); LevelLayouts.apply(layout)
    assert(#Bosses.items==1 and Bosses.items[1].kind=='wasp','Anciennes cartes converties en abeille')
    assert(not love.filesystem.getInfo('hellserpent.lua'),'Ancien boss supprimé du jeu')
    print('PASS terrain/abeille: murs, navigation, vent, boss Enfer, victoire, catalogue, migration des anciennes cartes')
end
return T
