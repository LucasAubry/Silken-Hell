-- Self-contained first-launch scene. No campaign simulation, achievements or
-- progression are touched until the player enters the silk portal.
local P={width=1200,height=750}
local ArtSet=require('final_art')
local Sound=require('prologue_audio')
local function clamp(x,a,b)return math.max(a,math.min(b,x))end
local function ease(t)t=clamp(t,0,1);return t*t*(3-2*t)end
local function distance(a,b)return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)end
local function move(a,x,y,speed,dt)
 local dx,dy=x-a.x,y-a.y;local d=math.sqrt(dx*dx+dy*dy)
 if d>.01 then local step=math.min(d,speed*dt);a.x=a.x+dx/d*step;a.y=a.y+dy/d*step;a.angle=math.atan2(dy,dx)-math.pi/2 end
 require('brown_walk').advance(a,math.min(d,speed*dt),dt)
end
function P.shouldStart()return not Profile.prologueSeen and not App.preview end
function P.load()
 if P.background then return end
 local g=love.graphics
 P.background=g.newImage('assets/prologue/autumn_forest.png')
 Art.add('prologue_tree','assets/prologue/autumn_tree.png')
 Art.add('prologue_carrier','assets/prologue/queen_carrying_partner.png')
 Sound.load()
end
function P.open(test)
 P.load();P.test=test==true;P.phase='wander';P.time=0;P.clock=0;P.travel=0;P.darkness=0;P.paused=false
 P.saved={selectedWorld=App.selectedWorld,hardcore=App.hardcore}
 P.hero={x=610,y=540,dir='up',sanctuaryPlayer=true};P.partner={x=730,y=440,angle=0}
 P.queen={x=1080,y=230,angle=0};P.tree={x=825,y=352};P.victim={x=710,y=440};P.portal={x=1010,y=330}
 P.treeFall=0;P.portalAmount=0;P.carrying=false;P.queenGone=false;P.entering=false
 Replay.input=nil;Replay.recording=false;App.hardcore=false;App.state='prologue';UI.buttons={};UI.pressed=nil
 require('run_start').active=false;require('run_start').suspend();love.keyboard.setTextInput(false)
end
function P.close()
 Sound.stop();App.selectedWorld=P.saved.selectedWorld;App.hardcore=P.saved.hardcore
 App.state='menu';UI.buttons={};Input.index=1;P.paused=false
end
function P.transition(phase)
 P.phase=phase;P.time=0
 if phase=='fall' then Sound.impact() end
end
function P.canMove()return not P.paused and (P.phase=='wander' or P.phase=='portal_player' or P.phase=='dusk' and P.time<2)end
function P.streamX(y)
 local points={{0,255},{120,230},{240,210},{360,220},{425,210},{510,242},{610,277},{750,345}}
 for i=2,#points do local a,b=points[i-1],points[i]
  if y<=b[1] then return a[2]+(b[2]-a[2])*(y-a[1])/(b[1]-a[1]) end
 end
 return 345
end
function P.blocked(x,y)
 if x<55 or x>1145 or y<115 or y>685 then return true end
 -- The stream is crossed at the little wooden bridge.
 local stream=P.streamX(y)
 if math.abs(x-stream)<37 and (y<400 or y>450) then return true end
 if P.treeFall<.1 and (x-P.tree.x)^2+(y-P.tree.y)^2<32^2 then return true end
 return false
end
function P.enterWorld()
 if P.entering then return end;P.entering=true;Sound.stop()
 Profile.prologueSeen=true
 if Profile.name=='' then Profile.name='Joueur' end
 Profile.save();App.hardcore=false;App.practice=nil;App.singleLevel=false;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
 App.start(1)
end
function P.update(dt)
 Sound.update(P.paused,P.darkness)
 if P.paused then return end
 dt=math.min(dt,.05);P.clock=P.clock+dt;P.time=P.time+dt
 local hero=P.hero
 hero.walkMoving=false;P.partner.walkMoving=false;P.queen.walkMoving=false
 if P.canMove() then
  local dx,dy=Input.move();local speed=Input.slow() and 155 or 245;local ox,oy=hero.x,hero.y
  if not P.blocked(hero.x+dx*speed*dt,hero.y) then hero.x=hero.x+dx*speed*dt end
  if not P.blocked(hero.x,hero.y+dy*speed*dt) then hero.y=hero.y+dy*speed*dt end
  if math.abs(dx)>math.abs(dy) then hero.dir=dx<0 and 'left' or 'right' elseif dy~=0 then hero.dir=dy<0 and 'up' or 'down' end
  local d=math.sqrt((hero.x-ox)^2+(hero.y-oy)^2);P.travel=P.travel+d;require('brown_walk').advance(hero,d,dt)
 end
 if P.phase=='wander' then
  move(P.partner,710+math.sin(P.clock*.36)*42,445+math.cos(P.clock*.4)*25,35,dt)
  if P.time>=12 and P.travel>100 or P.time>=24 then P.transition('dusk') end
 elseif P.phase=='dusk' then
  P.darkness=ease(P.time/5);move(P.partner,P.victim.x,P.victim.y,95,dt)
  if P.time>=5 then P.darkness=1;P.transition('blackout') end
 elseif P.phase=='blackout' then
  if P.time>=.7 then P.transition('fall') end
 elseif P.phase=='fall' then
  P.treeFall=ease(P.time/1.4);P.darkness=1-.43*ease(P.time/1.5)
  if P.time>=1.5 then P.transition('arrival') end
 elseif P.phase=='arrival' then
  P.darkness=.57;move(P.queen,P.victim.x+15,P.victim.y+5,165,dt)
  if distance(P.queen,P.victim)<22 then P.transition('lift') end
 elseif P.phase=='lift' then
  P.queen.angle=0
  if P.time>=1.2 then P.carrying=true;P.transition('confront') end
 elseif P.phase=='confront' then
  local target=math.atan2(hero.y-P.queen.y,hero.x-P.queen.x)-math.pi/2
  P.queen.angle=target*ease(P.time/.7)
  if P.time>=5.8 then P.transition('portal_open') end
 elseif P.phase=='portal_open' then
  P.portalAmount=ease(P.time/1.5)
  if P.time>=1.6 then P.transition('departure') end
 elseif P.phase=='departure' then
  move(P.queen,P.portal.x,P.portal.y,145,dt)
  if distance(P.queen,P.portal)<4 then P.queenGone=true;P.transition('portal_player') end
 elseif P.phase=='portal_player' then
  P.darkness=math.max(.32,P.darkness-dt*.12)
  if distance(hero,P.portal)<46 then P.transition('enter') end
 elseif P.phase=='enter' then
  P.darkness=.32+.68*ease(P.time/.8)
  if P.time>=.85 then P.enterWorld() end
 end
end
local function shadow(x,y,w)
 local g=love.graphics;g.setColor(.08,.035,.012,.22);g.ellipse('fill',x+3,y+11,w*.43,w*.13)
end
function P.drawTree()
 local g=love.graphics;local a=Art.images.prologue_tree;local scale=285/a.h
 g.setColor(1,1,1);g.draw(a.image,a.quad,P.tree.x,P.tree.y,-2.07*P.treeFall,scale,scale,a.w*.67,a.h*.96)
end
function P.drawPortal()
 if P.portalAmount<=0 then return end
 local g=love.graphics;local x,y=P.portal.x,P.portal.y;local amount=P.portalAmount;local t=P.clock
 g.push('all');g.translate(x,y);g.scale(amount,amount)
 g.setBlendMode('add');for i=10,1,-1 do g.setColor(.8,.27,.12,.018);g.ellipse('fill',0,0,45+i*4,60+i*4) end;g.setBlendMode('alpha')
 g.setColor(.025,.008,.025,.98);g.ellipse('fill',0,0,43,60)
 for i=1,16 do local a=i*math.pi/8
  g.setColor(.92,.8,.68,.8);g.setLineWidth(1);g.line(math.cos(a)*12,math.sin(a)*16,math.cos(a)*60,math.sin(a)*78)
  for ring=1,5 do
   local r=ring*11;local b=a+math.pi/8
   g.setColor(.98,.89,.76,.55+ring*.06)
   g.line(math.cos(a)*r,math.sin(a)*r*1.3,math.cos((a+b)/2)*r*.93,math.sin((a+b)/2)*r*1.3*.93,math.cos(b)*r,math.sin(b)*r*1.3)
  end
 end
 for i=1,16 do local a=t*.25+i*2.399;local r=25+(i*17+t*12)%44
  g.setColor(1,.63,.29,.4);g.circle('fill',math.cos(a)*r,math.sin(a)*r*1.3,1.3)
 end
 g.pop()
end
function P.draw(w,h)
 local g=love.graphics;local s=math.min(w/P.width,h/P.height)
 g.push('all');g.origin();g.setShader();g.clear(.045,.025,.015)
 g.translate((w-P.width*s)/2,(h-P.height*s)/2);g.scale(s)
 g.setColor(1,1,1);g.draw(P.background,0,0,0,P.width/P.background:getWidth(),P.height/P.background:getHeight())
 -- A little reflected light moves down the river; falling leaves stay visual only.
 for i=1,28 do
  local y=(i*31+P.clock*24)%750;local x=P.streamX(y)+math.sin(i*17)*20
  if y<400 or y>450 then g.setColor(.8,.94,.87,.18);g.setLineWidth(1);g.line(x,y,x+7+i%9,y-1) end
 end
 for i=1,52 do
  local x=(i*139+P.clock*(9+i%5))%1200;local y=(i*73+P.clock*(12+i%9))%750
  g.push();g.translate(x+math.sin(P.clock+i)*8,y);g.rotate(i+P.clock*.5)
  g.setColor(.76+i%3*.07,.28+i%4*.055,.055,.7)
  g.polygon('fill',-4,0,0,-2,5,0,0,3);g.pop()
 end
 if P.treeFall>0 and P.phase=='lift' then P.drawTree() end
 if not P.carrying and not P.queenGone then
  local partner=P.partner;local lift=P.phase=='lift' and ease(P.time/1.2) or 0
  shadow(partner.x,partner.y,43)
  g.setColor(1,1,1,1-lift);ArtSet.spider('partner',partner.x+(P.queen.x-partner.x)*lift,partner.y-32*lift,43,partner.angle,partner)
 end
 if P.treeFall>0 and P.phase~='lift' then P.drawTree() end
 shadow(P.hero.x,P.hero.y,48);g.setColor(1,1,1);Characters.draw(P.hero.x,P.hero.y,48,P.hero.dir,P.hero)
 if P.treeFall==0 then P.drawTree() end
 P.drawPortal()
 if P.phase~='wander' and P.phase~='dusk' and P.phase~='blackout' and P.phase~='fall' and not P.queenGone then
  local q=P.queen;local fade=P.phase=='departure' and clamp(distance(q,P.portal)/58,0,1) or 1
  shadow(q.x,q.y,112);g.setColor(1,1,1,fade)
  if P.carrying then
   local a=Art.images.prologue_carrier
   -- Rotate the assembled captive and queen together when she turns toward us.
   local scale=112/a.w;g.push();g.translate(q.x,q.y);g.rotate(q.angle)
   if not require('brown_walk').draw(a.image,'down',0,0,112,q,a.quad) then g.draw(a.image,a.quad,0,0,0,scale,scale,a.w/2,a.h/2) end;g.pop()
  else ArtSet.spider('queen',q.x,q.y,112,q.angle,q) end
 end
 g.setColor(.008,.005,.016,P.darkness);g.rectangle('fill',0,0,1200,750)
 -- The portal stays readable after the forest has gone dark.
 if P.darkness<.98 then P.drawPortal() end
 if P.phase=='confront' then
  local a=clamp(P.time/.5,0,1);g.setColor(.018,.008,.023,a*.88);g.rectangle('fill',170,605,860,84,10)
  UI.text('Si tu veux la revoir, viens la chercher en enfer.',195,628,'medium',{1,.89,.73,a},810,'center')
 end
 g.pop()
end
function P.ui()
 if not P.paused then return end
 local g=love.graphics;g.setColor(.01,.008,.016,.72);g.rectangle('fill',0,0,1200,750)
 UI.panel(375,275,450,210)
 UI.button('Reprendre',410,312,380,48,function()P.paused=false end,false,true)
 UI.button('Retour au menu',410,393,380,48,P.close)
end
function P.key(key)
 if key=='escape' or key==Profile.keys.pause then P.paused=not P.paused;Input.index=1 end
 return true
end
return P
