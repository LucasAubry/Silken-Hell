local T={}
function T.run()
 local g=love.graphics
 local profile={};for key,value in pairs(Profile) do profile[key]=value end
 local browsed,state=Characters.browsed,App.state
 local biome=Campaign.biome
 local playing,ghost,data=Replay.playing,Replay.ghost,Replay.data
 local originalImage,originalShader,originalCanvas=g.newImage,g.newShader,g.newCanvas
 g.push('all')
 local canvas=g.newCanvas(224,224,{dpiscale=1})
 local dirs={'down','up','left','right','down','left'}
 local walks={[5]={walkMoving=true,walkPhase=.7},[6]={walkMoving=true,walkPhase=2.8}}
 local function pixels(index,pose)
  g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.setShader();g.clear(0,0,0,0)
  g.setColor(1,1,1);Characters.portrait(index,112,112,176,dirs[pose],false,walks[pose]);g.pop()
  return canvas:newImageData()
 end
 local ok,err=xpcall(function()
  Profile.save=function()end;Profile.achievements={};Profile.completed={};Profile.skinGrants={}
  Profile.skinEffects={};Profile.tearExtension=false;Replay.playing=false;Replay.ghost=false
  App.state='menu';Campaign.biome=1
  assert(#Characters.keys==26 and Characters.baseCount==18)
  assert(Characters.names[23]=='Cocon' and not Characters.unlocked(23),'Existing achievement skin is still locked')
  local samples={}
  -- Every biome and menu retains the approved four-pair anatomy.
  for _,index in ipairs({1,2,3,5,14,23,24,25,26}) do
   local before=pixels(index,1)
   for _,world in ipairs({1,2}) do
    App.state='playing';Campaign.biome=world
    local after=pixels(index,1)
    assert(before:getString()==after:getString(),'Changing worlds cannot replace the approved eight-legged spiders')
    after:release()
   end
   before:release();App.state='menu';Campaign.biome=1
  end
  for index=24,26 do
   assert(Characters.unlocked(index) and Characters.select(index) and Characters.selected()==index,'New skins are immediately selectable')
   assert(Characters.effectColor(index)==Characters.materials[index].effect,'Effect palette is reused without per-frame allocations')
   assert(require('prism_palette').player(index)[1]==Characters.effectColor(index),'Trails use the equipped material')
   for pose=1,#dirs do
    assert(Characters.model(dirs[pose],index)==Characters.model(dirs[pose],2),'The authored eight-legged spider silhouette and rig remain identical')
    local before,after=pixels(2,pose),pixels(index,pose)
    local different=0
    for y=0,223 do for x=0,223 do
     local r,g0,b,a=before:getPixel(x,y);local nr,ng,nb,na=after:getPixel(x,y)
     assert(a==na,'Material changes cannot alter the silhouette or walking animation')
     if a>.9 and math.abs(r-nr)+math.abs(g0-ng)+math.abs(b-nb)>.08 then different=different+1 end
    end end
    assert(different>700,'Every pose visibly adopts the new material')
    before:release();after:release()
   end
   g.setColor(1,1,1);Characters.portrait(index,112,112,26,'down')
   samples[index]=Characters.smallPortraits[index..':down:nil']
   assert(samples[index],'Leaderboard miniature is cached')
   Replay.playing=true;Replay.data={skin=index}
   assert(Characters.selected()==index,'Replay retains the recorded appearance');Replay.playing=false
  end
  assert(samples[24]~=samples[25] and samples[25]~=samples[26],'Each skin owns its miniature')
  g.newImage=function()error('Warm skin render uploads an image')end
  g.newShader=function()error('Warm skin render compiles a shader')end
  g.newCanvas=function()error('Warm skin render allocates a canvas')end
  for index=24,26 do for pose=1,#dirs do
   Characters.portrait(index,112,112,59,dirs[pose],false,walks[pose])
  end;Characters.portrait(index,112,112,26,'down')end
  g.newImage,g.newShader,g.newCanvas=originalImage,originalShader,originalCanvas

  App.state='skins';UI.draw();assert(#UI.buttons==19,'18 skins fit the existing catalogue with Return')
  for position=16,18 do
   App.state='skins';UI.buttons[position].run()
   assert(Profile.character==position+8 and App.state=='menu','Catalogue equips the matching palette')
  end
  local sheet=g.newCanvas(1200,750,{dpiscale=1})
  g.push('all');g.setCanvas(sheet);g.origin();g.setScissor();g.setShader();g.clear(.055,.11,.12,1)
  local labels={'Face','Dos','Gauche','Droite','Marche','Marche'}
  for row,index in ipairs({24,25,26}) do
   local top=(row-1)*250
   UI.text(Characters.names[index],36,top+15,'heading',{1,.91,.72},1128,'left')
   g.setColor(1,1,1);Characters.portrait(index,1160,top+39,26,'down')
   for col=1,#dirs do
    local x=100+(col-1)*200
    g.setColor(1,1,1);Characters.portrait(index,x,top+143,150,dirs[col],false,walks[col])
    UI.text(labels[col],x-90,top+218,'body',{.94,.89,.78},180,'center')
   end
  end
  g.pop()
  local image=sheet:newImageData();local bytes=image:encode('png')
  local file=assert(io.open('/tmp/silken-champagne-skins.png','wb'));file:write(bytes:getString());file:close()
  bytes:release();image:release();sheet:release()
 end,debug.traceback)
 g.newImage,g.newShader,g.newCanvas=originalImage,originalShader,originalCanvas
 for key in pairs(Profile) do Profile[key]=nil end;for key,value in pairs(profile) do Profile[key]=value end
 Characters.browsed=browsed;App.state=state;Campaign.biome=biome;Replay.playing=playing;Replay.ghost=ghost;Replay.data=data
 g.pop();canvas:release();assert(ok,err)
 print('PASS Champagne/Sauge/Pétrole: immediate selection, 18 catalogue cards, exact eight-legged silhouettes in four directions and walking poses, unchanged artwork across worlds/menus, replay IDs, effect palettes, cached miniatures and zero warm GPU allocations')
end
return T
