local E={}
function E.run()
    LevelLayouts.disabled=true
    local data={version=1,levels={}}
    love.math.setRandomSeed(4242); Arena.configure(1200,750)
    for _,w in ipairs(Worlds.order) do for n=1,Worlds.levelCount(w) do
        Campaign.select(w); player.level=n; reset_level()
        data.levels[w..':'..n]=LevelLayouts.snapshot()
        if w==6 and n==1 then
            local pixels=Realms.floor:newImageData(); local png=pixels:encode('png')
            local path=os.getenv('SILKEN_EXPORT_PATH'):gsub('default_levels.json$','sky_floor.png')
            local f=assert(io.open(path,'wb')); f:write(png:getString()); f:close(); pixels:release()
        end
    end end
    local text=require('json').encode(data)
    local out=assert(io.open(assert(os.getenv('SILKEN_EXPORT_PATH')),'w')); out:write(text); out:close()
    print('EXPORT: 66 niveaux importés depuis le moteur du jeu')
end
return E
