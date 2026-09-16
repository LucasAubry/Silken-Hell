local json=require 'json'
local N={country='ZZ',connected=false,boards={},callbacks={},sequence=0,runs={},clock=0,nextPoll=0,scoreStatus='',enabled=true}
local config=require 'online_config'
local function saveOutbox()
    local rows={}
    for _,r in ipairs(N.runs) do
        if r.id and not r.failed and #r.pending>0 then rows[#rows+1]={id=r.id,world=r.world,pending=r.pending} end
    end
    love.filesystem.write('online-outbox.json',json.encode(rows))
end
local function request(path,body,callback)
    N.sequence=N.sequence+1; N.callbacks[N.sequence]=callback
    love.thread.getChannel('silken.requests'):push({id=N.sequence,url=config.url..path,method=body and 'POST' or 'GET',body=body,token=body and N.token or nil})
end
function N.refresh(world)
    if not N.enabled then return end
    local b=N.boards[world] or {}; N.boards[world]=b
    if world==3 then b.global={}; b.country={}; return end
    if b.loading then return end
    b.loading=true; b.requested=N.clock; b.remaining=2
    for _,scope in ipairs({'global','country'}) do local key=scope
        request('/v1/leaderboard?world='..world..'&scope='..scope,nil,function(data,code)
            b.remaining=b.remaining-1; b.loading=b.remaining>0
            if code==200 and type(data.scores)=='table' then b[key]=data.scores; b.error=false; b.updated=N.clock
            else b.error=true end
        end)
    end
end
function N.scores(world,country)
    if not N.enabled then return Profile.ranking(world,country and Profile.country or nil),'local' end
    local b=N.boards[world]
    if not b or (not b.loading and N.clock-(b.requested or -60)>30) then N.refresh(world); b=N.boards[world] end
    local data=b[country and 'country' or 'global']
    if data then return data,b.error and 'cached' or 'online' end
    return {},b.error and 'offline' or 'loading'
end
function N.locate()
    N.nextPoll=N.clock+30
    request('/v1/location',nil,function(data,code)
        if code==200 and type(data.country)=='string' and data.country:match('^%u%u$') then
            N.country=data.country; Profile.country=data.country; Profile.save()
        end
    end)
end
function N.init()
    N.enabled=os.getenv('SILKEN_TEST')~='1'
    if not N.enabled then N.country='FR'; return end
    N.token=love.filesystem.read('online-identity.txt')
    if not N.token or not N.token:match('^[a-f0-9]+$') or #N.token~=64 then
        local file=io.open('/dev/urandom','rb'); local bytes=file and file:read(32)
        if file then file:close() end
        if not bytes or #bytes~=32 then N.enabled=false; return end
        N.token=love.data.encode('string','hex',bytes); love.filesystem.write('online-identity.txt',N.token)
    end
    local ok,rows=pcall(json.decode,love.filesystem.read('online-outbox.json') or '[]')
    if ok and type(rows)=='table' then
        for _,r in ipairs(rows) do if type(r.id)=='string' and type(r.pending)=='table' and Worlds.playable(r.world) then N.runs[#N.runs+1]=r end end
    end
    N.thread=love.thread.newThread('network_thread.lua'); N.thread:start()
    N.locate(); N.refresh(1)
end
function N.start(world,name,skin)
    N.current=nil; N.scoreStatus='Partie hors ligne'
    if not N.enabled then return end
    local run={world=world,pending={},starting=true}; N.runs[#N.runs+1]=run; N.current=run
    N.scoreStatus='Connexion au classement…'
    request('/v1/runs',{world=world,name=name,skin=skin or 1},function(data,code)
        run.starting=false
        if code==201 and type(data.id)=='string' then
            run.id=data.id
            if N.current==run then N.scoreStatus='Partie classée'; N.country=data.country or N.country end
            N.flush(run)
        else
            run.failed=true
            if N.current==run then N.scoreStatus='Score conservé en local (connexion indisponible)' end
        end
    end)
end
function N.checkpoint(level,time,deaths)
    local r=N.current
    if not N.enabled or not r or r.failed then return end
    r.pending[#r.pending+1]={level=level,elapsedMs=math.floor(time*1000+0.5),deaths=deaths}
    if level==10 then N.scoreStatus='Envoi du score…' end
    saveOutbox(); N.flush(r)
end
function N.flush(r)
    if not r.id or r.busy or r.failed or #r.pending==0 or (r.retryAt and N.clock<r.retryAt) then return end
    r.busy=true
    local checkpoint=r.pending[1]
    request('/v1/runs/'..r.id..'/checkpoint',checkpoint,function(data,code)
        r.busy=false
        if code==200 then
            table.remove(r.pending,1); saveOutbox()
            if checkpoint.level==10 then
                if N.current==r then N.scoreStatus='Score publié dans les classements' end
                N.refresh(r.world)
            end
            N.flush(r)
        elseif code==0 or code>=500 or code==429 then
            r.retryAt=N.clock+15
            if N.current==r then N.scoreStatus='Score en attente de connexion' end
        else
            r.failed=true; saveOutbox()
            if N.current==r then N.scoreStatus='Score local uniquement : '..(data.error or 'validation refusée') end
        end
    end)
end
function N.update(dt)
    if not N.enabled then return end
    N.clock=N.clock+dt
    local channel=love.thread.getChannel('silken.responses')
    while channel:getCount()>0 do
        local response=channel:pop(); local cb=N.callbacks[response.id]; N.callbacks[response.id]=nil
        N.connected=response.code>0 and response.code<500
        local ok,data=pcall(json.decode,response.body)
        if cb then cb(ok and type(data)=='table' and data or {},response.code) end
    end
    if N.clock>=N.nextPoll then N.locate() end
    for _,r in ipairs(N.runs) do N.flush(r) end
end
function N.quit()
    if N.enabled then
        saveOutbox()
        local channel=love.thread.getChannel('silken.requests'); channel:clear(); channel:push('quit')
    end
end
return N
