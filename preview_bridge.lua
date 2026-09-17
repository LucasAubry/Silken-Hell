local json=require 'json'
local P={clock=0,last=nil}
function P.update(dt)
    if not App.preview then return end
    P.clock=P.clock+dt
    if P.clock<.15 then return end
    P.clock=0
    love.filesystem.write('preview-heartbeat.txt',tostring(os.time()))
    local raw=love.filesystem.read('preview-request.json')
    if not raw then return end
    local ok,r=pcall(json.decode,raw)
    if not ok or not r.ticket or r.ticket==P.last or not r.layout then return end
    local valid=LayoutSchema.validate(r.layout)
    if not valid then return end
    P.last=r.ticket; App.sessionLayout=r.layout; App.singleLevel=true; App.custom=true
    Campaign.select(r.layout.world); player.level=r.layout.level; timer=0; player.death=0
    App.state='playing'; reset_level()
end
return P
