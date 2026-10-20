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
    -- History shares preview rendering, but must never consume editor map requests.
    if not App.preview or App.historyPreview then return end
    P.clock=P.clock+dt
    if P.clock<.15 then return end
    P.clock=0
    local now=os.time()
    if P.heartbeat~=now then love.filesystem.write('preview-heartbeat.txt',tostring(now));P.heartbeat=now end
    local r,raw=P.request()
    if not r or r.ticket==P.last then return end
    P.last=r.ticket;P.raw=raw
    if r.workshop then
        local allowed,why=require('workshop_access').check(r.layout)
        if not allowed then
            love.filesystem.write('preview-response.json',json.encode({ticket=r.ticket,message=why}))
            Workshop.status=why;App.state='workshop';return
        end
    end
    App.sessionLayout=r.layout; App.singleLevel=true; App.custom=true
    require('map_assets').load(r.layout)
    Campaign.select(r.layout.world); player.level=r.layout.level; timer=0; player.death=0
    App.state='playing'; reset_level()
end
return P
