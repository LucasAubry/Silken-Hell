local T={}
local function level(w,n)
 Replay.disabled=true;Replay.recording=false;Replay.playing=false;Replay.data=nil;App.practice=nil;App.sessionLayout=nil;App.singleLevel=false
 LevelLayouts.disabled=true;Campaign.select(w);player.level=n;reset_level();App.state='playing';player.reset=false
end
function T.run()
 Online.enabled=false
 local u={};Achievements.check({world=1,deaths=95,time=1},u);assert(u.maxance)
 local u={};Achievements.check({world=1,deaths=94,time=9999},u);assert(not u.maxance)
 level(4,10);local o=Octopus
 for _,pos in ipairs({{55,55},{Arena.width-75,55},{55,520},{Arena.width-75,520},{Arena.width/2,510}}) do
  player.x,player.y=pos[1],pos[2];o.crabs={};o.inkPools={};o.releaseCrabs();assert(#o.crabs>=6,'Complete waves at arena edges')
  for _,c in ipairs(o.crabs) do assert(c.x>=46 and c.x<=Arena.width-46 and c.y>=44 and c.y<=556);assert(o.crabPathClear(c.x,c.y)) end
 end
 o.crabs={};for i=1,30 do o.crabs[i]={x=55,y=55} end;o.releaseCrabs();assert(#o.crabs==30,'No two-crab wave near cap')
 assert(not o.spawnClear(-100,-100) and not o.spawnClear(Arena.width+100,300))
 local function trace()
  local c={x=60,y=250,age=0,inked=true,frenzy=true,wave=3,slot=2,speed=195,hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12};local out={}
  for i=1,120 do o.walkCrab(c,1/60,function() end);out[#out+1]=string.format('%.8f,%.8f,%.8f,%.8f',c.x,c.y,c.vx,c.vy) end
  return table.concat(out,';')
 end
 assert(trace()==trace(),'Deterministic frenzy')
 level(7,10);Abyss.open=true;Abyss.breathAt=0;Abyss.clock=.1
 local mx,my=Abyss.mouth();player.x=mx-15;player.y=my-12;player.charges=1;Abyss.contact();assert(Abyss.swallowed)
 local test={x=80,y=80};Realms.fireflies={test};mobs={};Abyss.threads={};Realms.bolts={};Ocean.bubbles={};objet.larme.taken=true
 for i=1,60 do Abyss.update(1/60) end
 assert(Abyss.swallowed and Abyss.open,'Do not spit after .6 seconds')
 for i=1,300 do Abyss.update(1/60);if not Abyss.open then break end end
 assert(not Abyss.open and not test.abyssHeld and #Abyss.ejected>=1,'Capture and release all cargo together')
 local layout=require('json').decode(love.filesystem.read('tests/abyss_restored_layout.json'));LevelLayouts.disabled=false;Workshop.playLayout(layout)
 local boss=Bosses.items[1].boss;boss.open=true;boss.breathAt=0;boss.clock=.1
 local mx,my=boss.mouth();player.x=mx-15;player.y=my-12;player.abyssGrace=0;player.charges=1;boss.contact();assert(boss.swallowed)
 local thread={x=70,y=200,vx=0,vy=0,life=10,age=0};Abyss.threads={thread}
 local sawHeld=false
 for i=1,420 do boss.update(1/60);sawHeld=sawHeld or thread.abyssHeld==boss;if not boss.open then break end end
 assert(sawHeld and not boss.open and not thread.abyssHeld,'Saved boss captures and releases shared light projectiles')
 local play=Audio.play;local sounds={};Audio.play=function(name) sounds[#sounds+1]=name end
 Profile.completed={};for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end;App.selectedWorld=1;WorldMap.open();WorldMap.step(1)
 assert(#sounds==1 and sounds[1]=='selection','World keyboard navigation selection sound');Audio.play=play
 RunDetails.reset();player.level=1;player.death=0;RunDetails.tick(2);player.death=2;RunDetails.death();player.level=2;RunDetails.tick(3)
 local score={world=1,name='Split QA',country='FR',time=5,deaths=2,skin=1,splits=RunDetails.snapshot()}
 Profile.scores={score};Profile.save();Profile.load();assert(Profile.scores[1].splits[1].deaths==2)
 RunDetails.openScore(Profile.scores[1],1);assert(RunDetails.view.rows[2].time==3);RunDetails.view=nil
 RunDetails.openScore({},1);assert(RunDetails.view.status);RunDetails.view=nil
 print('PASS full crab waves, arena bounds, deterministic frenzy, complete abyss suction, Maxance, persistent splits')
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then App.selectedWorld=4;Profile.unlocked=8;WorldMap.open();App.capture='polish-worlds.png'
  elseif tick==3 then App.state='rankings';UI.boardWorld=1;UI.boardLocal=true;App.capture='polish-ranking.png'
  elseif tick==5 then RunDetails.openScore(Profile.scores[1],1);App.capture='polish-details.png'
  elseif tick==7 then RunDetails.view=nil;level(4,10);player.x=80;player.y=450;o.releaseCrabs();App.capture='polish-octopus.png'
  elseif tick==10 then love.event.quit() end
 end
end
return T
