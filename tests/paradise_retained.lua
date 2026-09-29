local T={}
function T.run()
 io.stdout:setvbuf('no')
 love.errorhandler=function(msg) print(debug.traceback(tostring(msg),2));return function()return 1 end end
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 Profile.character=1;App.practice=nil;App.start(1)
 local P=require('paradise_ink');assert(P.active())
 assert(not love.filesystem.getInfo('paradise_art.lua'),'Rejected renderer removed')
 assert(not love.filesystem.getInfo('assets/environments/paradis/sol-peint.png'),'Rejected art removed')
 assert(P.floor==nil and P.atmosphere==nil and P.facing==nil,'Only requested props retained')
 assert(not P.mob({type='ange'}) and not P.mob({type='snake'}))
 local canvas=love.graphics.newCanvas(Arena.width,600)
 local function renderLevel(n)
  player.level=n;reset_level();local before=love.math.getRandomState()
  local walls=require('json').encode(Arena.walls)
  love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.origin()
  Campaign.draw();for _,m in ipairs(mobs)do Campaign.drawMob(m)end;Raven.draw();require('atmosphere').draw()
  love.graphics.setColor(1,1,1)
  for _,d in ipairs({'up','down','left','right'})do
   player.walkMoving=true;player.walkPhase=1.2;Characters.draw(300,300,62,d)
   player.walkMoving=false;Characters.draw(300,300,62,d)
  end
  love.graphics.setCanvas();love.graphics.pop()
  assert(before==love.math.getRandomState(),'Rendering must not change gameplay random state')
  assert(walls==require('json').encode(Arena.walls),'Rendering must not change wall collisions')
 end
 for n=1,10 do renderLevel(n)end
 for key in pairs(P.metadata)do
  local a=P.frame(key);local x,y,w,h=a.quad:getViewport();local iw,ih=a.image:getDimensions()
  assert(x>=0 and y>=0 and w>0 and h>0 and x+w<=iw and y+h<=ih,key)
  assert(a.image:getFilter()=='linear',key)
 end
 App.start(6);assert(not P.active());local B=require('biome_borders');B.key=nil;B.draw();assert(B.key==nil)
 local tick=0
 love.update=function(dt)
  tick=tick+1;UI.clock=UI.clock+dt
  if tick==1 then App.start(1);App.capture='paradis-retour-niveau1.png'
  elseif tick==4 then player.level=6;reset_level();App.capture='paradis-retour-niveau6.png'
  elseif tick==7 then player.level=9;reset_level();App.capture='paradis-retour-niveau9.png'
  elseif tick==10 then player.level=10;reset_level();Raven.hp=6;Raven.hatch();Raven.fireNext();App.capture='paradis-retour-boss.png'
  elseif tick==13 then
   print('PASS 10 Paradise levels, ink atlas bounds, linear filtering, unchanged collisions/RNG, 4 walking directions, Sky unaffected')
   love.event.quit()
  end
 end
end
return T
