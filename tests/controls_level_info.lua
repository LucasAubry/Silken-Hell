local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false;Replay.input=nil
 App.sessionLayout=nil;App.workshopMap=nil;App.preview=false;App.singleLevel=false;App.practice=nil;Secret.duel=nil;LevelLayouts.disabled=true
 local files={};for _,name in ipairs({'profile.txt','scores.tsv','hardcore-scores.json','score_details.json','bestiary.json'}) do files[name]=love.filesystem.read(name) or false end
 local Pad=require('pad_controls');local C=require('run_start')
 local j={axes={},buttons={},connected=true}
 function j:isGamepad()return true end
 function j:isConnected()return self.connected end
 function j:getGamepadAxis(axis)return self.axes[axis] or 0 end
 function j:isGamepadDown(...)for _,button in ipairs({...})do if self.buttons[button]then return true end end;return false end
 function j:getName()return 'Test controller' end
 Input.pad=j;Profile.padBindings=Pad.load();App.state='settings'
 local keyboardDash=Profile.keys.dash
 Input.beginBinding('dash','pad');love.gamepadpressed(j,'b')
 assert(Profile.padBindings.dash=='b' and Profile.keys.dash==keyboardDash and not UI.binding,'B can be bound without closing the screen')
 j.buttons.b=true;assert(Input.speedHeld());j.buttons={a=true};assert(not Input.speedHeld(),'The previous speed binding is released')
 j.buttons={};Input.beginBinding('pause','pad');love.gamepadpressed(j,'b')
 assert(Profile.padBindings.pause=='b' and Profile.padBindings.dash=='start','Duplicate binding swaps actions')
 App.state='playing';love.gamepadpressed(j,'b');assert(App.state=='pause');love.gamepadpressed(j,'b');assert(App.state=='playing','Remapped pause resumes')
 App.state='settings';j.axes.triggerright=.9;Input.beginBinding('dash','pad')
 love.gamepadaxis(j,'triggerright',.8);assert(UI.binding,'Held trigger must first return to neutral')
 j.axes.triggerright=0;love.gamepadaxis(j,'triggerright',0)
 j.axes.triggerright=.8;love.gamepadaxis(j,'triggerright',.8)
 assert(Profile.padBindings.dash=='axis:triggerright:+' and not UI.binding and Input.speedHeld(),'Trigger capture and held speed')
 assert(C.keyLabel()=='RT / R2','Start prompt reflects assigned speed control')
 Profile.save();Profile.padBindings=Pad.load();Profile.load();assert(Profile.padBindings.dash=='axis:triggerright:+' and Profile.padBindings.pause=='b','Gamepad bindings persist')
 local saved=Pad.load({dash='invalid',up=42});assert(saved.dash=='a' and saved.up==Pad.defaults.up,'Invalid saved mappings fall back safely')
 j.axes={};Input.beginBinding('right','pad');love.gamepadaxis(j,'rightx',1);j.axes.rightx=1
 local x,y=Input.move();assert(x==1 and y==0,'Right stick remapping drives actual movement')
 j.axes={leftx=1};x=Input.move();assert(x==0,'Old right direction no longer moves')
 j.axes={};j.buttons.dpleft=true;x=Input.move();assert(x==-1,'Unchanged left direction retains D-pad')
 j.buttons={};Input.beginBinding('restartLevel','pad');love.keypressed('escape');assert(not UI.binding and App.state=='settings','Escape cancels capture')
 Input.beginBinding('restartWorld','pad');local previous=Profile.padBindings.restartWorld;love.keypressed('q');assert(UI.binding and Profile.padBindings.restartWorld==previous,'Keyboard cannot change a gamepad binding')
 Input.remove(j);assert(not UI.binding,'Disconnect cancels capture');Input.pad=j
 Input.beginBinding('restartWorld','pad');Input.bind('none');assert(Profile.padBindings.restartWorld=='none')
 Input.cancelBinding();Input.active=false
 local restart,world,practice=App.restartLevel,App.restartWorld,App.practiceWorld
 local calls={};App.restartLevel=function()calls.level=true end;App.restartWorld=function()calls.world=true end;App.practiceWorld=function(delta)calls.practice=delta end
 Profile.padBindings=Pad.load();App.state='playing'
 love.gamepadpressed(j,'x');love.gamepadpressed(j,'back');assert(calls.level and calls.world,'Mapped restart actions execute')
 Profile.padBindings.nextWorld='rightstick';love.gamepadpressed(j,'rightstick');assert(calls.practice==1,'Mapped world navigation executes')
 App.restartLevel,App.restartWorld,App.practiceWorld=restart,world,practice
 local replayKey=Replay.key;local key;Replay.key=function(value)key=value end;Replay.playing=true
 love.gamepadpressed(j,'rightshoulder');assert(key==Profile.keys.replayFaster,'Replay speed uses mapped shoulder')
 Profile.padBindings.pause='b';Replay.paused=false;love.gamepadpressed(j,'b');assert(Replay.paused,'B can pause replay when mapped')
 Replay.playing=false;Replay.paused=false;Replay.key=replayKey
 App.state='menu';local selected=false;UI.buttons={{x=0,y=0,w=50,h=50,run=function()selected=true end}};Input.index=1
 love.gamepadpressed(j,'a');UI.updatePress(.12);assert(selected,'Menu confirmation stays available with remapped gameplay controls')
 Profile.padBindings=Pad.load();App.state='playing';C.active=true;love.gamepadpressed(j,'a');assert(not C.active,'Default controller starts a run')
 j.axes.triggerright=.8;assert(Input.speedHeld(),'Default trigger shortcut is preserved');j.axes={}
 local function level(world,n)
  App.state='playing';Campaign.select(world);player.level=n;reset_level();player.reset=false;C.active=false
 end
 level(1,2);assert(Bestiary.levelIds.ange or Bestiary.levelIds.snake)
 Bestiary.openLevel();assert(App.state=='bestiary' and UI.bestReturn=='playing' and Bestiary.levelFilter)
 for _,e in ipairs(Bestiary.entries)do if not Bestiary.levelIds[e.id]then
  for _,row in ipairs(Bestiary.list(Bestiary.category(e)))do assert(row.entry.id~=e.id,'Unrelated creatures stay outside level bestiary')end
 end end
 assert(Bestiary.entries[UI.bestSelected] and Bestiary.levelIds[Bestiary.entries[UI.bestSelected].id],'Opening selects a creature from this level')
 level(1,10);assert(Bestiary.levelIds.merle)
 Bestiary.discover('blackbird_chick');Bestiary.openLevel();assert(Bestiary.levelFilter.blackbird_chick,'Summoned creatures remain in current level entries')
 Bestiary.open();assert(not Bestiary.levelFilter and #Bestiary.list('boss')>=7,'Main menu still opens full bestiary')
 level(7,10);assert(Bestiary.levelIds.skeleton_fish and not Bestiary.levelIds.merle,'Level transition clears previous boss')
 Bestiary.openLevel();assert(Bestiary.entries[UI.bestSelected].id=='skeleton_fish')
 level(3,1);Bestiary.openLevel();assert(Bestiary.entries[UI.bestSelected].id=='final_spider')
 local button=UI.button;local info,hardcore=false,false
 UI.button=function(label,x,y,w,h,run,...)
  if label=='i' then info=run==Bestiary.openLevel end
  if label=='Hardcore' then hardcore=true end
  return button(label,x,y,w,h,run,...)
 end
 App.state='playing';UI.gameHud();assert(info and not hardcore,'Queen HUD exposes only the level info button')
 info=false;level(1,10);UI.gameHud();assert(info and not hardcore,'Standard boss HUD exposes only the level info button')
 UI.button=button
 local text,raw=UI.text,UI.rawText
 UI.text=function(value,x,y,font,...)assert(font~='small' and font~='tiny','Settings text remains readable');return text(value,x,y,font,...)end
 UI.rawText=function(value,x,y,font,...)assert(font~='small' and font~='tiny','Settings buttons stay body-sized');return raw(value,x,y,font,...)end
 for _,option in ipairs(require('localization').options)do
  Profile.language=option.code;App.state='settings'
  for _,page in ipairs({'general','shortcuts','language'})do UI.settingsPage=page;UI.settings()end
  App.state='graphics';Graphics.draw()
 end
 UI.text,UI.rawText=text,raw;Profile.language='fr'
 print('PASS gamepad buttons, sticks, triggers, duplicate swaps, pause, persistence, cancellation, disconnect, start prompt; level bestiary filtering, summons, transition, queen HUD; readable settings in seven languages')
 local frame=0
 love.update=function()
  frame=frame+1;UI.clock=UI.clock+.016
  if frame==1 then App.state='settings';UI.settingsPage='shortcuts';UI.bindingTab='pad';UI.bindingPage=1;App.capture='controls-gamepad.png'
  elseif frame==3 then UI.bindingPage=2;App.capture='controls-gamepad-actions.png'
  elseif frame==5 then UI.settingsPage='general';App.capture='settings-clean.png'
  elseif frame==7 then level(1,2);Bestiary.openLevel();App.capture='level-bestiary.png'
  elseif frame==9 then level(7,10);Abyss.defeated=true;Aftermath.update(0);player.x=Arena.width*.4;player.y=300;App.capture='wall-tiny-gold.png'
  elseif frame==11 then level(1,10);App.capture='level-info-hud.png'
  elseif frame==13 then
   for name,data in pairs(files)do if data then love.filesystem.write(name,data)else love.filesystem.remove(name)end end
   print('PASS visual captures');love.event.quit()
  end
 end
end
return T
