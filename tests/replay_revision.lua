local T={}
function T.run()
    local json=require 'json'
    if os.getenv('SILKEN_REPLAY_CROSS_PROCESS')=='1' then
        Online.enabled=false;Replay.disabled=false
        local fixtures=json.decode(assert(love.filesystem.read('replay-qa-fixtures.json')))
        for i,recording in ipairs(fixtures) do
            assert(Replay.play(recording));local steps=0
            local function sample(dt) App.simulate(dt);if i>1 and Replay.frame==600 then App.state='customVictory' end end
            while Replay.playing and steps<2000 do Replay.update(1/47,sample);steps=steps+1 end
            assert(Replay.status=='Lecture terminée.','Cross-process fixture '..i..': '..Replay.status)
        end
        print('PASS cross-process playback: completed map and 16 world/boss recordings');io.stdout:flush();love.event.quit(0);return
    end
    local fixtures={}

    Online.enabled=false;LevelLayouts.disabled=false;Replay.disabled=false;Profile.name='Replay QA';Profile.country='FR'
    local map={world=1,level=1,width=960,height=600,entities={{kind='spawn',x=80,y=300},{kind='tear',x=650,y=300}}}
    Workshop.selected={key='qa',layout=map};Workshop.biome=1;Workshop.difficulty=1;Workshop.difficultyExtra='0'
    local oldMove,oldSlow=Input.move,Input.slow
    Input.move=function() if Replay.input then return Replay.input[1],Replay.input[2] end;return 1,0 end
    Input.slow=function() return false end
    Workshop.testPublication()
    local frames=0
    while App.state=='playing' and frames<2000 do Replay.update(1/60,App.simulate);frames=frames+1 end
    assert(App.state=='customVictory','Run must finish through real movement and collection')
    assert(Workshop.canPublish(),'Completion validates exact map')
    local recording=json.decode(json.encode(Replay.last));assert(Replay.validate(recording));assert(Replay.lastId)
    Workshop.biome=5;assert(not Workshop.canPublish(),'Biome change invalidates proof');Workshop.biome=1
    fixtures[#fixtures+1]=json.decode(json.encode(recording))
    local stats=json.encode(Profile.stats);local scores=#Profile.scores
    Workshop.validationRun=nil
    assert(Replay.play(recording));local played=0
    while Replay.playing and played<2500 do
        -- Rendering consumes unrelated randomness; it must not affect playback.
        love.math.random();math.random();Replay.update(1/37,App.simulate);played=played+1
    end
    assert(Replay.status=='Lecture terminée.',Replay.status)
    assert(json.encode(Profile.stats)==stats and #Profile.scores==scores,'Spectator must not mutate progress')
    recording.inputs[1][2]=0;assert(Replay.play(recording));played=0
    while Replay.playing and played<2500 do Replay.update(1/60,App.simulate);played=played+1 end
    assert(Replay.status:find('différente'),'Tampered simulation must be detected')
    Replay.recording=false;Replay.data=nil;App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;Secret.duel=nil
    local readLayouts=LevelLayouts.read;local campaignMaps={}
    for n=1,10 do campaignMaps['1:'..n]={world=1,level=n,width=960,height=600,entities={{kind='spawn',x=80,y=300},{kind='tear',x=240,y=300}}} end
    LevelLayouts.read=function() return campaignMaps end
    App.start(1);LevelLayouts.read=readLayouts
    local count=0
    while App.state=='playing' and count<1000 do Replay.update(1/60,App.simulate);count=count+1 end
    assert(App.state=='victory' and player.level==10 and Replay.lastId,'Full ten-level run must record its completion')
    assert(Profile.scores[#Profile.scores].replay==Replay.lastId,'Leaderboard score must reference its recording')
    local campaignRecording=json.decode(json.encode(Replay.last));fixtures[#fixtures+1]=campaignRecording
    assert(Replay.play(campaignRecording));count=0
    while Replay.playing and count<1000 do Replay.update(1/43,App.simulate);count=count+1 end
    assert(Replay.status=='Lecture terminée.','Ten-level replay: '..Replay.status)
    print('PASS complete ten-level run: transitions, leaderboard attachment and spectator playback')
    for _,world in ipairs({1,6,5,4,7,2,3,14}) do
        for _,start in ipairs({1,Worlds.levelCount(world)}) do
            Replay.recording=false;Replay.data=nil;LevelLayouts.disabled=true;App.sessionLayout=nil;App.singleLevel=true;App.practice=start;Secret.duel=nil
            Input.move=function() if Replay.input then return Replay.input[1],Replay.input[2] end;local phase=math.floor(Replay.frame/90)%4;return phase==0 and 1 or phase==2 and -1 or 0,phase==1 and 1 or phase==3 and -1 or 0 end
            local function sample(dt)
                App.simulate(dt)
                -- End this bounded physics sample identically on both passes.
                if Replay.frame==600 then App.state='customVictory';if not Replay.playing then Replay.finish() end end
            end
            App.start(world)
            for _=1,600 do if App.state=='playing' then Replay.update(1/60,sample) end end
            local saved=json.decode(json.encode(Replay.last));assert(saved.world==world and saved.startLevel==start);fixtures[#fixtures+1]=json.decode(json.encode(saved))
            assert(Replay.play(saved));local steps=0
            while Replay.playing and steps<1000 do love.math.random();Replay.update(1/45,sample);steps=steps+1 end
            assert(Replay.status=='Lecture terminée.','World '..world..' level '..start..': '..Replay.status)
        end
    end
    love.filesystem.write('replay-qa-fixtures.json',json.encode(fixtures))
    print('PASS deterministic physics samples: first and final encounter of all seven worlds and Demon mode')
    Input.move,Input.slow=oldMove,oldSlow
    Replay.recording=false;Replay.data=nil;LevelLayouts.disabled=true;App.singleLevel=false;App.practice=nil;App.sessionLayout=nil
    App.start(1);Replay.recording=false;Campaign.select(1);player.level=10;reset_level();App.state='playing'
    assert(Raven.active and Raven.hp==10 and #Raven.nests==6)
    player.reset=false;player.dashing=true;player.x=Raven.x-15;player.y=Raven.y-12
    Raven.contact();assert(Raven.hp==9 and #Raven.chicks==4);assert(#Raven.projectiles==0,'Hits do not synchronize shooters');assert(Raven.interval()<=1,'Continuous alternating shots')
    for _,m in ipairs(Raven.chicks) do local n=Raven.nests[m.slot];assert(m.kind==(m.slot%2==1 and 'shooter' or 'charger')) end
    Raven.contact();assert(Raven.hp==9,'One hit per entry')
    player.x=30;Raven.contact();player.x=Raven.x-15;Raven.contact();assert(Raven.hp==8 and #Raven.chicks==5)
    for _=1,8 do player.x=30;Raven.contact();player.x=Raven.x-15;Raven.contact() end
    assert(Raven.broken and not Raven.defeated and objet.larme.taken)
    while #Raven.chicks>0 do local m=Raven.chicks[1];player.x=m.x-15;player.y=m.y-12;Raven.contact() end
    assert(Raven.defeated and #Raven.chicks==0 and #Raven.projectiles==0 and not objet.larme.taken)
    for _,w in ipairs(Worlds.order) do if w~=8 then local a={};Achievements.check({world=w,time=60,deaths=0},a);assert(a['flawless'..w]) end end
    for _,name in ipairs({'go','back','selection','editor'}) do assert(Audio[name]:getDuration()>0) end
    local canvas=love.graphics.newCanvas(80,80)
    for _,id in ipairs({8,9,10,11,12,13,14}) do
        love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,.12);Characters.portrait(id,40,40,62,'down');love.graphics.pop()
        local pixels=canvas:newImageData();local maximum=0
        for y=0,79 do for x=0,79 do local _,_,_,alpha=pixels:getPixel(x,y);maximum=math.max(maximum,alpha) end end
        pixels:release();assert(maximum<.13 and maximum>.02,'Actual rendered skin alpha must respect the ghost fade')
    end
    canvas:release()
    print('PASS replay: real completed map, save/load, deterministic playback, divergence detection, spectator isolation, exact-map validation')
    print('PASS boss: six fixed nests, ten hits and stunned-bird cleanup, alternating bird roles, hit latch, cleanup; seven world achievements and audio sources')
    io.stdout:flush()
    local tick=0
    love.update=function(dt)
        tick=tick+1
        if tick==1 then Campaign.select(1);player.level=10;reset_level();App.state='playing';App.capture='revision-egg-boss.png' end
        if tick==4 then Campaign.select(4);player.level=10;reset_level();App.capture='revision-octopus.png' end
        if tick==7 then App.state='menu';App.selectedWorld=5;App.capture='revision-menu.png' end
        if tick==10 then App.state='achievements';UI.achievementPage=2;App.capture='revision-achievements.png' end
        if tick==13 then love.event.quit(0) end
    end
end
return T
