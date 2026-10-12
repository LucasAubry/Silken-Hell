local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false;Replay.ghost=false
 App.preview=false;App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;App.workshopMap=nil;Secret.duel=nil;App.state='menu'
 local files={};for _,n in ipairs({'profile.txt','scores.tsv','hardcore-scores.json','score_details.json','top-records.json','top-records.backup.json'}) do files[n]=love.filesystem.read(n) or false end
 local save=Profile.save;Profile.save=function()end;Bestiary.save=function()end
 Profile.skinGrants={};Profile.achievements={heartbreak=true};Profile.character=1;Characters.browsed=nil;Profile.skinEffects={};Profile.tearExtension=false;Profile.topRecords={}
 Profile.completed={};Profile.scores={};Hardcore.completed={}
 local E=require('skin_effects');local records=require('top_records');local N=require('achievement_notice');local R=require('skin_unlock');local g=love.graphics
 assert(not E.unlocked('gold') and not E.unlocked('hardcore') and E.unlocked('heartbreak'))
 Profile.completed[5]=true;assert(Hardcore.unlocked() and not E.unlocked('hardcore'),'Unlocking hardcore mode does not award its completion effect')
 Hardcore.completed['5']=true;assert(E.unlocked('hardcore') and not E.unlocked('gold'))
 E.equip('hardcore',true);E.equip('heartbreak',true);assert(Profile.character==1 and E.enabled('hardcore') and E.enabled('heartbreak'))
 N.init();R.init()
 local row={runId='12345678-1234-1234-1234-123456789abc',world=6,hardcore=false,achievedAt=1791530000000,rawTime=95.75,deaths=3,skin=1,name='QA',hasReplay=false}
 records.merge({row});assert(E.unlocked('gold') and records.has(6) and not records.has(5))
 records.merge({row});assert(#Profile.topRecords==1,'Repeated server polling never duplicates a souvenir')
 records.merge({});assert(#Profile.topRecords==1,'Losing first place never removes the achievement')
 row.hasReplay=true;records.merge({row});assert(Profile.topRecords[1].hasReplay,'Late replay upload becomes watchable')
 Profile.topRecords={};records.load();assert(#Profile.topRecords==1 and Profile.topRecords[1].rawTime==95.75 and Profile.topRecords[1].achievedAt==row.achievedAt)
 N.update(.01);R.update(.01);assert(N.active.entry.id=='top1' and not R.active,'First-place achievement precedes the gold effect')
 N.update(3.7);R.update(.01);assert(R.active.index=='gold' and App.state=='skinUnlock')
 R.update(3.3);R.close(true);assert(E.enabled('gold') and Profile.character==1,'Equipping gold does not select a different skin')
 Characters.select(2);assert(E.enabled('gold') and E.enabled('hardcore') and E.enabled('heartbreak'),'Effects follow the selected skin')
 App.state='skins';UI.draw();assert(#UI.buttons==15,'Only fourteen skins and the return button appear in the gallery')
 Characters.select(1);App.state='menu';UI.clock=4;UI.menuArrival=0
 local mouse=UI.mouse;UI.mouse=function()return 760,301 end
 UI.draw();local seen={};for _,b in ipairs(UI.buttons) do if b.effect then seen[b.effect]=b end end
 assert(seen.hardcore and seen.heartbreak and seen.gold)
 seen.heartbreak.run();assert(not E.enabled('heartbreak'));seen.heartbreak.run();assert(E.enabled('heartbreak'))
 UI.mouse=mouse
 -- Sample the rendered tear only: it never disappears and stays under the left eye.
 local canvas=g.newCanvas(256,256)
 for _,time in ipairs({0,.4,1/.65,2/.65}) do
  UI.clock=time;g.push('all');g.setCanvas(canvas);g.clear(0,0,0,0);g.setColor(1,1,1)
  require('skin_extension').draw(128,128,220,'down');g.pop()
  local data=canvas:newImageData();local count=0
  for y=0,255 do for x=0,255 do local _,_,_,a=data:getPixel(x,y);if a>.1 then count=count+1;assert(x<128,'Only the left eye sheds the tear')end end end
  assert(count>20,'Continuous stream at animation boundaries');data:release()
 end
 -- Both visible eyes flow in the menu and gameplay.
 g.push('all');g.setCanvas(canvas);g.clear(0,0,0,0);g.setColor(1,1,1)
 require('skin_extension').draw(128,128,220,'down',false,true);g.pop()
 local data=canvas:newImageData();local left,right=0,0
 for y=0,255 do for x=0,255 do local _,_,_,a=data:getPixel(x,y)
  if a>.1 then if x<128 then left=left+1 else right=right+1 end end
 end end
 assert(left>20 and right>20,'Both visible eyes have a continuous tear');data:release()
 -- The complete halo follows the head in every direction, including the back.
 for _,dir in ipairs({'left','right','down','up'}) do
  g.push('all');g.setCanvas(canvas);g.clear(0,0,0,0);g.setColor(1,1,1)
  E.front(128,128,220,'hardcore',dir);g.pop()
  local pixels=canvas:newImageData();local count,sumX,sumY=0,0,0
  for y=0,255 do for x=0,255 do local r=pixels:getPixel(x,y)
   if r>.4 then count=count+1;sumX=sumX+x;sumY=sumY+y end
  end end
  assert(count>100,'The red halo remains bright in every direction')
  if dir=='up' then assert(sumY/count>45 and sumY/count<80,'The back-view halo stays close to the far head')
  elseif dir~='down' then assert(dir=='left' and sumX/count<110 or dir=='right' and sumX/count>146,'Halo stays on the profile head') end
  local upper,lower=0,0
  for y=0,255 do for x=0,255 do local r=pixels:getPixel(x,y)
   if r>.4 then if y<sumY/count then upper=upper+1 else lower=lower+1 end end
  end end
  assert(upper>count*.3 and lower>count*.3,'Both arcs form a complete halo')
  pixels:release()
 end
 canvas:release()
 -- A replay carries the cosmetic switches of its run, not the current user's switches.
 Replay.playing=true;Replay.data={effects={hardcore=true,gold=false,heartbreak=false}}
 assert(E.enabled('hardcore') and not E.enabled('gold') and not E.enabled('heartbreak'));Replay.playing=false
 local request=Online.request;local fetched=false
 local replay={version=1,build=Replay.build(),world=1,seed=123,width=960,height=600,skin=1,startLevel=1,single=false,hardcore=false,
  effects={hardcore=false,gold=true,heartbreak=true},completed=true,time=1/60,deaths=0,frames=1,layouts={},inputs={{1,0,0,0}},checks={{1,10,10000,30000,0,true}}}
 App.state='topRecords'
 Online.request=function(path,body,callback)
  assert(path=='/v1/replays/'..row.runId and body==nil);fetched=true;callback({replay=replay},200)
 end
 Replay.watch(row);assert(fetched and Replay.playing and E.enabled('gold') and not E.enabled('hardcore'))
 Replay.stop();Online.request=request;assert(App.state=='topRecords','Watching a saved first place returns to its history')
 Profile.scores={
  {world=1,name='Larmes',country='FR',time=10,deaths=0,skin=1,effects={heartbreak=true}},
  {world=1,name='Auréole',country='FR',time=11,deaths=0,skin=1,effects={hardcore=true}},
  {world=1,name='Doré',country='FR',time=12,deaths=0,skin=1,effects={gold=true}},
  {world=1,name='Tous',country='FR',time=13,deaths=0,skin=1,effects={gold=true,hardcore=true,heartbreak=true}},
  {world=1,name='Sans effet',country='FR',time=14,deaths=0,skin=1,effects={}},
  {world=1,name='Hardcore',country='FR',time=15,deaths=0,skin=1,hardcore=true,effects={heartbreak=true,hardcore=true}}
 }
 Profile.character=15;Profile.skinEffects={};save()
 love.filesystem.append('scores.tsv','\n6\tAncien\tFR\t10.000\t0\t1\t')
 Profile.load()
 assert(#Profile.scores==7 and Profile.scores[1].effects.heartbreak and not Profile.scores[1].effects.gold,'Normal score cosmetics and legacy scores survive reload')
 assert(Profile.ranking(1,nil,true)[1].effects.hardcore,'Hardcore score cosmetics survive reload')
 assert(Profile.character==6 and Profile.skinEffects.hardcore,'Legacy gold skin migrates to its base plus hardcore effect')
 Profile.skinGrants={};Profile.topRecords={row};Profile.character=1;Characters.browsed=nil;Profile.tearExtension=true
 Hardcore.completed={['5']=true};Profile.skinEffects={hardcore=true,gold=false};N.init();R.init();UI.clock=4
 print('PASS independent effects, records, replay, reward ordering, gameplay tear, both menu eyes and complete directional halo')
 local frame=0;local draw=love.draw
 love.update=function()
  frame=frame+1;UI.clock=4.3;UI.menuArrival=0
  if frame==1 then App.state='menu';UI.mouse=function()return 760,301 end
  elseif frame==2 then UI.mouse=mouse;Profile.skinEffects={gold=true};App.state='menu'
  elseif frame==3 then App.state='skins'
  elseif frame==4 then records.open()
  elseif frame==5 then App.state='achievements';UI.achievementFilter='done';require('achievements_screen').scroll=0
  elseif frame==6 then Profile.skinEffects={hardcore=true};App.state='playing'
  elseif frame==7 then Profile.skinEffects={hardcore=true,gold=true};App.state='pause'
  elseif frame==8 then Profile.skinEffects={};Profile.tearExtension=false;App.state='rankings';UI.boardWorld=1;UI.boardLocal=true;UI.boardHardcore=false;UI.boardPage=1
  else
   for n,data in pairs(files) do if data then love.filesystem.write(n,data) else love.filesystem.remove(n) end end
   love.event.quit()
  end
 end
 love.draw=function()
  if frame==6 then
   g.push('all');g.origin();g.clear(.035,.045,.06);g.setColor(1,1,1)
   for i,dir in ipairs({'left','down','right','up'}) do
    local x=160+(i-1)*290
    Characters.draw(x,320,220,dir)
    Characters.draw(x,460,Characters.playerWidth,dir)
    Characters.portrait(2,x,540,Characters.playerWidth,dir)
    E.front(x,540,Characters.playerWidth,'hardcore',dir)
   end
   g.pop()
  else draw() end
  if frame<=8 then g.captureScreenshot(function(image)local f=assert(io.open('/tmp/silken-effects-'..frame..'.png','wb'));f:write(image:encode('png'):getString());f:close()end)end
 end
end
return T
