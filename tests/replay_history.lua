local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=false;love.focus=function()end
 Profile.save=function()end;Bestiary.save=function()end
 local json=require 'json'
 local E=require 'replay_engine';local engine=E.catalog().engines[1]
 local record={version=1,build=engine.build,world=6,seed=4321,width=960,height=600,skin=1,startLevel=1,single=true,session=true,hardcore=false,completed=true,
  frames=1,deaths=0,time=0,startedAt=engine.time,inputs={},checks={},layouts={['6:1']={world=6,level=1,width=960,height=600,entities={{kind='spawn',x=80,y=300},{kind='tear',x=400,y=300}}}}}
 local stats=json.encode(Profile.stats);local original=player
 Replay.saveContext();Replay.playing=true;Replay.data=record
 Replay.legacy=E.create(engine,Replay);Replay.legacy.start(true)
 -- Redrawing a PNG must never pair the new atlas quad with historical pivots.
 for _,key in ipairs({'gull_down','gull_up','gull_left','gull_right','cloud_snare'}) do
  local art=Replay.legacy.env.Art.images[key]
  local _,_,w,h=art.quad:getViewport()
  assert(w==art.w and h==art.h,'Historical '..key..' retains its matching image bounds')
  assert(not Art.images[key] or art.image~=Art.images[key].image,'Historical Sky sprites retain their original PNG')
 end
 for frame=1,1000 do
  Replay.frame=frame;Replay.enter();Replay.input={frame<=300 and 0 or 1,0,false};Replay.legacy.tick(1/60);Replay.leave()
  if frame%240==0 or App.state~='playing' then record.checks[#record.checks+1]=Replay.checkpoint() end
  if App.state~='playing' then record.frames=frame;break end
 end
 assert(App.state=='customVictory','Historical fixture must finish by collecting its tear')
 record.inputs={{300,0,0,0},{record.frames-300,1,0,0}};record.time=timer;record.deaths=player.death
 Replay.stop();assert(player==original)
 local records={record}
 local alternate=json.decode(json.encode(record));alternate.build=string.rep('d',64);records[#records+1]=alternate
 local partial=json.decode(json.encode(record));partial.build=string.rep('e',64);partial.inputs={{partial.frames,0,0,0}};records[#records+1]=partial
 local catalog=E.catalog;local bank=catalog()
 local raw=love.filesystem.read('history-fixtures.json')
 if raw then for _,data in ipairs(json.decode(raw)) do records[#records+1]=data end end
 for _,data in ipairs(records) do
  if data==partial then E.catalog=function()return {engines={engine},blobs=bank.blobs}end else E.catalog=catalog end
  local untouched=json.encode(data)
  print('HISTORY '..data.build:sub(1,12)..' world '..data.world..' frames '..data.frames)
  assert(Replay.play(data),Replay.status..' '..(love.filesystem.read('replay-error.log') or ''))
  Replay.speed=8;local steps=0;local drawn=false;local restarted=false
  while Replay.playing and steps<200000 do
   Replay.update(.25,App.simulate);steps=steps+1
   if Replay.legacy and not Replay.recovery and not restarted then
    Replay.paused=true;local frame=Replay.frame;Replay.update(.2,App.simulate);assert(Replay.frame==frame)
    assert(Replay.seekLevel(data.startLevel) and not Replay.recovery,'Restored engine survives restart without losing transport')
    assert(Replay.paused);Replay.paused=false;Replay.speed=8;restarted=true
   end
   if Replay.legacy and not Replay.recovery and not drawn then
    local random=Replay.rng:getState();local flash=Replay.legacy.env.shader_effect_timer;Replay.legacy.env.shader_effect_timer=.2
    love.draw();assert(Replay.rng:getState()==random,'Historical rendering cannot advance gameplay RNG')
    if Replay.legacy then Replay.legacy.env.shader_effect_timer=flash end
    drawn=true;assert(Replay.playing,Replay.status..' '..(love.filesystem.read('replay-error.log') or ''))
   end
  end
  assert(Replay.status==(data==partial and 'Fin de la partie restaurée.' or 'Lecture terminée.'),Replay.status..' '..json.encode(Replay.lastMismatch or {}))
  assert(json.encode(data)==untouched,'Historical migrations cannot rewrite the original recording')
  assert(player==original and json.encode(Profile.stats)==stats,'Historical spectator restores the live player and progress')
  print('OK historical replay '..data.build:sub(1,12))
 end
 E.catalog=catalog
 -- A development build keeps its own engine even when a later build replaces it.
 local move,slow=Input.move,Input.slow
 Input.move=function()return 1,0 end;Input.slow=function()return false end
 App.sessionLayout=record.layouts['6:1'];App.singleLevel=true;App.practice=1;App.hardcore=false;App.start(6)
 local ticks=0
 while Replay.recording and ticks<2000 do Replay.update(1/60,App.simulate);ticks=ticks+1 end
 Input.move,Input.slow=move,slow
 assert(Replay.last and Replay.last.completed,'Current engine fixture must finish naturally')
 local recent=Replay.last;assert(E.find(recent.build) and not E.find(recent.build).revision,'Current sources were archived locally')
 local build=Replay.buildId;Replay.buildId=string.rep('f',64)
 assert(Replay.play(recent));local rendered=false
 while Replay.playing do
  Replay.speed=8;Replay.update(.25,App.simulate)
  if Replay.legacy and not Replay.recovery and not rendered then love.draw();rendered=true end
 end
 Replay.buildId=build
 assert(Replay.status=='Lecture terminée.','Local engine archive must survive a later build: '..Replay.status)
 print('PASS historical replay engines: exact and intermediate builds, partial recovery, pause/restart, immutable recordings, progress isolation, local archives after updates, exact world hashes and rendering')
 love.event.quit()
end
return T
