local T={}
function T.run()
    Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
    App.sessionLayout=nil;App.singleLevel=false;App.practice=nil
    local save=Profile.save;Profile.save=function() end
    local function start(hardcore,n)
        App.hardcore=hardcore;Campaign.select(6);player.level=n;reset_level();App.state='playing';player.death=0;RunDetails.reset()
    end
    for _,hardcore in ipairs({false,true}) do
        start(hardcore,3)
        -- A practice run can begin above a level that has never been loaded.
        Campaign.data[6][2]={}
        local deaths=player.death
        Hazards.kill('abyss_projectile');player.falling=true
        assert(App.resolveDeath() and player.death==deaths+1)
        assert(player.level==3,'Do not switch levels during the fall')
        love.draw()
        App.simulate(.16)
        assert(player.level==3 and player.fallTimer>0)
        local remaining=player.fallTimer
        App.resolveDeath()
        assert(player.fallTimer==remaining,'Repeated resolution cannot restart a fall')
        love.draw()
        App.simulate(.16)
        assert(player.level==(hardcore and 2 or 3))
        assert(not player.reset and not player.falling and player.fallTimer==0)
        assert(RunDetails.rows[3].deaths==1 and RunDetails.rows[3].time>=.32)
        assert(not RunDetails.rows[2],'Death and fall time belong to the dying level')
        love.draw()
    end
    for _,hardcore in ipairs({false,true}) do for _,n in ipairs({1,3}) do
        start(hardcore,n)
        Hazards.kill('abyss_projectile');assert(App.resolveDeath())
        assert(player.level==(hardcore and math.max(1,n-1) or n))
        assert(not player.reset and not player.falling);love.draw()
    end end
    App.hardcore=false;Profile.save=save
    print('PASS death reset: falling and immediate deaths, hardcore level transition, first-frame rendering, duplicate resolution and death/time attribution')
end
return T
