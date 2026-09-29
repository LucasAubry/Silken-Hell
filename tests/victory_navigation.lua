local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Profile.save=function() end;Replay.disabled=false
 local V=require 'victory_screen';local json=require 'json'
 local read=LevelLayouts.read;local maps={}
 for n=1,10 do maps['1:'..n]={world=1,level=n,width=960,height=600,entities={{kind='spawn',x=80,y=300},{kind='tear',x=290,y=300}}} end
 LevelLayouts.read=function() return maps end
 Input.move=function() if Replay.input then return Replay.input[1],Replay.input[2] end;return 1,0 end;Input.slow=function() return false end
 App.practice=nil;App.singleLevel=false;App.hardcore=false;App.sessionLayout=nil;Secret.duel=nil;App.start(1);LevelLayouts.read=read
 for i=1,1800 do if App.state=='playing' then Replay.update(1/60,App.simulate) end end
 assert(App.state=='victory' and Replay.last,'Complete recorded run')
 local original=V.run;local data=json.decode(json.encode(Replay.last));original.replayData=data
 UI.buttons={};V.draw();UI.buttons[2].run();assert(App.state=='rankings');UI.backRankings();assert(App.state=='victory' and V.run==original)
 UI.buttons={};V.draw();UI.buttons[2].run();love.keypressed('escape');assert(App.state=='victory')
 assert(Replay.play(data));for i=1,1800 do if Replay.playing then Replay.update(1/60,App.simulate) end end
 assert(not Replay.playing and App.state=='victory' and V.run==original,'Replay completion restores original result')
 assert(Replay.play(data));Replay.stop();assert(App.state=='victory' and V.run==original,'Replay exit returns to result')
 App.state='rankings';UI.boardReturn=nil;assert(Replay.play(data));Replay.stop();assert(App.state=='rankings');UI.backRankings();assert(App.state=='menu','Normal rankings keep normal return')
 local text=UI.text;local seen={};UI.text=function(s,...) seen[s]=true;return text(s,...) end
 App.state='victory';V.run=original;UI.buttons={};V.draw();UI.text=text
 assert(seen['Niveau 1'] and seen['Le Merle noir'] and not seen['CHAQUE SECONDE COMPTE'])
 local frame=0;love.focus=function() end
 love.update=function(dt)
  frame=frame+1;UI.clock=2+frame*.1
  if frame==1 then App.state='victory';App.capture='victory-polished.png'
  elseif frame==4 then App.state='menu';App.selectedWorld=6;App.capture='sky-currents.png'
  elseif frame==7 then App.selectedWorld=1;App.capture='paradise-warm.png'
  elseif frame==10 then print('PASS victory navigation: actual complete replay, early exit, rankings button/Escape, snapshot preservation, level labels, three screens');love.event.quit() end
 end
end
return T
