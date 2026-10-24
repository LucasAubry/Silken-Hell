local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 LevelLayouts.disabled=true;App.preview=false;App.practice=nil;App.singleLevel=false;App.hardcore=false;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
 local B=require('hell_boss_arrival');local H=require('history');local C=require('run_start')
 local save,seen=Profile.save,Profile.transitionsSeen;local writes=0
 Profile.save=function()writes=writes+1 end;Profile.transitionsSeen={}
 local scene;for _,s in ipairs(H.scenes)do if s.id=='boss_hell' then scene=s end end
 assert(scene and not H.unlocked(scene) and H.play('boss_hell')==false)
 Campaign.select(2);player.level=9;reset_level();App.state='playing';C.active=false
 assert(not B.active,'No boss scene in level nine')
 -- Use the same level-completion path as a collected final tear.
 player.level=10;reset_level()
 assert(B.active and #B.bees==3 and B.age==0,'Level ten starts the three-sister arrival')
 local hp,deaths=Wasp.hp,player.death;local rng=love.math.getRandomState()
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local set=g.setCanvas
  g.push('all');set(c);g.setCanvas=function(target,...)if target==nil then return set(c)end;return set(target,...)end
  love.draw();g.setCanvas=set;set();g.pop();local data=c:newImageData();data:encode('png','hell-boss-'..name..'.png');data:release();c:release()
 end
 local function advance(t)while B.active and B.age<t-1e-6 do App.simulate(math.min(1/60,t-B.age))end end
 advance(1.5);capture('cracks');advance(3.5);capture('emergence');advance(5.7);capture('flight');advance(7.4);capture('formation')
 assert(B.captures==1 and B.boss.active,'The real arena is rendered only once and the encounter stays active')
 assert(B.pose(1,4.5).fissure>B.pose(1,5).fissure and B.pose(1,5.6).fissure==0,'Fissures shrink away')
 for i=1,3 do local p=B.pose(i,5.9);assert(p.x<0 or p.x>Arena.width or p.y<0,'All bees leave the arena before returning') end
 assert(Wasp.hp==hp and player.death==deaths and Wasp.elapsed==0 and Wasp.round==0,'No combat during the film')
 assert(love.math.getRandomState()==rng,'Cinematic motion does not consume gameplay RNG')
 for i,bee in ipairs(Wasp.bees)do local p=B.pose(i,7.4);assert(math.abs(p.x-bee.x)<.001 and math.abs(p.y-(bee.y-10))<.001,'The last shot matches the combat formation')end
 assert(not H.unlocked(scene),'Unlock waits for the ending')
 advance(8.6);assert(not B.active and H.unlocked(scene) and writes==1)
 App.respawn();assert(not B.active,'Death retries do not replay the film')
 App.state='menu';local world,level,biome=Campaign.world,player.level,Campaign.biome
 local state=love.math.getRandomState();H.play('boss_hell');assert(B.active and H.bossPreview=='hell')
 local ticks=0
 while App.historyPreview do love.update(1/30);ticks=ticks+1;assert(ticks<300);assert(B.active or App.state=='history')end
 assert(Campaign.world==world and Campaign.biome==biome and player.level==level and love.math.getRandomState()==state and writes==1)
 H.play('boss_hell');love.keypressed('escape');assert(not B.active and App.state=='history')
 Profile.transitionsSeen={};Replay.playing=true;Campaign.select(2);player.level=10;reset_level();assert(B.active)
 while B.active do B.update(.05) end
 assert(not H.unlocked(scene));Replay.playing=false
 App.preview=true;reset_level();assert(not B.active,'Editor previews skip the movie');App.preview=false
 Profile.save=save;Profile.transitionsSeen=seen
 print('PASS Hell boss arrival: formation, frozen combat, deterministic visuals, discovery, retry, History, Escape and replay isolation')
 love.event.quit()
end
return T
