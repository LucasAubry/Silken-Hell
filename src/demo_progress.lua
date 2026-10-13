-- Steamworks must bind the signed-in account before enabling demo rewards.
-- demo-entitlements.json is intended for shared Steam Cloud between both App IDs.
local D={}
local json=require('json')
function D.bindAccount(steamId)
 D.account=type(steamId)=='string' and steamId:match('^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$') and steamId or nil
 local ok,data=pcall(json.decode,love.filesystem.read('demo-entitlements.json') or '{}')
 D.accounts=ok and type(data)=='table' and data or {}
end
function D.unlocked() return D.account~=nil and (D.accounts or {})[D.account]==true end
function D.active()
 if os.getenv('SILKEN_DEMO')=='1' then return true end
 for _,value in ipairs(arg or {}) do if value=='--demo' then return true end end
 return false
end
function D.played()
 if not D.account or not D.active() or Replay.playing or App.preview or App.sessionLayout or D.unlocked() then return false end
 D.accounts[D.account]=true
 if not love.filesystem.write('demo-entitlements.json',json.encode(D.accounts)) then D.accounts[D.account]=nil;return false end
 return true
end
return D
