local T={}
local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
function T.run()
    for _,w in ipairs({4,5,6,7}) do for n=1,10 do
        level(w,n)
        for _,m in ipairs(mobs) do assert(m.type~='piege' and m.type~='scie','Aucun piège mécanique hors Paradis/Enfer') end
        if Campaign.carrier then
            local capture
            for _,m in ipairs(mobs) do if m.capture then capture=m end end
            assert(capture,'Décor adapté pour chaque porteur')
        end
        if w==4 or w==7 then
            assert(Ocean.active and #Ocean.bubbles==0 and player.oxygen==nil)
        else assert(not Ocean.active) end
        love.draw()
    end end
    level(7,1); local lamps=0; local fish
    for _,m in ipairs(mobs) do if m.type=='lanternfish' then lamps=lamps+1; fish=m end end
    assert(lamps>=2 and Bestiary.seen.lanternfish)
    player.x=70; player.y=540; Ocean.update(120); assert(not player.reset and player.oxygen==nil,'Aucune asphyxie dans les Abysses')
    reset_level(); fish=nil; for _,m in ipairs(mobs) do if m.type=='lanternfish' then fish=m; break end end
    local x,y=fish.x,fish.y; MobBehaviors.lanternfish.update(fish,.1); assert(fish.x~=x or fish.y~=y)
    local g=love.graphics; local canvas=g.newCanvas(Arena.width,600)
    g.push('all'); g.setCanvas(canvas); g.clear(1,1,1); Realms.drawDarkness(); g.setCanvas(); g.pop()
    local pixels=canvas:newImageData(); local dark=pixels:getPixel(45,45); local lit=pixels:getPixel(math.floor(fish.x),math.floor(fish.y-15))
    assert(dark<.04 and lit>.7,'Abysses presque noirs, lumière locale des poissons')
    pixels:release(); canvas:release()
    level(4,10)
    for _,phase in ipairs({'attack','rest'}) do
        Octopus.phase=phase
        for i=0,3 do Octopus.angle=i*math.pi/2; local key=Octopus.sprite()
            assert(key:match('^octopus_extended_'),'Tentacules toujours dépliés')
            assert(Art.images[key]); love.draw()
        end
    end
    for _,name in ipairs({'octopus_extended','octopus_folded','lanternfish'}) do for _,dir in ipairs({'up','down','left','right'}) do
        local data=Art.imageData('assets/sprites/directional/'..name..'_'..dir..'.png')
        local _,_,_,a=data:getPixel(0,0); assert(a==0,'PNG transparent '..name..' '..dir); data:release()
    end end
    for _,name in ipairs({'coral_snare','root_snare','cloud_snare','abyss_snare','ink_splatter'}) do
        local data=Art.imageData('assets/sprites/'..name..'.png'); local _,_,_,a=data:getPixel(0,0); assert(a==0,name); data:release()
    end
    print('PASS révision marine : bulle de tête sans asphyxie Océan/Abysse, obscurité/lampes, huit formes poulpe, décors naturels et PNG transparents')
end
return T
