local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;LevelLayouts.disabled=true
 local H=require('history');local C=require('run_start');local P=require('prologue')
 App.state='menu';App.selectedWorld=5;App.hardcore=true;App.preview=false;App.singleLevel=false;App.practice=nil;App.sessionLayout=nil
 Replay.playing=false;Replay.recording=false;Secret.duel=nil
 local function snapshot(value)
  if type(value)~='table' then return type(value)..':'..tostring(value) end
  local out={};for key,item in pairs(value) do out[#out+1]=snapshot(key)..'='..snapshot(item) end;table.sort(out);return '{'..table.concat(out,';')..'}'
 end
 local profile=snapshot({stats=Profile.stats,biomes=Profile.biomeStats,achievements=Profile.achievements,completed=Profile.completed,seen=Profile.prologueSeen,name=Profile.name})
 local bestiary=snapshot({Bestiary.seen,Bestiary.unread});local replay=Replay.last;local rng=love.math.getRandomState()
 local record,online,begin=Profile.record,Online.start,Replay.begin
 Profile.record=function()error('Preview must not record attempts')end
 Online.start=function()error('Preview must not start an online run')end
 Replay.begin=function()error('Preview must not record a replay')end
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  g.push('all');setCanvas(c);g.setCanvas=function(target,...)if target==nil then return setCanvas(c) end;return setCanvas(target,...)end
  love.draw();g.setCanvas=setCanvas;setCanvas();g.pop();c:newImageData():encode('png','history-'..name..'.png');c:release()
 end
 H.open();capture('menu');assert(#UI.buttons==6 and H.scenes[1].label=='Le début' and H.scenes[2].label=='Paradis → Ciel' and H.scenes[3].label=='Ciel → Terre' and H.scenes[4].label=='Terre → Océan' and H.scenes[5].label=='Océan → Abysse','Beginning, four biome transitions and Return')
 local read=LevelLayouts.read
 LevelLayouts.read=function()
  local layouts={}
  for _,world in ipairs({1,4,5,6,7}) do layouts[world..':1']={world=world,biome=2,level=1,width=960,height=600,entities={}} end
  return layouts
 end
 for i,scene in ipairs(H.scenes) do
  H.open();UI.draw();UI.buttons[i].run();assert(App.historyPreview,'Every scene button launches a preview')
  capture(scene.id)
  if scene.id=='story' then P.enterWorld()
  elseif scene.id=='intro' then
   local ticks=0
   while App.state=='prologue' do P.update(.05);ticks=ticks+1;assert(ticks<700) end
   assert(C.arrival and App.historyPreview,'Kidnapping preview includes arrival in Paradise')
  end
  local ticks=0
  while App.historyPreview do
   if C.scene() and C.arrival>=C.arrivalDuration then
    assert(Campaign.biome==(scene.id=='ocean_abyss' and 7 or scene.id=='earth_ocean' and 4 or scene.id=='sky_earth' and 5 or 6),'Arrival stays on the real destination biome')
    if not scene.landed then capture(scene.id..'-landed');scene.landed=true end
   end
   C.advance(.05);ticks=ticks+1;assert(ticks<300)
  end
  if scene.id=='paradise_sky' or scene.id=='sky_earth' or scene.id=='earth_ocean' or scene.id=='ocean_abyss' then assert(scene.landed,'Preview holds on the landed destination') end
  assert(App.state=='history' and not C.active and not C.arrival,'Scene automatically returns to the chooser')
  assert(App.selectedWorld==5 and App.hardcore and not App.preview and not App.singleLevel,'Preview restores menu settings')
  assert(snapshot({stats=Profile.stats,biomes=Profile.biomeStats,achievements=Profile.achievements,completed=Profile.completed,seen=Profile.prologueSeen,name=Profile.name})==profile,'Profile stays unchanged')
  assert(snapshot({Bestiary.seen,Bestiary.unread})==bestiary and Replay.last==replay,'Bestiary and last replay stay unchanged')
  assert(love.math.getRandomState()==rng,'Preview restores RNG')
 end
 LevelLayouts.read=read
 App.historyPreview=true;Replay.data={layouts={['5:1']={world=2}}};Replay.recording=true
 assert(next(LevelLayouts.read())==nil,'History ignores replay layouts even if replay state is stale')
 Replay.recording=false;Replay.data=nil;App.historyPreview=nil
 H.play('sky');C.advance(.05);love.keypressed('escape');assert(App.state=='history' and not App.historyPreview,'Escape returns directly to History')
 H.play('paradise');capture('return');local back
 for _,button in ipairs(UI.buttons) do if button.x==28 then back=button end end
 assert(back);back.run();assert(App.state=='history','Visible return button works')
 UI.draw();Input.index=2;love.keypressed('return');assert(App.historyPreview and require('sky_arrival').fromParadise,'Keyboard launches the selected transition')
 H.close();love.keypressed('escape');assert(App.state=='menu')
 Profile.record,Online.start,Replay.begin=record,online,begin
 print('PASS History: all five scene buttons, automatic return, Escape, return button, keyboard, no progression/bestiary/online/replay/RNG changes')
 love.event.quit()
end
return T
