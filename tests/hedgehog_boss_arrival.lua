local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 LevelLayouts.disabled=true;App.preview=false;App.practice=nil;App.singleLevel=false;App.hardcore=false;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
 local B=require('hedgehog_boss_arrival');local H=require('history');local C=require('run_start')
 local read,saveProfile=love.filesystem.read,Profile.save;local fixture
 Profile.save=function()end
 love.filesystem.read=function(name,...)
  if name=='profile.txt' then return 'statsVersion=1\nprogressVersion=2\n'..fixture end
  if name=='scores.tsv' then return '' end
  if name=='hardcore-scores.json' then return '[]' end
  return read(name,...)
 end
 for _,case in ipairs({{'level3=1',true,false},{'completed3=1',true,false},{'transitionsSeen={"3":true}',true,false},{'level2=10',false,false},{'level5=9',false,false},{'level5=10',false,true}}) do
  fixture=case[1];Profile.load()
  assert((Profile.transitionsSeen.boss_queen==true)==case[2],'Old Renaissance saves recover the cocoon button')
  assert((Profile.transitionsSeen.boss_hedgehog==true)==case[3],'Old earth saves unlock only a reached boss')
 end
 love.filesystem.read=read;Profile.load();Profile.save=saveProfile
 local save,seen=Profile.save,Profile.transitionsSeen;local writes=0
 Profile.save=function()writes=writes+1 end;Profile.transitionsSeen={}
 local scene;for _,s in ipairs(H.scenes)do if s.id=='boss_hedgehog' then scene=s end end
 assert(scene and not H.unlocked(scene) and H.play('boss_hedgehog')==false)
 Campaign.select(5);player.level=9;reset_level();App.state='playing';C.active=false
 assert(not B.active,'No boss scene in level nine')
 -- Use the same level-completion path as a collected final tear.
 player.level=10;reset_level()
 assert(B.active and B.age==0,'Level ten starts the rolling arrival')
 local boss=B.boss;local hp,deaths=boss.hp,player.death;local rng=love.math.getRandomState()
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local set=g.setCanvas
  g.push('all');set(c);g.setCanvas=function(target,...)if target==nil then return set(c)end;return set(target,...)end
  love.draw();g.setCanvas=set;set();g.pop();local data=c:newImageData();data:encode('png','hedgehog-boss-'..name..'.png');data:release();c:release()
 end
 local function advance(t)while B.active and B.age<t-1e-6 do App.simulate(math.min(1/60,t-B.age))end end
 advance(.8);capture('rumble');advance(2.4);capture('roll');advance(3.3);capture('impact');advance(6.5);capture('unfold');advance(7.6);capture('ready')
 local sx,sy=B.shake(3.2);assert(math.abs(sx)+math.abs(sy)>1,'Impact shakes the camera')
 local m={type='mole',x=350,y=400,age=2.7}
 assert(Realms.molePhase(B.molePose(m,1.8).age)=='dig','Mole dives when the boss enters')
 assert(Realms.molePhase(B.molePose(m,3).age)=='hidden','Mole stays underground during rolling')
 assert(Realms.molePhase(B.molePose(m,6.5).age)=='emerge','Mole emerges once boss reaches its point')
 assert(Realms.molePhase(B.molePose(m,7).age)=='surface' and m.age==2.7,'Mole returns without mutating simulation')
 assert(B.captures>1 and B.boss.active,'The real earth arena stays animated')
 assert(not B.pose(1).visible and B.pose(2.4).visible and B.pose(2.4).unroll==0,'Boss arrives rolled into a ball')
 assert(B.pose(3).x>B.pose(3.5).x and B.pose(3.5).x>B.pose(4).x,'Impact sends the boss back across the arena')
 local pose=B.pose(7.6);assert(pose.unroll==1 and pose.x==boss.x and pose.y==boss.y,'Unfolding reaches the exact combat position')
 assert(boss.hp==hp and player.death==deaths and boss.phase=='standing' and boss.phaseTime==1.35 and #boss.projectiles==0,'Cinematic leaves combat untouched')
 assert(love.math.getRandomState()==rng,'Cinematic consumes no simulation RNG')
 assert(not H.unlocked(scene),'Unlock waits for the ending')
 advance(8.6);assert(not B.active and H.unlocked(scene) and writes==1)
 App.respawn();assert(not B.active,'Death retries do not replay the film')
 App.state='menu';local world,level,biome=Campaign.world,player.level,Campaign.biome
 local state=love.math.getRandomState();H.play('boss_hedgehog');assert(B.active and H.bossPreview=='hedgehog')
 local ticks=0
 while App.historyPreview do love.update(1/30);ticks=ticks+1;assert(ticks<300);assert(B.active or App.state=='history')end
 assert(Campaign.world==world and Campaign.biome==biome and player.level==level and love.math.getRandomState()==state and writes==1)
 H.play('boss_hedgehog');love.keypressed('escape');assert(not B.active and App.state=='history')
 Profile.transitionsSeen={};Campaign.select(5);player.level=10
 local replayData=Replay.data;Replay.data={layouts={}}
 Replay.playing=true;reset_level();assert(B.active,'Replay launches the same film')
 while B.active do B.update(.05) end
 assert(not H.unlocked(scene));Replay.playing=false;Replay.data=replayData
 App.preview=true;reset_level();assert(not B.active,'Editor previews skip the movie');App.preview=false
 Profile.save=save;Profile.transitionsSeen=seen
 print('PASS Hedgehog boss arrival: rolling entrance, rebound, unfolding, frozen combat, deterministic visuals, discovery, retry, History, Escape and replay isolation')
 love.event.quit()
end
return T
