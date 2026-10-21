local json=require 'json'
local P={clock=0,last=nil}
function P.request()
    local raw=love.filesystem.read('preview-request.json')
    if not raw or raw==P.raw then return end
    local ok,r=pcall(json.decode,raw)
    if not ok or not r.ticket or not r.layout or not LayoutSchema.validate(r.layout) then return end
    return r,raw
end
function P.update(dt)
    -- Every open game can receive an explicit test request from the editor.
    P.clock=P.clock+dt
    if P.clock<.15 then return end
    P.clock=0
    local now=os.time()
    if P.heartbeat~=now then love.filesystem.write('preview-heartbeat.txt',tostring(now));P.heartbeat=now end
    local r,raw=P.request()
    if not r or r.ticket==P.last then return end
    P.last=r.ticket;P.raw=raw
    P.load(r)
end
function P.load(r)
    if r.workshop then
        local allowed,why=require('workshop_access').check(r.layout)
        if not allowed then
            love.filesystem.write('preview-response.json',json.encode({ticket=r.ticket,message=why}))
            P.error=why;Workshop.status=why;App.state='workshop';return
        end
    end
    if Replay.playing or Replay.ghost then Replay.stop() end
    App.preview=true;App.historyPreview=false;App.hardcore=false;App.practice=nil;Secret.duel=nil
    App.sessionLayout=r.layout; App.singleLevel=true; App.custom=true
    require('map_assets').load(r.layout)
    App.start(r.layout.world,{skipArrival=true})
    App.custom=true
    P.error=nil;return true
end
function P.reload()
    if not App.preview or App.historyPreview or Replay.playing then return false end
    local raw=love.filesystem.read('preview-draft.json') or love.filesystem.read('preview-request.json')
    local ok,r=pcall(json.decode,raw or '')
    if not ok or type(r)~='table' or r.ticket~=P.last or type(r.layout)~='table' then
        P.error='Rouvre ce niveau dans l’éditeur puis clique sur Tester.';return false
    end
    LayoutSchema.migrate(r.layout)
    local valid,why=LayoutSchema.validate(r.layout)
    if not valid then P.error=why;return false end
    return P.load(r)
end
return P
