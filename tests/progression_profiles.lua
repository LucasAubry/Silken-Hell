local T={}
function T.run()
 local D=require('demo_progress');local P=require('player_profile')
 Profile.name='Test';Profile.stats={tears=0,eggs=0,deaths=0,attempts=0};Profile.biomeStats={};Profile.bossKills={};Profile.storyTexts={}
 Profile.scores={};Profile.completed={};Profile.levels={};Profile.skinGrants={};Profile.achievements={};Profile.devProgress=false;Profile.topRecords={};Hardcore.completed={}
 D.bindAccount(nil);Characters.browsed=nil;Profile.character=1
 for _,i in ipairs(Characters.baseIndices) do assert(Characters.unlocked(i)==(i==1 or i==2),'Fresh reward '..i) end
 assert(Characters.names[13]=='Gil' and Characters.names[14]=='Max' and Characters.names[27]=='Amir')
 assert(not Characters.unlocked(9));for _,i in ipairs(Characters.baseIndices) do assert(i~=9) end
 Profile.completed[1]=true;Profile.completed[5]=true
 assert(Worlds.canEnter(6) and not Worlds.canViewScores(6),'Unlocked world is not a completed world')
 assert(Hardcore.available(1) and not Worlds.canViewScores(1,true),'Available hardcore is not completed hardcore')
 Hardcore.completed['1']=true;assert(Worlds.canViewScores(1,true))
 App.selectedWorld=6;UI.boardWorld=1;App.state='menu';UI.buttons={};UI.menu();assert(UI.boardWorld==6)
 Profile.completed[4]=true;assert(Characters.unlocked(4));assert(not Characters.unlocked(24) and not Characters.unlocked(25))
 App.sessionLayout={};App.singleLevel=true;Achievements.workshop('workshop_test');assert(Characters.unlocked(25));App.sessionLayout=nil;App.singleLevel=nil
 assert(not Characters.unlocked(24));Achievements.workshop('workshop_publish');assert(Characters.unlocked(24))
 Profile.save();Profile.load();assert(Characters.unlocked(24) and Characters.unlocked(25),'Workshop rewards persist')
 for _,world in ipairs(Worlds.order) do if world~=3 then Hardcore.completed[tostring(world)]=true end end
 assert(not Characters.unlocked(27));Hardcore.completed['3']=true;assert(Characters.unlocked(27))
 local demo='76561198000000001';local other='76561198000000002'
 love.filesystem.write('demo-entitlements.json',require('json').encode({[demo]=true}))
 D.bindAccount(demo);assert(Characters.unlocked(5) and Characters.unlocked(26));D.bindAccount(other);assert(not Characters.unlocked(5) and not Characters.unlocked(26));D.bindAccount(nil)
 Profile.achievements.flawless6=true;assert(Profile.flawless(6) and not Profile.flawless(7))
 local data=P.snapshot();assert(data.worlds[2].flawless and data.worlds[2].world==6)
 local requests={};local request=Online.request
 Online.request=function(path,body,callback)requests[#requests+1]={path=path,callback=callback,body=body}end
 App.state='rankings';P.open({name='Remote',runId='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'})
 assert(P.data==nil and App.state=='playerProfile');P.close();requests[1].callback(data,200);assert(P.data==nil,'Stale callback cannot reopen profile')
 P.open({name='Remote',runId='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'});requests[2].callback(data,200);assert(P.data==data)
 P.close();App.state='menu';P.open({name='Local'});assert(P.data.stats.tears==Profile.stats.tears);P.close();assert(App.state=='menu')
 Online.request=request
 local sounds={};local play=Audio.play;Audio.play=function(s)sounds[#sounds+1]=s end
 App.state='achievements';love.keypressed('right');assert(sounds[#sounds]=='go');love.keypressed('escape');assert(sounds[#sounds]=='back')
 Audio.play=play
 local g=love.graphics;local canvas=g.newCanvas(1200,750,{dpiscale=1})
 local function capture(name,draw)
  UI.buttons={};g.push('all');g.setCanvas(canvas);g.origin();g.clear(.015,.025,.04);draw();g.pop()
  local im=canvas:newImageData();im:encode('png',name..'.png');im:release()
 end
 capture('progression-skins',function()
  for row,index in ipairs({27,6}) do
   UI.rawText(Characters.names[index],30,100+(row-1)*310,'body',{1,1,1})
   for col,dir in ipairs({'down','up','left','right'}) do g.setColor(1,1,1);Characters.portrait(index,245+(col-1)*260,185+(row-1)*310,220,dir) end
  end
 end)
 App.state='playerProfile';P.data=data;P.tab='stats';P.page=1;capture('player-profile-stats',P.draw)
 P.tab='achievements';capture('player-profile-achievements',P.draw)
 App.state='statistics';capture('progression-statistics',require('statistics').draw)
 App.selectedWorld=6;WorldMap.open();capture('progression-worlds',WorldMap.draw)
 App.state='rankings';UI.boardLocal=true;UI.boardWorld=1;UI.boardHardcore=false;UI.boardPage=1
 Profile.scores={{world=1,name='Test',time=10,deaths=0,skin=27,country='FR'}}
 capture('progression-rankings',UI.rankings)
 local found=false;for _,b in ipairs(UI.buttons) do if b.x==280 then b.run();found=App.state=='playerProfile' end end;assert(found,'Clicking player opens profile')
 print('PASS progression: fresh/demo account rewards, Workshop persistence, mode completion gates, Amir, flawless badge/stats, profile identity and stale callbacks, keyboard sounds and rendered screens')
 love.event.quit()
end
return T
