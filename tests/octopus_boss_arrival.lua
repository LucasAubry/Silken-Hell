local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 LevelLayouts.disabled=true;App.preview=false;App.practice=nil;App.singleLevel=false;App.hardcore=false;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
 local B=require('octopus_boss_arrival');local H=require('history');local C=require('run_start')
 local save,seen=Profile.save,Profile.transitionsSeen;local writes=0
 Profile.save=function()writes=writes+1 end;Profile.transitionsSeen={}
 local scene;for _,s in ipairs(H.scenes)do if s.id=='boss_octopus' then scene=s end end
 assert(scene and not H.unlocked(scene) and H.play('boss_octopus')==false)
 Campaign.select(4);player.level=9;reset_level();App.state='playing';C.active=false
 assert(not B.active,'No boss scene in level nine')
 -- Use the same level-completion path as a collected final tear.
 player.level=10;reset_level()
 assert(B.active and B.age==0,'Level ten starts the ocean arrival')
 local boss=B.boss;local hp,deaths=boss.hp,player.death;local rng=love.math.getRandomState()
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local set=g.setCanvas
  g.push('all');set(c);g.setCanvas=function(target,...)if target==nil then return set(c)end;return set(target,...)end
  love.draw();g.setCanvas=set;set();g.pop();local data=c:newImageData();data:encode('png','octopus-boss-'..name..'.png');data:release();c:release()
 end
 local function advance(t)while B.active and B.age<t-1e-6 do App.simulate(math.min(1/60,t-B.age))end end
 advance(1.8);capture('lens');advance(3.4);capture('skin');advance(7.8);capture('retreat');advance(11.5);capture('ready')
 assert(B.captures>1 and B.boss.active,'The ocean stays animated')
 assert(B.pose(1).near and B.pose(1).x>B.pose(3).x and B.pose(6.54).x<-800,'Whole animal crosses right to left and fully exits')
 assert(not B.pose(6.7).visible and not B.pose(7).near and B.pose(7).x<B.pose(8).x,'Animal returns from the left at arena depth')
 local pose=B.pose(11.5);assert(pose.scale==1 and pose.x==boss.x and pose.y==boss.y and pose.angle==boss.angle and pose.swim==0,'Exact combat pose at handoff')
 local first=B.armCurve(8,1,B.pose(8));local second=B.armCurve(8.3,1,B.pose(8.3));assert(first[40].x~=second[40].x,'Tentacles undulate continuously')
 local a=B.contact(2.35,1,B.pose(2.35));local b=B.contact(2.5,1,B.pose(2.5))
 assert(a.planted and b.planted and math.abs(a.x-b.x)<.001 and math.abs(a.y-b.y)<.001,'A planted sucker stays fixed while the body advances')
 assert(B.pose(2).angle>0 and B.pose(8).angle<0,'Eyes lead both travel directions')
 assert(boss.hp==hp and player.death==deaths and boss.clock==0 and #boss.projectiles==0 and #boss.crabs==0,'Combat stays frozen')
 assert(love.math.getRandomState()==rng,'Cinematic consumes no simulation RNG')
 assert(not H.unlocked(scene),'Unlock waits for the ending')
 advance(12.1);assert(not B.active and H.unlocked(scene) and writes==1)
 App.respawn();assert(not B.active,'Death retries do not replay the film')
 App.state='menu';local world,level,biome=Campaign.world,player.level,Campaign.biome
 local state=love.math.getRandomState();H.play('boss_octopus');assert(B.active and H.bossPreview=='octopus')
 local ticks=0
 while App.historyPreview do love.update(1/30);ticks=ticks+1;assert(ticks<400);assert(B.active or App.state=='history')end
 assert(Campaign.world==world and Campaign.biome==biome and player.level==level and love.math.getRandomState()==state and writes==1)
 H.play('boss_octopus');love.keypressed('escape');assert(not B.active and App.state=='history')
 Profile.transitionsSeen={};Campaign.select(4);player.level=10
 local replayData=Replay.data;Replay.data={layouts={}}
 Replay.playing=true;reset_level();assert(B.active,'Replay launches the same film')
 while B.active do B.update(.05) end
 assert(not H.unlocked(scene));Replay.playing=false;Replay.data=replayData
 App.preview=true;reset_level();assert(not B.active,'Editor previews skip the movie');App.preview=false
 Profile.save=save;Profile.transitionsSeen=seen
 print('PASS Octopus boss arrival: continuous whole-body crossing, left-to-right swimming, joined undulating arms, frozen combat, deterministic visuals, discovery, retry, History, Escape and replay isolation')
 love.event.quit()
end
return T
