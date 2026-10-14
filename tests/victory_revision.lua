local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function() end
 local V=require 'victory_screen'
 assert(Audio.paradise and Audio.paradise:getDuration()>0,'New music decodes')
 Campaign.select(1);player.level=10;reset_level();timer=237.48;player.death=8;App.hardcore=false
 RunDetails.reset();for i=1,10 do RunDetails.rows[i]={level=i,time=18+i*1.2,deaths=i%3} end
 Profile.scores={{world=1,name=Profile.name,time=timer,deaths=8,country='FR'}}
 UI.boardCountry=true;UI.boardLocal=true
 V.enter();assert(V.run.rankScope=='global' and V.rank(V.run)=='Hors ligne','Results default to global and never substitute a device rank offline')
 V.changeRankScope(V.run);assert(V.run.rankScope=='country' and V.rank(V.run)=='Hors ligne')
 V.changeRankScope(V.run);assert(V.rank(V.run)=='#1','Device ranking is available only when explicitly selected')
 V.enter();assert(V.run.rankScope=='global','Every new result resets to world ranking')
 local request=Online.page;Online.enabled=true;Online.country='FR'
 V.run.online={id='test-run',pending={}}
 Online.page=function(world,country,page,hardcore)
  assert(world==1 and not hardcore)
  if country then return {scores={{runId='other-country'},{runId='test-run'}},hasMore=false},'online' end
  return {scores={{runId=page==2 and 'test-run' or 'another'}},hasMore=page==1},'online'
 end
 V.rank(V.run);assert(V.run.page==2);assert(V.rank(V.run)=='#11','Global rank locates the exact run across pages')
 V.changeRankScope(V.run);assert(V.rank(V.run)=='#2' and V.run.page==1,'Country rank has an independent search and cache')
 V.changeRankScope(V.run);assert(V.rank(V.run)=='#1')
 V.changeRankScope(V.run);V.rank(V.run);assert(V.rank(V.run)=='#11','Returning to global does not retain the local or country rank')
 for _,status in ipairs({'local','offline','loading'}) do
  V.run.rankKey=nil
  Online.page=function()return {scores={{runId='test-run'}},hasMore=false},status end
  assert(V.rank(V.run)==(status=='loading' and 'Chargement…' or 'Hors ligne'),'Fallback data cannot masquerade as a global rank')
 end
 V.run.online.pending={{level=10}};assert(V.rank(V.run)=='Envoi…')
 V.run.online.pending={};V.run.online.failed=true;assert(V.rank(V.run)=='Non classé')
 V.run.online.failed=nil;V.run.rankKey=nil
 Online.page=function()return {scores={},hasMore=false},'online' end
 assert(V.rank(V.run)=='Non classé','Missing submitted run cannot use a local rank')
 Online.page=request;Online.enabled=false
 local music,focused=Audio.paradise,Audio.focused;local playing=false
 Audio.focused=true;Audio.paradise={setVolume=function()end,play=function()playing=true end,stop=function()playing=false end,isPlaying=function()return playing end}
 App.selectedWorld=1;Audio.update(Profile,false);assert(not Audio.paradise:isPlaying(),'No menu music on victory')
 App.state='customVictory';Audio.update(Profile,false);assert(not Audio.paradise:isPlaying(),'No menu music on map completion')
 App.state='menu';Audio.update(Profile,false);assert(Audio.paradise:isPlaying())
 App.state='playing';Audio.update(Profile,false);assert(not Audio.paradise:isPlaying())
 Audio.paradise,Audio.focused=music,focused
 -- The result keeps the current recording, including its deferred finalization.
 Replay.recording=true;Replay.data={completed=false};V.enter();local captured=Replay.data
 Replay.data.completed=true;UI.buttons={};V.draw();assert(not UI.buttons[1].disabled)
 local play=Replay.play;local watched
 Replay.play=function(data) watched=data end;UI.buttons[1].run();assert(watched==captured);Replay.play=play;Replay.recording=false
 V.run.hardcore=true;V.run.rankScope='local';assert(V.rank(V.run)=='Non classé','Normal scores are absent from hardcore rank')
 -- Restart the captured result's world, even after visiting another screen.
 local start=App.start;local restarted
 App.start=function(world)restarted=world end
 for _,hardcore in ipairs({false,true}) do
  V.run.world=6;V.run.hardcore=hardcore;App.practice=10;App.singleLevel=true
  UI.buttons={};V.draw();UI.buttons[3].run()
  assert(restarted==6 and App.hardcore==hardcore and not App.practice and not App.singleLevel,'Restart keeps world/mode and resets practice')
 end
 App.start=start;App.hardcore=false
 -- The category control sits directly below the rank, with no subtitle or microtext.
 V.run.rankScope='global';local text,raw=UI.text,UI.rawText
 UI.text=function(label,x,y,font,...)assert(font~='small' and font~='tiny','Results use normal-size text');return text(label,x,y,font,...)end
 UI.rawText=function(label,x,y,font,...)assert(font~='small' and font~='tiny','Results and buttons use normal-size text');return raw(label,x,y,font,...)end
 UI.buttons={};V.draw();UI.text,UI.rawText=text,raw
 local switch=UI.buttons[#UI.buttons];assert(switch.x==95 and switch.y==528,'Scope button is underneath the rank')
 switch.run();assert(V.run.rankScope=='country')
 Online.enabled=true;Online.current={id='visual-run',pending={}}
 Online.page=function(_,country)return {scores=country and {{runId='other'},{runId='visual-run'}} or {{runId='visual-run'}},hasMore=false},'online' end
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1;UI.clock=frame/60
  if frame<=7 then
   Campaign.select(frame);V.enter();App.capture='victory-biome-'..frame..'.png'
  elseif frame==8 then Campaign.select(1);V.enter();App.capture='victory-rank-world.png'
  elseif frame==9 then V.changeRankScope(V.run);App.capture='victory-rank-country.png'
  elseif frame==10 then V.changeRankScope(V.run);App.capture='victory-rank-device.png'
  else Online.page=request;Online.enabled=false;print('PASS victory: global default, explicit world/country/device scopes, no fallback rank, independent pagination, readable controls, seven biome renders and music transitions');love.event.quit() end
 end
end
return T
