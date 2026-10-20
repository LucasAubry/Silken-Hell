local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 App.practice=nil;App.singleLevel=false;App.preview=false;App.historyPreview=nil;App.hardcore=false;App.sessionLayout=nil;Secret.duel=nil
 Input.speedHeld=function()return false end
 local C=require('run_start');local O=require('ocean_arrival');local bubble=require('breathing_bubble')
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  g.push('all');setCanvas(c);g.setCanvas=function(target,...)if target==nil then return setCanvas(c) end;return setCanvas(target,...)end
  love.draw();g.setCanvas=setCanvas;setCanvas();g.pop();c:newImageData():encode('png','ocean-arrival-'..name..'.png');c:release()
 end
 Profile.complete(5,10,0);App.start(5);C.active=false;C.arrival=nil;C.arrivalKind=nil
 require('victory_screen').enter();UI.buttons={};require('victory_screen').draw()
 for _,button in ipairs(UI.buttons) do if button.x==796 then button.run();break end end
 assert(App.state=='entry' and App.selectedWorld==4 and App.entryFromWorld==5)
 App.draftName='Ocean arrival';App.submit()
 assert(C.arrivalKind=='ocean' and Campaign.world==4 and Campaign.biome==4 and player.level==1)
 assert(not O.pose(1).equipped and O.pose(2.4).equip>0 and O.pose(3.2).equipped and O.pose(3.2).dive==0,'Find and equip the bubble before entering water')
 assert(O.pose(4).edge==1 and O.pose(4.8).edge==1 and O.pose(4.8).swim==0 and O.pose(4).dir=='down','Dive stays vertical before swimming')
 assert(O.pose(5.6).swim>0 and O.pose(5.6).dir=='up','Swims toward the destination after submerging')
 assert(O.pose(6.1).underwater==1 and O.pose(8.1).mapAlpha==1)
 assert(O.pose(8).actorsAlpha==0 and O.pose(9).actorsAlpha>0 and O.pose(10).actorsAlpha==1,'Creatures appear gradually after landing')
 local drawAt=bubble.drawAt;local bubbleDrawn=0
 bubble.drawAt=function(...)bubbleDrawn=bubbleDrawn+1;return drawAt(...)end
 local px,py=player.x,player.y;local rng=love.math.getRandomState();local shots={};local ticks=0
 while C.arrival do
  assert(not C.press(Profile.keys.dash) and not C.launch())
  if ticks==10 then App.state='pause';local age=C.arrival;C.advance(.05);assert(C.arrival==age);App.state='playing' end
  C.advance(.05);ticks=ticks+1;assert(ticks<250)
  assert(player.x==px and player.y==py and timer==0 and love.math.getRandomState()==rng,'No simulation or RNG changes')
  for _,shot in ipairs({{'discovery',1.4},{'equip',2.4},{'helmet',3.2},{'spring',4.2},{'surface-crossing',4.5},{'submerged',5.2},{'current',5.8},{'ocean',7},{'landed',8},{'creatures',9.2},{'settled',10.3}}) do
   if C.arrival and C.arrival>=shot[2] and not shots[shot[1]] then capture(shot[1]);shots[shot[1]]=true end
  end
 end
 assert(O.environment,'Environment is captured before the creatures are drawn')
 bubble.drawAt=drawAt;assert(bubbleDrawn>=9,'Uses the real gameplay bubble renderer throughout the scene')
 assert(not C.active and direction=='up' and O.pose(O.duration).progress==1)
 capture('gameplay');assert(C.advance(.016)==.016)
 App.openEntry(4,false);App.draftName='Direct Ocean';App.submit();assert(C.arrivalKind=='portal')
 print('PASS Ocean arrival: campaign continuation, found/equipped shared bubble before water, current, real Ocean landing, pause, frozen scoring/RNG and resumed gameplay')
 love.event.quit()
end
return T
