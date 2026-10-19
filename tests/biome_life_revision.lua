local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 Profile.save=function()end;Bestiary.save=function()end
 App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;App.hardcore=false;Secret.duel=nil
 -- Reproduce both horizontal and vertical impacts with authored fish (no vx/vy).
 Campaign.select(4);player.level=1;reset_level();App.state='playing'
 local layout={world=4,level=1,width=Arena.width,height=600,entities={{kind='spawn',x=400,y=300},{kind='tear',x=600,y=300},{kind='mob',type='fish',x=40,y=40}}}
 LevelLayouts.apply(layout)
 local fish;for _,m in ipairs(mobs) do if m.type=='fish' then fish=m end end
 assert(fish and fish.vx==nil and fish.vy==nil)
 local move=Arena.move;Arena.move=function()return true,true end
 MobBehaviors.fish.update(fish,1/60);Arena.move=move
 for i=1,3 do Hazards.kill();assert(App.resolveDeath());App.simulate(1/60);love.draw() end
 print('PASS ocean fish wall collision and repeated death/reset')
 local sky=require('sky');local weather=require('sky_weather')
 weather.active=true;weather.holes={};weather.mistCuts={};weather.mist={}
 assert(weather.playerVisibility()==1)
 weather.fog(player.x+15,player.y+12);weather.mist[1].age=1
 local thin=weather.playerVisibility();assert(thin<1 and thin>.24)
 for i=1,12 do weather.fog(player.x+15,player.y+12);weather.mist[#weather.mist].age=1 end
 assert(weather.playerVisibility()<thin and weather.playerVisibility()>=.24 and not weather.playerHidden())
 weather.clearFog(player.x+15,player.y+12);assert(weather.playerVisibility()==1)
 local signatures={}
 for n=1,10 do
  local l=sky.layout(n,960);assert(LayoutSchema.validate(l))
  local signature=Replay.hash(l.entities);assert(not signatures[signature]);signatures[signature]=true
  Campaign.select(6);player.level=n;App.sessionLayout=l;reset_level();App.state='playing';love.draw()
  if n<10 then assert(#levels[n].larme_position>=3 and not objet.larme.taken) else assert(Bosses.alive()) end
 end
 App.sessionLayout=nil
 print('PASS ten distinct playable sky layouts, guardian, graded fog visibility')
 local complete,unlocked,scores=Profile.completed,Profile.unlocked,Profile.scores
 Profile.completed={};Profile.scores={};Profile.unlocked=1
 assert(not Creator.open() and App.state~='creatorConfirm')
 Profile.completed[1]=true;App.state='workshop';assert(not Creator.open() and App.state=='creatorConfirm');UI.draw();assert(#UI.buttons==2)
 local launch=require('platform').launch;local called=false;require('platform').launch=function()called=true;return true end
 assert(Creator.open(true) and called);require('platform').launch=launch
 Profile.completed=complete;Profile.unlocked=unlocked;Profile.scores=scores
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 local g=love.graphics;local canvas=g.newCanvas(960,600)
 for _,w in ipairs({1,2,3,4,5,6,7}) do
  Campaign.select(w);player.level=1;reset_level();App.state='playing';UI.clock=2
  g.push('all');g.setCanvas(canvas);g.origin();g.clear();draw_level()
  require('renaissance_frame').draw();require('earth_frame').draw();require('paradise_frame').draw();require('hell_frame').draw();require('biome_edge_life').draw();g.pop()
  canvas:newImageData():encode('png','edge-life-'..w..'.png')
 end
 canvas:release()
 print('PASS creator progression/confirmation and all biome border renders')
 local queen=require('final_spider')
 Campaign.select(3);player.level=1;reset_level();App.state='playing'
 queen.engaged=true;queen.phase='roam';queen.phaseTime=0
 queen.babies={};require('queen_heirs').hatch(queen,{x=100,y=100,seed=1});local baby=queen.babies[1]
 queen.update(1/60)
 assert(baby.walkMoving and baby.walkPhase and baby.walkPhase>0,'Renaissance feet follow actual travel')
 baby.frozen=2;queen.update(1/60);assert(not baby.walkMoving,'Trapped spiders stop stepping')
 print('PASS Renaissance movement-driven walking and stationary pose')
 -- UI callbacks: details are opened, populated and return closes the overlay.
 App.state='rankings';UI.boardWorld=1;UI.boardHardcore=false;UI.boardLocal=true;UI.boardPage=1
 local ranking=Profile.ranking
 Profile.ranking=function()return {{world=1,name='Test',time=12,deaths=0,skin=1,splits={{level=1,time=12,deaths=0}},hasReplay=true,runId='12345678-1234-1234-1234-123456789abc'}} end
 UI.draw();assert(UI.click(976,297));assert(RunDetails.view and RunDetails.view.rows[1].time==12)
 UI.draw();UI.click(600,616);assert(not RunDetails.view)
 local request,play=Online.request,Replay.play;local watched=false
 Online.request=function(path,body,callback)callback({replay={test=true}},200)end
 Replay.play=function(data)watched=data.test;return true end
 UI.draw();assert(UI.click(1040,296));assert(watched)
 Online.request,Replay.play,Profile.ranking=request,play,ranking
 print('PASS leaderboard details and replay button callbacks')
 love.event.quit(0)
end
return T
