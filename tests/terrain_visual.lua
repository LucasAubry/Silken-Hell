local T={}
local function level(w,n) App.start(w); player.level=n; reset_level(); timer=12.3 end
function T.run()
    Profile.unlocked=6; local tick=0
    love.update=function(dt)
        tick=tick+1; UI.clock=UI.clock+dt
        if tick==1 then
            level(5,8)
            for _,m in ipairs(mobs) do if m.type=='worm' then m.age=.6 end end
            Realms.larvae={{x=player.x-45,y=player.y+40,dir='right'},{x=player.x+65,y=player.y+45,dir='left'}}
            App.capture='terrain-earth.png'
        elseif tick==5 then level(6,8); Realms.wind={x=130,y=35}; Realms.clock=2; App.capture='terrain-wind.png'
        elseif tick==9 then level(2,10); App.capture='hell-wasp-flying.png'
        elseif tick==13 then Wasp.phase='landed'; Wasp.x=Arena.width/2; Wasp.y=300; App.capture='hell-wasp-ground.png'
        elseif tick==17 then love.event.quit() end
    end
end
return T
