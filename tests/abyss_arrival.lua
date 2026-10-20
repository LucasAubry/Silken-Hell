local T={}
function T.run()
 Profile.transitionsSeen={};io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 App.practice=nil;App.singleLevel=false;App.preview=false;App.historyPreview=nil;App.hardcore=false;App.sessionLayout=nil;Secret.duel=nil
 Input.speedHeld=function()return false end
 local C=require('run_start');local B=require('abyss_arrival')
 local function pose(t)return B.pose(B.timelineTime(t))end
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  g.push('all');setCanvas(c);g.setCanvas=function(target,...)if target==nil then return setCanvas(c) end;return setCanvas(target,...)end
  love.draw();g.setCanvas=setCanvas;setCanvas();g.pop();c:newImageData():encode('png','abyss-arrival-'..name..'.png');c:release()
 end
 Profile.complete(4,10,0);App.openEntry(7,false,4);App.draftName='Abyss arrival';App.submit()
 assert(C.arrivalKind=='abyss' and Campaign.world==7 and Campaign.biome==7 and player.level==1)
 assert(pose(2).camera==0 and pose(3.6).equip==1,'Camera holds on the visible lamp pickup')
 assert(pose(5).camera>0 and pose(5).leave==0,'Camera follows the rider before she leaves the sliding platform')
 assert(pose(3.45).crack>0 and pose(3.45).slide==0,'Crack opens before the ledge falls')
 assert(pose(4.45).y-pose(3.6).y>.08 and pose(4.2).tilt>.1,'Rider visibly drops and tips with the breaking rock')
 assert(pose(7.8).tilt==0 and math.abs(pose(7.8).jolt)<.0001,'Landing has no residual shake or tilt')
 assert(pose(3.7).dir=='up','Rider turns her back when the stone breaks')
 assert(pose(3.75).jolt>.9,'Rock break has a readable short camera impulse')
 for t=1.8,6.4,.1 do assert(math.abs(pose(t).x-.43)<.0001,'Rider stays on one lateral axis before landing') end
 assert(pose(7.1).rockY>1.5 and pose(7.1).rockX<0,'Rock continues down and left out of frame before landing')
 local entryX=B.position(B.timelineTime(6.4),1200,750,600,375)
 assert(entryX<600,'Enters the destination from the left')
 local endX,endY=B.position(B.duration,1200,750,600,375);assert(endX==600 and endY==375,'Ends on the actual gameplay spawn')
 assert(pose(1).equip==0 and pose(2.7).equip>0 and pose(3.7).equip==1,'Lamp travels from the stone to the helmet before the rock detaches')
 assert(pose(0).x<0 and pose(5).x<.5,'Enters from the left and remains left during destination reveal')
 assert(B.pose(4.6).actorsAlpha==0 and B.pose(5.3).actorsAlpha==B.pose(5.3).mapAlpha and B.pose(B.duration).actorsAlpha==1,'Creatures and scenery share the reveal')
 for _,t in ipairs({1.5,3.6,5.6,7.8}) do
  local dt=.0001;local before=pose(t-dt).x;local at=pose(t).x;local after=pose(t+dt).x
  assert(math.abs((at-before)/dt-(after-at)/dt)<.01,'Current does not snap swimmer velocity')
 end
 local px,py=player.x,player.y;local rng=love.math.getRandomState();local shots={};local ticks=0
 while C.arrival do
  if ticks==10 then App.state='pause';local age=C.arrival;C.advance(.05);assert(C.arrival==age);App.state='playing' end
  assert(not C.press(Profile.keys.dash) and not C.launch())
  C.advance(.05);ticks=ticks+1;assert(ticks<230)
  assert(player.x==px and player.y==py and timer==0 and love.math.getRandomState()==rng)
  for _,shot in ipairs({{'ledge-approach',1.3},{'lamp-transfer',2.7},{'crack',3.5},{'helmet',3.7},{'break',4.1},{'rockslide',4.9},{'entry-left',6.2},{'landing',7.8}}) do
   if C.arrival and C.arrival>=B.timelineTime(shot[2]) and not shots[shot[1]] then capture(shot[1]);shots[shot[1]]=true end
  end
 end
 assert(B.environment and C.active and direction=='up' and B.pose(B.duration).progress==1)
 capture('gameplay');assert(C.press(Profile.keys.dash));assert(C.advance(.016)==.016)
 App.openEntry(7,false);App.draftName='Direct abyss';App.submit();assert(C.arrivalKind=='brief')
 print('PASS Abyss arrival: Ocean campaign handoff, visible lantern pickup, camera follows rockslide, left entrance, destination reveal, pause and frozen scoring/RNG')
 love.event.quit()
end
return T
