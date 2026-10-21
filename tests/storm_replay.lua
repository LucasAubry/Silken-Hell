local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=false;Profile.save=function()end;Profile.record=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end
 local json=require('json');local State=require('replay_state')
 Hazards.kill=function()end;Campaign.canCollect=function()return false end
 App.sessionLayout={world=6,level=10,width=960,height=600,environment={lightning=false},entities={{kind='spawn',x=480,y=300},{kind='boss',type='storm',x=480,y=140}}}
 App.singleLevel=true;App.practice=nil;App.hardcore=false;LevelLayouts.disabled=false;Replay.recording=false;Replay.data=nil
 Input.move=function()
  if Replay.input then return Replay.input[1],Replay.input[2] end
  return 0,0
 end
 Input.slow=function()return true end
 App.start(6);require('run_start').active=false
 local initial=State.hash();local states={};local waves={};local rise,strike,clean=false,false,false
 local function tick(dt)
  local b=Bosses.items[1].boss
  -- Reproducible crossing fixture exercises actual silk collision, not direct HP edits.
  if b.phase=='hunt' and b.phaseAge>1 then
   local ax,ay=b.anchor()
   for _,p in ipairs(b.snails)do if p.phase=='tethered' then player.x=(ax+p.x)/2-15;player.y=(ay+p.y)/2-12;break end end
  end
  App.simulate(dt);waves[b.wave]=true;clean=clean or b.phase=='clean'
  for _,p in ipairs(b.snails)do rise=rise or p.phase=='rise';strike=strike or p.phase=='strike' end
  if Replay.playing then assert(states[Replay.frame]==State.hash(),'Silk replay diverged at '..Replay.frame)
  else states[Replay.frame]=State.hash()end
  if Replay.frame==2200 then App.state='customVictory';if not Replay.playing then Replay.finish()end end
 end
 for _=1,2200 do Replay.update(Replay.step,tick)end
 assert(waves[2] and rise and strike and clean,'Replay includes physics, freed attacks, hole cleanup and next wave')
 local recording=json.decode(json.encode(Replay.last));App.sessionLayout=nil;LevelLayouts.disabled=true
 assert(Replay.play(recording));require('run_start').active=false;assert(State.hash()==initial,'Replay restores encounter')
 local count=0
 while Replay.playing and count<2800 do Replay.update(1/47,tick);count=count+1 end
 assert(Replay.status=='Lecture terminée.',Replay.status)
 print('PASS silk Merle replay: full-state physical tethers, cut collisions, homing snails, cleanup and waves at different playback cadence')
 love.event.quit()
end
return T
