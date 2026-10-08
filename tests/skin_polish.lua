local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true;Hardcore.completed[tostring(w)]=true end
 Profile.achievements={gillou=true,maxance=true}
 local C=Characters;local original=Art.draw;local calls=0
 Art.draw=function(key,...)if key=='reward_crown' then calls=calls+1 end;return original(key,...)end
 for i=15,22 do
  for _,dir in ipairs({'down','up','left','right'})do
   calls=0;C.portrait(i,100,100,100,dir)
   assert(calls==0,'Gold rewards never draw crowns '..i..dir)
  end
 end
 Art.draw=original
 local last;local draw=Art.draw;Art.draw=function(key,...)last=key;return draw(key,...)end
 C.portrait(1,100,100,80,'left');assert(last==C.model('left'),'Brown portrait uses profile pose')
 C.portrait(1,100,100,80,'right');assert(last==C.model('right'))
 Art.draw=draw
 App.start(3);Profile.character=22;player.walkMoving=true;player.walkPhase=1
 for _,dir in ipairs({'down','up','left','right'})do C.draw(100,100,62,dir) end
 player.walkMoving=false
 local g=love.graphics;g.setColor(.3,.4,.5,.7);C.portrait(15,100,100,80,'up',true)
 local r,gg,b,a=g.getColor();assert(math.abs(r-.3)<.001 and math.abs(a-.7)<.001,'Portrait restores tint and alpha')
 g.setColor(1,1,1)
 local random=love.math.getRandomState();local fx=require('skin_reward_fx')
 local polygon=g.polygon;local particles=0
 g.polygon=function(...)particles=particles+1;return polygon(...)end
 Graphics.effects=true;fx.orbit(100,100,59,false,false);fx.orbit(100,100,59,true,false)
 assert(particles>0,'Orbit exists at gameplay size');particles=0
 for _,size in ipairs({25,26}) do
  particles=0;C.portrait(15,100,100,size)
  assert(particles>0,'Reward particles visible in leaderboard at size '..size)
  particles=0;C.portrait(6,100,100,size);assert(particles==0,'Classic leaderboard skin has no reward particles')
 end
 particles=0
 Graphics.effects=false;fx.orbit(100,100,59,false,false);assert(particles==0,'Effects toggle disables particles')
 Graphics.effects=true;fx.orbit(100,100,59,false,true);assert(particles==0,'Locked preview has no particles');g.polygon=polygon
 local canvas=g.newCanvas(160,160)
 local function rendered(time)
  UI.clock=time;g.push('all');g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);g.setColor(1,1,1)
  C.portrait(22,80,80,100,'down');g.pop();return canvas:newImageData()
 end
 local first,second=rendered(0),rendered(.8);local changed,gold=0,0
 for y=0,159 do for x=0,159 do
  local r,g,b,a=first:getPixel(x,y);local rr,gg,bb,aa=second:getPixel(x,y)
  if a>.9 and r>.65 and g>.3 and b<.4 then gold=gold+1 end
  if math.abs(r-rr)+math.abs(g-gg)+math.abs(b-bb)+math.abs(a-aa)>.1 then changed=changed+1 end
 end end
 assert(changed>30,'Visible moving reward particles')
 -- Turning particles off leaves precisely the base skin, without a yellow rim.
 Graphics.effects=false
 local reward=rendered(0)
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);g.setColor(1,1,1);C.portrait(1,80,80,100,'down');g.pop()
 local base=canvas:newImageData()
 assert(reward:getString()==base:getString(),'Reward body exactly matches its base: no outline')
 reward:release();base:release();Graphics.effects=true
 -- The menu reuses its resolved body while position/time change continuously.
 Profile.character=11;C.selectionPortrait(100.1,120.2,216);local cached=C.menuCache
 UI.clock=12;C.selectionPortrait(100.4,120.6,216);assert(C.menuCache==cached,'Menu motion does not resample source details')
 first:release();second:release();canvas:release()
 assert(random==love.math.getRandomState(),'Gold effects never consume gameplay RNG')
 -- Rays belong only to the equipped reward, in play and the main menu.
 local rays=fx.rays;local rayCalls=0
 fx.rays=function(...)rayCalls=rayCalls+1;return rays(...)end
 g.setColor(1,1,1);Profile.character=1;App.state='playing';C.draw(100,100,59,'down');assert(rayCalls==0)
 Profile.character=22;C.draw(100,100,59,'down');assert(rayCalls==1)
 App.state='menu';C.selectionPortrait(600,247,216);assert(rayCalls==2)
 Profile.character=1;C.selectionPortrait(600,247,216);assert(rayCalls==2)
 Profile.character=22;App.state='worlds';C.draw(100,100,59,'down');assert(rayCalls==2)
 fx.rays=rays
 local normalDraw=love.draw
 love.draw=function()
  normalDraw()
  if App.captureReward then
   local name=App.captureReward;App.captureReward=nil
   g.captureScreenshot(function(data)local f=assert(io.open('/tmp/silken-reward-'..name..'.png','wb'));f:write(data:encode('png'):getString());f:close()end)
  end
 end
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then
   local rows={}
   for i=1,10 do rows[i]={name='Test '..i,skin=14+(i-1)%8+1,time=80+i,deaths=i} end
   Online.scores=function()return rows,'online'end
   Online.page=function()return {scores=rows,total=10,hasMore=false},'online'end
   UI.boardWorld=1;App.state='menu';Profile.character=22;App.captureReward='menu'
  elseif tick==2 then
   App.singleLevel=true;App.practice=2;App.start(1);Profile.character=22;player.reset=false;player.death=8;timer=22;App.captureReward='game'
  elseif tick==3 then
   App.state='rankings';UI.boardLocal=false;UI.boardPage=1;App.captureReward='rankings'
  elseif tick==4 then
   love.draw=function()
    g.clear(.03,.04,.06);local sw,sh=g.getDimensions();g.push();g.scale(sw/1200,sh/720)
    for i=15,22 do
     local x=150+((i-15)%4)*300;local y=125+math.floor((i-15)/4)*345
     g.setColor(1,1,1);C.portrait(i,x,y,160,'down')
     UI.text(C.names[i],x-140,y+78,'small',{1,1,1},280,'center')
     for n,dir in ipairs({'left','up','right'})do C.portrait(i,x-90+(n-1)*90,y+150,65,dir)end
    end
    g.pop();if tick==5 then g.captureScreenshot(function(data)local f=assert(io.open('/tmp/silken-gold-rewards.png','wb'));f:write(data:encode('png'):getString());f:close()end) end
   end
  elseif tick==8 then print('PASS all 8 gold rewards in 4 views; no reward crowns; no rim and larger orbits; quality toggle; RNG isolation; directional walking and render state');love.event.quit()end
 end
end
return T
