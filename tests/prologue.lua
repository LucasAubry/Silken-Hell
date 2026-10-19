local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Audio.focused=false
 local P=require('prologue');local saved=Profile.prologueSeen;local save=Profile.save
 Profile.save=function()end;Input.move=function()return 0,0 end
 Profile.prologueSeen=false;assert(P.shouldStart());Profile.prologueSeen=true;assert(not P.shouldStart())
 P.open(true);assert(App.state=='prologue' and P.canMove())
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(1200,750);g.push('all');g.setCanvas(c);P.draw(1200,750);g.setCanvas();g.pop()
  c:newImageData():encode('png','prologue-'..name..'.png');c:release()
 end
 capture('forest')
 -- Directional views retain independent source pixels, including both sides.
 for _,entry in ipairs({{'down',0},{'up',math.pi},{'left',math.pi/2},{'right',-math.pi/2}}) do
  local q={x=300,y=300,angle=entry[2]};assert(P.drawCarrier(q,112)==entry[1])
 end
 assert(Art.images.prologue_carrier_left.image~=Art.images.prologue_carrier_right.image)
 P.phase='confront';P.carrying=true;P.time=1;P.queen.x=710;P.queen.y=440
 for _,entry in ipairs({{'down',0},{'up',math.pi},{'left',math.pi/2},{'right',-math.pi/2}}) do
  P.queen.angle=entry[2];capture('direction-'..entry[1])
 end
 P.open(true)
 assert(P.blocked(P.streamX(300),300) and not P.blocked(P.streamX(425),425),'Stream and bridge collision')
 local x=P.hero.x;Input.move=function()return 1,0 end;P.update(.05);assert(P.hero.x>x);Input.move=function()return 0,0 end
 P.paused=true;local t=P.clock;P.update(.05);assert(P.clock==t);P.paused=false
 local seen={};local loops=0
 while P.phase~='portal_player' do
  P.update(.05);loops=loops+1;assert(loops<1600,'Timeline completes')
  if not seen[P.phase] then seen[P.phase]=true
   if P.phase=='blackout' then assert(P.darkness==1 and not P.canMove()) end
   if P.phase=='confront' then assert(P.carrying) end
  end
  if P.phase=='confront' and P.time>1 and not seen.picture then capture('queen');seen.picture=true end
 end
 assert(seen.fall and seen.arrival and seen.lift and seen.confront and seen.departure)
 assert(P.queenGone and P.canMove());capture('portal')
 P.close();assert(App.state=='menu');P.open(true);assert(P.phase=='wander' and not P.carrying)
 P.hero.x=P.portal.x;P.hero.y=P.portal.y;P.phase='portal_player';P.update(.05);assert(P.phase=='enter')
 local start=App.start;local called=0;App.start=function(n)assert(n==1);called=called+1 end
 for i=1,20 do P.update(.05) end
 assert(called==1 and Profile.prologueSeen and not App.hardcore)
 App.start=start;Profile.record=function()end;Replay.disabled=true;Bestiary.save=function()end
 P.entering=false;P.enterWorld();assert(App.state=='playing' and Campaign.world==1 and player.level==1,'Real first-world initialization')
 P.close();love.draw();local button
 for _,b in ipairs(UI.buttons) do if b.y==695 and b.w==350 then button=b end end
 assert(button,'Menu replay button present');button.run();assert(App.state=='prologue' and P.phase=='wander')
 Profile.save=save;Profile.prologueSeen=saved
 print('PASS prologue: first launch gating, movement, river collision, pause, complete kidnapping, portal and world 1 transition; screenshots captured')
 love.event.quit()
end
return T
