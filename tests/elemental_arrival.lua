local T={}
function T.run()
 Profile.transitionsSeen={};io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
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
  local S=C.scene();local function pose(t)return S.pose(S.timelineTime(t))end;local px,py=player.x,player.y;local rng=love.math.getRandomState();local ticks=0;local shots={}
  assert(S.pose(S.duration).actorsAlpha==1,'Creatures are fully revealed at gameplay handoff')
  if route.kind=='hell' then
   assert(S.pose(5).mapAlpha>0 and S.pose(5.8).mapAlpha<1,'Same continuous dissolve as Sky')
   assert(pose(2).dir=='down' and pose(4).dir=='down','Faces the viewer during the fall')
   assert(not pose(2.6).detached and pose(2.7).detached and not pose(2.7).broken and pose(3).broken,'Lamp detaches then its taut thread breaks at the waterline')
   assert(pose(4).x==.5 and pose(8).x==.5,'Falls directly rather than entering a side gallery')
   local ex,ey=S.position(S.duration,1200,750,197,533);assert(ex==197 and ey==533,'Hell finishes at the exact spawn')
  end
  if route.kind=='renaissance' then
   assert(pose(4).silk==0 and pose(8.8).silk>0 and S.pose(S.duration).silk==0,'Web catches the fall and releases at landing')
   local ax,ay=S.position(S.duration,1200,750,197,533);assert(ax==197 and ay==533,'Renaissance lands at the actual spawn, even away from the center')
  end
  if route.kind=='hell' then assert(pose(2.6).release==0 and pose(2.9).release>0 and pose(3.2).bubble==0,'Breathing bubble clears when leaving the water') end
  for _,t in ipairs({2,3.8,4,5.8,6.2}) do
   for _,key in ipairs({'x','y'}) do
    local dt=.0001;local before=pose(t-dt)[key];local at=pose(t)[key];local after=pose(t+dt)[key]
    assert(math.abs((at-before)/dt-(after-at)/dt)<.01,'Continuous velocity during the crossing')
   end
  end
  while C.arrival do
   if ticks==10 then App.state='pause';local age=C.arrival;C.advance(.05);assert(C.arrival==age);App.state='playing' end
   assert(not C.launch() and not C.press(Profile.keys.dash))
   C.advance(.05);ticks=ticks+1;assert(ticks<240)
   assert(player.x==px and player.y==py and timer==0 and love.math.getRandomState()==rng)
   for _,shot in ipairs({{'departure',1},{'passage',3.5},{'change',5},{'hidden',6.6},{'landing',7.6},{'return',8.8},{'settled',10.2}}) do
    if C.arrival and C.arrival>=S.timelineTime(shot[2]) and not shots[shot[1]] then capture(route.kind..'-arrival-'..shot[1]);shots[shot[1]]=true end
   end
  end
  assert(S.environment and C.active and direction=='up' and S.pose(S.duration).progress==1)
  capture(route.kind..'-arrival-gameplay');assert(C.advance(.016)==0);assert(C.press(Profile.keys.dash));assert(C.advance(.016)==.016)
  App.openEntry(route.to,false);App.draftName='Direct';App.submit();assert(C.arrivalKind=='brief')
 end
 print('PASS elemental arrivals: both campaign handoffs, destination maps, continuous motion, bubble release, pause and frozen RNG/scoring')
 love.event.quit()
end
return T
