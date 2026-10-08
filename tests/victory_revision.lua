local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function() end
 local V=require 'victory_screen'
 assert(Audio.paradise and Audio.paradise:getDuration()>0,'New music decodes')
 Campaign.select(1);player.level=10;reset_level();timer=237.48;player.death=8;App.hardcore=false
 RunDetails.reset();for i=1,10 do RunDetails.rows[i]={level=i,time=18+i*1.2,deaths=i%3} end
 Profile.scores[#Profile.scores+1]={world=1,name=Profile.name,time=timer,deaths=8,country='FR'}
 V.enter();assert(V.rank(V.run):sub(1,1)=='#')
 local request=Online.page;Online.enabled=true
 V.run.online={id='test-run',pending={}};Online.page=function(_,_,page) return {scores={{runId=page==2 and 'test-run' or 'another'}},hasMore=page==1},'online' end
 V.rank(V.run);assert(V.run.page==2);assert(V.rank(V.run)=='#11','Rank locates exact run across pages')
 Online.page=request;Online.enabled=false
 App.selectedWorld=1;Audio.update(Profile,false);assert(not Audio.paradise:isPlaying(),'No menu music on victory')
 App.state='customVictory';Audio.update(Profile,false);assert(not Audio.paradise:isPlaying(),'No menu music on map completion')
 App.state='menu';Audio.update(Profile,false);assert(Audio.paradise:isPlaying())
 App.state='playing';Audio.update(Profile,false);assert(not Audio.paradise:isPlaying())
 -- The result keeps the current recording, including its deferred finalization.
 Replay.recording=true;Replay.data={completed=false};V.enter();local captured=Replay.data
 Replay.data.completed=true;UI.buttons={};V.draw();assert(not UI.buttons[1].disabled)
 local play=Replay.play;local watched
 Replay.play=function(data) watched=data end;UI.buttons[1].run();assert(watched==captured);Replay.play=play;Replay.recording=false
 V.run.hardcore=true;assert(V.rank(V.run)=='—','Normal scores are absent from hardcore rank')
 -- Restart the captured result's world, even after visiting another screen.
 local start=App.start;local restarted
 App.start=function(world)restarted=world end
 for _,hardcore in ipairs({false,true}) do
  V.run.world=6;V.run.hardcore=hardcore;App.practice=10;App.singleLevel=true
  UI.buttons={};V.draw();UI.buttons[3].run()
  assert(restarted==6 and App.hardcore==hardcore and not App.practice and not App.singleLevel,'Restart keeps world/mode and resets practice')
 end
 App.start=start;App.hardcore=false
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1;UI.clock=frame/60
  if frame<=7 then
   Campaign.select(frame);V.enter();App.capture='victory-biome-'..frame..'.png'
  else print('PASS victory: seven biome renders, splits, exact paginated rank, streaming music transitions');love.event.quit() end
 end
end
return T
