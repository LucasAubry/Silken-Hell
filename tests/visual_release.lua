local T={}
function T.run()
    Profile.unlocked=6; Profile.name='Test'; Online.country='FR'
    Online.scores=function()
        local rows={}; for i=1,10 do rows[i]={name=({'Aube','Étoile','Nyx','Soie','Lune'})[(i-1)%5+1],time=80+i*7.31,deaths=i-1,skin=(i-1)%5+1} end
        return rows,'online'
    end
    local tick=0
    love.update=function(dt)
        tick=tick+1; UI.clock=UI.clock+dt
        if tick==1 then Profile.character=5; App.state='menu'; App.capture='release-menu.png' end
        if tick==5 then App.state='worlds'; App.capture='release-worlds.png' end
        if tick==9 then Bestiary.discover('wasp'); Bestiary.open(); UI.bestSelected=8; App.capture='release-bestiary.png' end
        if tick==13 then App.start(4); player.level=8; reset_level(); App.capture='release-ocean.png' end
        if tick==17 then App.start(5); player.level=8; reset_level(); for _,m in ipairs(mobs) do if m.age then m.age=3 end end; App.capture='release-earth.png' end
        if tick==21 then App.start(6); player.level=8; reset_level(); Realms.rain={{x=320,y=350,age=.7},{x=730,y=210,age=.9}}; App.capture='release-sky.png' end
        if tick==25 then App.start(2); player.level=10; reset_level(); Wasp.phase='landed'; player.venom=3; Wasp.fire('venom'); App.capture='release-venom.png' end
        if tick==29 then
            App.start(5); player.level=8; reset_level()
            for _,m in ipairs(mobs) do if m.age then m.age=3; m.dir='left' end end
            App.capture='release-earth-left.png'
        end
        if tick==33 then love.event.quit() end
    end
end
return T
