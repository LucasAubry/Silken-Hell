local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 App.sessionLayout=nil;App.workshopMap=nil;App.preview=false;App.singleLevel=false;App.practice=nil;Secret.duel=nil;LevelLayouts.disabled=true
 local S=Story;local N=require('achievement_notice');local screen=require('achievements_screen')
 local files={};for _,name in ipairs({'profile.txt','scores.tsv','hardcore-scores.json','score_details.json'}) do files[name]=love.filesystem.read(name) or false end
 Profile.storyTexts={};N.init()
 local first,all
 for _,entry in ipairs(Achievements.list) do if entry.id=='story_first' then first=entry elseif entry.id=='story_all' then all=entry end end
 assert(first and all and not Achievements.unlocked(first) and not all.visible())
 local function reset(world,n)
  Campaign.select(world);player.level=n or (world==3 and 1 or 10);reset_level();App.state='playing';player.reset=false
  local boss=({[1]=Raven,[2]=Wasp,[3]=require('final_spider'),[4]=Octopus,[5]=Hedgehog,[6]=Storm,[7]=Abyss})[Campaign.biome]
  if boss and boss.active and (Campaign.biome~=7 or boss.boss) then boss.defeated=true;objet.larme.taken=false;Aftermath.update(0) end
  S.wallKey=nil;S.nearSince=nil;S.readTime=0
 end
 local function approach()
  local x,y,side=S.wallSpot()
  player.x=side=='left' and 22 or side=='right' and Arena.width-60 or x-15
  player.y=side=='top' and 22 or side=='bottom' and 549 or y-12
  assert(S.atWall(x,y,side));return x,y,side
 end
 local function read()
  approach();for _=1,4 do UI.clock=UI.clock+.1;S.updateWall(.1) end
 end
 reset(1);approach();S.drawWallMessage();assert(S.progress()==0,'Drawing is read-only')
 S.updateWall(.1);assert(S.progress()==0,'A quick pass is not a reading')
 player.x=Arena.width*.5;player.y=300;S.updateWall(.1);assert(S.readTime==0)
 read();local found,total=S.progress();assert(found==1 and total==7,'Seven unique messages')
 assert(Achievements.unlocked(first) and all.visible() and not Achievements.unlocked(all) and all.description():find('1/7',1,true))
 N.update(.1);assert(N.active and N.active.entry==first,'First discovery triggers the achievement notification')
 read();N.update(.1);assert(S.progress()==1 and #N.queue==0,'Rereading does not count or notify twice')
 Profile.load();assert(S.progress()==1 and Achievements.unlocked(first),'Read messages survive profile reload')
 N.init();N.update(.1);assert(not N.active,'Loading previously earned achievements stays silent')
 reset(6,1);read();assert(S.progress()==1,'Exploration walls are not messages')
 reset(6)
 for _,flag in ipairs({'preview','sessionLayout'}) do App[flag]=true;read();assert(S.progress()==1);App[flag]=nil end
 Replay.playing=true;read();Replay.playing=false;assert(S.progress()==1,'Playback cannot discover messages')
 Replay.ghost=true;read();Replay.ghost=false;assert(S.progress()==1,'Ghosts cannot discover messages')
 player.reset=true;read();player.reset=false;assert(S.progress()==1,'Dead player cannot read')
 reset(9);read();assert(S.progress()==1,'Hardcore variant reuses the same message')
 for _,world in ipairs({6,5,4,7,2,3}) do reset(world);read() end
 found,total=S.progress();assert(found==total and found==7 and Achievements.unlocked(all),'All seven distinct texts complete the second achievement')
 N.update(.1);assert(N.active and N.active.entry==all,'Collection completion triggers a notification')
 Profile.storyTexts['999']=true;assert(S.progress()==7,'Unknown saved keys never inflate progress')
 Profile.load();assert(S.progress()==7 and Achievements.unlocked(all),'Completed collection survives reload')
 for _,lang in ipairs(require('localization').options) do
  Profile.language=lang.code
  for _,key in ipairs({'Une longue histoire','Tous ses mots','Trouve un texte qu’elle t’a laissé.','Retrouve tous les textes qu’elle t’a laissés. %d/%d'}) do assert(require('localization').has(key,lang.code)) end
 end
 Profile.language='fr'
 print('PASS seven unique texts, first and all achievements, 1/7 progress, durable saves, duplicate/hardcore handling, read-only rendering, preview/replay/ghost/death isolation and notifications')
 local frame=0
 love.update=function()
  frame=frame+1
  if frame==1 then
   Profile.storyTexts={['1']=true};reset(1);Raven.defeated=true;Aftermath.update(0);read()
   N.init();N.active={entry=first,age=.6};App.capture='story-gold-paradise.png'
  elseif frame==3 then
   App.state='achievements';UI.achievementFilter='todo';screen.scroll=0;App.capture='story-progress-one.png'
  elseif frame==5 then
   reset(7);Abyss.defeated=true;Aftermath.update(0);read();N.active=nil;App.capture='story-gold-abyss.png'
  elseif frame==7 then
   reset(3);require('final_spider').defeated=true;Aftermath.update(0);read();App.capture='story-gold-queen.png'
  elseif frame==9 then
   Profile.storyTexts={};for biome in pairs(S.inscriptions) do Profile.storyTexts[tostring(biome)]=true end
   App.state='achievements';UI.achievementFilter='done';screen.scroll=0;App.capture='story-progress-complete.png'
  elseif frame==11 then
   for name,data in pairs(files) do if data then love.filesystem.write(name,data) else love.filesystem.remove(name) end end
   print('PASS story discovery visual captures');love.event.quit()
  end
 end
end
return T
