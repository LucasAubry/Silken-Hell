local T={}
function T.run()
 Profile.transitionsSeen={};io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 App.practice=nil;App.singleLevel=false;App.preview=false;App.historyPreview=nil;App.hardcore=false;App.sessionLayout=nil;Secret.duel=nil
 Input.speedHeld=function()return false end
 local C=require('run_start');local E=require('earth_arrival')
 assert(Worlds.next(1)==6 and Worlds.next(6)==5 and Worlds.next(5)==4,'Keep Paradise, Sky, Earth, Ocean progression')
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  g.push('all');setCanvas(c);g.setCanvas=function(target,...)if target==nil then return setCanvas(c) end;return setCanvas(target,...)end
  love.draw();g.setCanvas=setCanvas;setCanvas();g.pop();c:newImageData():encode('png','earth-arrival-'..name..'.png');c:release()
 end
 Profile.complete(1,10,0);App.start(6);C.active=false;C.arrival=nil;C.arrivalKind=nil
 player.level=10;reset_level();capture('source');assert(E.source)
 Profile.complete(6,10,0);require('victory_screen').enter();UI.buttons={};require('victory_screen').draw()
 for _,button in ipairs(UI.buttons) do if button.x==796 then button.run();break end end
 assert(App.state=='entry' and App.selectedWorld==5 and App.entryFromWorld==6)
 App.draftName='Earth arrival';App.submit()
 assert(C.arrivalKind=='earth' and Campaign.world==5 and Campaign.biome==5 and player.level==1,'Sky continuation loads the actual first Earth map')
 assert(E.pose(.4).jump==0 and not E.pose(.4).silk,'Starts resting on a cloud')
 assert(E.pose(1).jump>0 and not E.pose(1).silk,'Jumps off the cloud before deploying silk')
 assert(math.abs(E.pose(1.8).x-E.cloudState(2,1.8).x)<.001 and not E.pose(1.8).silk,'Lands on the middle cloud before rappel')
 assert(E.pose(2.2).silk and E.pose(2.5).y<E.pose(2.1).y,'Second jump pays silk out from the middle cloud')
 for _,t in ipairs({.5,1.12,1.8,1.95,2.1,2.5,3.3,4.5,6}) do
  for _,key in ipairs({'x','y'}) do
   local dt=.0001;local before=E.pose(t-dt)[key];local at=E.pose(t)[key];local after=E.pose(t+dt)[key]
   assert(math.abs((at-before)/dt-(after-at)/dt)<.01,'Position and velocity join smoothly during both jumps and rappel')
  end
 end
 assert(E.pose(9).angle==0,'Swing settles on landing')
 assert(E.pose(3).rappel>0 and E.pose(3).mapAlpha==0,'Descends before revealing cave')
 assert(E.pose(8.25).actorsAlpha==0 and E.pose(E.duration).actorsAlpha==1,'Soft reveal introduces creatures after landing')
 local x,y=player.x,player.y;local rng=love.math.getRandomState();local shots={};local ticks=0
 while C.arrival do
  assert(not C.press(Profile.keys.dash) and not C.launch())
  if ticks==10 then App.state='pause';local age=C.arrival;C.advance(.05);assert(C.arrival==age);App.state='playing' end
  C.advance(.05);ticks=ticks+1;assert(ticks<260)
  assert(player.x==x and player.y==y and timer==0 and love.math.getRandomState()==rng,'Cinematic freezes position, scoring and gameplay RNG')
  for _,shot in ipairs({{'cloud',.4},{'jump',1.1},{'middle-cloud',1.8},{'front-jump',2.5},{'catch',3.3},{'rappel',3.5},{'cave-entrance',5.5},{'cave-interior',6.6},{'impact',8.9},{'creatures',9.6},{'landed',10.5}}) do
   if C.arrival and C.arrival>=shot[2] and not shots[shot[1]] then capture(shot[1]);shots[shot[1]]=true end
  end
 end
 assert(C.active and C.goAge==nil and direction=='up')
 local pose=E.pose(E.duration);assert(pose.progress==1 and pose.size==1 and pose.lift==0 and pose.mapAlpha==1)
 capture('gameplay');assert(C.press(Profile.keys.dash));assert(C.advance(.016)==.016,'Normal gameplay resumes after landing')
 App.openEntry(5,false);App.draftName='Direct Earth';App.submit();assert(C.arrivalKind=='brief','Repeat Earth launch uses a short rappel')
 print('PASS Earth arrival: correct campaign order, Sky continuation, cloud/jump/web catch/rappel/cave landing, actual Earth landing, pause, frozen scoring/RNG and gameplay resumption')
 love.event.quit()
end
return T
