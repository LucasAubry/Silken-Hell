local T={}
local function level(w,n)
    App.practice=nil;App.singleLevel=false;App.sessionLayout=nil;Secret.duel=nil
    Campaign.select(w);player.level=n;reset_level();App.state='playing';player.x=60;player.y=500
end
function T.run()
    Replay.disabled=true
    LevelLayouts.disabled=true;Online.enabled=false
    Profile.scores={};Profile.completed={};Profile.levels={};Profile.unlocked=7
    assert(Worlds.canEnter(1) and not Worlds.canEnter(6) and not Worlds.canEnter(8),'Ordered unlocks, including sanctuary')
    for _,w in ipairs(Worlds.order) do
        assert(Worlds.canEnter(w));Profile.completed[w]=true;Profile.levels[w]=Worlds.levelCount(w)
        assert(Characters.unlocked(Worlds.rank(w)+5))
    end
    assert(Worlds.canEnter(8));Profile.completed[3]=nil;assert(not Worlds.canEnter(8));Profile.completed[3]=true
    level(5,10);Hedgehog.projectiles={};Hedgehog.fire();assert(#Hedgehog.projectiles==18)
    level(5,2);mobs={};Realms.larvae={};Realms.eggs={};spawn_piege(300,300)
    Realms.add('worm',300,300,80);local worm=mobs[#mobs];worm.age=0
    Realms.capture(worm);assert(not worm.is_frozen and not mobs[1].active,'Buried worm ignores traps')
    Campaign.carrier=worm;worm.has_larme=true;objet.larme_dropped=false
    Campaign.updateTear(0);Campaign.drawTear()
    worm.age=2;Realms.capture(worm);assert(worm.is_frozen and objet.larme_dropped,'Surface worm trapped and drops tear')
    player.x=worm.x;player.y=worm.y;assert(not isTouching(player,worm),'Frozen creature harmless')
    mobs={};spawn_piege(350,300)
    Realms.larvae={{type='larva',x=350,y=300,speed=72,age=0,life=16,dir='down',hitBox_width=16,hitBox_height=16,hitBox_offset_x=-8,hitBox_offset_y=-8}}
    Realms.updateProjectiles(.1);local larva=Realms.larvae[1];assert(larva.is_frozen and larva.x==350 and larva.y==300,'Small worm stops in trap')
    mobs={};Realms.larvae={};Realms.eggs={{x=200,y=200,vx=0,vy=0,life=.001},{x=220,y=200,vx=0,vy=0,life=.001}}
    Realms.updateProjectiles(.01);assert(#Realms.eggs==0 and #Realms.larvae==2,'Each expired egg hatches once')
    level(4,2);mobs={};Octopus.spawnCrab(300,300,100);local crab=mobs[1];freeze(crab,2);player.x=285;player.y=288
    Octopus.crabContact(crab);assert(not player.reset,'Frozen crab contact harmless')
    level(2,10);Wasp.reset(true);Wasp.round=1;Wasp.roundActive=true;Profile.achievements.gillou=nil
    for i,b in ipairs(Wasp.bees) do b.phase='fatigued';b.time=1.65;b.x=180+i*180;b.y=250 end
    for _,b in ipairs(Wasp.bees) do player.x=b.x-15;player.y=b.y-12;Wasp.contact() end
    assert(Profile.achievements.gillou and Wasp.hitGrace==.85,'Three sisters touched in one KO')
    Wasp.reset(true);Profile.achievements.gillou=nil
    for i,b in ipairs(Wasp.bees) do b.phase='fatigued';b.time=1.65;b.x=180+i*180;b.y=250 end
    player.x=Wasp.bees[1].x-15;player.y=238;Wasp.contact();assert(Wasp.combo)
    Wasp.bees[2].time=.001;player.x=60;player.y=500;Wasp.roundActive=true;Wasp.updateBees(.01)
    assert(not Wasp.combo and not Profile.achievements.gillou,'Wakeup invalidates combo')
    level(5,10);Hedgehog.hp=0;Hedgehog.defeated=true;objet.larme.taken=false
    Realms.add('mole',300,300,80);Aftermath.update(.01)
    assert(Aftermath.cleared and #mobs==0 and #Aftermath.sparks>0,'Victory clears creatures with sparks')
    Hazards.kill();assert(not player.reset,'Victory terrain harmless')
    local starts=0;local original=Online.start;Online.start=function() starts=starts+1 end
    local scores=#Profile.scores;Profile.levels[1]=3
    assert(App.practiceLevel(1,3));assert(player.level==3 and App.singleLevel and starts==0)
    assert(not App.practiceLevel(1,4));mobs={};Campaign.carrier=nil;objet.larme_dropped=true;objet.larme.taken=false
    player.x=objet.larme.x;player.y=objet.larme.y;love.update(.01)
    assert(App.state=='customVictory' and #Profile.scores==scores,'Practice never completes campaign or scores')
    Online.start=original
    local valid=LayoutSchema.validate({world=5,level=1,width=960,height=600,difficulty=5,difficultyExtra=999,biome=4,entities={{kind='spawn',x=50,y=50},{kind='mob',type='mole',x=200,y=200,startUnderground=true}}});assert(valid)
    Profile.save();Profile.load();assert(Profile.levels[1]==3 and Profile.hasCompleted(5),'Progress persists')
    for _,state in ipairs({'menu','worlds','achievements','story','workshop','rankings'}) do App.state=state;love.draw() end
    for _,world in ipairs(Worlds.order) do for n=1,Worlds.levelCount(world) do
        level(world,n);love.update(.016);love.draw()
    end end
    level(4,10);Octopus.releaseCrabs();assert(#Octopus.crabs==6,'Six crabs per wave')
    Octopus.enraged=true;Octopus.releaseCrabs();assert(#Octopus.crabs==14,'Eight crabs in rage')
    for i=1,6 do local before=#Octopus.crabs;Octopus.releaseCrabs();local added=#Octopus.crabs-before;assert(added==0 or added>=6,'Complete waves only') end;assert(#Octopus.crabs<=32,'Bounded population')
    Octopus.enraged=false
    Octopus.stun=2;Octopus.rider={arm=1};player.x=90;player.y=480
    for arm=1,8 do
        for _,destination in ipairs({{100,200},{-370,180},{330,-210}}) do
            local points,length=Octopus.tetherCurve(arm,destination[1],destination[2])
            assert(#points==65 and length>0)
            local first,last=points[1],points[#points]
            assert(math.abs(first.x^2+first.y^2-40^2)<.001,'Root remains attached')
            assert(last.x==destination[1] and last.y==destination[2],'Tip stays in player hand')
            for i,p in ipairs(points) do assert(p.width>0 and p.width<22 and p.x==p.x)
                if i>1 then assert(p.distance>=points[i-1].distance) end
            end
        end
    end
    Octopus.updateTether(.2);assert(Octopus.tether.blend>.9);love.draw()
    Octopus.rider=nil;Octopus.updateTether(.01);assert(Octopus.tether,'Release transitions gradually')
    Octopus.updateTether(1);assert(not Octopus.tether,'Release settles cleanly')
    for arm=1,8 do
        local resting=Octopus.armCurve(arm);local tip=Octopus.tipOffsets[arm]
        Octopus.rider={arm=arm};player.x=Octopus.x+tip.x-15;player.y=Octopus.y+tip.y-12
        Octopus.updateTether(.2);local held=Octopus.armCurve(arm)
        for i,p in ipairs(resting) do assert(math.abs(p.x-held[i].x)<.001 and math.abs(p.y-held[i].y)<.001,'No shape switch on grabbing the resting tip') end
        local p=held[45];assert(Octopus.touches(Octopus.x+p.x,Octopus.y+p.y),'Collision follows visible arm')
        Octopus.arms[arm]=0;assert(Octopus.armAt(Octopus.x+p.x,Octopus.y+p.y)~=arm,'Torn arm has no collision');Octopus.arms[arm]=3
        Octopus.rider=nil;Octopus.updateTether(1)
    end
    App.selectedWorld=1;WorldMap.open();WorldMap.step(1);assert(App.selectedWorld==6)
    WorldMap.step(1);assert(App.selectedWorld==5);WorldMap.step(-1);assert(App.selectedWorld==6)
    local before=WorldMap.scroll;WorldMap.step(1)
    assert(WorldMap.scroll==before,'Arrow must not teleport camera')
    local target=WorldMap.scrollTarget;WorldMap.update(.016)
    assert(WorldMap.scroll>before and WorldMap.scroll<target,'Smooth camera advances toward target')
    for i=1,120 do WorldMap.update(1/60) end
    assert(math.abs(WorldMap.scroll-target)<.1,'Camera settles on selected world')
    WorldMap.step(-1);WorldMap.step(1);WorldMap.step(1);WorldMap.update(.016)
    assert(WorldMap.scroll==WorldMap.scroll,'Rapid direction changes stay finite')
    print('PASS attached tentacle, 6/8 crabs, population cap, smooth world navigation')
    print('PASS 66 campaign levels: reset, update and render')
    print('PASS goal revision: progression, skins, sanctuary, 18 spikes, traps, eggs, Gillou, aftermath, practice and menus');io.stdout:flush()
    local ticks=0
    love.update=function(dt)
        ticks=ticks+1;UI.clock=UI.clock+dt
        if ticks==1 then Profile.completed={[1]=true,[6]=true};App.selectedWorld=5;WorldMap.open();App.capture='goal-world-map.png' end
        if ticks==4 then level(5,5);App.capture='goal-earth.png' end
        if ticks==7 then level(2,10);Wasp.beginRound();for _,b in ipairs(Wasp.bees) do b.attack=3;b.phase='aim';b.tx=b.x;b.ty=b.y;b.launchLarva=true end;App.capture='goal-bees-warning.png' end
        if ticks==10 then App.state='achievements';App.capture='goal-achievements.png' end
        if ticks==13 then level(4,10);Octopus.stun=2;Octopus.rider={arm=1};player.x=80;player.y=450;Octopus.updateTether(1);App.capture='goal-tentacle.png' end
        if ticks==16 then level(5,10);Hedgehog.hp=0;Hedgehog.defeated=true;objet.larme.taken=false;Aftermath.update(.1);player.x=Aftermath.x-15;player.y=530;player.lastMoveX=0;player.lastMoveY=1;Aftermath.update(.1);App.capture='goal-inscriptions.png' end
        if ticks==19 then App.selectedWorld=8;App.state='menu';App.capture='goal-sanctuary-menu.png' end
        if ticks==22 then App.state='worlds';App.selectedWorld=4;WorldMap.open();App.capture='goal-locked-map.png' end
        if ticks==25 then level(4,10);Octopus.stun=2;Octopus.rider={arm=1};player.x=Octopus.x+250;player.y=Octopus.y+80;Octopus.updateTether(1);App.capture='goal-tentacle-right.png' end
        if ticks==28 then Octopus.rider={arm=6};player.x=Octopus.x-200;player.y=70;Octopus.updateTether(1);App.capture='goal-tentacle-up.png' end
        if ticks==31 then level(4,10);App.capture='goal-octopus-rest.png' end
        if ticks==34 then love.event.quit(0) end
    end
end
return T
