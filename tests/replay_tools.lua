local T={}
function T.run()
 io.stdout:setvbuf('no')
 local json=require 'json';Online.enabled=false;Replay.disabled=false;Workshop.validationRun=nil
 local oldMove,oldSlow,read=Input.move,Input.slow,LevelLayouts.read
 local maps={};for n=1,10 do maps['1:'..n]={world=1,level=n,width=960,height=600,entities={{kind='spawn',x=80,y=300},{kind='tear',x=290,y=300}}} end
 LevelLayouts.read=function() return maps end
 Input.move=function() if Replay.input then return Replay.input[1],Replay.input[2] end;return 1,0 end;Input.slow=function() return false end
 App.practice=nil;App.singleLevel=false;App.hardcore=false;App.sessionLayout=nil;Secret.duel=nil;App.start(1);LevelLayouts.read=read
 for _=1,1500 do if App.state=='playing' then Replay.update(1/60,App.simulate) end end
 assert(App.state=='victory' and Replay.last,'Record a complete real run')
 local data=json.decode(json.encode(Replay.last));local stats=json.encode(Profile.stats);local count=#Profile.scores
 assert(Replay.play(data));Replay.paused=true;UI.draw();local buttons=#UI.buttons;assert(buttons>=15,'Transport and level buttons are visible')
 local speed=Replay.speed;UI.click(829,30);assert(Replay.speed==2 and Replay.speed~=speed,'Clickable x1 control')
 love.keypressed(Profile.keys.replaySlower);assert(Replay.speed==1);love.keypressed(Profile.keys.pause);assert(not Replay.paused)
 Replay.speed=.25;Replay.changeSpeed(-1);assert(Replay.speed==.25);Replay.speed=8;Replay.changeSpeed(1,true);assert(Replay.speed==.25)
 Replay.speed=1;assert(Replay.seekLevel(5))
 for _=1,1500 do if not Replay.job then break end;Replay.update(.016,App.simulate) end
 assert(not Replay.job and player.level==5 and Replay.playing,'Seek reaches exact level')
 assert(Replay.seekLevel(2));for _=1,1500 do if not Replay.job then break end;Replay.update(.016,App.simulate) end
 assert(not Replay.job and player.level==2,'Backward seek rebuilds deterministic state')
 assert(Replay.seekLevel(5,true));for _=1,1500 do if not Replay.job then break end;Replay.update(.016,App.simulate) end
 assert(Replay.ghost and #Replay.ghost.samples>2 and player.level==5 and App.singleLevel,'Ghost preparation captures real replay trajectory')
 assert(Replay.ghost.levelState and Replay.ghost.levelState.rng,'Ghost practice preserves original level generation state')
 local samples=Replay.ghost.samples;local first=samples[1];local last=samples[#samples];assert(last.x>first.x,'Ghost follows recorded movement')
 Input.move=function() if Replay.input then return Replay.input[1],Replay.input[2] end;return 0,-1 end
 local x,y=player.x,player.y;Replay.update(.05,App.simulate);assert(player.y<y and player.x==x,'Live input controls player separately from ghost')
 Replay.paused=true;local frame=Replay.frame;y=player.y;Replay.update(.2,App.simulate);assert(Replay.frame==frame and player.y==y)
 Replay.paused=false;Replay.speed=.25;Replay.accumulator=0;frame=Replay.frame;Replay.update(.2,App.simulate);assert(Replay.frame-frame==3,'Slow motion scales player and ghost together')
 local random=love.math.random;player.reset=true;Replay.update(.1,App.simulate);assert(Replay.frame==0 and Replay.ghost.attempts==2 and love.math.random==random,'Death restarts both without leaking RNG override')
 love.keypressed(Profile.keys.restartLevel);assert(Replay.frame==0 and Replay.ghost.samples==samples and Replay.ghost.attempts==3)
 assert(json.encode(Profile.stats)==stats and #Profile.scores==count,'Ghost practice cannot alter stats or scores')
 Replay.paused=true;UI.draw();Replay.drawGhost();Replay.stop();assert(not Replay.ghost and not Replay.job)
 local key=Profile.keys.restartLevel;UI.binding='restartLevel';Input.bind('f6');Profile.load();assert(Profile.keys.restartLevel=='f6','Binding persists');UI.binding='restartLevel';Input.bind(key)
 App.practice=4;App.singleLevel=true;App.start(1);Input.action(Profile.keys.restartWorld);assert(player.level==1 and App.singleLevel)
 App.practice=4;App.start(1);Input.action(Profile.keys.restartLevel);assert(player.level==4 and App.singleLevel and not Online.current)
 local completed=Profile.completed;Profile.completed={[1]=true,[6]=true};assert(App.practiceWorld(1) and Campaign.world==6);assert(App.practiceWorld(-1) and Campaign.world==1);Profile.completed=completed
 print('PASS replay tools: real recorded run, clickable speed, keyboard, bounded slow/fast speeds, forward/backward level seek, trajectory capture, independent live ghost controls, pause, shared slow motion, synchronized retries, isolated scores, saved bindings and training world shortcuts')
 Input.move,Input.slow=oldMove,oldSlow
 local tick=0;love.focus=function() end
 love.update=function()
  tick=tick+1
  if tick==1 then Replay.play(data);Replay.paused=true;App.capture='replay-controls.png'
  elseif tick==3 then Replay.seekLevel(5,true);for _=1,1500 do if not Replay.job then break end;Replay.update(.016,App.simulate) end;Replay.paused=true;player.x=player.x+90;App.capture='replay-ghost.png'
  elseif tick==5 then Replay.stop();App.state='settings';UI.settingsPage='shortcuts';App.capture='replay-shortcuts.png'
  elseif tick==7 then love.event.quit(0) end
 end
end
return T
