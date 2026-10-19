local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false
 Replay.disabled=false;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 local F=require('final_spider');local State=require('replay_state');local json=require('json')
 local kill=Hazards.kill;Hazards.kill=function()end
 App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;App.hardcore=false;Replay.recording=false;Replay.data=nil
 Input.move=function()if Replay.input then return Replay.input[1],Replay.input[2] end;return 0,Replay.frame<65 and -1 or 0 end
 Input.slow=function()return true end
 App.start(3);local initial=State.hash();local states={};local sawShot,sawBomb,sawSilk,sawHeir=false,false,false,false
 local function tick(dt)
  if Replay.frame==30 or Replay.frame==60 then F.damageGrace=0;F.damage() end
  App.simulate(dt)
  sawHeir=sawHeir or #F.babies>0
  sawShot=sawShot or #F.webs>0;sawBomb=sawBomb or #F.bombs>0;sawSilk=sawSilk or #F.stuck>0
  if Replay.playing then assert(states[Replay.frame]==State.hash(),'Queen replay differs at frame '..Replay.frame)
  else states[Replay.frame]=State.hash() end
  if Replay.frame==1200 then App.state='customVictory';if not Replay.playing then Replay.finish()end end
 end
 for i=1,1200 do Replay.update(Replay.step,tick) end
 assert(sawShot and sawBomb and sawSilk and sawHeir,'Replay must exercise shots, bombs, silk and hatched heirs')
 local recording=json.decode(json.encode(Replay.last));assert(Replay.play(recording));assert(State.hash()==initial,'Queen initial state restored')
 local count=0
 while Replay.playing and count<1500 do Replay.update(1/47,tick);count=count+1 end
 assert(Replay.status=='Lecture terminée.',Replay.status);Hazards.kill=kill
 print('PASS queen replay: 1200 full-state ticks with projectiles, immortal heirs, explosive brood and fading silk at a different playback cadence')
 love.event.quit(0)
end
return T
