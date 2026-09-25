-- Replay transport and isolated ghost practice. Ghosts are drawn only: never actors.
local T={}
local json=require 'json'
function T.install(R)
 R.speeds={.25,.5,1,2,4,8}
 function R.beforeLevelReset()
  if not R.playing or not R.rng then return end
  if R.ghost and R.ghost.levelState then
   local state=R.ghost.levelState;R.rng:setState(state.rng)
   Campaign.starts=json.decode(json.encode(state.starts));Campaign.lastSide=state.side
  elseif R.levelStates and not R.levelStates[player.level] then
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
 local function sample(job)
  local t=R.frame-job.startFrame
  local last=job.samples[#job.samples]
  if not last or t-last.t>=(job.interval or 3) or last.deaths~=player.death then
   job.samples[#job.samples+1]={t=t,x=player.x+15,y=player.y+12,dir=direction,deaths=player.death}
   if #job.samples>20000 then local compact={};for i=1,#job.samples,2 do compact[#compact+1]=job.samples[i] end;job.samples=compact;job.interval=(job.interval or 3)*2 end
  end
 end
 function R.seekLevel(n,ghost)
  local valid=false;for _,v in ipairs(R.levels()) do if v==n then valid=true end end;if not valid then return false end
  local data,saved,paused,speed=R.data,R.saved,R.paused,R.speed
  if not R.play(data) then return false end
  R.saved=saved or R.saved;R.speed=speed
  R.job={level=n,ghost=ghost==true,samples={},restorePaused=paused};R.paused=false
  if player.level==n then
   if ghost then R.job.startFrame=0;sample(R.job)
   else R.job=nil;R.paused=paused end
  end
  return true
 end
 function R.startGhost(job)
  R.job=nil;R.ghost={level=job.level,samples=job.samples,levelState=R.levelStates[job.level],duration=math.max(1,(job.endFrame or R.frame)-job.startFrame),index=1,attempts=0}
  R.restartGhost()
 end
 function R.restartGhost()
  if not R.ghost then return end
  local ghost=R.ghost
  App.practice=ghost.level;App.singleLevel=true;App.hardcore=false;R.paused=false;R.input=nil
  App.start(R.data.world)
  R.ghost=ghost;R.playing=true;R.recording=false;ghost.index=1;ghost.attempts=ghost.attempts+1;ghost.won=false
  R.generation=(R.generation or 0)+1
 end
 function R.afterFrame()
  local job=R.job;if not job then return false end
  if player.level==job.level then
   if not job.ghost then R.job=nil;R.paused=job.restorePaused;R.accumulator=0;return true end
   if not job.startFrame then job.startFrame=R.frame end
   sample(job)
  end
  if job.ghost and job.startFrame and (player.level~=job.level or App.state=='victory' or App.state=='customVictory') then
   job.endFrame=R.frame;R.startGhost(job);return true
  end
  return false
 end
 function R.endPlayback()
  local job=R.job
  if job and job.ghost and job.startFrame then job.endFrame=R.frame;R.startGhost(job)
  elseif job then R.stop('Ce niveau est absent de cet enregistrement.')
  else R.stop('Lecture terminée.') end
 end
 function R.updateGhost(dt,tick)
  if R.paused then return end
  R.accumulator=R.accumulator+math.min(dt,.25)*R.speed
  local steps=0;local generation=R.generation
  while R.accumulator>=R.step and steps<32 do
   R.accumulator=R.accumulator-R.step;R.frame=R.frame+1;steps=steps+1
   R.enter();R.input=nil;local ok,err=xpcall(function() tick(R.step) end,debug.traceback);R.leave();if not ok then error(err) end
   if R.ghostRetry then R.ghostRetry=nil;R.restartGhost();break end
   if generation~=R.generation then break end
   if App.state=='victory' or App.state=='customVictory' then R.ghost.won=true;R.paused=true;App.state='playing';break end
  end
 end
 function R.drawGhost()
  local ghost=R.ghost;if not ghost then return end
  local list=ghost.samples;if #list==0 then return end
  while ghost.index<#list and list[ghost.index+1].t<=R.frame do ghost.index=ghost.index+1 end
  local a=list[ghost.index];local b=list[math.min(#list,ghost.index+1)];local t=b.t>a.t and math.min(1,(R.frame-a.t)/(b.t-a.t)) or 0
  if a.deaths~=b.deaths then t=0 end -- Never interpolate a death across the map.
  local x,y=a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t
  local g=love.graphics;g.push('all');g.setColor(.4,.9,1,.4);Characters.portrait(R.data.skin,x,y,48,a.dir)
  g.setColor(.5,.95,1,.7);g.setLineWidth(1.5);g.ellipse('line',x,y,24,18);g.pop()
 end
 function R.key(key)
  local k=Profile.keys
  if key=='escape' then R.stop()
  elseif key==k.pause or (not R.ghost and key=='space') then if not R.job then R.paused=not R.paused end
  elseif key==k.replayFaster or (not R.ghost and key=='right') then R.changeSpeed(1)
  elseif key==k.replaySlower or (not R.ghost and key=='left') then R.changeSpeed(-1)
  elseif key==k.restartLevel then if R.ghost then R.restartGhost() else R.seekLevel(player.level) end
  elseif key==k.restartWorld then R.seekLevel(R.data.startLevel)
  elseif key==k.ghost and not R.ghost and not R.job then R.seekLevel(player.level,true) end
 end
 function R.controls()
  local U=UI;local k=Profile.keys
  U.button('x'..R.speed,790,13,78,36,function() R.changeSpeed(1,true) end)
  U.button(R.ghost and 'Revoir' or 'Jouer / fantôme',878,13,170,36,function() R.seekLevel(player.level,not R.ghost) end,R.job~=nil)
  U.panel(160,656,880,81)
  if R.job then
   U.text((R.job.ghost and 'Préparation du fantôme' or 'Recherche du niveau')..' '..R.job.level..' · '..math.floor(R.frame/R.data.frames*100)..' %',180,671,'body',nil,840,'center')
   U.text('Échap : quitter · préparation sans modifier tes scores',180,708,'small',nil,840,'center');return
  end
  U.text('NIVEAU',180,674,'small');local levels=R.levels()
  for i,n in ipairs(levels) do local target=n;U.button(tostring(n),250+(i-1)*50,664,45,32,function() R.seekLevel(target,R.ghost~=nil) end,false,player.level==n) end
  U.button('Recommencer',815,664,200,32,function() if R.ghost then R.restartGhost() else R.seekLevel(player.level) end end)
  local label=R.ghost and (R.ghost.won and 'Niveau réussi !' or 'Entraînement fantôme · non classé') or 'Replay'
  if R.ghost and R.frame>=R.ghost.duration then label=label..' · fantôme arrivé' end
  if R.paused then label=label..' · PAUSE' end
  U.text(label..'   |   '..Input.label(k.pause)..' : pause   '..Input.label(k.replaySlower)..' / '..Input.label(k.replayFaster)..' : vitesse   '..Input.label(k.restartLevel)..' : rejouer',180,708,'small',nil,840,'center')
 end
end
return T
