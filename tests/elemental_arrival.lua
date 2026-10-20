local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 App.practice=nil;App.singleLevel=false;App.preview=false;App.historyPreview=nil;App.hardcore=false;App.sessionLayout=nil;Secret.duel=nil
 Input.speedHeld=function()return false end
 local C=require('run_start')
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  g.push('all');setCanvas(c);g.setCanvas=function(target,...)if target==nil then return setCanvas(c) end;return setCanvas(target,...)end
  love.draw();g.setCanvas=setCanvas;setCanvas();g.pop();c:newImageData():encode('png',name..'.png');c:release()
 end
 for _,route in ipairs({{from=7,to=2,kind='hell'},{from=2,to=3,kind='renaissance'}}) do
  Profile.complete(route.from,10,0);App.openEntry(route.to,false,route.from);App.draftName='Transition';App.submit()
  assert(C.arrivalKind==route.kind and Campaign.biome==route.to and player.level==1)
  local S=C.scene();local px,py=player.x,player.y;local rng=love.math.getRandomState();local ticks=0;local shots={}
  assert(S.pose(8.4).actorsAlpha==0 and S.pose(9).actorsAlpha>0)
  if route.kind=='hell' then assert(S.pose(1).release==0 and S.pose(4).release>0 and S.pose(5).bubble==0,'Bubble and lamp leave together in the steam') end
  for _,t in ipairs({2,3.8,4,5.8,6.2}) do
   for _,key in ipairs({'x','y'}) do
    local dt=.0001;local before=S.pose(t-dt)[key];local at=S.pose(t)[key];local after=S.pose(t+dt)[key]
    assert(math.abs((at-before)/dt-(after-at)/dt)<.01,'Continuous velocity during the crossing')
   end
  end
  while C.arrival do
   if ticks==10 then App.state='pause';local age=C.arrival;C.advance(.05);assert(C.arrival==age);App.state='playing' end
   assert(not C.launch() and not C.press(Profile.keys.dash))
   C.advance(.05);ticks=ticks+1;assert(ticks<240)
   assert(player.x==px and player.y==py and timer==0 and love.math.getRandomState()==rng)
   for _,shot in ipairs({{'departure',1},{'passage',3.5},{'change',5},{'landing',7.6},{'settled',10.2}}) do
    if C.arrival and C.arrival>=shot[2] and not shots[shot[1]] then capture(route.kind..'-arrival-'..shot[1]);shots[shot[1]]=true end
   end
  end
  assert(S.environment and not C.active and direction=='up' and S.pose(S.duration).progress==1)
  capture(route.kind..'-arrival-gameplay');assert(C.advance(.016)==.016)
  App.openEntry(route.to,false);App.draftName='Direct';App.submit();assert(C.arrivalKind=='portal')
 end
 print('PASS elemental arrivals: both campaign handoffs, destination maps, continuous motion, bubble release, pause and frozen RNG/scoring')
 love.event.quit()
end
return T
