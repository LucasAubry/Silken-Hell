local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true;Hardcore.completed[tostring(w)]=true end
 Profile.achievements={gillou=true,maxance=true}
 local paths=require('asset_paths');local checked=0
 for old,path in pairs(paths.paths)do
  assert(love.filesystem.getInfo(path),'Missing moved asset '..path)
  assert(not love.filesystem.getInfo(old),'Obsolete duplicate still packaged '..old)
  checked=checked+1
 end
 local function syntax(dir)
  for _,name in ipairs(love.filesystem.getDirectoryItems(dir))do
   local path=dir=='' and name or dir..'/'..name;local info=love.filesystem.getInfo(path)
   if info.type=='directory' then syntax(path)
   elseif name:match('%.lua$')then assert(love.filesystem.load(path),'Syntax '..path)end
  end
 end
 for _,dir in ipairs({'src','designer','tests'}) do syntax(dir) end
 assert(love.filesystem.getInfo('assets/fonts/police.ttf'))
 assert(love.filesystem.getInfo('assets/audio/music/menu paradi.mp3'))
 assert(love.filesystem.getInfo('assets/textures/larme.png'))
 -- Worker threads have their own Lua state: validate their module lookup offline.
 love.thread.getChannel('silken.requests'):push('quit')
 local worker=love.thread.newThread('src/network_thread.lua');worker:start();worker:wait()
 assert(not worker:getError(),worker:getError())
 for _,world in ipairs(Worlds.order)do
  App.start(world);player.level=Worlds.levelCount(world);reset_level();Campaign.draw()
 end
 Secret.open();require('sanctuary_scene').draw(Secret)
 -- Validate every editor thumbnail using its fallback lookup.
 for _,c in ipairs(require('designer.catalog'))do
  if c.art and not Art.images[c.art]then
   local a=paths.resolve('assets/sprites/'..c.art..'.png')
   if not love.filesystem.getInfo(a)then a=paths.resolve('assets/sprites/directional/'..c.art..'.png')end
   Art.add(c.art,a)
  end
 end
 local A=require('final_art')
 for _,name in ipairs({'queen','partner','baby_red','baby_white','baby_black'})do
  for _,angle in ipairs({0,math.pi,math.pi/2,-math.pi/2})do A.spider(name,100,100,62,angle)end
 end
 local g=love.graphics
 local function pixels(dir,index)
  local canvas=g.newCanvas(128,128);g.push('all');g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);g.setColor(1,1,1)
  Characters.portrait(index,64,64,100,dir);g.setCanvas();g.pop();local d=canvas:newImageData();canvas:release();return d
 end
 for _,i in ipairs({1,2,3,4,5})do
  local a,b=pixels('left',i),pixels('right',i)
  local total=0
  for y=0,127 do for x=0,127 do
   local r,g,b1,alpha=a:getPixel(x,y);local rr,gg,bb,aa=b:getPixel(127-x,y)
   total=total+math.abs(r-rr)+math.abs(g-gg)+math.abs(b1-bb)+math.abs(alpha-aa)
  end end
  assert(total<1,'Exact profile symmetry '..i..' difference '..total);a:release();b:release()
 end
 for i=1,22 do for _,dir in ipairs({'down','up','left','right'})do Characters.portrait(i,100,100,70,dir)end end
 App.start(1);Profile.character=22;player.walkMoving=true;player.walkPhase=1
 for _,dir in ipairs({'down','up','left','right'})do Characters.draw(100,100,62,dir)end
 player.walkMoving=false
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then
   love.draw=function()
    g.clear(.03,.04,.055);local sw,sh=g.getDimensions();g.push();g.scale(sw/1200,sh/720)
    for i,index in ipairs({1,2,3,4,5})do
     local x=120+(i-1)*240;Characters.portrait(index,x,175,155,'up')
     Characters.portrait(index,x-53,370,95,'left');Characters.portrait(index,x+53,370,95,'right')
     UI.text(Characters.names[index],x-105,280,'small',{1,1,1},210,'center')
    end
    for i=15,22 do Characters.portrait(i,80+(i-15)*150,575,80,'up')end
    g.pop();if tick==2 then g.captureScreenshot('organized-skins.png')end
   end
  elseif tick==5 then print('PASS '..checked..' relocated assets; Lua syntax; all biomes; sanctuary; editor thumbnails; all 22 skins; exact mirrored profiles');love.event.quit()end
 end
end
return T
