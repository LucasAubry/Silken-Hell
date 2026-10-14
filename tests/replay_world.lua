local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=false;love.focus=function()end
 Profile.save=function()end;Bestiary.save=function()end;Workshop.validationRun=nil
 local json=require('json');local State=require('replay_state')
 local originalMove,originalSlow=Input.move,Input.slow
 Input.move=function()
  if Replay.input then return Replay.input[1],Replay.input[2] end
  -- Include idle retries, directional changes and analog movement.
  local n=Replay.frame
  if n>=60 and n<100 then return 0,0 end
  local a=math.floor(n/100)*math.pi/2;return math.cos(a)*.75,math.sin(a)*.75
 end
 Input.slow=function() if Replay.input then return Replay.input[3] end;return Replay.frame%80<40 end
 for _,world in ipairs({1,4,6,7,3}) do
  local map={world=world,level=world==3 and 1 or 7,width=960,height=600,entities={
   {kind='spawn',x=150,y=300},{kind='tear',x=850,y=500},
   {kind='mob',type='spinner',x=750,y=100,speed=90},
   {kind='mob',type='ange',x=600,y=100,speed=1,has_larme=true},
  }}
  App.sessionLayout=map;App.singleLevel=true;App.practice=map.level;App.hardcore=false;Secret.duel=nil
  LevelLayouts.disabled=false;Replay.recording=false;Replay.data=nil
  App.start(world);local initial=State.hash();local states={};local died=false
  local function tick(dt)
   if Replay.frame==60 then Hazards.kill('lightning');App.resolveDeath();died=true end
   App.simulate(dt)
   if Replay.playing then
    assert(states[Replay.frame]==State.hash(),'Full world differs on frame '..Replay.frame..' in '..world)
   else states[Replay.frame]=State.hash() end
   if Replay.frame==300 then App.state='customVictory';if not Replay.playing then Replay.finish() end end
  end
  for _=1,300 do
   Replay.update(Replay.step,tick)
   if Replay.frame%20==0 and App.state=='playing' then love.draw() end
  end
  assert(died and Replay.last.world==world and Replay.last.session,'Session mode recorded')
  local recording=json.decode(json.encode(Replay.last))
  -- Fresh playback after unrelated RNG, graphics settings and layout changes.
  Graphics.effects=not Graphics.effects;for _=1,55 do love.math.random() end
  App.sessionLayout=nil;LevelLayouts.disabled=true
  assert(Replay.play(recording));assert(State.hash()==initial,'Initial world, enemies and tear are restored exactly')
  local steps=0
  while Replay.playing and steps<400 do
   if steps==4 then
    Replay.paused=true;local frame=Replay.frame;Replay.update(.2,tick);assert(Replay.frame==frame);Replay.paused=false
    Replay.speed=4
   end
   Replay.update(1/47,tick);steps=steps+1
   if Replay.playing then love.draw() end
  end
  assert(Replay.status=='Lecture terminée.',world..': '..Replay.status..' '..(love.filesystem.read('replay-error.log') or ''))
  print('PASS replay world '..world..': session generation, every tick, death, idle retry, analog input, pause, x4, different render cadence and settings')
 end
 Input.move,Input.slow=originalMove,originalSlow
 love.event.quit()
end
return T
