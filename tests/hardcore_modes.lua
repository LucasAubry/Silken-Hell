local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;LevelLayouts.disabled=true
 Profile.name='Hardcore QA';Profile.country='FR';Profile.scores={};Profile.completed={};Profile.levels={};Hardcore.completed={}
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;App.workshopMap=nil;Secret.duel=nil
 -- Normal Sanctuary stays free; hardcore launches a single seven-boss run.
 App.openEntry(8,false);assert(App.state=='bossWorld' and not App.hardcore and not Secret.hardcore)
 App.openEntry(8,true);assert(App.state=='entry' and App.hardcore);App.submit()
 assert(App.state=='playing' and Campaign.world==8 and player.level==1 and Raven.active)
 local expected={'merle','storm','hedgehog','octopus','skeleton_fish','wasp','final_spider'}
 for n=1,7 do
  player.level=n;reset_level()
  assert(Campaign.biome==Worlds.order[n],'Sanctuary biome '..n)
  local kind,boss=Bestiary.currentBoss()
  assert(kind==expected[n] and boss.active,'Correct boss '..n..': '..tostring(kind))
  assert(not Secret.duel and not App.singleLevel,'Full ranked run')
  App.simulate(.016);love.draw()
 end
 -- Completing each real boss exit advances directly to the next encounter.
 App.start(8)
 for n=1,6 do
  for _,boss in ipairs({Raven,Storm,Hedgehog,Octopus,Abyss,Wasp}) do if boss.active or boss.boss then boss.defeated=true end end
  for _,item in ipairs(Bosses.items) do item.boss.defeated=true end
  objet.larme.taken=false;objet.larme_dropped=true;Aftermath.update(0)
  player.x=objet.larme.x;player.y=objet.larme.y
  App.simulate(.016)
  assert(player.level==n+1 and Campaign.world==8 and App.state=='playing','Boss exit advances directly '..n)
 end
 timer=91;player.death=2;player.reset=true;RunDetails.reset();App.resolveDeath()
 assert(player.level==6 and Campaign.world==8 and Campaign.biome==2 and timer==91 and player.death==2,'Death returns from queen to previous boss without resetting totals')
 player.level=1;reset_level();player.reset=true;App.resolveDeath();assert(player.level==1,'First boss is the lower bound')
 player.level=4;reset_level();player.reset=true;player.falling=true;player.fallTimer=0;App.resolveDeath()
 assert(player.level==4,'Fall animation keeps the current boss')
 App.simulate(.32)
 assert(player.level==3 and Campaign.biome==5,'Falling death goes back once')
 App.simulate(.01);assert(player.level==3,'No double retreat')
 player.level=7;reset_level();timer=123;player.death=4;Ending.openReunion()
 assert(App.state=='victory' and not Ending.active and #Profile.ranking(8,nil,true)==1 and #Profile.ranking(8)==0,'Queen ends complete hardcore run')
 local V=require('victory_screen');assert(V.rank(V.run)=='#1');love.draw()
 V.restart(V.run);assert(player.level==1 and timer==0 and player.death==0 and App.hardcore and Raven.active,'Victory restarts Sanctuary from first boss')
 -- Completion must persist without becoming a normal-world record.
 Profile.complete(1,10,0);Hardcore.complete(1)
 Profile.save();Profile.load()
 assert(#Profile.ranking(1)==1 and #Profile.ranking(1,nil,true)==1 and #Profile.ranking(8,nil,true)==1 and not Profile.hasCompleted(8),'Persistent isolated scores')
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 -- Online queues each completed milestone once, even after several retreats.
 local begin,flush=Online.begin,Online.flush;Online.begin=function()end;Online.flush=function()end
 Online.enabled=true;Online.runs={};Online.start(1,'Hardcore QA',22,true)
 local run=Online.current;assert(run.hardcore and run.skin==22)
 for _,n in ipairs({1,2,3,2,1,2,3,4}) do Online.checkpoint(n,100+n,5) end
 assert(#run.pending==4 and run.pending[4].level==4,'Retreats do not duplicate online milestones')
 local requests=love.thread.getChannel('silken.requests');requests:clear();Online.boards={};Online.pages={}
 Online.refresh(1,false);Online.refresh(1,true);Online.page(1,false,1,false);Online.page(1,false,1,true)
 local normal,hard=0,0
 while requests:getCount()>0 do local req=requests:pop();if req.url:find('mode=hardcore',1,true) then hard=hard+1 else normal=normal+1 end end
 assert(normal==3 and hard==3,'Online caches and requests separate the modes')
 Online.enabled=false;Online.current=nil;Online.begin,Online.flush=begin,flush
 -- Complete and replay a real hardcore campaign, preserving its mode and score.
 local maps={}
 for n=1,10 do maps['1:'..n]={world=1,level=n,width=960,height=600,entities={{kind='spawn',x=80,y=300},{kind='tear',x=160,y=300}}} end
 local read,move,slow=LevelLayouts.read,Input.move,Input.slow
 LevelLayouts.read=function()return maps end;LevelLayouts.disabled=false
 Input.move=function()if Replay.input then return Replay.input[1],Replay.input[2] end;return 1,0 end;Input.slow=function()return false end
 App.practice=nil;App.hardcore=true;App.singleLevel=false;Replay.recording=false;Replay.disabled=false;App.start(1);LevelLayouts.read=read
 local count=#Profile.ranking(1,nil,true)
 for i=1,3000 do if App.state~='playing' then break end;Replay.update(1/60,App.simulate) end
 assert(App.state=='victory' and #Profile.ranking(1,nil,true)==count+1,'Hardcore completion is ranked')
 local data=require('json').decode(require('json').encode(Replay.last));assert(data.hardcore and data.completed)
 assert(Replay.play(data))
 for i=1,3000 do if not Replay.playing then break end;Replay.update(1/43,App.simulate) end
 assert(Replay.status=='Lecture terminée.','Hardcore replay: '..Replay.status)
 Input.move,Input.slow=move,slow;Replay.disabled=true;LevelLayouts.disabled=true
 print('PASS hardcore: seven Sanctuary bosses, backward deaths, first-boss bound, completion/restart, isolated persistent scores, online modes and replay')
 -- Capture every menu biome, the bright/dark game extremes and Sanctuary results.
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=tick*.25
  if tick<=7 then
   App.selectedWorld=Worlds.order[tick];WorldMap.hardcore=true;UI.boardHardcore=true;UI.boardWorld=App.selectedWorld;App.state='menu';App.capture='hardcore-menu-'..tick..'.png'
  elseif tick==8 then
   App.hardcore=true;App.practice=nil;App.singleLevel=false;App.start(1);App.capture='hardcore-play-paradise.png'
  elseif tick==9 then App.start(7);App.capture='hardcore-play-abyss.png'
  elseif tick==10 then App.start(8);App.capture='hardcore-sanctuary-first.png'
  elseif tick==11 then player.level=7;reset_level();App.capture='hardcore-sanctuary-queen.png'
  elseif tick==12 then Ending.openReunion();App.capture='hardcore-sanctuary-victory.png'
  elseif tick==13 then App.state='rankings';UI.boardWorld=8;UI.boardHardcore=true;UI.boardLocal=true;UI.boardPage=1;App.capture='hardcore-rankings.png'
  elseif tick==14 then App.selectedWorld=8;WorldMap.hardcore=true;WorldMap.open();App.capture='hardcore-map.png'
  elseif tick==15 then print('PASS hardcore visual captures');love.event.quit() end
 end
end
return T
