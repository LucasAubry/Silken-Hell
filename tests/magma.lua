local T={}
function T.run()
    local disabled=LevelLayouts.disabled; LevelLayouts.disabled=true
    for n=1,10 do
        Campaign.select(2); player.level=n; reset_level(); App.state='playing'
        assert(#Magma.spawners>0,'Flaques dans chaque niveau Enfer')
        for _,s in ipairs(Magma.spawners) do
            assert(not Arena.blocked(s.x-31,s.y-23,62,46),'Flaque hors des murs')
            assert((s.x-player.x-15)^2+(s.y-player.y-12)^2>=160^2,'Départ dégagé')
            for _,p in ipairs(levels[n].larme_position) do assert((s.x-p.x-15)^2+(s.y-p.y-39)^2>=85^2,'Cercles dégagés') end
        end
        local snap=LevelLayouts.snapshot(); assert(LayoutSchema.validate(snap))
        LevelLayouts.apply(snap); assert(#Magma.spawners>0,'Spawners conservés par l’éditeur')
    end
    Campaign.select(1); player.level=1; reset_level()
    assert(#Magma.spawners==0,'Pas de spawner ajouté aux autres mondes')
    Arena.interior={}; while #Arena.walls>4 do table.remove(Arena.walls) end
    mobs={}; Magma.reset(); player.x=700; player.y=400; player.reset=false
    local s=Magma.addSpawner(220,200); Magma.update(2.19); assert(#mobs==0)
    Magma.update(.02); assert(#mobs==1 and mobs[1].type=='magma_larva','Invocation différée')
    local obstacle={x=400,y=250,w=36,h=190}; Arena.walls[#Arena.walls+1]=obstacle; Arena.navigationVersion=Arena.navigationVersion+1
    local probe={x=330,y=350,hitBox_width=18,hitBox_height=18,hitBox_offset_x=-9,hitBox_offset_y=-9}
    for _=1,180 do Arena.navigate(probe,520,350,245,.025); assert(not Arena.blocked(probe.x-9,probe.y-9,18,18),'La larve contourne le mur') end
    assert(probe.x>480,'Chemin trouvé autour du mur'); table.remove(Arena.walls); Arena.navigationVersion=Arena.navigationVersion+1
    local m=mobs[1]; local x=m.x; MobBehaviors.magma_larva.update(m,.1); assert(m.x>x and m.age>0,'Poursuite rapide')
    m.age=3.59; MobBehaviors.magma_larva.update(m,.02)
    assert(m.spent and #Magma.pools==1 and not player.reset,'Explosion retardée et flaque')
    Magma.update(.01); assert(#mobs==0,'Larve retirée après explosion')
    local p=Magma.pools[1]; Magma.spawners={}; Magma.update(600)
    assert(#Magma.pools==1,'Le poison n’expire jamais pendant une tentative')
    player.x=p.x-15; player.y=p.y-12; Magma.contact(); assert(player.reset,'Poison mortel')
    player.reset=false; player.x=700; player.y=400
    Magma.poison(p.x,p.y); assert(#Magma.pools==1,'Impacts identiques fusionnés sans fuite mémoire')
    Magma.resize(.9); assert(#Magma.pools==1 and math.abs(Magma.pools[1].x-p.x*.9)<.01)
    Magma.drawGround()
    reset_level(); assert(#Magma.pools==0 and #Magma.bursts==0 and not Magma.canvas,'Nettoyage au recommencement')
    local layout={world=4,level=1,width=Arena.width,height=600,entities={{kind='spawn',x=700,y=400},{kind='magma_spawner',x=200,y=200},{kind='mob',type='magma_larva',x=300,y=200,speed=245}}}
    assert(LayoutSchema.validate(layout)); LevelLayouts.apply(layout)
    assert(#Magma.spawners==1 and #mobs==1,'Objets utilisables dans tous les biomes')
    MobBehaviors.magma_larva.draw(mobs[1]); Magma.drawGround()
    local d=love.image.newImageData('assets/sprites/magma_pool.png'); local _,_,_,a=d:getPixel(0,0); assert(a==0,'Transparence flaque'); d:release()
    d=love.image.newImageData('assets/sprites/magma_larva.png'); _,_,_,a=d:getPixel(0,0); assert(a==0,'Transparence larve'); d:release()
    LevelLayouts.disabled=disabled; App.sessionLayout=nil; Campaign.select(1); player.level=1; reset_level()
    print('PASS magma: native levels, clearance, spawn, chase, fuse, permanent poison, reset, resize, editor, alpha')
end
function T.visual()
    local tick=0
    love.update=function()
        tick=tick+1
        if tick==1 then
            LevelLayouts.disabled=true; Campaign.select(2); player.level=5; reset_level(); App.state='playing'
            for i,p in ipairs(Magma.spawners) do local m=Magma.spawn(Arena.width*.4+i*45,250); m.angle=-.8; m.age=2.4+i*.25 end
            Magma.poison(Arena.width*.52,420); Magma.poison(Arena.width*.6,380)
            App.capture='magma-hell.png'
        elseif tick==5 then love.event.quit() end
    end
end
return T
