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
 assert(Replay.play(data));Replay.paused=true;UI.draw();local buttons=#UI.buttons;assert(#Replay.levels()==10 and buttons>=14,'Ten level buttons and spectator controls are visible')
 local speed=Replay.speed;UI.click(950,30);assert(Replay.speed==2 and Replay.speed~=speed,'Clickable x1 control')
 love.keypressed(Profile.keys.replaySlower);assert(Replay.speed==1);love.keypressed(Profile.keys.pause);assert(not Replay.paused)
 Replay.speed=.25;Replay.changeSpeed(-1);assert(Replay.speed==.25);Replay.speed=8;Replay.changeSpeed(1,true);assert(Replay.speed==.25)
 Replay.speed=1;assert(Replay.seekLevel(5))
 for _=1,1500 do if not Replay.job then break end;Replay.update(.016,App.simulate) end
 assert(not Replay.job and player.level==5 and Replay.playing,'Seek reaches exact level')
 assert(Replay.seekLevel(2));for _=1,1500 do if not Replay.job then break end;Replay.update(.016,App.simulate) end
 assert(not Replay.job and player.level==2,'Backward seek rebuilds deterministic state')
 Replay.paused=true;assert(Replay.seekLevel(5))
 for _=1,1500 do if not Replay.job then break end;Replay.update(.016,App.simulate) end
 assert(Replay.paused and Replay.playing and player.level==5 and not Replay.ghost,'Seek remains spectator-only and restores pause')
 local frame,x,y=Replay.frame,player.x,player.y
 Replay.update(.2,App.simulate);assert(Replay.frame==frame and player.x==x and player.y==y,'Pause freezes the entire replay')
 Replay.paused=false;Replay.speed=.25;Replay.accumulator=0;Replay.update(.2,App.simulate)
 assert(Replay.frame-frame==3,'Slow playback advances exactly three fixed ticks')
 local random=love.math.random
 assert(Replay.seekLevel(2));for _=1,1500 do if not Replay.job then break end;Replay.update(.016,App.simulate) end
 assert(love.math.random==random and player.level==2,'Seeking restores RNG functions')
 assert(json.encode(Profile.stats)==stats and #Profile.scores==count,'Spectator seeking never alters scores')
 Replay.stop();assert(not Replay.ghost and not Replay.job)
 local key=Profile.keys.restartLevel;UI.binding='restartLevel';Input.bind('f6');Profile.load();assert(Profile.keys.restartLevel=='f6','Binding persists');UI.binding='restartLevel';Input.bind(key)
 App.practice=4;App.singleLevel=true;App.start(1);Input.action(Profile.keys.restartWorld);assert(player.level==1 and App.singleLevel)
 App.practice=4;App.start(1);Input.action(Profile.keys.restartLevel);assert(player.level==4 and App.singleLevel and not Online.current)
 local completed=Profile.completed;Profile.completed={[1]=true,[6]=true};assert(App.practiceWorld(1) and Campaign.world==6);assert(App.practiceWorld(-1) and Campaign.world==1);Profile.completed=completed
 print('PASS replay transport: real campaign recording, controls, pause, slow/fast speeds, exact forward/backward seeking, RNG isolation, scores, bindings and practice shortcuts')
 Input.move,Input.slow=oldMove,oldSlow;love.event.quit(0)
end
return T
