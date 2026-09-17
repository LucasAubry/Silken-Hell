local T={}
local function level(w,n) App.start(w); player.level=n; reset_level(); timer=27.4 end
function T.run()
    Profile.unlocked=6; Profile.character=1; local tick=0
    love.update=function(dt)
        tick=tick+1; UI.clock=UI.clock+dt
        if tick==1 then
            level(4,8)
            for _,s in ipairs(Realms.schools) do s.age=2.4; s.angle=1 end
            for _,m in ipairs(mobs) do if m.type=='jelly' then m.age=3; Realms.zap(m) end end
            for _,p in ipairs(Realms.bolts) do p.x=p.x+p.vx*.35; p.y=p.y+p.vy*.35 end
            App.capture='encounter-ocean.png'
        end
        if tick==5 then
            level(5,8)
            for _,m in ipairs(mobs) do if m.type=='worm' then m.age=1.3; m.dir='left'; Realms.spit(m)
                elseif m.type=='mole' then m.age=2 end end
            for _,p in ipairs(Realms.eggs) do p.x=p.x+p.vx*.3; p.y=p.y+p.vy*.3 end
            Realms.larvae={{x=280,y=280,dir='right'},{x=300,y=290,dir='down'},{x=285,y=308,dir='left'}}
            App.capture='encounter-earth.png'
        end
        if tick==9 then
            level(1,10); player.x=Arena.width/2-15; player.y=510
            local e=Raven.eggs[1]; Raven.projectiles={{x=e.x,y=e.y,vx=0,vy=0,life=1}}; Raven.shot=100; Raven.update(.1)
            Raven.update(.1); Raven.fire(); App.capture='encounter-merle.png'
        end
        if tick==13 then
            level(6,8); Realms.rainClock=0; Realms.update(.01)
            for i,p in ipairs(Realms.rain) do p.age=i%2==0 and .65 or .95 end
            App.capture='encounter-sky.png'
        end
        if tick==17 then
            Bestiary.seen.wasp=nil; Bestiary.discover('wasp'); Bestiary.open(); App.capture='encounter-bosses.png'
        end
        if tick==21 then
            level(2,10); Wasp.minions={}
            for i,d in ipairs({'up','down','left','right'}) do Wasp.minions[i]={x=300+i*85,y=330,dir=d} end
            App.capture='encounter-wasplings.png'
        end
        if tick==25 then
            level(5,10); Hedgehog.fire()
            for _,p in ipairs(Hedgehog.projectiles) do p.x=p.x+p.vx*.6; p.y=p.y+p.vy*.6 end
            Realms.spawnMole(240,350); mobs[#mobs].age=3
            App.capture='encounter-hedgehog-standing.png'
        end
        if tick==29 then
            Hedgehog.roll(); Hedgehog.x=Arena.width*.65; Hedgehog.y=330; Hedgehog.rotation=.6
            App.capture='encounter-hedgehog-ball.png'
        end
        if tick==33 then
            Profile.scores={}
            for i=1,23 do Profile.scores[i]={world=5,name='Joueur '..i,country='FR',time=60+i*1.3,deaths=i%7,skin=i%5+1} end
            UI.boardWorld=5; UI.boardPage=2; UI.boardCountry=false; App.state='rankings'
            App.capture='encounter-rankings.png'
        end
        if tick==37 then love.event.quit() end
    end
end
return T
