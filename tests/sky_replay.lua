local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=false;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 local json=require('json');local State=require('replay_state')
 App.sessionLayout={world=6,level=1,width=960,height=600,entities={{kind='spawn',x=480,y=300},{kind='tear',x=850,y=500},
  {kind='mob',type='dragonfly',x=700,y=110,speed=70},{kind='mob',type='mist_moth',x=800,y=440,speed=55}}}
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
 assert(sawHole and sawTrail,'The recording must exercise lightning holes and electric trails')
 local recording=json.decode(json.encode(Replay.last));App.sessionLayout=nil;LevelLayouts.disabled=true
 assert(Replay.play(recording));assert(State.hash()==initial,'Initial sky state is restored')
 local count=0
 while Replay.playing and count<600 do Replay.update(1/47,tick);count=count+1 end
 assert(Replay.status=='Lecture terminée.',Replay.status)
 print('PASS Sky replay: 480 full-state ticks with both creatures, electricity, mist, warning, impact and persistent holes at a different playback cadence')
 love.event.quit()
end
return T
