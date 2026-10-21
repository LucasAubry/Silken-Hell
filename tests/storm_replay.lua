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
  if player.throw then return 0,0 end
  local targetX,targetY=Arena.width/2,300
  if player.whirl then
   if (player.whirl.age or 0)<1 then return 0,0 end
   local boss=Bosses.items[1].boss;local nearest,dist=1,math.huge
   for i,p in ipairs(boss.route)do local d=(p.x-player.whirl.tornado.x)^2+(p.y-player.whirl.tornado.y)^2;if d<dist then nearest,dist=i,d end end
   local p=boss.route[math.min(#boss.route,nearest+1)]
   if p then targetX,targetY=p.x,p.y end
  end
  local dx,dy=targetX-player.x-15,targetY-player.y-12;local d=math.sqrt(dx*dx+dy*dy)
  if d<3 then return 0,0 end
  return dx/d,dy/d
 end
 Profile.speedMode='accelerate'
 Input.slow=function()return not (player.whirl and (player.whirl.age or 0)>=1) end
 App.start(6);require('run_start').active=false
 local initial=State.hash();local states={};local patterns={};local captured,projected=false,false
 local function tick(dt)
  App.simulate(dt)
  local b=Bosses.items[1].boss;patterns[b.pattern]=true
  captured=captured or player.whirl~=nil;projected=projected or player.throw~=nil
  if Replay.playing then assert(states[Replay.frame]==State.hash(),'Merle replay diverged at '..Replay.frame)
  else states[Replay.frame]=State.hash()end
  if Replay.frame==3100 then App.state='customVictory';if not Replay.playing then Replay.finish()end end
 end
 for _=1,3100 do Replay.update(Replay.step,tick)end
 assert(patterns[1] and patterns[2] and patterns[3] and captured and projected,'Recording covers three patterns and player-triggered launches')
 local recording=json.decode(json.encode(Replay.last));App.sessionLayout=nil;LevelLayouts.disabled=true
 Profile.speedMode='slow' -- Playback must retain the recorded Space semantics.
 assert(Replay.play(recording));require('run_start').active=false;assert(State.hash()==initial,'Replay restores the initial boss state')
 local count=0
 while Replay.playing and count<2800 do Replay.update(1/47,tick);count=count+1 end
 assert(Replay.status=='Lecture terminée.',Replay.status)
 print('PASS Merle replay: 3100 full-state ticks, three fixed patterns, growth, ring, feathers and manual tornado launches at a different playback cadence')
 love.event.quit()
end
return T
