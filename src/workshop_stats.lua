local S={pending={},clock=0,nextSend=0}
local json=require('json')
local function save() love.filesystem.write('workshop-stats-outbox.json',json.encode(S.pending)) end
function S.queue()
 local r=S.run;if not r then return end
 S.pending[r.id]={map=r.map,version=r.version,id=r.id,deaths=r.deaths,completed=r.completed,elapsed=timer or 0,hotspots=r.hotspots}
 -- Detach snapshots from the active session before asynchronous requests.
 S.pending[r.id]=json.decode(json.encode(S.pending[r.id]));save()
end
function S.begin()
 S.run=nil
 if not App.workshopMap or App.workshopMap.owned or Replay.playing then return end
 S.run={map=App.workshopMap.id,version=App.workshopMap.updated_at,id=love.data.encode('string','hex',require('platform').randomBytes(16)),deaths=0,completed=false,hotspots={[player.level..':0:0']=0}}
 S.queue()
end
function S.death()
 local r=S.run;if not r or Replay.playing or r.completed or r.deaths>=player.death then return end
 local key=player.level..':'..math.max(0,math.min(3,math.floor((player.x+15)/Arena.width*4)))..':'..math.max(0,math.min(2,math.floor((player.y+12)/200)))
 local delta=player.death-r.deaths;r.deaths=player.death;r.hotspots[key]=(r.hotspots[key] or 0)+delta;S.queue()
end
function S.update(dt)
 if not S.loaded then
  local ok,p=pcall(json.decode,love.filesystem.read('workshop-stats-outbox.json') or '{}')
  if ok then for k,v in pairs(p) do if not S.pending[k] then S.pending[k]=v end end end
  S.loaded=true
 end
 S.clock=S.clock+dt
 if S.run and App.state=='customVictory' and not S.run.completed and not Replay.playing then S.run.completed=true;S.queue() end
 if S.run and (not App.workshopMap or App.workshopMap.id~=S.run.map) then S.run=nil end
 if S.sending or S.clock<S.nextSend or not Online.enabled then return end
 local id,p=next(S.pending);if not id then return end
 S.sending=true;S.nextSend=S.clock+2
 Online.request('/v1/workshop/'..p.map..'/session',p,function(_,code)
  S.sending=false
  if code==200 or code==404 or code==400 or code==403 then if S.pending[id]==p then S.pending[id]=nil;save() end
  else S.nextSend=S.clock+15 end
 end)
end
return S
