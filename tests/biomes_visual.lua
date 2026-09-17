local T={}
local function level(w,n) App.start(w); player.level=n; reset_level(); timer=31.8 end
function T.run()
    Profile.unlocked=6; local tick=0
    love.update=function(dt)
        tick=tick+1; UI.clock=UI.clock+dt
        if tick==1 then level(1,8); App.capture='biomes-paradise8.png' end
        if tick==5 then level(1,9); App.capture='biomes-paradise9.png' end
        if tick==9 then level(4,10); Octopus.angle=.25; Octopus.ink(); App.capture='biomes-octopus.png' end
        if tick==13 then Octopus.splash(); App.capture='biomes-ink.png' end
        if tick==17 then Octopus.blots={}; Octopus.phase='rest'; Octopus.extension=0; App.capture='biomes-octopus-rest.png' end
        if tick==21 then level(6,8); App.capture='biomes-sky.png' end
        if tick==25 then level(7,8); Realms.clock=1; App.capture='biomes-abyss.png' end
        if tick==29 then
            level(5,8); mobs={}
            for i,t in ipairs({1.9,2.4,3,4.6}) do Realms.spawnMole(Arena.width*.2+i*110,260); local m=mobs[#mobs]; m.x=Arena.width*.2+i*110; m.y=260; m.age=t end
            App.capture='biomes-digging.png'
        end
        if tick==33 then level(5,8); for _,m in ipairs(mobs) do if m.type=='worm' then m.age=2 end end; App.capture='biomes-worms.png' end
        if tick==37 then App.state='worlds'; App.capture='biomes-order.png' end
        if tick==41 then love.event.quit() end
    end
end
return T
