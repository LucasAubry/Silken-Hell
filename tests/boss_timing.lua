local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 local Timing=require('boss_attack_timing');local json=require('json')
 App.practice=1;App.start(6);require('run_start').active=false
 local originalKill=Hazards.kill;Hazards.kill=function()end
 for _,kind in ipairs({'merle','wasp','hedgehog','octopus','storm','skeleton_head'}) do
  local e={kind='boss',type=kind,x=460,y=260}
  local rows=Timing.spec(e);assert(rows and #rows>=3)
  local dummy={shotClock=.22,rest=.25,phaseTime=1.35,shot=.28};local before=json.encode(dummy);Timing.configure(dummy,e);assert(json.encode(dummy)==before,'Defaults remain untouched: '..kind)
  e.bossTimings={};for _,row in ipairs(rows) do e.bossTimings[row[1]]=row[3]+2 end
  local map={world=6,level=1,width=960,height=600,entities={{kind='spawn',x=800,y=500},e}}
  assert(require('layout_schema').validate(map))
  Bosses.load({e},{},{})
  local b=Bosses.items[1].boss
  for key,value in pairs(e.bossTimings) do assert(math.abs(b.bossTimings[key]-value)<1e-9,'Independent settings transferred: '..kind..' '..key) end
  if kind=='merle' then assert(b.shotClock==2.22);b.fire();assert(b.projectiles[1].life==5.5);assert(b.interval()==2.32)
  elseif kind=='wasp' then assert(b.rest==2.25);b.updateBees(.1);assert(not b.roundActive)
  elseif kind=='hedgehog' then assert(b.phaseTime==3.35 and b.shot==2.28);b.finishRound();assert(b.phaseTime==2.45)
  elseif kind=='octopus' then assert(b.shot==4 and b.summon==3.2)
  elseif kind=='storm' then assert(b.shot==2.7 and b.bolt==2.65);b.setPhase('leave');b.setPhase('flightTell');assert(math.abs(b.phaseTime-2.6)<.001)
  else local cycle=require('mobs.bosses.abyss.pattern_cycle');cycle.enter(b,'suction');assert(cycle.duration(b)==8.5) end
  local found=false
  for _,entry in ipairs(LevelLayouts.snapshot().entities) do if entry.kind=='boss' and entry.bossTimings then found=math.abs(entry.bossTimings[rows[1][1]]-rows[1][3]-2)<1e-9 end end
  assert(found,'Snapshot preserves boss timings: '..kind)
  e.bossTimings[rows[1][1]]=121;assert(not require('layout_schema').validate(map),'Invalid duration rejected')
 end
 -- Record and replay an actual custom encounter, including the nested settings.
 Replay.disabled=false;Replay.recording=false;Replay.data=nil;LevelLayouts.disabled=false
 App.sessionLayout={world=1,level=1,width=960,height=600,entities={{kind='spawn',x=80,y=500},{kind='boss',type='merle',x=480,y=280,bossTimings={firstShot=1.1,shotInterval=.4,featherLife=1.4}}}}
 App.singleLevel=true;App.hardcore=false
 Input.move=function() if Replay.input then return Replay.input[1],Replay.input[2] end;return 0,0 end
 Input.slow=function()return true end
 App.start(1);local State=require('replay_state');local initial=State.hash();local states={}
 local function tick(dt)
  App.simulate(dt)
  if Replay.playing then assert(states[Replay.frame]==State.hash(),'Boss replay state differs: '..Replay.frame) else states[Replay.frame]=State.hash() end
  if Replay.frame==240 then App.state='customVictory';if not Replay.playing then Replay.finish() end end
 end
 for i=1,240 do Replay.update(Replay.step,tick) end
 local recording=json.decode(json.encode(Replay.last));App.sessionLayout=nil;LevelLayouts.disabled=true
 assert(Replay.play(recording));assert(State.hash()==initial,'Boss settings restore the initial replay state')
 local count=0;while Replay.playing and count<400 do Replay.update(1/47,tick);count=count+1 end
 assert(Replay.status=='Lecture terminée.',Replay.status)
 Hazards.kill=originalKill
 print('PASS boss attack timings: all six encounters, native defaults, phase/shot overrides, independent instances, validation and snapshots');love.event.quit()
end
return T
