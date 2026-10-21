local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=false;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 local json=require('json');local State=require('replay_state')
 -- Keep this stationary replay fixture alive long enough to cover all weather.
 -- Lethal contacts are exercised separately by sky_weather/ecosystem_revision.
 local kill=Hazards.kill;Hazards.kill=function()end
 local collect=Campaign.canCollect;Campaign.canCollect=function()return false end
 App.sessionLayout={world=6,level=1,width=960,height=600,environment={lightning=true},lightning={interval=.5,delay=.2},entities={{kind='lightning_zone',x=250,y=250,w=240,h=200},{kind='lightning_zone',x=670,y=320,w=220,h=220},{kind='spawn',x=480,y=300},{kind='tear',x=850,y=500},
  {kind='mob',type='cloud_beast',startDirection='left',x=350,y=120,speed=330},{kind='mob',type='cloud_beast',x=550,y=140,speed=330},{kind='mob',type='cloud_beast',x=730,y=260,speed=330},{kind='hole',x=300,y=240,radius=20,points={0,0}},{kind='mob',type='cloud_snail',has_larme=true,startDirection='up',x=300,y=300,speed=66},{kind='mob',type='dragonfly',x=700,y=110,speed=70},{kind='mob',type='mist_moth',attackDelay=4,attackDuration=10,attackInterval=1,startDirection='left',x=800,y=440,speed=55},{kind='mob',type='wind_bat',x=80,y=80,speed=0}}}
 App.singleLevel=true;App.practice=1;App.hardcore=false;LevelLayouts.disabled=false;Replay.recording=false;Replay.data=nil
 Input.move=function()if Replay.input then return Replay.input[1],Replay.input[2] end;return 0,0 end
 Input.slow=function()return true end
 App.start(6);local initial=State.hash();local states={};local sawHole=false;local sawTrail=false
 local function tick(dt)
  App.simulate(dt)
  local W=require('sky_weather');sawHole=sawHole or #W.holes>0;sawTrail=sawTrail or #W.trails>0
  if Replay.playing then assert(states[Replay.frame]==State.hash(),'Sky simulation differs at replay frame '..Replay.frame)
  else states[Replay.frame]=State.hash() end
  if Replay.frame==480 then App.state='customVictory';if not Replay.playing then Replay.finish() end end
 end
 for _=1,480 do Replay.update(Replay.step,tick) end
 assert(objet.larme_dropped,'Replay exercises a falling snail carrier and a safe tear drop')
 assert(#require('sky_weather').holes==10,'Replay exercises all five positions in both authored zones')
 assert(sawHole and sawTrail,'The recording must exercise lightning holes and electric trails')
 local recording=json.decode(json.encode(Replay.last));App.sessionLayout=nil;LevelLayouts.disabled=true
 assert(Replay.play(recording));assert(State.hash()==initial,'Initial sky state is restored')
 local count=0
 while Replay.playing and count<600 do Replay.update(1/47,tick);count=count+1 end
 assert(Replay.status=='Lecture terminée.',Replay.status)
 Hazards.kill=kill;Campaign.canCollect=collect
 print('PASS Sky replay: 480 full-state ticks with both creatures, electricity, mist, warning, impact and persistent holes at a different playback cadence')
 love.event.quit()
end
return T
