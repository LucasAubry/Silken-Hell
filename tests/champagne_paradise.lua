-- Exercise the complete Paradise rendering path with frozen gameplay snapshots.
-- Run through tools/test_background.py so screenshots never interrupt the user.
local T={}
local json=require('json')

local function body(m)
 return {type=m.type,x=m.x,y=m.y,size=m.size,speed=m.speed,dir=m.dir,
  rotation=m.rotation,tipX=m.tipX,tipY=m.tipY,active=m.active,
  width=m.hitBox_width,height=m.hitBox_height,
  offsetX=m.hitBox_offset_x,offsetY=m.hitBox_offset_y,
  frozen=m.is_frozen,hasTear=m.has_larme,kind=m.kind,phase=m.phase,
  vx=m.vx,vy=m.vy,life=m.life,slot=m.slot}
end

local function physicalState()
 local state={world=Campaign.world,biome=Campaign.biome,level=player.level,
  timer=timer,player=body(player),deaths=player.death,reset=player.reset,
  walls=Arena.walls,interior=Arena.interior,navigation=Arena.navigationVersion,mobs={},
  tear={x=objet.larme.x,y=objet.larme.y,taken=objet.larme.taken,
   dropped=objet.larme_dropped,width=objet.larme.hitBox_width,height=objet.larme.hitBox_height},
  raven={active=Raven.active,x=Raven.x,y=Raven.y,hp=Raven.hp,broken=Raven.broken,
   defeated=Raven.defeated,nests=Raven.nests,chicks={},projectiles={}}}
 for i,m in ipairs(mobs) do state.mobs[i]=body(m) end
 for i,m in ipairs(Raven.chicks) do state.raven.chicks[i]=body(m) end
 for i,p in ipairs(Raven.projectiles) do state.raven.projectiles[i]=body(p) end
 return json.encode(state)
end

local function materialChecks()
 local g=love.graphics
 local style=require('paradise_style');local atlas=require('paradise_ink')
 local previousEnabled,previousBiome=style.enabled,Campaign.biome
 local canvas=g.newCanvas(160,160,{dpiscale=1})
 local custom=g.newShader('vec4 effect(vec4 c,Image t,vec2 uv,vec2 px){vec4 p=Texel(t,uv);return vec4(p.rgb*vec3(.7,.9,1.),p.a)*c;}')
 local frames={}
 for _,name in ipairs({'ange','snake','merle'}) do
  for _,dir in ipairs({'down','up','left','right'}) do
   frames[#frames+1]={key=name..'_'..dir,kind=name=='merle' and 'bird' or nil}
  end
 end
 for _,key in ipairs({'border','nest','egg','wheel','tear','trap_open','trap_closed'}) do
  frames[#frames+1]={key=key,kind=key}
 end
 frames[#frames+1]={key='black_feather',kind='bird',art=true}
 local function sample(frame,kind,enabled,biome,caller)
  style.enabled=enabled;Campaign.biome=biome
  g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.setShader(caller)
  g.setBlendMode('alpha');g.clear(0,0,0,0);g.setColor(1,1,1,.73)
  local previous=style.bind(frame,kind)
  local scale=144/math.max(frame.w,frame.h)
  g.draw(frame.image,frame.quad,80,80,0,scale,scale,frame.w/2,frame.h/2)
  g.setShader(previous)
  assert(g.getShader()==caller,'Paradise material must restore its caller shader')
  g.pop()
  return canvas:newImageData()
 end
 for _,item in ipairs(frames) do
  local frame=item.art and assert(Art.images[item.key]) or atlas.frame(item.key)
  local original=sample(frame,item.kind,false,1)
  local styled=sample(frame,item.kind,true,1)
  local other=sample(frame,item.kind,true,2)
  assert(other:getString()==original:getString(),'Other biomes retain their exact colors: '..item.key)
  local differences=0
  for y=0,159 do for x=0,159 do
   local r,green,b,a=original:getPixel(x,y)
   local sr,sg,sb,sa=styled:getPixel(x,y)
   assert(a==sa,'Paradise palette must preserve exact source alpha: '..item.key)
   if a>.25 and math.abs(r-sr)+math.abs(green-sg)+math.abs(b-sb)>.025 then differences=differences+1 end
  end end
  assert(differences>30,'Paradise material must visibly adapt '..item.key)
  original:release();styled:release();other:release()
 end
 local frame=atlas.frame('merle_down')
 local before=sample(frame,'bird',false,1,custom)
 local after=sample(frame,'bird',true,1,custom)
 assert(before:getString()==after:getString(),'Attack flashes and boss-specific materials stay intact')
 before:release();after:release();canvas:release();custom:release()
 style.enabled=previousEnabled;Campaign.biome=previousBiome
 print('PASS Paradise material: exact alpha in 20 original frames, visible color treatment, exact other-biome pixels, preserved caller materials')
end

function T.run()
 io.stdout:setvbuf('no')
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 love.focus=function()end
 Input.move=function()return 0,0 end;Input.slow=function()return true end
 Profile.character=24;Profile.unlocked=7;Profile.language='fr'
 Profile.achievements={};Profile.completed={};Profile.scores={};Profile.skinGrants={}
 Profile.skinEffects={};Profile.tearExtension=false;Profile.topRecords={};Profile.storyTexts={}
 Hardcore.completed={}
 require('achievement_notice').init();require('skin_unlock').init()
 Graphics.quality=2;Graphics.effects=true;Graphics.psychedelic=2
 Graphics.showFPS=false;Graphics.vsync=0;Graphics.limit=0
 Characters.browsed=nil
 require('tests.champagne_skins').run()
 materialChecks()

 local g=love.graphics
 local material=require('prism_material');material.enabled=true
 local paradise=require('paradise_ink')
 local draw=love.draw
 local originalImage,originalShader=g.newImage,g.newShader
 local uploads,compiles,measured=0,0,false
 g.newImage=function(...)
  if measured then uploads=uploads+1 end
  return originalImage(...)
 end
 g.newShader=function(...)
  if measured then compiles=compiles+1 end
  return originalShader(...)
 end
 local realTime=love.timer.getTime
 local function frozenTime()return UI.clock end
 local tasks={}
 for level=1,10 do tasks[#tasks+1]={world=1,level=level,
  capture=level>=9 and 'world1-level'..level or nil} end
 tasks[#tasks+1]={world=1,level=9,skin=1,capture='world1-level9-soie'}
 tasks[#tasks+1]={world=1,level=9,dropped=true,capture='world1-tear-traps'}
 tasks[#tasks+1]={world=1,level=1,custom=true,capture='world1-custom'}
 -- Return to normal rendering in every other biome to catch leaked state.
 for _,world in ipairs({2,6,5,4,7,3}) do
  tasks[#tasks+1]={world=world,level=world==3 and 1 or 7}
 end
 tasks[#tasks+1]={menu=true,capture='menu'}
 tasks[#tasks+1]={catalogue=true,capture='skins-catalogue'}
 local directories={'champagne-paradise'}
 for _,path in ipairs(directories) do assert(love.filesystem.createDirectory(path)) end
 local index,frame,pending,finished=0,0,0,false
 local task
 local dirs={'down','left','up','right'}
 local function setup(nextTask)
  task=nextTask;frame=0;UI.clock=5;direction='down'
  if task.menu or task.catalogue then
   App.state=task.menu and 'menu' or 'skins';App.selectedWorld=1
   Profile.character=24;Characters.browsed=nil
   return
  end
  love.math.setRandomSeed(84841+task.world*100+task.level)
  App.hardcore=false;App.singleLevel=true;App.practice=task.level
  Profile.character=task.skin or 24;App.start(task.world);player.reset=false
  -- Captures show the regular campaign HUD; the non-captured level 8 also
  -- exercises the readable practice-status panel.
  if task.level~=8 then App.practice=nil end
  timer=12.48
  assert(paradise.active()==(task.world==1),'Paradise style must remain scoped to its biome')
  player.walkMoving=true;player.walkPhase=.7
  if task.custom then
   local width=Arena.width
   task.layout={world=1,biome=1,level=1,width=width,height=600,entities={
    {kind='spawn',x=width*.48,y=305},
    {kind='tear',x=width*.84,y=95},
    {kind='tear',x=width*.14,y=480},
    {kind='mob',type='ange',x=width*.20,y=135,speed=2},
    {kind='mob',type='snake',x=width*.81,y=460,speed=2},
    {kind='mob',type='scie',x=width*.68,y=165,speed=2,rota=1},
    {kind='mob',type='piege',x=width*.27,y=405},
    {kind='wall',x=width*.31,y=240,w=180,h=28,rotation=0},
    {kind='wall',x=width*.63,y=395,w=160,h=30,rotation=45},
   }}
   local valid,why=LayoutSchema.validate(task.layout);assert(valid,why)
   task.layoutJSON=json.encode(task.layout)
   assert(LevelLayouts.apply(task.layout),'The custom layout must use the normal game importer')
   assert(json.encode(task.layout)==task.layoutJSON,'Import must preserve authored layout data')
   assert(#Arena.interior==2 and #Arena.walls==6,'Custom walls retain both collision rectangles')
   for i,entity in ipairs({task.layout.entities[8],task.layout.entities[9]}) do
    local wall=Arena.interior[i]
    assert(wall.w==entity.w and wall.h==entity.h and wall.rotation==entity.rotation,
     'Wall dimensions and rotation must match the authored layout')
    assert(wall.x==entity.x-entity.w/2 and wall.y==entity.y-entity.h/2,
     'Wall collision origin must match the authored center')
   end
   assert(Arena.interior[1].rotation==0 and Arena.interior[2].rotation==45)
  end
  if task.world==1 and task.level==10 then
   Raven.hp=6;Raven.hatch();Raven.elapsed=2
   Raven.projectiles={
    {x=Arena.width*.38,y=220,vx=120,vy=75,life=3},
    {x=Arena.width*.64,y=320,vx=-120,vy=35,life=3}}
   -- This is the existing harmless fallen-bird state, without adding blood.
   Raven.corpses={{x=Arena.width*.32,y=420,dir='left',fall=.6,side=1}}
  end
  if task.dropped then
   objet.larme_dropped=true;objet.larme.taken=false
   objet.larme.x=Arena.width*.62;objet.larme.y=300
   local closed=false
   for _,m in ipairs(mobs) do
    if m.type=='piege' and not closed then m.active=true;closed=true end
   end
   assert(closed,'The trap capture must show a closed trap beside open traps')
  end
  -- Reconciliation can move a rotor's pivot during level setup. Resolve the
  -- tip exactly as the first gameplay update does before freezing the scene.
  for _,m in ipairs(mobs) do
   if m.type=='scie' then MobBehaviors.scie.update(m,0,true) end
  end
 end
 local function capture(name)
  pending=pending+1
  g.captureScreenshot(function(data)
   local path='champagne-paradise/'..name..'.png'
   local encoded=data:encode('png',path);encoded:release();data:release()
   print('CAPTURE '..love.filesystem.getSaveDirectory()..'/'..path)
   pending=pending-1
  end)
 end
 love.update=function()
  if finished then return end
  if task and frame<12 then return end
  index=index+1
  if not tasks[index] then
   if pending>0 then index=index-1;return end
   measured=false;g.newImage=originalImage;g.newShader=originalShader
   love.timer.getTime=realTime
   assert(uploads==0,'Steady rendering must not upload images: '..uploads)
   assert(compiles==0,'Steady rendering must not compile shaders: '..compiles)
   print('PASS Champagne Paradise: 10 levels, 4 facings, open/closed traps, dropped tear, cracked boss egg, nests, chicks and feathers; custom horizontal/45-degree walls and untouched layout data; 6 other biomes; menu and skin catalogue; unchanged collisions and gameplay RNG; zero warm image uploads or shader compilations')
   finished=true;love.event.quit();return
  end
  setup(tasks[index])
 end
 love.draw=function()
  if not task or finished then return end
  frame=frame+1
  local dir=dirs[(frame-1)%#dirs+1]
  direction=dir
  for _,m in ipairs(mobs) do
   if m.imgs then m.dir=dir;m.img=m.imgs[dir] or m.img end
  end
  for _,m in ipairs(Raven.chicks) do m.dir=dir end
  UI.clock=5+frame/60
  local physics=physicalState();local rng=love.math.getRandomState()
  -- Warm all four directions once before tracking allocations and compilation.
  measured=frame>4
  love.timer.getTime=frozenTime
  draw()
  love.timer.getTime=realTime;measured=false
  assert(love.math.getRandomState()==rng,'Rendering must preserve gameplay RNG')
  assert(physicalState()==physics,'Rendering must preserve collision geometry and actor state')
  if task.custom then assert(json.encode(task.layout)==task.layoutJSON,'Drawing must not rewrite the custom layout') end
  if frame==9 and task.capture then capture(task.capture) end
 end
end

return T
