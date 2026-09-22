local json=require 'json'
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
        for _,name in ipairs({'main','campaign','input','realms','hazards','arena','level_layouts','replay','level','player','hit_box','objet','burning','aftermath','breathing_bubble','abyss_terrain','secret','world','effect'}) do sources[#sources+1]=assert(love.filesystem.read(name..'.lua')) end
        local function actorSources(dir)
            local names=love.filesystem.getDirectoryItems(dir);table.sort(names)
            for _,name in ipairs(names) do local path=dir..'/'..name;local info=love.filesystem.getInfo(path)
                if info.type=='directory' then actorSources(path)
                elseif name:match('%.lua$') then sources[#sources+1]=assert(love.filesystem.read(path)) end
            end
        end
        actorSources('mobs')
        for i=1,10 do sources[#sources+1]=assert(love.filesystem.read('levels/level_'..i..'.lua')) end
        for _,name in ipairs({'worlds','scoring','layout_schema'}) do sources[#sources+1]=assert(love.filesystem.read(name..'.lua')) end
        R.buildId=R.hash(table.concat(sources))
    end
    return R.buildId
end
function R.enter()
    R.oldRandom=love.math.random;R.oldMathRandom=math.random
    love.math.random=function(...) return R.rng:random(...) end;math.random=love.math.random
end
function R.leave() love.math.random=R.oldRandom;math.random=R.oldMathRandom;R.input=nil end
function R.begin(world)
    R.accumulator=0;R.frame=0;R.eventIndex=1;R.eventLeft=0;R.checkIndex=1;R.pendingFinish=nil;R.pendingScore=nil
    if not R.playing then
        R.data=nil
        local layouts=LevelLayouts.read()
        local seed=love.math.random(1,2147483646)
        R.data={version=1,build=R.build(),world=world,seed=seed,width=Arena.width,height=600,skin=Characters.selected(),startLevel=player.level,single=not not App.singleLevel,layouts=json.decode(json.encode(layouts)),duel=Secret.duel and {kind=Secret.duel.kind,name=Secret.duel.name,time=0} or nil,inputs={},checks={},frames=0,startedAt=os.time()}
    end
    R.rng=love.math.newRandomGenerator(R.data.seed);R.recording=not R.playing;R.enter()
end
function R.checkpoint()
    return {R.frame,player.level,math.floor(player.x*100+.5),math.floor(player.y*100+.5),player.death,App.state=='victory' or App.state=='customVictory'}
end
function R.finish(score) R.pendingFinish=true;R.pendingScore=score end
function R.saveFinished()
    R.data.completed=true;R.data.frames=R.frame;R.data.time=timer;R.data.deaths=player.death
    local id=R.hash(R.data);love.filesystem.createDirectory('replays')
    local ok=love.filesystem.write('replays/'..id..'.json',json.encode(R.data))
    R.last=R.data;R.lastId=ok and id or nil
    if R.pendingScore and ok then R.pendingScore.replay=id;Profile.save();if Online.attachReplay then Online.attachReplay(id) end end
    if Workshop and Workshop.validationRun then Workshop.validationFinished(R.data,id) end
    R.recording=false;R.pendingFinish=nil;R.pendingScore=nil
end
function R.update(dt,tick)
    if R.disabled then tick(dt);return end
    if not R.playing and not R.recording then tick(math.min(dt,.05));return end
    if R.playing and R.paused then return end
    R.accumulator=R.accumulator+math.min(dt,.25)*(R.playing and R.speed or 1)
    local limit=0
    while R.accumulator>=R.step and App.state=='playing' and limit<32 do
        R.accumulator=R.accumulator-R.step;limit=limit+1
        local x,y,slow
        if R.playing then
            if R.frame>=R.data.frames then R.stop('Lecture terminée.');break end
            if R.eventLeft<=0 then local e=R.data.inputs[R.eventIndex];if not e then R.stop('Replay incomplet.');break end;R.event=e;R.eventLeft=e[1];R.eventIndex=R.eventIndex+1 end
            x,y,slow=R.event[2],R.event[3],R.event[4]==1;R.eventLeft=R.eventLeft-1
        else
            x,y=Input.move();slow=Input.slow()
            local list=R.data.inputs;local previous=list[#list];local s=slow and 1 or 0
            if previous and previous[2]==x and previous[3]==y and previous[4]==s then previous[1]=previous[1]+1 else list[#list+1]={1,x,y,s} end
        end
        R.frame=R.frame+1;R.data.frames=R.playing and R.data.frames or R.frame
        R.enter();R.input={x,y,slow};local ok,err=xpcall(function() tick(R.step) end,debug.traceback);R.leave();if not ok then error(err) end
        local actual=R.checkpoint()
        if R.playing then
            local expected=R.data.checks[R.checkIndex]
            if expected and expected[1]==R.frame then
                if expected[2]~=actual[2] or expected[3]~=actual[3] or expected[4]~=actual[4] or expected[5]~=actual[5] or expected[6]~=actual[6] then R.stop('Lecture arrêtée : simulation différente de la run enregistrée.');break end
                R.checkIndex=R.checkIndex+1
            end
            if R.frame>=R.data.frames then R.stop('Lecture terminée.');break end
        elseif R.frame%240==0 or R.pendingFinish then
            R.data.checks[#R.data.checks+1]=actual
            if R.pendingFinish then R.saveFinished();break end
        end
    end
end
function R.validate(data)
    if type(data)~='table' or data.version~=1 or data.build~=R.build() then return false,'Replay créé avec une autre version du jeu.' end
    if not Worlds.playable(data.world) or type(data.inputs)~='table' or type(data.checks)~='table' or type(data.layouts)~='table' or type(data.seed)~='number' or data.seed%1~=0 or type(data.width)~='number' or data.width~=data.width or data.width<400 or data.width>4000 or type(data.frames)~='number' or data.frames<1 then return false,'Replay invalide.' end
    local function integer(n,lo,hi) return type(n)=='number' and n%1==0 and n>=lo and n<=hi end
    if data.completed~=true or type(data.single)~='boolean' or not integer(data.startLevel,1,Worlds.levelCount(data.world)) or not integer(data.skin,1,14) or not integer(data.seed,1,2147483646) or not integer(data.frames,1,5184000) or not integer(data.deaths,0,100000) or type(data.time)~='number' or data.time~=data.time or data.time<0 or data.time>86400 or data.height~=600 or #data.inputs>100000 or #data.checks>25000 then return false,'Replay invalide.' end
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
function R.play(data)
    local ok,why=R.validate(data);if not ok then R.status=why;return false end
    R.saved={character=Profile.character,achievements=json.decode(json.encode(Profile.achievements)),selected=App.selectedWorld}
    R.recording=false;R.playing=true;R.data=data;R.speed=1;R.paused=false
    Secret.duel=data.duel and {kind=data.duel.kind,name=data.duel.name,time=0} or nil;App.sessionLayout=nil;App.singleLevel=data.single;App.practice=data.startLevel;App.workshopMap=nil;App.preview=false
    App.start(data.world);R.status='';return true
end
function R.stop(message)
    R.playing=false;R.recording=false;R.input=nil;R.accumulator=0;R.paused=false
    if R.saved then Profile.character=R.saved.character;Profile.achievements=R.saved.achievements;App.selectedWorld=R.saved.selected;R.saved=nil end
    Secret.duel=nil;App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;App.state='rankings';R.status=message or 'Lecture arrêtée.'
end
function R.watch(score)
    if type(score.replay)=='string' and #score.replay==64 and score.replay:match('^[a-f0-9]+$') then
        local raw=love.filesystem.read('replays/'..score.replay..'.json');local ok,data=pcall(json.decode,raw or '')
        if ok then return R.play(data) end
    end
    if type(score.runId)=='string' and score.runId:match('^[a-f0-9%-]+$') and #score.runId==36 and score.hasReplay then
        R.status='Chargement du replay…'
        Online.request('/v1/replays/'..score.runId,nil,function(data,code) if code==200 then R.play(data.replay) else R.status=data.error or 'Replay indisponible.' end end)
    else R.status='Cette ancienne run ne possède pas de replay.' end
end
return R
