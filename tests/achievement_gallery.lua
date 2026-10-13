local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Graphics.showFPS=false
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false;Replay.ghost=false
 App.preview=false;App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;App.workshopMap=nil;Secret.duel=nil
 Profile.save=function()error('The achievement gallery must not write progress or equip rewards')end
 Bestiary.save=function()end
 local S=require('achievements_screen');local M=require('menu_trophies');local E=require('skin_effects');local g=love.graphics
 local json=require('json');local effects=Graphics.effects
 local function profile(kind)
  Profile.completed={};Profile.scores={};Profile.achievements={};Profile.skinGrants={};Profile.skinEffects={}
  Profile.storyTexts={};Profile.topRecords={};Profile.tearExtension=false;Profile.character=1;Characters.browsed=nil;Hardcore.completed={}
  if kind=='partial' then
   Profile.achievements={gillou=true,flawless1=true,bossflawless=true,top1_2=true}
   Profile.completed[1]=true;Profile.storyTexts[tostring(Worlds.order[1])]=true
  elseif kind=='full' then
   Profile.achievements={gillou=true,maxance=true,heartbreak=true,hardcore=true,top1=true,flawless_all=true,workshop_publish=true,workshop_test=true}
   for _,world in ipairs(Worlds.order)do Profile.completed[world]=true;Profile.storyTexts[tostring(world)]=true;Hardcore.completed[tostring(world)]=true end
  end
 end
 local function progress()
  return json.encode({completed=Profile.completed,scores=Profile.scores,achievements=Profile.achievements,
   grants=Profile.skinGrants,stories=Profile.storyTexts,records=Profile.topRecords,hardcore=Hardcore.completed})
 end
 profile('empty');S.index=1;S.open();UI.clock=4.2;Input.active=false
 assert(#Achievements.list==18,'The gallery has eighteen achievements, including undiscovered stories')
 local byId={};local group=0;local groups={0,0,0}
 for i,a in ipairs(Achievements.list)do
  byId[a.id]=i
  local nextGroup=a.rewardEffect and 1 or a.rewardSkin and 2 or 3
  assert(nextGroup>=group,'The gallery groups effects, skins, then trophies')
  group=nextGroup;groups[group]=groups[group]+1
 end
 assert(groups[1]==3 and groups[2]==13 and groups[3]==2,'The flawless skin appears once in the skin reward group')
 local earned,total=S.count();assert(earned==0 and total==18)
 local selected=Characters.selected();local equipped=json.encode(E.snapshot());local before=progress()
 local fonts={};local rawText=UI.rawText;local background=UI.background;local backgrounds=0
 UI.background=function(...) backgrounds=backgrounds+1;return background(...) end
 UI.rawText=function(text,x,y,font,...)
  assert(font~='tiny' and font~='small','Gallery text stays at body size or larger')
  fonts[font]=true;return rawText(text,x,y,font,...)
 end
 local function draw()
  UI.draw();assert(#UI.buttons==5,'Only the two arrows and three navigation buttons are shown')
  for _,b in ipairs(UI.buttons)do assert(b.w>=76 and b.h>=42,'Generous interactive targets')end
 end
 draw();assert(fonts.body and fonts.heading);assert(backgrounds==1,'Gallery uses the shared menu background')
 UI.rawText=rawText;UI.background=background
 assert(S.current()==Achievements.list[1]);love.keypressed('left');assert(S.index==18)
 love.keypressed('right');assert(S.index==1)
 love.keypressed('pagedown');assert(S.index==2);love.keypressed('pageup');assert(S.index==1)
 love.wheelmoved(0,-1);assert(S.index==2);love.wheelmoved(0,1);assert(S.index==1)
 local prev,next=UI.buttons[1],UI.buttons[2]
 assert(prev.achievementStep==-1 and next.achievementStep==1)
 UI.click(next.x+next.w/2,next.y+next.h/2);assert(S.index==2)
 UI.click(prev.x+prev.w/2,prev.y+prev.h/2);assert(S.index==1)
 local oldPad=Input.pad;local axis=0
 local pad={isGamepad=function()return true end,isConnected=function()return true end,
  getGamepadAxis=function(_,key)return key=='leftx' and axis or 0 end,isGamepadDown=function()return false end}
 Input.pad=pad;Input.state='achievements';Input.index=1;Input.repeatAt=0
 Input.press(pad,'rightshoulder');assert(S.index==2);Input.press(pad,'leftshoulder');assert(S.index==1)
 axis=1;Input.update(.01);assert(S.index==2);Input.update(.01);assert(S.index==2,'Held stick is repeat-limited')
 axis=0;Input.update(.01);axis=-1;Input.update(.01);assert(S.index==1)
 axis=0;Input.update(.01);Input.index=3;Input.navigate(1,0);assert(Input.index==4,'Footer remains accessible with gamepad')
 Input.pad=oldPad;Input.active=false;Input.index=1
 for i=1,#Achievements.list do
  S.index=i;S.open();draw()
  local a=S.current()
  if a.trophy then local art=assert(Art.images[S.trophy(a)]);assert(art.w>0 and art.h>0)end
 end
 assert(Characters.selected()==selected and json.encode(E.snapshot())==equipped and progress()==before,
  'Browsing cannot alter progress, the selected skin or equipped effects')

 -- The left number counts acquired achievements, never the selected page.
 profile('partial');before=progress();local counterCalls=0
 UI.rawText=function(text,x,y,font,...)
  if x==165 and y==329 then assert(text=='2/18','Left counter remains acquired / total');counterCalls=counterCalls+1 end
  return rawText(text,x,y,font,...)
 end
 for i=1,#Achievements.list do
  S.index=i;S.open();draw();earned,total=S.count();assert(earned==2 and total==18,'Legacy flags are not extra achievements')
 end
 UI.rawText=rawText;assert(counterCalls==18);assert(progress()==before)

 -- Effect achievements display the existing standalone logo, even with reduced effects.
 local portrait=Characters.portrait;local icon=E.icon;local iconCalls=0
 Characters.portrait=function()error('Effect rewards must never draw a skin portrait')end
 E.icon=function(kind,x,y,size,alpha,active)
  assert(kind=='heartbreak' or kind=='hardcore' or kind=='gold')
  assert(size==164 and alpha==1 and active==true,'Reward logos keep their recognizable filled shape')
  iconCalls=iconCalls+1;return icon(kind,x,y,size,alpha,active)
 end
 for _,reduced in ipairs({false,true})do
  Graphics.effects=not reduced
  for _,id in ipairs({'heartbreak','hardcore','top1'})do
   local a=Achievements.list[byId[id]];S.reward(a,true,600,350,328);S.reward(a,false,600,350,328)
  end
 end
 Characters.portrait=portrait;E.icon=icon;Graphics.effects=effects;assert(iconCalls==12)
 local coconCalls=0
 Characters.portrait=function(index,...)assert(index==23);coconCalls=coconCalls+1;return portrait(index,...)end
 S.reward(Achievements.list[byId.flawless_all],true,600,350,328)
 Characters.portrait=portrait;assert(coconCalls==1,'The flawless achievement displays its Cocon reward')

 -- Locked rewards are pure black, with a readable question mark at their center.
 local canvas=g.newCanvas(500,500,{dpiscale=1})
 for _,id in ipairs({'gillou','flawless_all','story_all','heartbreak'})do
  g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.clear(0,0,0,0)
  S.reward(Achievements.list[byId[id]],false,250,250,328);g.pop()
  local pixels=canvas:newImageData();local opaque,question=0,0
  for y=0,499,3 do for x=0,499,3 do
   local r,b,c,a=pixels:getPixel(x,y)
   if math.abs(x-250)<40 and math.abs(y-250)<55 then
    if a>.5 and math.min(r,b,c)>.5 then question=question+1 end
   elseif a>.99 then
     opaque=opaque+1
     assert(math.max(r,b,c)<.01,'Locked silhouettes are black without internal shading')
   end
  end end
  assert(opaque>20 and question>5,string.format('Locked reward %s: black=%d question=%d',id,opaque,question));pixels:release()
 end
 canvas:release()

 Graphics.effects=true;UI.clock=10;S.index=byId.worlds_all;S.open();local previous=S.current();S.step(1)
 assert(S.outgoing.achievement==previous and S.dropOffset()<0,'Changing selection starts a fall from above')
 local initial=S.dropOffset();UI.clock=10.2
 assert(S.dropOffset()>initial and S.dropOffset()<0,'Incoming reward falls toward its display position')
 UI.clock=10.7;assert(S.dropOffset()==0,'The fall settles at the central position')
 previous=S.current();S.step(-1)
 assert(S.outgoing.achievement==previous and S.dropOffset()>0,'Returning starts a rise from below')
 initial=S.dropOffset();UI.clock=10.9
 assert(S.dropOffset()<initial and S.dropOffset()>0,'Returning reward rises toward its display position')
 UI.clock=11.4;assert(S.dropOffset()==0,'The rise settles at the central position')
 S.step(1);S.open();assert(S.dropOffset()==0 and S.outgoing==nil,'Reopening clears all transition state')
 Graphics.effects=false;S.step(1);assert(S.dropOffset()==0,'Reduced effects show the next reward immediately')
 S.step(-1);assert(S.dropOffset()==0,'Reduced effects show the previous reward immediately')
 Graphics.effects=effects

 -- Trophy slots show both acquired art and locked silhouettes and open their achievement.
 local slots=M.slots();assert(#slots==3,'Only the three trophy achievements have display cases')
 local thumbnail=M.thumbnail
 for _,kind in ipairs({'empty','partial','full'})do
  profile(kind);local shown={};UI.buttons={};App.state='menu'
  M.thumbnail=function(a)
   assert(a.trophy,'Menu slots contain trophies only')
   shown[#shown+1]=a.id
   local result=thumbnail(a);local min,mag=result.image:getFilter()
   assert(min=='nearest' and mag=='nearest',
    'Menu trophies retain the same crisp pixel edges as the gallery')
   return result
  end
  M.draw();M.thumbnail=thumbnail
  assert(#shown==3,'Every trophy is shown, with a silhouette while locked')
  if kind=='full' then assert(Achievements.unlocked(Achievements.list[byId.worlds_all])) end
  assert(#UI.buttons==3)
  for i,b in ipairs(UI.buttons)do
   assert(b.trophyId==slots[i].achievement.id and b.y+b.h<496,'Trophy cases sit above Play')
  end
 end
 profile('partial');before=progress()
 for _,slot in ipairs(slots)do
  App.state='menu';UI.pressed=nil;UI.draw()
  local target;for _,b in ipairs(UI.buttons)do if b.trophyId==slot.achievement.id then target=b end end
  assert(target,'Every menu trophy has a click target')
  assert(UI.click(target.x+target.w/2,target.y+target.h/2));UI.updatePress(.12)
  assert(App.state=='achievements' and S.current().id==slot.achievement.id,'A trophy case opens its matching achievement')
 end
 assert(progress()==before and Characters.selected()==selected and json.encode(E.snapshot())==equipped,
  'Menu trophy navigation cannot write or equip progress')

 local shots={
  {id='heartbreak',name='locked',profile='empty'},
  {id='gillou',name='locked-skin',profile='empty'},
  {id='flawless_all',name='locked-cocon',profile='empty'},
  {id='story_all',name='locked-trophy',profile='empty'},
  {id='hardcore',name='locked-logo',profile='empty'},
  {id='worlds_all',name='partial-count',profile='partial'},
  {id='worlds_all',name='all-worlds'},
  {id='story_all',name='story-all'},
  {id='flawless_all',name='flawless'},
  {id='gillou',name='gillou'},
  {id='maxance',name='maxance'},
  {id='world1',name='biome-skin'},
  {id='hardcore',name='halo'},
  {id='top1',name='champion'},
  {id='top1',name='champion-reduced',reduced=true},
  {id='heartbreak',name='tears'},
  {id='worlds_all',name='fall-early',age=.14},
  {id='worlds_all',name='fall-late',age=.34},
  {id='story_all',name='rise-early',age=.14,direction=-1},
  {id='story_all',name='rise-late',age=.34,direction=-1},
  {name='menu-empty',menu=true,profile='empty'},
  {name='menu-partial',menu=true,profile='partial'},
  {name='menu-full',menu=true}
 }
 local tick=0;local realDraw=love.draw
 love.update=function()
  tick=tick+1;local shot=shots[tick];UI.clock=4.2
  if not shot then
   print('PASS achievement gallery: acquired counter, reward groups, flat locked silhouettes, effect logos, directional transitions, shared background, readable menu trophies, navigation and unchanged progress')
   love.event.quit();return
  end
  Graphics.effects=effects
  if shot.reduced then Graphics.effects=false elseif shot.age then Graphics.effects=true end
  profile(shot.profile or 'full');earned,total=S.count()
  assert(earned==({empty=0,partial=2,full=18})[shot.profile or 'full'] and total==18)
  if shot.menu then App.state='menu';UI.pressed=nil;UI.menuArrival=0
  else
   S.index=assert(byId[shot.id]);S.open()
   if shot.age then S.step(shot.direction or 1);UI.clock=UI.clock+shot.age end
  end
 end
 love.draw=function()
  realDraw();local shot=shots[tick]
  if shot then g.captureScreenshot(function(data)
   if shot.name=='locked-trophy' then
    -- Returning from the silhouette canvas must keep the window clip right-way up.
    local w,h=data:getDimensions();local scale=math.min(w/1200,h/750)
    local opaque=0
    for yy=160,330,3 do for xx=480,720,3 do
     local x=math.floor((w-1200*scale)/2+xx*scale)
     local y=math.floor((h-750*scale)/2+yy*scale)
     local r,green,b=data:getPixel(x,y)
     if math.max(r,green,b)<.01 then opaque=opaque+1 end
    end end
    assert(opaque>20,'The upper half of a locked trophy remains visible inside the window clip')
   end
   local path='/tmp/silken-achievement-gallery-'..shot.name..'.png'
   local f=assert(io.open(path,'wb'));f:write(data:encode('png'):getString());f:close()
  end)end
 end
end
return T
