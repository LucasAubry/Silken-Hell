local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end;Profile.language='fr'
 local g=love.graphics;local C=require('collision_shapes')
 local completed,hardcore,achievements,scores=Profile.completed,Hardcore.completed,Profile.achievements,Profile.scores
 Profile.scores={}
 Profile.completed={[1]=true,[6]=true};Hardcore.completed={};Profile.achievements={};Profile.character=6
 assert(not Characters.selectVariant(true) and Profile.character==6,'Locked variant cannot be equipped')
 Hardcore.completed['1']=true
 assert(Characters.selectVariant(true) and Profile.character==15,'Gold variant equips within its family')
 assert(Characters.selectVariant(false) and Profile.character==6,'Classic variant can be restored')
 Characters.selectVariant(true);Characters.cycle(1)
 assert(Profile.character==7,'Next family falls back to its unlocked classic')
 Characters.cycle(-1);assert(Profile.character==6,'Arrows cycle families, not duplicate variants')
 Profile.character=2;assert(not Characters.selectVariant(true),'No fabricated variant for a skin without one')
 Profile.completed={};Profile.character=15;Characters.cycle(-1);Characters.cycle(1)
 assert(Profile.character==15,'A family unlocked only through hardcore remains selectable')
 Profile.completed=completed;Hardcore.completed=hardcore;Profile.achievements=achievements;Profile.scores=scores;Profile.character=1
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
 -- Compare the same unadorned body material, not eyes, outlines or crowns.
 -- These UVs lie on the lit abdomen of each source drawing.
 local colorCanvas=g.newCanvas(256,256)
 for id=1,22 do
  local front
  for _,dir in ipairs({'down','up','left','right'}) do
   g.push('all');g.setCanvas(colorCanvas);g.origin();g.clear(0,0,0,0);g.setColor(1,1,1)
   Characters.portrait(id,128,128,220,dir);g.pop()
   local art=Art.images[Characters.model(dir)];local qx,qy,qw,qh=art.quad:getViewport()
   local iw,ih=art.image:getDimensions();local scale=220/math.max(qw,qh)
   local side=dir=='left' or dir=='right'
   -- The profile's central abdomen now carries the shared marking; sample beside it.
   local dx=(iw*(side and .62 or .42)-qx-qw/2)*scale;local dy=(ih*(side and .29 or .26)-qy-qh/2)*scale
   local data=colorCanvas:newImageData();local rgb={0,0,0}
   for y=-1,1 do for x=-1,1 do
    local r,g,b,a=data:getPixel(math.floor(128+(dir=='right' and -dx or dx))+x,math.floor(128+dy)+y)
    assert(a>.99,'Opaque skin material');rgb[1]=rgb[1]+r/9;rgb[2]=rgb[2]+g/9;rgb[3]=rgb[3]+b/9
   end end
   if dir=='down' then
    for _,eyeX in ipairs({590,851}) do
     local ex=math.floor(128+(eyeX-qx-qw/2)*scale)
     local ey=math.floor(128+(637-qy-qh/2)*scale)
     local r,g,b,a=data:getPixel(ex,ey)
     assert(math.min(r,g,b)>.9 and a>.99,'White opaque eye catchlight: skin '..id)
    end
    for _,irisX in ipairs({.384,.616}) do
     local ex=math.floor(128+(iw*irisX-qx-qw/2)*scale)
     local ey=math.floor(128+(ih*.585-qy-qh/2)*scale)
     local r,g,b,a=data:getPixel(ex,ey)
     local base=Characters.crowned[id] or id
     assert(a>.99,'Opaque iris')
     if base==1 then assert(r>g and g>b,'Clean amber iris without blue/body fragments')
     else assert(b>r+.2,'Blue iris retained independently of body tint') end
    end
   end
   if side then
    local markX=(iw*.57-qx-qw/2)*scale
    local markY=(ih*.24-qy-qh/2)*scale
    local r,g,b,a=data:getPixel(math.floor(128+(dir=='right' and -markX or markX)),math.floor(128+markY))
    local base=Characters.crowned[id] or id
    assert(a>.99,'Opaque profile marking')
    if base==1 then assert(r<rgb[1]*.8,'Brown profile retains the dark abdomen marking')
    else assert(r>b*1.4+.06 and g>b*1.1+.02,'Gold abdomen marking in profile: skin '..id..' '..dir) end
   end
   data:release()
   if not front then front=rgb else for channel=1,3 do
    assert(math.abs(front[channel]-rgb[channel])<.065,'Consistent body color: '..id..' '..dir..' channel '..channel..' ('..front[channel]..' / '..rgb[channel]..')')
   end end
  end
 end
 colorCanvas:release()
 -- Background motes must never brighten any opaque part of the menu spider.
 local menuCanvas=g.newCanvas(1200,750);local actorCanvas=g.newCanvas(1200,750)
 Profile.character=1;App.selectedWorld=1
 for _,time in ipairs({0,3,9,15}) do
  UI.clock=time;local x=600+math.sin(time*.32)*9;local y=247+math.sin(time*.9)*7
  g.push('all');g.origin();g.setCanvas(menuCanvas);g.clear();UI.background()
  g.setCanvas(actorCanvas);g.clear(0,0,0,0);g.setColor(1,1,1);Characters.selectionPortrait(x,y,216);g.pop()
  local scene=menuCanvas:newImageData();local actor=actorCanvas:newImageData()
  for py=160,330,2 do for px=490,710,2 do
   local r,g,b,a=actor:getPixel(px,py)
   if a>.999 then
    local sr,sg,sb=scene:getPixel(px,py)
    assert(math.max(math.abs(sr-r),math.abs(sg-g),math.abs(sb-b))<.01,'Menu particles remain behind the body and eyes')
   end
  end end
  scene:release();actor:release()
 end
 menuCanvas:release();actorCanvas:release()
 for _,a in ipairs(Achievements.list)do
  local _,lines=UI.fonts.body:getWrap(a.description(),715)
  assert(#lines<=2,'Readable card text: '..a.id)
 end
 Profile.completed={[1]=true};Profile.achievements={maxance=true}
 App.state='achievements';UI.achievementFilter='all';UI.achievementPage=1;UI.draw()
 assert(#UI.buttons==3,'Only filter, statistics and back buttons')
 local list=require('achievements_screen');love.wheelmoved(0,-100);assert(list.scroll==list.maxScroll and list.scroll>0,'All achievements accessible by scrolling')
 love.keypressed('pageup');assert(list.scroll<list.maxScroll);list.move(-10000)
 UI.buttons[2].run();assert(App.state=='statistics');love.keypressed('escape');assert(App.state=='achievements');UI.draw()
 UI.buttons[1].run();assert(UI.achievementFilter=='todo');UI.draw()
 UI.buttons[1].run();assert(UI.achievementFilter=='done');UI.draw()
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
  elseif tick==7 then
   App.state='menu';App.selectedWorld=1;Profile.character=1;UI.clock=9;draw();capture('menu-opaque')
  elseif tick==8 then
   g.clear(.08,.09,.10);g.setColor(1,1,1);Characters.portrait(1,600,360,650,'down');capture('skin-brown-detail')
  elseif tick>=9 then print('PASS fixed collisions, swept contacts, F3 removal, all boss renderers, achievement filters and readable descriptions, consistent body colors, PNG profile markings, clean irises and white eye catchlights for all 22 skins, opaque menu sprite over particles, map and skin captures');love.event.quit() end
 end
end
return T
