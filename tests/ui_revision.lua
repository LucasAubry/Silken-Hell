local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end;Profile.language='fr'
 local g=love.graphics;local C=require('collision_shapes')
 App.singleLevel=true;App.practice=2;App.start(1);player.reset=false;player.x=100;player.y=200
 local px,py,pw,ph=C.playerRect()
 assert(C.projectile(px,py,1,1) and not C.projectile(px+pw,py,1,1))
 local cx,cy=C.center()
 assert(C.touchCircle('test',cx+33,cy,34) and not C.touchCircle('test',cx+34,cy,34))
 assert(C.sweptCircle('test',cx-100,cy,cx+100,cy,1),'Swept contact catches fast crossings')
 assert(not C.sweptCircle('test',cx-100,cy+2,cx+100,cy+2,1))
 local oldWalls=Walls;Walls={{x=px+pw,y=py,w=5,h=ph}}
 assert(not willCollide(player.x,player.y) and willCollide(player.x+1,player.y));Walls=oldWalls
 love.keypressed('f3');assert(App.state=='playing' and not package.loaded.hitbox_tuner)
 assert(not C.set and not C.drawWorld,'No editing or overlay API')
 for _,w in ipairs(Worlds.order) do
  App.practice=Worlds.levelCount(w);App.start(w);player.reset=false;love.draw()
 end
 local canvas=g.newCanvas(80,80)
 for id=1,22 do
  g.push('all');g.setCanvas(canvas);g.clear(0,0,0,0);g.setColor(1,1,1,.12)
  Characters.portrait(id,40,40,62,'down');g.pop()
  local pixels=canvas:newImageData();local maximum=0
  for y=0,79 do for x=0,79 do local _,_,_,alpha=pixels:getPixel(x,y);maximum=math.max(maximum,alpha) end end
  pixels:release();assert(maximum<.13 and maximum>.02,'Skin opacity '..id)
 end
 canvas:release()
 for _,a in ipairs(Achievements.list)do
  local _,lines=UI.fonts.body:getWrap(a.description(),715)
  assert(#lines<=2,'Readable card text: '..a.id)
 end
 Profile.completed={[1]=true};Profile.achievements={maxance=true}
 App.state='achievements';UI.achievementFilter='all';UI.achievementPage=1;UI.draw()
 UI.buttons[2].run();assert(UI.achievementFilter=='todo');UI.draw()
 UI.buttons[3].run();assert(UI.achievementFilter=='done');UI.draw()
 assert(UI.achievementPage==1)
 local function capture(name)
  g.captureScreenshot(function(d)
   local f=assert(io.open('/tmp/silken-'..name..'.png','wb'));f:write(d:encode('png'):getString());f:close()
  end)
 end
 local draw=love.draw;local tick=0
 love.update=function() tick=tick+1 end
 love.draw=function()
  if tick==1 or tick==2 then
   App.state='achievements';UI.achievementFilter=tick==1 and 'all' or 'done';UI.achievementPage=1;draw();capture('achievements-'..tick)
  elseif tick==3 or tick==4 then
   love.window.setMode(tick==3 and 1200 or 1440,tick==3 and 750 or 700,{resizable=true})
   App.selectedWorld=1;WorldMap.open();WorldMap.scroll=220;draw();capture('map-'..tick)
  elseif tick==5 then
   love.window.setMode(1200,750,{resizable=true});g.clear(.035,.05,.065)
   for i=1,5 do
    local x=120+(i-1)*240
    UI.text(Characters.names[i],x-90,25,'medium',{1,1,1},180,'center')
    for row,dir in ipairs({'down','up','left','right'})do
     g.setColor(1,1,1);Characters.portrait(i,x,70+row*125,100,dir)
    end
   end
   capture('skins-shared')
  elseif tick==6 then
   App.singleLevel=true;App.practice=2;App.start(1);player.reset=false;draw();capture('game-clean')
  elseif tick>=7 then print('PASS fixed collisions, swept contacts, F3 removal, all boss renderers, achievement filters and readable descriptions, map and skin captures');love.event.quit() end
 end
end
return T
