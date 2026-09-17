local T={}
function T.run()
    for _,world in ipairs({4,7}) do for n=1,10 do
        Campaign.select(world); player.level=n; reset_level(); App.state='playing'
        for attempt=1,4 do
            local fish
            for _,m in ipairs(mobs) do if m.type==(world==4 and 'fish' or attempt%2==0 and 'abyss_fish' or 'lanternfish') then fish=m; break end end
            if fish then
                local deaths=player.death
                player.x=fish.x-15; player.y=fish.y-12; player.illuminated=attempt%2==0 and 6 or 0
                Abyss.clock=attempt%2==0 and 6 or 0
                love.update(.001)
                assert(player.death==deaths+1,'Collision poisson mortelle')
                assert(not player.reset,'Niveau réinitialisé')
                love.draw()
                for _=1,4 do love.update(.016); love.draw() end
            end
        end
    end end
    print('PASS fish death: repeated collisions, reset, first frames and death shader')
end
return T
