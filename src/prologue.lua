-- Self-contained first-launch scene. No campaign simulation, achievements or
-- progression are touched until the player enters the silk portal.
local P={width=960,height=600,partnerWidth=62}
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
 if P.loaded then return end
 require('prologue_terrain').load(P.terrainStreamX)
 Art.add('prologue_carrier_down','assets/prologue/queen_carrying_partner.png')
 for _,dir in ipairs({'up','left','right'}) do Art.add('prologue_carrier_'..dir,'assets/prologue/queen_carrying_'..dir..'.png') end
 Sound.load();P.loaded=true
end
function P.open(test)
 Arena.configure(love.graphics.getDimensions());P.width=Arena.width;P.height=Arena.height
 P.load();P.test=test==true;P.phase='wander';P.time=0;P.clock=0;P.travel=0;P.darkness=0;P.paused=false
 P.saved={selectedWorld=App.selectedWorld,hardcore=App.hardcore}
 P.hero={x=P.width*.51,y=432,dir='up',sanctuaryPlayer=true};P.partner={x=P.width*.51+72,y=425,angle=0}
 P.nest={x=P.width*.64,y=185};P.victim={x=P.nest.x+35,y=P.nest.y+4}
 P.portal={x=P.width*.86,y=300};P.queen={x=P.portal.x,y=P.portal.y,angle=0}
 P.portalAmount=0;P.carrying=false;P.queenGone=false;P.entering=false
 Replay.input=nil;Replay.recording=false;App.hardcore=false;App.state='prologue';UI.buttons={};UI.pressed=nil
 require('run_start').active=false;require('run_start').suspend();love.keyboard.setTextInput(false)
end
function P.close()
 Sound.stop();App.selectedWorld=P.saved.selectedWorld;App.hardcore=P.saved.hardcore
 App.state='menu';UI.buttons={};Input.index=1;P.paused=false
end
function P.transition(phase)
 P.phase=phase;P.time=0
end
function P.canMove()return not P.paused and (P.phase=='wander' or P.phase=='portal_player')end
function P.terrainStreamX(y)
 local points={{0,255},{120,230},{240,210},{360,220},{425,210},{510,242},{610,277},{750,345}}
 for i=2,#points do local a,b=points[i-1],points[i]
  if y<=b[1] then return a[2]+(b[2]-a[2])*(y-a[1])/(b[1]-a[1]) end
 end
 return 345
end
function P.streamX(y)return P.terrainStreamX(y*750/P.height)*P.width/1200 end
function P.blocked(x,y)
 if x<40 or x>P.width-40 or y<48 or y>P.height-40 then return true end
 if math.abs(x-P.streamX(y))<37*P.width/1200+12 and (y<332 or y>348) then return true end
 return false
end
function P.inNest(a)
 return ((a.x-P.nest.x)/67)^2+((a.y-P.nest.y)/39)^2<1
end
local function accompany(dt)
 local a,h=P.partner,P.hero
 if distance(a,h)<86 then return end
 local x,y=h.x,h.y
 -- Both companions cross the stream at the bridge, never through the water.
 if (a.x-P.streamX(a.y))*(h.x-P.streamX(h.y))<0 then
  if math.abs(a.y-340)>6 then x=a.x;y=340 else x=P.streamX(340)+(h.x>P.streamX(h.y) and 75 or -75);y=340 end
 end
 move(a,x,y,210,dt)
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
  local dx,dy=Input.move();local speed=Input.slow() and 300 or 540;local ox,oy=hero.x,hero.y
  if not P.blocked(hero.x+dx*speed*dt,hero.y) then hero.x=hero.x+dx*speed*dt end
  if not P.blocked(hero.x,hero.y+dy*speed*dt) then hero.y=hero.y+dy*speed*dt end
  if math.abs(dx)>math.abs(dy) then hero.dir=dx<0 and 'left' or 'right' elseif dy~=0 then hero.dir=dy<0 and 'up' or 'down' end
  local d=math.sqrt((hero.x-ox)^2+(hero.y-oy)^2);P.travel=P.travel+d;require('brown_walk').advance(hero,d,dt)
 end
 if P.phase=='wander' then
  accompany(dt)
  if P.inNest(hero) then P.transition('settle') end
 elseif P.phase=='settle' then
  move(hero,P.nest.x-35,P.nest.y+4,160,dt);hero.dir='up'
  if (P.partner.x-P.streamX(P.partner.y))*(P.victim.x-P.streamX(P.victim.y))<0 then accompany(dt) else move(P.partner,P.victim.x,P.victim.y,180,dt) end
  if distance(hero,{x=P.nest.x-35,y=P.nest.y+4})<1 and distance(P.partner,P.victim)<1 then P.partner.angle=math.pi;P.transition('dusk') end
 elseif P.phase=='dusk' then
  P.darkness=.62*ease(P.time/4)
  if P.time>=4 then P.transition('portal_open') end
 elseif P.phase=='portal_open' then
  P.portalAmount=ease(P.time/1.5)
  if P.time>=1.6 then P.transition('arrival') end
 elseif P.phase=='arrival' then
  P.darkness=.62;move(P.queen,P.victim.x+15,P.victim.y+5,165,dt)
  if distance(P.queen,P.victim)<22 then P.transition('lift') end
 elseif P.phase=='lift' then
  P.queen.angle=0
  if P.time>=1.2 then P.carrying=true;P.transition('confront') end
 elseif P.phase=='confront' then
  local target=math.atan2(hero.y-P.queen.y,hero.x-P.queen.x)-math.pi/2
  P.queen.angle=target*ease(P.time/.7)
  if P.time>=6.5 then P.transition('departure') end
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
function P.drawNest()
 local g=love.graphics;local x,y=P.nest.x,P.nest.y
 g.push('all');g.translate(x,y)
 g.setColor(.07,.065,.035,.55);g.ellipse('fill',3,7,96,61)
 g.setColor(.25,.23,.15);g.ellipse('fill',0,0,91,55)
 g.setColor(.49,.46,.32);g.ellipse('fill',0,-2,80,45)
 g.setColor(.66,.64,.47);g.ellipse('fill',0,0,67,34)
 -- Overlapping loose silk makes a hollow bed, rather than a portal or trap.
 for i=1,32 do
  local a=i*2.399;local rx=75+i%5*3;local ry=43+i%4*2
  g.setColor(.84,.81,.65,.23+i%3*.07);g.setLineWidth(.8)
  g.ellipse('line',math.sin(a)*3,math.cos(a)*2,rx,ry)
  g.line(math.cos(a)*rx,math.sin(a)*ry,math.cos(a+.55)*(rx-12),math.sin(a+.55)*(ry-9))
 end
 for i=1,14 do
  local a=i*2.399;g.setColor(.78,.73,.53,.3);g.line(math.cos(a)*62,math.sin(a)*29,math.cos(a+2)*62,math.sin(a+2)*29)
 end
 g.pop()
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
-- Each side has its own passenger view: mirroring would swap her fixed flank.
function P.drawCarrier(q,width)
 local dir=ArtSet.facing(q.angle);local a=Art.images['prologue_carrier_'..dir]
 local g=love.graphics;local scale=width/a.w
 if not require('brown_walk').draw(a.image,dir,q.x,q.y,width,q,a.quad) then
  g.draw(a.image,a.quad,q.x,q.y,0,scale,scale,a.w/2,a.h/2)
 end
 return dir
end
function P.draw(w,h)
 local g=love.graphics;local s=math.min(w/P.width,h/P.height)
 g.push('all');g.origin();g.setShader();g.clear(.045,.025,.015)
 g.translate((w-P.width*s)/2,(h-P.height*s)/2);g.scale(s)
 g.push();g.scale(P.width/1200,P.height/750);require('prologue_terrain').draw(P.terrainStreamX,P.clock);g.pop()
 -- A little reflected light moves down the river; falling leaves stay visual only.
 for i=1,28 do
  local y=(i*31+P.clock*24)%P.height;local x=P.streamX(y)+math.sin(i*17)*20
  if y<320 or y>360 then g.setColor(.8,.94,.87,.18);g.setLineWidth(1);g.line(x,y,x+7+i%9,y-1) end
 end
 for i=1,52 do
  local x=(i*139+P.clock*(9+i%5))%P.width;local y=(i*73+P.clock*(12+i%9))%P.height
  g.push();g.translate(x+math.sin(P.clock+i)*8,y);g.rotate(i+P.clock*.5)
  g.setColor(.76+i%3*.07,.28+i%4*.055,.055,.7)
  g.polygon('fill',-4,0,0,-2,5,0,0,3);g.pop()
 end
 P.drawNest()
 if not P.carrying and not P.queenGone then
  local partner=P.partner;local lift=P.phase=='lift' and ease(P.time/1.2) or 0
  shadow(partner.x,partner.y,P.partnerWidth)
  g.setColor(1,1,1,1-lift);ArtSet.spider('partner',partner.x+(P.queen.x-partner.x)*lift,partner.y-32*lift,P.partnerWidth,partner.angle,partner)
 end
 shadow(P.hero.x,P.hero.y,Characters.playerWidth);g.setColor(1,1,1);Characters.draw(P.hero.x,P.hero.y,Characters.playerWidth,P.hero.dir,P.hero)
 P.drawPortal()
 if (P.phase=='arrival' or P.phase=='lift' or P.carrying) and not P.queenGone then
  local q=P.queen;local fade=P.phase=='departure' and clamp(distance(q,P.portal)/58,0,1) or 1
  shadow(q.x,q.y,112);g.setColor(1,1,1,fade)
  if P.carrying then
   P.drawCarrier(q,112)
  else ArtSet.spider('queen',q.x,q.y,112,q.angle,q) end
 end
 g.setColor(.008,.005,.016,P.darkness);g.rectangle('fill',0,0,P.width,P.height)
 -- The portal stays readable after the forest has gone dark.
 if P.darkness<.98 then P.drawPortal() end
 if P.phase=='confront' then
  local a=clamp(P.time/.5,0,1);g.setColor(.018,.008,.023,a*.88);g.rectangle('fill',40,P.height-110,P.width-80,90,10)
  UI.text('Son heure est venue. Je dois l’emmener là-haut. Je suis désolée.',60,P.height-92,'medium',{1,.89,.73,a},P.width-120,'center')
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
