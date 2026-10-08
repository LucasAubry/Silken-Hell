local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 local C=require('run_start');local F=require('game_feedback');local H=require('boss_hud');local json=require('json')
 Online.enabled=false;Replay.disabled=false;Replay.playing=false;LevelLayouts.disabled=false
 Profile.name='Start QA';Profile.language='fr';Profile.completed={};Profile.levels={}
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true;Profile.levels[w]=10 end
 App.hardcore=false;App.preview=false;App.practice=nil;App.singleLevel=false;App.sessionLayout=nil;Secret.duel=nil
 local maps={}
 for n=1,10 do maps['1:'..n]={world=1,level=n,width=960,height=600,entities={{kind='spawn',x=80,y=300},{kind='tear',x=300,y=300},{kind='mob',type='ange',x=800,y=450}}} end
 local read,move,slow=LevelLayouts.read,Input.move,Input.slow
 LevelLayouts.read=function()return maps end
 Input.move=function()if Replay.input then return Replay.input[1],Replay.input[2] end;return 1,0 end
 Input.slow=function()return false end
 local speedHeld=Input.speedHeld;local held=false;Input.speedHeld=function()return held end
 App.start(1);assert(C.active)
 local px,mx,my,rng=player.x,mobs[1].x,mobs[1].y,Replay.rng:getState()
 love.update(.4);love.draw()
 assert(timer==0 and player.x==px and mobs[1].x==mx and mobs[1].y==my,'Player, clock and enemies stay frozen')
 assert(Replay.frame==0 and #Replay.data.inputs==0 and next(RunDetails.rows)==nil and Replay.rng:getState()==rng,'Start wait is excluded from replay, splits and RNG')
 love.keypressed('escape');assert(App.state=='pause');local elapsed=C.elapsed
 love.keypressed(Profile.keys.dash);love.update(1);assert(C.active and C.elapsed==elapsed and timer==0,'Paused input cannot launch')
 love.keypressed('escape');love.update(10);assert(C.active and timer==0,'Waiting never starts automatically')
 love.keypressed('up');love.keypressed(Profile.keys.dash,nil,true);assert(C.active,'Movement and key repeats cannot launch')
 love.keypressed(Profile.keys.dash);assert(not C.active and timer==0 and Replay.frame==0,'Fresh speed press starts without counting waiting time')
 love.update(.05);assert(timer>0 and timer<.051 and player.x>px and Replay.frame==3,'Held movement starts immediately')
 -- The menu's held speed button must be released before polling can start a run.
 held=true;App.start(1);love.update(.5);assert(C.active)
 held=false;love.update(.01);held=true;love.update(.01);assert(not C.active)
 held=false
 local oldKey=Profile.keys.dash
 Profile.keys.dash='lshift';App.start(1);love.keypressed('space');assert(C.active);love.keypressed('lshift');assert(not C.active and C.keyLabel()=='LSHIFT')
 Profile.keys.dash='mouse:2';App.start(1);love.mousepressed(0,0,1);assert(C.active);love.mousepressed(0,0,2);assert(not C.active)
 Profile.keys.dash=oldKey
 local pad={buttons={},axes={}}
 function pad:isConnected()return true end
 function pad:isGamepad()return true end
 function pad:isGamepadDown(...)for _,key in ipairs({...})do if self.buttons[key]then return true end end;return false end
 function pad:getGamepadAxis(key)return self.axes[key]or 0 end
 local oldPad=Input.pad;Input.pad=pad;Input.speedHeld=speedHeld
 App.start(1);Input.press(pad,'a');assert(not C.active and C.keyLabel()=='A')
 App.start(1);pad.axes.triggerright=.8;love.update(.01);assert(not C.active,'Analog acceleration trigger starts')
 pad.axes={};Input.pad=oldPad;Input.active=false;Input.speedHeld=function()return held end
 App.start(1);love.keypressed(Profile.keys.dash)
 local p=timer;player.death=player.death+1;player.reset=true;App.resolveDeath();F.update(0)
 assert(not C.active and timer==p and F.events[#F.events].kind=='respawn','Death returns immediately, without start prompt')
 -- Replay an actual completed ranked run recorded through the gated update loop.
 App.start(1);love.keypressed(Profile.keys.dash)
 for _=1,2400 do if App.state~='playing' then break end;love.update(1/60) end
 assert(App.state=='victory' and Replay.last and Replay.last.completed,'Ranked run completes normally')
 local recording=json.decode(json.encode(Replay.last))
 assert(math.abs(recording.time-recording.frames*Replay.step)<.001,'Recorded active time excludes start start prompt')
 assert(Replay.play(recording) and not C.active,'Spectator playback starts directly')
 for _=1,2400 do if not Replay.playing then break end;love.update(1/47) end
 assert(Replay.status=='Lecture terminée.','Gameplay feedback keeps replay deterministic: '..Replay.status)
 App.practice=3;App.singleLevel=true;App.sessionLayout=nil;App.start(1);assert(not C.active,'Training starts immediately')
 App.practice=nil;App.sessionLayout=maps['1:1'];App.start(1);assert(not C.active,'Workshop starts immediately')
 App.singleLevel=false;App.sessionLayout=nil;App.preview=true;App.start(1);assert(not C.active,'Editor preview starts immediately');App.preview=false
 App.hardcore=true;App.start(8);assert(C.active,'Ranked Sanctuary gets the start prompt');C.press(Profile.keys.dash)
 player.level=2;reset_level();assert(not C.active,'Next boss never restarts start prompt')
 App.hardcore=false;App.practice=1;App.singleLevel=true;App.start(1);F.reset()
 local mob=mobs[1];local before=json.encode({x=mob.x,y=mob.y,hp=player.death})
 mob.is_frozen=true;F.update(.01);assert(#F.events==1 and F.events[1].kind=='capture')
 F.update(.01);assert(#F.events==1,'One capture pulse per freeze')
 player.charges=(player.charges or 0)+1;F.update(.01);assert(F.events[#F.events].kind=='charge')
 assert(json.encode({x=mob.x,y=mob.y,hp=player.death})==before,'Feedback never moves actors')
 local savedRng=love.math.getRandomState();F.drawWorld();F.drawHud();assert(love.math.getRandomState()==savedRng,'Cosmetics never consume random numbers')
 player.death=player.death+1;player.falling=true;player.reset=true;F.update(.01)
 assert(F.pendingRespawn and #F.events==0,'Falling does not flash a false respawn')
 player.falling=false;player.reset=false;F.update(.01);assert(F.events[1].kind=='respawn')
 local boss={hp=6,maxHp=6};UI.clock=10;assert(H.trailingHealth(boss,6,6)==6)
 boss.hp=4;assert(H.trailingHealth(boss,4,6)==6)
 UI.clock=10.2;local trail=H.trailingHealth(boss,4,6);assert(trail>4 and trail<6 and boss.hp==4,'Damage trail follows actual lost health')
 UI.clock=10.5;assert(H.trailingHealth(boss,4,6)==4)
 boss.hp=6;assert(H.trailingHealth(boss,6,6)==6,'Healing/reset does not trail backward')
 Graphics.effects=false;F.events={};F.emit('capture',10,10);assert(#F.events==0)
 boss.hp=3;assert(H.trailingHealth(boss,3,6)==3,'Effects off keeps health display immediate');Graphics.effects=true
 local L=require('localization')
 for _,language in ipairs(L.options) do
  Profile.language=language.code
  for _,label in ipairs({'Appuie pour démarrer','ESPACE','SOURIS %s'}) do
   assert(L.has(label,language.code) and UI.fonts.heading:hasGlyphs(L.text(label,'2')),'Localized start prompt: '..language.code)
  end
 end
 Profile.language='fr'
 LevelLayouts.read=read;Input.move,Input.slow=move,slow;Input.speedHeld=speedHeld;LevelLayouts.disabled=true;Replay.disabled=true
 print('PASS gameplay feedback: frozen start prompt, pause/resume, active-only time/replay, immediate respawn, mode eligibility, seven-boss start, deterministic playback, capture/charge, falling return, boss damage trail, effects setting')
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=30+tick*.15
  if tick==1 then App.practice=nil;App.singleLevel=false;App.sessionLayout=nil;App.hardcore=false;App.start(1);C.elapsed=.2;App.capture='game-start-prompt-3.png'
  elseif tick==2 then C.elapsed=.85;App.capture='game-start-prompt-2.png'
  elseif tick==3 then C.elapsed=1.5;App.capture='game-start-prompt-1.png'
  elseif tick==4 then C.press(Profile.keys.dash);App.capture='game-start-prompt-go.png'
  elseif tick==5 then C.goAge=1;player.level=10;reset_level();player.x=100;player.y=450;F.update(.5);H.trailingHealth(Raven,Raven.hp,Raven.maxHp)
  elseif tick==6 then Raven.hp=Raven.hp-1;App.capture='game-boss-hit.png'
  elseif tick==7 then App.practice=1;App.singleLevel=true;App.start(2);F.emit('capture',mobs[1].x,mobs[1].y);F.emit('respawn',player.x+15,player.y+12);F.update(.06);App.capture='game-contact-feedback.png'
  elseif tick==8 then App.start(7);F.emit('charge',player.x+15,player.y+12);F.update(.06);App.capture='game-charge-feedback.png'
  elseif tick==9 then print('PASS gameplay captures');love.event.quit() end
 end
end
return T
