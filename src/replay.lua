local json=require 'json'
local Tools=require 'replay_tools'
local R={version=1,step=1/60,accumulator=0,speed=1,status=''}
function R.canonical(value)
    if type(value)~='table' then return json.encode(value) end
    if #value>0 then local out={};for i,v in ipairs(value) do out[i]=R.canonical(v) end;return '['..table.concat(out,',')..']' end
    local keys={};for k in pairs(value) do keys[#keys+1]=k end;table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    local out={};for _,k in ipairs(keys) do out[#out+1]=json.encode(tostring(k))..':'..R.canonical(value[k]) end;return '{'..table.concat(out,',')..'}'
end
function R.hash(value) return love.data.encode('string','hex',love.data.hash('sha256',type(value)=='string' and value or R.canonical(value))) end
function R.build()
    if not R.buildId then
        local sources={}
        -- Include every gameplay dependency, including shared collision helpers.
        local function sourceTree(dir)
            local names=love.filesystem.getDirectoryItems(dir);table.sort(names)
            for _,name in ipairs(names) do
                local path=dir..'/'..name;local info=love.filesystem.getInfo(path)
                if info.type=='directory' then sourceTree(path)
                elseif name:match('%.lua$') then
                    sources[#sources+1]=path;sources[#sources+1]=assert(love.filesystem.read(path))
                end
            end
        end
        sourceTree('src')
        R.buildId=R.hash(table.concat(sources))
    end
    return R.buildId
end
function R.enter()
    assert(not R.entered,'Nested replay RNG scope');R.entered=true
    R.oldRandom=love.math.random;R.oldMathRandom=math.random
    love.math.random=function(...) return R.rng:random(...) end;math.random=love.math.random
end
function R.leave()
    if R.entered then love.math.random=R.oldRandom;math.random=R.oldMathRandom;R.entered=false end
    R.input=nil
end
function R.fail(err)
    R.leave()
    love.filesystem.write('replay-error.log','Frame '..tostring(R.frame)..'\n'..tostring(err))
    R.stop('Lecture interrompue : enregistrement incompatible ou endommagé.')
end
function R.begin(world)
    R.accumulator=0;R.frame=0;R.eventIndex=1;R.eventLeft=0;R.checkIndex=1;R.pendingFinish=nil;R.pendingScore=nil
    if not R.playing then
        R.data=nil
        local layouts=LevelLayouts.read()
        local seed=love.math.random(1,2147483646)
        R.data={version=1,build=R.build(),world=world,seed=seed,width=Arena.width,height=600,skin=Characters.selected(),effects=require('skin_effects').snapshot(),startLevel=player.level,single=not not App.singleLevel,hardcore=not not App.hardcore,layouts=json.decode(json.encode(layouts)),session=App.sessionLayout~=nil,states={},duel=Secret.duel and {kind=Secret.duel.kind,name=Secret.duel.name,time=0} or nil,inputs={},checks={},frames=0,startedAt=os.time()}
    end
    if not R.playing then require('replay_engine').remember(R.data.build) end
    R.rng=love.math.newRandomGenerator(R.data.seed);R.recording=not R.playing;R.enter()
end
function R.checkpoint()
    if R.legacy then return R.legacy.checkpoint() end
    return {R.frame,player.level,math.floor(player.x*100+.5),math.floor(player.y*100+.5),player.death,App.state=='victory' or App.state=='customVictory' or (App.state=='credits' and Ending.completed)}
end
function R.finish(score) R.pendingFinish=true;R.pendingScore=score end
function R.saveFinished()
    R.data.splits=RunDetails.snapshot();R.data.completed=true;R.data.frames=R.frame;R.data.time=timer;R.data.deaths=player.death
    local id=R.hash(R.data);love.filesystem.createDirectory('replays')
    local ok=love.filesystem.write('replays/'..id..'.json',json.encode(R.data))
    R.last=R.data;R.lastId=ok and id or nil
    if R.pendingScore and ok then R.pendingScore.replay=id;Profile.save();if Online.attachReplay then Online.attachReplay(id) end end
    if Workshop and Workshop.validationRun then Workshop.validationFinished(R.data,id) end
    R.recording=false;R.pendingFinish=nil;R.pendingScore=nil
end
function R.update(dt,tick)
    if R.recovery and not R.recovery.running then require('replay_recovery').update(R);return end
    if R.legacy then tick=R.legacy.tick end
    if R.ghost then R.updateGhost(dt,tick);return end
    if R.disabled then tick(dt);return end
    if not R.playing and not R.recording then tick(math.min(dt,.05));return end
    if R.playing and R.paused and not R.recovery then return end
    if R.job or R.recovery then R.accumulator=R.step*240 else R.accumulator=R.accumulator+math.min(dt,.25)*(R.playing and R.speed or 1) end
    local deadline=(R.job or R.recovery) and love.timer.getTime()+.012
    local limit=0
    while R.accumulator>=R.step and App.state=='playing' and limit<((R.job or R.recovery) and 240 or 32) and (not deadline or love.timer.getTime()<deadline) do
        R.accumulator=R.accumulator-R.step;limit=limit+1
        local x,y,slow
        if R.playing then
            if R.frame>=(R.playbackEnd or R.data.frames) then R.endPlayback();break end
            if R.eventLeft<=0 then local e=R.data.inputs[R.eventIndex];if not e then R.stop('Replay incomplet.');break end;R.event=e;R.eventLeft=e[1];R.eventIndex=R.eventIndex+1 end
            x,y,slow=R.event[2],R.event[3],R.event[4]==1;R.eventLeft=R.eventLeft-1
        else
            x,y=Input.move();slow=Input.slow()
            local list=R.data.inputs;local previous=list[#list];local s=slow and 1 or 0
            if previous and previous[2]==x and previous[3]==y and previous[4]==s then previous[1]=previous[1]+1 else list[#list+1]={1,x,y,s} end
        end
        R.frame=R.frame+1;R.data.frames=R.playing and R.data.frames or R.frame
        R.enter();R.input={x,y,slow};local ok,err=xpcall(function() if App.state=='playing' then tick(R.step) end end,debug.traceback);R.leave();if not ok then if R.playing then R.fail(err);break else error(err) end end
        if R.playing then
            local expected=R.data.checks[R.checkIndex]
            if expected and expected[1]==R.frame then
                local actual=R.checkpoint()
                if expected[2]~=actual[2] or expected[3]~=actual[3] or expected[4]~=actual[4] or expected[5]~=actual[5] or expected[6]~=actual[6] then
                    R.lastMismatch={expected=expected,actual=actual}
                    R.stop('Lecture arrêtée : simulation différente de la run enregistrée.');break
                end
                if R.data.states then
                    local ok,hash=pcall(function() return R.legacy and R.legacy.stateHash() or require('replay_state').hash() end)
                    if not ok then R.fail(hash);break end
                    if R.data.states[R.checkIndex]~=hash then R.stop('Lecture arrêtée : objets différents de la run enregistrée.');break end
                end
                R.checkIndex=R.checkIndex+1
            end
            if App.state~='playing' and R.frame<R.data.frames then
                R.stop('Lecture arrêtée : fin prématurée de la simulation.');break
            end
            if R.afterFrame() then break end
            if R.frame>=(R.playbackEnd or R.data.frames) then R.endPlayback();break end
        elseif R.frame%240==0 or R.pendingFinish then
            R.data.checks[#R.data.checks+1]=R.checkpoint()
            R.data.states[#R.data.states+1]=require('replay_state').hash()
            if R.pendingFinish then R.saveFinished();break end
        end
    end
end
function R.validate(data)
    if type(data)=='table' and ((data.hardcore~=nil and type(data.hardcore)~='boolean') or data.world==8 and data.hardcore~=true) then return false,'Mode de replay invalide.' end
    if type(data)~='table' or type(data.version)~='number' or data.version%1~=0 or data.version<1 then return false,'Replay invalide.' end
    if data.effects~=nil then
        if type(data.effects)~='table' then return false,'Effets de replay invalides.' end
        for key,value in pairs(data.effects) do if not ({gold=true,hardcore=true,heartbreak=true})[key] or type(value)~='boolean' then return false,'Effets de replay invalides.' end end
    end
    if not Worlds.playable(data.world) or type(data.inputs)~='table' or type(data.checks)~='table' or type(data.layouts)~='table' or type(data.seed)~='number' or data.seed%1~=0 or type(data.width)~='number' or data.width~=data.width or data.width<400 or data.width>4000 or type(data.frames)~='number' or data.frames<1 then return false,'Replay invalide.' end
    local function integer(n,lo,hi) return type(n)=='number' and n%1==0 and n>=lo and n<=hi end
    if data.completed~=true or type(data.single)~='boolean' or not integer(data.startLevel,1,Worlds.levelCount(data.world)) or not integer(data.skin,1,#Characters.keys) or not integer(data.seed,1,2147483646) or not integer(data.frames,1,5184000) or not integer(data.deaths,0,100000) or type(data.time)~='number' or data.time~=data.time or data.time<0 or data.time>86400 or data.height~=600 or #data.inputs>100000 or #data.checks>25000 then return false,'Replay invalide.' end
    if type(data.build)~='string' or not data.build:match('^[a-f0-9]+$') or #data.build~=64 then return false,'Version de replay invalide.' end
    if data.session~=nil and type(data.session)~='boolean' then return false,'Carte de replay invalide.' end
    if data.session and not data.layouts[data.world..':'..data.startLevel] then return false,'Carte de replay absente.' end
    if data.states~=nil then
        if type(data.states)~='table' or #data.states~=#data.checks then return false,'États de replay invalides.' end
        for _,hash in ipairs(data.states) do
            if type(hash)~='string' or #hash~=64 or not hash:match('^[a-f0-9]+$') then return false,'État de replay invalide.' end
        end
    end
    local frame=0
    for _,c in ipairs(data.checks) do
        if type(c)~='table' or not integer(c[1],frame+1,data.frames) or not integer(c[2],1,10) or not integer(c[3],-10000000,10000000) or not integer(c[4],-10000000,10000000) or not integer(c[5],0,100000) or type(c[6])~='boolean' then return false,'Vérification invalide.' end
        frame=c[1]
    end
    local last=data.checks[#data.checks]
    if not last or last[1]~=data.frames or last[5]~=data.deaths or not last[6] then return false,'Run inachevée.' end
    if data.duel and (type(data.duel)~='table' or (data.duel.kind~='mob' and data.duel.kind~='boss') or type(data.duel.name)~='string' or #data.duel.name>200) then return false,'Duel invalide.' end
    local total=0
    for _,e in ipairs(data.inputs) do
        if type(e)~='table' or type(e[1])~='number' or e[1]<1 or e[1]%1~=0 or type(e[2])~='number' or type(e[3])~='number' or e[2]~=e[2] or e[3]~=e[3] or math.abs(e[2])>1 or math.abs(e[3])>1 or (e[4]~=0 and e[4]~=1) then return false,'Commandes invalides.' end
        total=total+e[1]
    end
    if total~=data.frames or total>5184000 then return false,'Durée de replay invalide.' end
    for _,layout in pairs(data.layouts) do if not LayoutSchema.validate(layout) then return false,'Carte de replay invalide.' end end
    return true
end
function R.saveContext()
    if R.saved then return end
    R.saved={character=Profile.character,achievements=json.decode(json.encode(Profile.achievements)),selected=App.selectedWorld,
        returnTo=App.state=='victory' and 'victory' or App.state=='topRecords' and 'topRecords' or 'rankings',
        victory=(App.state=='victory' or UI.boardReturn=='victory') and require('victory_screen').run or nil}
end
function R.play(data,choice)
    local ok,why=R.validate(data);if not ok then R.status=why;return false end
    if data.version~=R.version then R.status='Format de replay inconnu.';return false end
    if not choice and data.build~=R.build() then
        if R.verified and R.verified.id==R.hash(data) then choice=R.verified.choice
        else return require('replay_recovery').start(R,data) end
    end
    local engine=choice and choice.engine
    if R.legacy then R.legacy.close();R.legacy=nil end
    R.job=nil;R.ghost=nil;R.ghostRetry=nil;R.levelStates={}
    R.saveContext()
    R.recording=false;R.playing=true;R.compatibility=false;R.sourceData=data;R.data=json.decode(json.encode(data));data=R.data;R.playbackEnd=choice and choice.untilFrame;R.speed=1;R.paused=false
    Secret.duel=data.duel and {kind=data.duel.kind,name=data.duel.name,time=0} or nil;App.sessionLayout=data.session and data.layouts[data.world..':'..data.startLevel] or nil;App.hardcore=data.hardcore==true;App.singleLevel=data.single;App.practice=data.startLevel;App.workshopMap=nil;App.preview=false
    R.lastMismatch=nil;R.frame=0;R.checkIndex=1
    local started,err=xpcall(function()
        if engine then
            R.legacy=require('replay_engine').create(engine,R)
            Arena.width=data.width;Campaign.select(data.world)
            R.legacy.start(choice.session==true)
        else App.start(data.world) end
    end,debug.traceback)
    if not started then R.fail(err);return false end
    R.status='';return true
end
function R.stop(message)
    R.leave()
    if R.legacy then R.legacy.close();R.legacy=nil end
    if R.recovery and R.recovery.running then R.recovery.result=message or 'Interrompu';R.accumulator=0;App.state='playing';return end
    R.recovery=nil;R.playbackEnd=nil;R.sourceData=nil
    R.job=nil;R.ghost=nil;R.ghostRetry=nil
    R.playing=false;R.compatibility=false;R.recording=false;R.input=nil;R.accumulator=0;R.paused=false
    local saved=R.saved
    if saved and saved.victory then require('victory_screen').run=saved.victory end
    if R.saved then Profile.character=R.saved.character;Profile.achievements=R.saved.achievements;App.selectedWorld=R.saved.selected;R.saved=nil end
    Secret.duel=nil;App.sessionLayout=nil;App.hardcore=false;App.singleLevel=false;App.practice=nil;App.state=saved and saved.returnTo or 'rankings';if App.state=='victory' and saved.victory then App.hardcore=saved.victory.hardcore end;R.status=message or 'Lecture arrêtée.'
end
function R.watch(score)
    R.status=''
    if type(score.replay)=='string' and #score.replay==64 and score.replay:match('^[a-f0-9]+$') then
        local raw=love.filesystem.read('replays/'..score.replay..'.json');local ok,data=pcall(json.decode,raw or '')
        if ok then return R.play(data) end
    end
    if type(score.runId)=='string' and score.runId:match('^[a-f0-9%-]+$') and #score.runId==36 and score.hasReplay then
        R.status='Chargement du replay…'
        Online.request('/v1/replays/'..score.runId,nil,function(data,code) if code==200 then R.play(data.replay) else R.status=data.error or 'Replay indisponible.' end end)
    else R.status='Cette ancienne run ne possède pas de replay.' end
end
Tools.install(R)
return R
