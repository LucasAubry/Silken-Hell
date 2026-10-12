local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 Profile.character=7;Profile.skinGrants={};Profile.skinEffects={};Profile.completed={};Profile.achievements={}
 for id=1,#Characters.keys do Profile.skinGrants[tostring(id)]=true end
 require('achievement_notice').init();require('skin_unlock').init()
 Graphics.quality=2;Graphics.effects=true;Graphics.showFPS=false;Graphics.vsync=0;Graphics.limit=0
 local g=love.graphics;local bolts=require('sky_lightning');bolts.load()
 local canvas=g.newCanvas(400,300,{dpiscale=1})
 local function ground(age)
  g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.setShader();g.clear()
  bolts.draw(200,150,age,.55,4);g.pop()
  local data=canvas:newImageData();local count,radius=0,0
  for y=0,299 do for x=0,399 do
   local r,green,b,a=data:getPixel(x,y)
   if math.max(r,green,b)>.12 then count=count+1;radius=math.max(radius,(x-200)^2+(y-150)^2) end
  end end
  data:release();return count,radius
 end
 local rng=love.math.getRandomState()
 assert(ground(-.01)==0 and ground(.55)==0,'No veins before impact or after fading')
 local early,near=ground(.04);local late,far=ground(.27)
 assert(early>0 and late>early*2 and far>near*3,string.format('The light must spread outward: pixels %d -> %d, radius squared %.0f -> %.0f',early,late,near,far))
 assert(love.math.getRandomState()==rng,'Decorative branching cannot consume gameplay randomness')
 local shader,image,newCanvas=g.newShader,g.newImage,g.newCanvas
 g.newShader=function()error('Discharge compiled a shader')end
 g.newImage=function()error('Discharge uploaded an image')end
 g.newCanvas=function()error('Discharge allocated a surface')end
 ground(.16)
 g.newShader,g.newImage,g.newCanvas=shader,image,newCanvas
 canvas:release()

 -- Real impacts leave one hole, it shrinks and disappears, and resets clear light.
 App.singleLevel=true;App.practice=10;App.start(6);App.practice=nil;player.reset=false
 local rain=require('sky_rain');local drops={{x=180,y=240,age=.84}}
 local state=love.math.getRandomState()
 rain.update(drops,.02)
 assert(#Realms.holes==1 and #bolts.events==1,'A sky impact creates a hole and persistent light')
 assert(Realms.fallAt(180,240),'The impact hole must be dangerous')
 rain.update(drops,.02)
 assert(#Realms.holes==1,'An impact must not add a hole each frame')
 local radius=Realms.holes[1].rx
 Realms.updateSkyImpacts(2)
 assert(Realms.holes[1].rx<radius and #bolts.events==1,'The hole shrinks while light propagates')
 Realms.updateSkyImpacts(.5)
 assert(#bolts.events==0 and #Realms.holes==1,'Veins fade before the hole closes')
 Realms.updateSkyImpacts(4.1)
 assert(#Realms.holes==0 and not Realms.fallAt(180,240),'The closed hole no longer collides')
 Realms.lightningImpact(180,240,7);Aftermath.cleared=true;Realms.updateSkyImpacts(.01)
 assert(#Realms.holes==0 and #bolts.events==0,'Victory clears temporary sky hazards')
 Aftermath.cleared=false
 assert(love.math.getRandomState()==state,'Impact decoration must not consume gameplay RNG')
 for i=1,10 do bolts.trigger(100+i*20,300,i) end
 assert(#bolts.events==4,'Concurrent lighting stays bounded')
 Realms.reset(1,1);assert(#bolts.events==0,'Changing worlds clears old light')

 -- Every source silhouette, including custom glasses and silk, remains intact.
 local sample=g.newCanvas(200,200,{dpiscale=1})
 for _,id in ipairs(Characters.baseIndices) do
  for _,dir in ipairs({'down','up','left','right'}) do
   local function pixels(styled)
    g.push('all');g.setCanvas(sample);g.origin();g.setScissor();g.setShader();g.clear();g.setColor(1,1,1)
    if styled then Characters.portrait(id,100,100,160,dir,false)
    else
     local a=Art.images[Characters.model(dir,id)];local scale=160/math.max(a.w,a.h)
     if dir=='right' then g.translate(200,0);g.scale(-1,1) end
     g.draw(a.image,a.quad,100,100,0,scale,scale,a.w/2,a.h/2)
    end
    g.pop();return sample:newImageData()
   end
   local original,styled=pixels(false),pixels(true)
   for y=0,199 do for x=0,199 do
    local _,_,_,a=original:getPixel(x,y);local _,_,_,b=styled:getPixel(x,y)
    assert(a==b,'Material must keep source silhouette: '..id..' '..dir)
   end end
   original:release();styled:release()
  end
 end
 sample:release()
 -- Existing reward requirements are independent of the new render palettes.
 Profile.skinGrants={};assert(not Characters.unlocked(7) and not Characters.unlocked(23))
 for id=1,#Characters.keys do Profile.skinGrants[tostring(id)]=true end

 local tasks={}
 for level=1,10 do tasks[#tasks+1]={level=level,name=level==9 and 'world2' or level==10 and 'world2-boss' or nil} end
 for i,age in ipairs({.83,.92,1.07,1.34}) do tasks[#tasks+1]={level=10,age=age,name='lightning-'..i} end
 tasks[#tasks+1]={sheet=1,name='skins-1'};tasks[#tasks+1]={sheet=2,name='skins-2'}
 tasks[#tasks+1]={menu=true,name='menu'}
 love.filesystem.createDirectory('sky-style')
 local draw=love.draw;local index,frames,pending=0,0,0;local task
 local function capture(name)
  pending=pending+1
  g.captureScreenshot(function(data)
   local path='sky-style/'..name..'.png';local encoded=data:encode('png',path)
   encoded:release();data:release();pending=pending-1
   print('CAPTURE '..love.filesystem.getSaveDirectory()..'/'..path)
  end)
 end
 love.update=function()
  if task and frames<3 then return end
  if index==#tasks then
   if pending>0 then return end
   print('PASS Sky style: 10 levels and boss, branching map-wide cloud light, no GPU allocations for discharge, no gameplay RNG changes, all 18 skins in four poses with exact source alpha and stable unlocks')
   love.event.quit();return
  end
  index=index+1;task=tasks[index];frames=0;UI.clock=5.15
  if task.sheet then App.state='skins';return end
  if task.menu then App.state='menu';Profile.character=24;Characters.browsed=nil;UI.menuArrival=0;return end
  App.singleLevel=true;App.practice=task.level;App.hardcore=false
  App.start(6);App.practice=nil;player.reset=false;timer=12.48
  Realms.clock=5.15
  if task.level==9 then
   Realms.lightningImpact(Arena.width*.45,310,3);bolts.update(.6)
   Realms.lightning={}
  end
  if task.age then
   Storm.rain={{x=Arena.width*.45,y=310,age=task.age}}
   if task.age>=.85 then Realms.lightningImpact(Arena.width*.45,310,3);bolts.update(task.age-.85) end
   Storm.strikes={};Storm.projectiles={};Storm.holes={}
  end
 end
 love.draw=function()
  if not task then return end
  local state=love.math.getRandomState()
  if task.sheet then
   g.clear(.025,.075,.08)
   local w,h=g.getDimensions();local scale=math.min(w/1200,h/750)
   g.push('all');g.translate((w-1200*scale)/2,(h-750*scale)/2);g.scale(scale)
   for slot=1,9 do
    local id=Characters.baseIndices[(task.sheet-1)*9+slot]
    if id then
     local x=((slot-1)%3)*400;local y=math.floor((slot-1)/3)*250
     UI.text(Characters.names[id],x+12,y+12,'body',{1,.93,.78},376,'center')
     g.setColor(1,1,1);Characters.portrait(id,x+130,y+142,137,'down')
     g.setColor(1,1,1);Characters.portrait(id,x+286,y+142,116,'left')
    end
   end
   g.pop()
  else draw() end
  assert(love.math.getRandomState()==state,'Rendering cannot alter gameplay RNG')
  frames=frames+1;if frames==2 and task.name then capture(task.name) end
 end
end
return T
