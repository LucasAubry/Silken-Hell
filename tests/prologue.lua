local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Audio.focused=false
 local P=require('prologue');local saved=Profile.prologueSeen;local save=Profile.save
 Profile.save=function()end;Input.move=function()return 0,0 end
 Profile.prologueSeen=false;assert(P.shouldStart());Profile.prologueSeen=true;assert(not P.shouldStart())
 P.open(true);assert(App.state=='prologue' and P.canMove())
 assert(P.width==Arena.width and P.height==600 and P.partnerWidth==62 and Characters.playerWidth==59,'Campaign map and sprite scale')
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(1200,750);g.push('all');g.setCanvas(c);P.draw(1200,750);g.setCanvas();g.pop()
  c:newImageData():encode('png','prologue-'..name..'.png');c:release()
 end
 capture('forest')
 local trees=require('prologue_trees');local tree=trees.geometry(3,P.width,P.height)
 assert(tree.h>Characters.playerWidth*3 and tree.h<Characters.playerWidth*4,'Trees scaled to spiders')
 assert(P.blocked(tree.x,tree.y) and not P.blocked(tree.x,tree.y-65),'Only the trunk blocks passage')
 P.hero.x=tree.x-65;P.hero.y=tree.y;Input.move=function()return 1,0 end
 for i=1,12 do P.update(.05) end
 assert(P.hero.x<tree.x-15,'Walking cannot cross a trunk')
 Input.move=function()return 0,0 end
 P.hero.x=tree.x;P.hero.y=tree.y+27;capture('tree-front')
 P.hero.y=tree.y-28;capture('tree-back')
 local events={};local drawPart=trees.drawPart
 trees.drawPart=function(t,crown)events[#events+1]=crown and 'crown' or t.y end
 trees.drawScene({{y=tree.y-1,draw=function()events[#events+1]='back'end},{y=tree.y+1,draw=function()events[#events+1]='front'end}},P.width,P.height,0)
 trees.drawPart=drawPart
 local back,trunk,front,crown
 for i,e in ipairs(events) do if e=='back' then back=i elseif e==tree.y then trunk=i elseif e=='front' then front=i elseif e=='crown' and not crown then crown=i end end
 assert(back<trunk and trunk<front and front<crown,'Trunk depth and canopy occlusion')
 assert(P.blocked(P.nest.x,P.nest.y-30) and not P.blocked(P.nest.x,P.nest.y+12),'Cocoon collision leaves front entrance open')
 P.open(true)
 -- Directional views retain independent source pixels, including both sides.
 for _,entry in ipairs({{'down',0},{'up',math.pi},{'left',math.pi/2},{'right',-math.pi/2}}) do
  local q={x=300,y=300,angle=entry[2]};assert(P.drawCarrier(q,112)==entry[1])
 end
 assert(Art.images.prologue_carrier_left.image~=Art.images.prologue_carrier_right.image)
 P.phase='confront';P.carrying=true;P.time=1;P.queen.x=P.width*.70;P.queen.y=300
 for _,entry in ipairs({{'down',0},{'up',math.pi},{'left',math.pi/2},{'right',-math.pi/2}}) do
  P.queen.angle=entry[2];capture('direction-'..entry[1])
 end
 P.open(true)
 assert(not P.blocked(P.streamX(300),300) and P.inWater(P.streamX(300),300) and not P.inWater(P.streamX(340),340),'Water is lethal, bridge remains safe')
 P.phase='arrival';P.portalAmount=1;P.darkness=.62
 local portalDraw=P.drawPortal;local art=require('final_art');local spiderDraw=art.spider;local portalCount=0;local queenSeen=false
 P.drawPortal=function()portalCount=portalCount+1;assert(not queenSeen,'Portal must stay behind queen');portalDraw()end
 art.spider=function(kind,x,y,width,...)
  if kind=='queen' then assert(width==Characters.playerWidth,'Queen matches player size');queenSeen=true end
  return spiderDraw(kind,x,y,width,...)
 end
 capture('queen-portal');assert(portalCount==1 and queenSeen)
 P.drawPortal=portalDraw;art.spider=spiderDraw;P.open(true)
 assert(P.nest.x==P.width-115 and P.nest.y==112,'Small cocoon in upper-right corner')
 local phase=P.phase;local savedAttempts=Profile.stats.attempts
 P.hero.x=P.streamX(280)+80;P.hero.y=280;Input.move=function()return -1,0 end
 for i=1,12 do P.update(.05);if P.drowning then break end end
 assert(P.drowning and not P.canMove() and P.waterDeaths==1,'Walking into river drowns')
 capture('drowning')
 Input.move=function()return 0,0 end
 for i=1,24 do P.update(.05) end
 assert(not P.drowning and not P.inWater(P.hero.x,P.hero.y) and P.phase==phase,'Respawn on safe land without restarting story')
 assert(Profile.stats.attempts==savedAttempts,'Intro drowning does not alter campaign attempts')
 P.hero.x=P.streamX(340)+75;P.hero.y=340;Input.move=function()return -1,0 end
 for i=1,6 do P.update(.05) end
 assert(not P.drowning and P.hero.x<P.streamX(340),'Bridge can be crossed at running speed')
 P.open(true);Input.move=function()return 0,0 end
 local x=P.hero.x;Input.move=function()return 1,0 end;P.update(.05);assert(P.hero.x>x);Input.move=function()return 0,0 end
 P.paused=true;local t=P.clock;P.update(.05);assert(P.clock==t);P.paused=false
 for i=1,700 do P.update(.05) end
 assert(P.phase=='wander' and P.darkness==0,'No timed kidnapping outside nest')
 P.hero.x=P.nest.x;P.hero.y=P.nest.y;P.update(.05);assert(P.phase=='settle' and not P.canMove())
 local seen={};local loops=0
 while P.phase~='portal_player' do
  P.update(.05);loops=loops+1;assert(loops<1600,'Timeline completes')
  if not seen[P.phase] then seen[P.phase]=true
   if P.phase=='portal_open' then assert(P.darkness==.62 and not P.canMove());capture('sleep') end
   if P.phase=='confront' then assert(P.carrying) end
  end
  if P.phase=='confront' and P.time>1 and not seen.picture then capture('queen');seen.picture=true end
 end
 assert(seen.dusk and seen.portal_open and seen.arrival and seen.lift and seen.confront and seen.departure)
 assert(not seen.fall and not seen.blackout,'No tree fall or blackout')
 assert(P.queenGone and P.canMove());capture('portal')
 P.hero.x=P.streamX(270);P.hero.y=270;P.update(.05);assert(P.drowning)
 for i=1,23 do P.update(.05) end
 assert(P.phase=='portal_player' and P.queenGone and P.portalAmount==1 and not P.drowning,'Water respawn preserves open portal after kidnapping')
 P.close();assert(App.state=='menu');P.open(true);assert(P.phase=='wander' and not P.carrying)
 P.hero.x=P.portal.x;P.hero.y=P.portal.y;P.phase='portal_player';P.update(.05);assert(P.phase=='enter')
 local start=App.start;local called=0;App.start=function(n)assert(n==1);called=called+1 end
 for i=1,20 do P.update(.05) end
 assert(called==1 and Profile.prologueSeen and not App.hardcore)
 App.start=start;Profile.record=function()end;Replay.disabled=true;Bestiary.save=function()end
 P.entering=false;P.enterWorld();assert(App.state=='playing' and Campaign.world==1 and player.level==1,'Real first-world initialization')
 local startGate=require('run_start');assert(startGate.arrival==0)
 assert(not startGate.press(Profile.keys.dash) and not startGate.launch(),'Arrival cannot be skipped by held run input')
 local function arrivalCapture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  g.push('all');setCanvas(c)
  g.setCanvas=function(target,...)if target==nil then return setCanvas(c) end;return setCanvas(target,...)end
  love.draw();g.setCanvas=setCanvas;setCanvas();g.pop()
  c:newImageData():encode('png','prologue-paradise-'..name..'.png');c:release()
 end
 local px,py=player.x,player.y
 for i=1,80 do
  assert(startGate.advance(.05)==0)
  if i==44 then
   assert(startGate.arrivalActor.y<py+12 and startGate.arrivalActor.y>startGate.arrivalPortal.y and startGate.arrivalActor.walkMoving,'Spider walks out of portal')
   arrivalCapture('emergence')
  end
 end
 assert(player.x==px and player.y==py and startGate.active,'Arrival keeps the level safe and frozen')
 assert(startGate.arrivalActor.y==py+12 and not startGate.arrivalActor.walkMoving,'Visual arrival matches campaign spawn')
 arrivalCapture('closing')
 App.state='pause';local arrivalTime=startGate.arrival;startGate.advance(.5);assert(startGate.arrival==arrivalTime);App.state='playing'
 for i=1,112 do startGate.advance(.05);if i==25 then arrivalCapture('arrival') end end
 assert(not startGate.arrival and startGate.active,'Story leads into normal start prompt')
 P.close();love.draw();local button
 for _,b in ipairs(UI.buttons) do if b.y==695 and b.w==350 then button=b end end
 assert(button,'Menu replay button present');button.run();assert(App.state=='prologue' and P.phase=='wander')
 Profile.save=save;Profile.prologueSeen=saved
 print('PASS prologue: campaign dimensions, corner cocoon, water death/respawn before and after kidnapping, safe bridge, cocoon-triggered sleep, no timed/tree event, visible nighttime kidnapping, portal and world 1 transition; screenshots captured')
 love.event.quit()
end
return T
