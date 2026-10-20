local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;App.practice=nil;App.singleLevel=false;App.hardcore=false;App.preview=false;App.sessionLayout=nil;Secret.duel=nil
 Replay.disabled=true;Replay.playing=false;Replay.recording=false;Input.speedHeld=function()return false end
 local C=require('run_start');local S=require('sky_arrival')
 local function capture(name)
  local g=love.graphics;local canvas=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  g.push('all');setCanvas(canvas)
  g.setCanvas=function(target,...)if target==nil then return setCanvas(canvas) end;return setCanvas(target,...)end
  love.draw();g.setCanvas=setCanvas;setCanvas();g.pop()
  canvas:newImageData():encode('png','sky-arrival-'..name..'.png');canvas:release()
 end
 App.start(1);player.level=10;reset_level();C.active=false
 Aftermath.cleared=true;Aftermath.portalAge=2;Aftermath.centerTear();mobs={};Raven.active=false
 capture('source');assert(S.source,'Real Paradise arena is preserved without the player')
 Profile.complete(1,10,0)
 require('victory_screen').enter();UI.buttons={};require('victory_screen').draw()
 local nextWorld
 for _,b in ipairs(UI.buttons) do if b.x==796 and b.y==617 then nextWorld=b end end
 assert(nextWorld);nextWorld.run();assert(App.state=='entry' and App.entryFromWorld==1)
 App.draftName='Transition test';App.submit()
 assert(C.arrivalKind=='sky' and S.fromParadise and C.arrivalDuration==S.duration+S.exitDuration)
 local px,py=player.x,player.y;local rng=love.math.getRandomState();local skyClock=require('sky_weather').clock
 local portal=require('prologue').drawPortal
 require('prologue').drawPortal=function(...)assert(C.arrival<S.exitDuration,'No second portal after leaving Paradise');return portal(...)end
 local frames=0;local lastZoom=math.huge;local pauseChecked=false;local screenshots={}
 while C.arrival do
  assert(not C.press(Profile.keys.dash) and not C.launch(),'Inputs cannot skip the cinematic')
  local age=C.arrival
  if age>.4 and not pauseChecked then
   App.state='pause';assert(C.advance(.05)==0 and C.arrival==age,'Pause freezes the transition');App.state='playing';pauseChecked=true
  end
  assert(C.advance(.05)==0);frames=frames+1;assert(frames<190)
  assert(player.x==px and player.y==py and timer==0 and require('sky_weather').clock==skyClock,'No movement, hazards or timer during the fall')
  assert(love.math.getRandomState()==rng,'Transition cannot alter simulation RNG')
  for _,shot in ipairs({{'portal',.6},{'enter',1.25},{'direct-fall',2.1},{'high',2.5},{'cloud',2.85},{'middle',4.1},{'landing',6.1},{'settled',6.5}}) do
   if C.arrival and C.arrival>=shot[2] and not screenshots[shot[1]] then capture(shot[1]);screenshots[shot[1]]=true end
  end
  if age>S.exitDuration then local pose=S.pose(age);assert(pose.zoom<=lastZoom and pose.zoom>=1 and pose.dir=='up','Full-screen sky and rear view throughout descent');lastZoom=pose.zoom end
 end
 require('prologue').drawPortal=portal
 assert(not C.active and C.goAge==nil,'Landing starts the map automatically')
 local pose=S.pose(S.duration+S.exitDuration)
 assert(pose.zoom==1 and pose.tilt==1 and pose.angle==0 and pose.height==0 and pose.size==1 and direction=='up','Final camera and sprite match gameplay exactly')
 capture('gameplay')
 App.openEntry(6,false);App.draftName='Direct sky';App.submit()
 assert(C.arrivalKind=='sky' and not S.fromParadise,'Direct sky launch contains only the fall')
 local portal=require('prologue').drawPortal;require('prologue').drawPortal=function()error('No portal on direct Sky arrival')end
 C.advance(.05);capture('direct');require('prologue').drawPortal=portal
 local draw=Characters.draw;local seenBack=false
 Characters.draw=function(x,y,size,dir,...)assert(dir=='up','Spider faces away during the fall');seenBack=true;return draw(x,y,size,dir,...)end
 capture('rear-view');Characters.draw=draw;assert(seenBack)
 local shadows=0;local shadow=Characters.shadow;Characters.shadow=function(...)shadows=shadows+1;return shadow(...)end
 capture('direct-shadow');assert(shadows==0,'No shadow high in the sky')
 C.beginSkyArrival(true);C.arrival=S.exitDuration+3.6;S.advance(C.arrival)
 shadows=0;capture('fall-no-shadow');assert(shadows==0,'Paradise to Sky has no shadow during the fall')
 C.arrival=S.exitDuration+4.2;S.advance(C.arrival)
 shadows=0;capture('landing-shadow');assert(shadows>0,'Shadow returns at landing')
 App.start(1);C.beginArrival(true,true);for i=1,70 do C.advance(.05) end
 shadows=0;capture('portal-shadow');assert(shadows>0 and C.arrivalActor.y==player.y+8,'Portal arrival ends at the gameplay sprite and shadow position')
 Characters.shadow=shadow
 App.practice=1;App.start(6);assert(not C.arrival and not C.active,'Practice bypasses cinematics')
 App.practice=nil;App.preview=true;App.start(6);assert(not C.arrival,'Editor preview bypasses cinematics');App.preview=false
 Replay.playing=true;C.begin();assert(not C.arrival and not C.active,'Replay bypasses cinematics');Replay.playing=false
 print('PASS Sky arrival: Paradise portal, direct fall, growing real map, exact landing, shadows, frozen timer/RNG, pause, practice/preview/replay exclusions')
 love.event.quit()
end
return T
