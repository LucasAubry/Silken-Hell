-- Spectator-only replay transport. Playback never switches into a playable ghost.
local T={}
local json=require 'json'
function T.install(R)
 R.speeds={.25,.5,1,2,4,8}
 function R.beforeLevelReset()
  if not R.playing or not R.rng then return end
  if R.levelStates and not R.levelStates[player.level] then
   R.levelStates[player.level]={rng=R.rng:getState(),starts=json.decode(json.encode(Campaign.starts)),side=Campaign.lastSide}
  end
 end
 function R.changeSpeed(delta,wrap)
  local index=3;for i,v in ipairs(R.speeds) do if v==R.speed then index=i end end
  index=index+(delta or 1)
  if wrap then index=(index-1)%#R.speeds+1 else index=math.max(1,math.min(#R.speeds,index)) end
  R.speed=R.speeds[index]
 end
 function R.levels()
  local result={};if not R.data then return result end
  local first=R.data.startLevel;local last=R.data.single and first or R.data.checks[#R.data.checks][2]
  for n=first,last do result[#result+1]=n end;return result
 end
 function R.seekLevel(n)
  local valid=false;for _,v in ipairs(R.levels()) do if v==n then valid=true end end;if not valid then return false end
  local data,saved,paused,speed=R.data,R.saved,R.paused,R.speed
  if not R.play(data) then return false end
  R.saved=saved or R.saved;R.speed=speed
  R.job={level=n,restorePaused=paused};R.paused=false
  if player.level==n then R.job=nil;R.paused=paused end
  return true
 end
 function R.afterFrame()
  local job=R.job;if not job then return false end
  if player.level==job.level then R.job=nil;R.paused=job.restorePaused;R.accumulator=0;return true end
  return false
 end
 function R.endPlayback()
  if R.job then R.stop('Ce niveau est absent de cet enregistrement.') else R.stop('Lecture terminée.') end
 end
 function R.drawGhost() end
 function R.key(key)
  local k=Profile.keys
  if key=='escape' then R.stop()
  elseif key==k.pause or key=='space' then if not R.job then R.paused=not R.paused end
  elseif key==k.replayFaster or key=='right' then R.changeSpeed(1)
  elseif key==k.replaySlower or key=='left' then R.changeSpeed(-1)
  elseif key==k.restartLevel then R.seekLevel(player.level)
  elseif key==k.restartWorld then R.seekLevel(R.data.startLevel) end
 end
 function R.controls()
  local U=UI;local k=Profile.keys
  U.button('x'..R.speed,890,13,145,36,function() R.changeSpeed(1,true) end)
  U.panel(160,656,880,81)
  if R.job then
   U.text('Recherche du niveau '..R.job.level..' · '..math.floor(R.frame/R.data.frames*100)..' %',180,671,'body',nil,840,'center')
   return
  end
  U.text('NIVEAU',180,674,'small');local levels=R.levels()
  for i,n in ipairs(levels) do local target=n;U.button(tostring(n),250+(i-1)*50,664,45,32,function() R.seekLevel(target) end,false,player.level==n) end
  U.button('Recommencer',815,664,200,32,function() R.seekLevel(player.level) end)
  local label=R.paused and 'Spectateur · PAUSE' or 'Spectateur'
  U.text(label..'   |   '..Input.label(k.pause)..' : pause   '..Input.label(k.replaySlower)..' / '..Input.label(k.replayFaster)..' : vitesse   '..Input.label(k.restartLevel)..' : rejouer',180,708,'small',nil,840,'center')
 end
end
return T
