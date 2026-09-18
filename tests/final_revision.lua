local T={}
function T.run()
    Online.start=function() end;Profile.name='QA';Profile.unlocked=7
    Secret.hardcore=false;Secret.open();assert(#Secret.portals==6 and not Secret.hardcore)
    for _,p in ipairs(Secret.normalBosses) do
        Secret.launch(p);assert(App.singleLevel and #Bosses.items==1 and not Bosses.items[1].boss.hardcore)
        love.draw()
    end
    for _,p in ipairs(Secret.creatures) do
        Secret.launch(p);assert(#mobs==1 and not Bosses.any(),'Un seul mob : '..p.type);love.draw()
    end
    Secret.updateDuel(20);assert(App.state=='customVictory')
    Secret.open();Secret.x=Arena.width-50;Secret.y=300;Secret.cooldown=0;Secret.update(0)
    assert(Secret.hardcore and #Secret.portals==1 and Secret.portals[1].world==14)
    Secret.launch(Secret.portals[1]);assert(not App.singleLevel and Bosses.items[1].boss.hardcore)
    Secret.duel=nil;App.sessionLayout=nil;App.singleLevel=false;LevelLayouts.disabled=true
    Campaign.select(2);player.level=10;reset_level();App.state='playing'
    Wasp.roundActive=true;local b=Wasp.bees[1];b.phase='position';b.tx=b.x;b.ty=b.y;b.attack=1;player.x=60;player.y=510
    Wasp.update(.001);assert(b.phase=='aim' and b.time==.4)
    Wasp.update(.2);assert(b.phase=='aim',b.phase..':'..tostring(b.time));Wasp.update(.21);assert(b.phase=='charge',b.phase..':'..tostring(b.time))
    Campaign.select(7);player.level=10;reset_level();player.x=50;player.y=540
    Abyss.charge(6);assert(Abyss.playerLightRadius()==85)
    local y=Abyss.head.y;Abyss.motionTime=1;Abyss.buildBones();assert(Abyss.head.y~=y)
    Abyss.swallowed={charged=1,time=.6};player.abyssHeld=Abyss;Abyss.spit();Abyss.refreshLight()
    assert(player.abyssSpit and player.illuminated==0 and player.charges==0)
    player.abyssGrace=0;Hazards.kill();assert(not player.reset,'Invincible pendant tout le trajet')
    Abyss.updatePlayer(.3);assert(not player.abyssSpit and player.abyssGrace>0)
    Campaign.select(4);player.level=10;reset_level();for _,m in ipairs(mobs) do assert(m.type~='jelly') end
    player.x=55;player.y=520;Octopus.releaseCrabs();local c=Octopus.crabs[1];c.launch=nil;c.x=80;c.y=150
    Octopus.inkPools={{x=80,y=150,rx=38,ry=27,life=6}};Octopus.updateCrabs(.01);assert(c.inked and c.frenzy and not c.dead)
    local vx,vy=c.vx,c.vy;Octopus.walkCrab(c,.4,function() end);assert(c.vx~=vx or c.vy~=vy)
    Secret.hardcore=false;Secret.open();local frames=0;love.focus=function() end
    love.update=function()
        frames=frames+1
        if frames==1 then App.capture='sanctuary-duels.png'
        elseif frames==5 then Secret.category='mobs';Secret.refresh();App.capture='sanctuary-mobs.png'
        elseif frames==9 then Secret.hardcore=true;Secret.refresh();App.capture='sanctuary-hardcore.png'
        elseif frames==13 then Secret.duel=nil;Campaign.select(7);player.level=10;reset_level();App.state='playing';App.capture='abyss-helmet-revision.png'
        elseif frames==17 then print('PASS revision: all solo boss/mob encounters, hardcore door, wasp pause, low first charge, floating head, safe dark spit, octopus without jelly and ink frenzy');love.event.quit() end
    end
end
return T
