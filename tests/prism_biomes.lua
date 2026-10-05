local T={}
local Material=require 'prism_material'
local Palette=require 'prism_palette'
local FX=require 'psychedelic_fx'
local function setup()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Profile.character=1;Profile.unlocked=7;Profile.language='fr';Profile.name='Essai prismatique'
 Graphics.psychedelic=2;Graphics.showFPS=false;App.hardcore=false;App.singleLevel=true
 App.practice=7;App.start(1)
end
function T.demo()
 setup();local key=love.keypressed;local index=1
 love.keypressed=function(k,...)
  if k=='f4' then Profile.character=(Profile.character or 1)%22+1;Characters.unlocked=function()return true end;return
  elseif k=='f5' then
   index=index%#Worlds.order+1;local world=Worlds.order[index]
   App.practice=world==3 and 1 or 7;App.start(world);return
  elseif k=='f6' then Material.enabled=not Material.enabled;return
  elseif k=='f7' and App.state=='playing' then Hazards.kill();App.resolveDeath();return
  elseif k=='f8' and App.state=='playing' then FX.collect(player.x+15,player.y+12);return end
  key(k,...)
 end
 love.window.setTitle('Silken Hell · Couleurs originales et reflets · F4 skin · F5 biome · F6 comparer · F7 mort · F8 larme')
 print('Essai ouvert : couleurs originales conservées. F5 biome, F6 reflets, F7 mort, F8 larme.')
end
function T.bench()
 local target;local begin=Material.beginScene
 Material.beginScene=function(canvas) target=canvas;begin(canvas) end
 for _,world in ipairs({1,4,6,7}) do
  App.practice=10;App.start(world);FX.reset();love.draw()
  local times={}
  for _,enabled in ipairs({false,true}) do
   Material.enabled=enabled;love.draw();target:newImageData():release()
   local started=love.timer.getTime()
   for _=1,12 do love.draw();target:newImageData():release() end
   times[#times+1]=(love.timer.getTime()-started)*1000/12
  end
  print(string.format('PRISM render biome %d: original %.2f ms, material %.2f ms (GPU readback included)',world,times[1],times[2]))
 end
 Material.beginScene=begin;Material.enabled=true
end
function T.run()
 setup();require('tests.skin_fx').run();local g=love.graphics;local ink=require 'paradise_ink'
 local function sample(enabled,scope,shader)
  Material.enabled=enabled
  local c=g.newCanvas(160,160);g.push('all');g.setCanvas(c);g.origin();g.clear(0,0,0,0);g.setColor(1,1,1,.5)
  if scope then Material.beginScene(c) end
  if shader then g.setShader(shader) end
  ink.draw('original_down',80,80,120)
  if shader then assert(g.getShader()==shader,'Status shader must survive') end
  Material.endScene();g.pop();local data=c:newImageData();c:release();return data
 end
 local plain,prism=sample(false,true),sample(true,true)
 Campaign.select(7);local otherBiome=sample(true,true);Campaign.select(1)
 local outside=sample(true,false);local changes=0
 for y=0,159 do for x=0,159 do
  local r,green,b,a=plain:getPixel(x,y);local nr,ng,nb,na=prism:getPixel(x,y)
  local ur,ug,ub,ua=outside:getPixel(x,y)
  assert(math.abs(na-a)<.005,'Material must preserve silhouettes and opacity')
  local br,bg,bb,ba=otherBiome:getPixel(x,y)
  assert(math.abs(nr-br)+math.abs(ng-bg)+math.abs(nb-bb)+math.abs(na-ba)<.005,'Biome palettes must not recolor textures')
  local total=r+green+b;local newTotal=nr+ng+nb
  if a>.2 and total>.15 then
   local gain=newTotal/total
   -- Two quantization steps cover 8-bit output rounding and the unchanged contact shadow.
   assert(math.abs(r*gain-nr)<2/255 and math.abs(green*gain-ng)<2/255 and math.abs(b*gain-nb)<2/255,'Sheen must preserve original RGB proportions')
  end
  assert(math.abs(ur-r)+math.abs(ug-green)+math.abs(ub-b)+math.abs(ua-a)<.005,'UI rendering must remain unchanged')
  if math.abs(r-nr)+math.abs(green-ng)+math.abs(b-nb)>.015 then changes=changes+1 end
 end end
 assert(changes>200,'Neutral highlights must remain visible');plain:release();prism:release();outside:release();otherBiome:release()
 local status=g.newShader('assets/shaders/polish.glsl');status:send('strength',.4)
 local data=sample(true,true,status);data:release();status:release()
 for id,biome in pairs(Worlds.secretBiomes) do Campaign.select(id);assert(Palette.current()==biome) end
 Campaign.select(7);local palette=Palette.player();FX.death(300,300);FX.collect(400,300);Campaign.select(2)
 assert(FX.deathPulse.palette==palette and FX.pickupPulse.palette==Palette.get(7),'Pickup must retain the source biome through transitions')
 local dir=os.getenv('SILKEN_STYLE_CAPTURE_DIR')
 local draw=love.draw;local index,drawn=0,true
 local tasks={}
 for _,w in ipairs(Worlds.order) do
  tasks[#tasks+1]={world=w,level=w==3 and 1 or 7}
  tasks[#tasks+1]={world=w,level=Worlds.levelCount(w)}
 end
 local image,shader=g.newImage,g.newShader;local uploads=0
 g.newImage=function(...) uploads=uploads+1;return image(...) end
 love.update=function()
  if not drawn then return end;drawn=false;index=index+1
  local task=tasks[index]
  if task then
   App.practice=task.level;App.start(task.world);UI.clock=3;player.walkMoving=true;player.walkPhase=1
   for _,m in ipairs(mobs) do if m.imgs then m.dir='down';m.img=m.imgs.down or m.imgs.up end end
   FX.collect(player.x+15,player.y+12);FX.update(.12)
  elseif index==#tasks+1 then
   Secret.open(false);UI.clock=3
  else
   g.newImage=image
   assert(uploads==0,'Biome changes must reuse textures: '..uploads)
   if os.getenv('SILKEN_PRISM_BENCH')=='1' then love.draw=draw;T.bench() end
   print('PASS neutral sheen: original RGB proportions and alpha preserved, no biome recoloring; unchanged UI/status shaders; seven biomes/bosses; pickup effects retain biome palettes; no runtime texture uploads')
   love.event.quit()
  end
 end
 love.draw=function()
  local before=love.math.getRandomState();local walls=require('json').encode(Arena.walls)
  draw()
  assert(love.math.getRandomState()==before and walls==require('json').encode(Arena.walls),'Rendering cannot change RNG or collisions')
  if dir and index>0 then
   local task=tasks[index];local name=task and ('biome-'..task.world..'-niveau-'..task.level) or 'sanctuaire'
   g.captureScreenshot(function(pixels)
    local bytes=pixels:encode('png');local file=assert(io.open(dir..'/'..name..'.png','wb'))
    file:write(bytes:getString());file:close();bytes:release();pixels:release()
   end)
  end
  drawn=true
 end
end
return T
