local T={}
function T.run()
    local json=require 'json'
    if os.getenv('SILKEN_REPLAY_CROSS_PROCESS_TEST')=='1' then
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
            local snapshots={}
            local function compare(a,b,path)
                if type(a)~='table' or type(b)~='table' then
                    if a~=b then error(path..': '..tostring(a)..' ~= '..tostring(b)) end
                    return
                end
                for k,v in pairs(a) do compare(v,b[k],path..'.'..k) end
                for k,v in pairs(b) do if a[k]==nil then compare(nil,v,path..'.'..k) end end
            end
            local function sample(dt)
                App.simulate(dt)
                -- End this bounded physics sample identically on both passes.
                if Replay.frame%240==0 then
                    local state=require('replay_state').snapshot()
                    if Replay.playing then compare(snapshots[Replay.frame],state,'world'..world..'level'..start)
                    else snapshots[Replay.frame]=state end
                end
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
    print('PASS replay: completed workshop and campaign, exact world state across 16 encounters, divergence detection and spectator isolation')
    io.stdout:flush();love.event.quit(0)
end
return T
