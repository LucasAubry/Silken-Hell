local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 LevelLayouts.disabled=true;App.preview=false;App.practice=nil;App.singleLevel=false;App.hardcore=false;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
 local B=require('sky_boss_arrival');local H=require('history');local C=require('run_start')
 local save,seen=Profile.save,Profile.transitionsSeen;local writes=0
 Profile.save=function()writes=writes+1 end;Profile.transitionsSeen={}
 local scene;for _,s in ipairs(H.scenes)do if s.id=='boss_sky' then scene=s end end
 assert(scene and not H.unlocked(scene) and H.play('boss_sky')==false)
 Campaign.select(6);player.level=9;reset_level();App.state='playing';C.active=false
 assert(not B.active,'No boss scene in level nine')
 -- Use the same level-completion path as a collected final tear.
 player.level=10;reset_level()
 assert(B.active and B.age==0,'Level ten starts the diving arrival')
 local boss=B.boss;local hp,deaths=boss.hp,player.death;local rng=love.math.getRandomState()
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local set=g.setCanvas
  g.push('all');set(c);g.setCanvas=function(target,...)if target==nil then return set(c)end;return set(target,...)end
  love.draw();g.setCanvas=set;set();g.pop();local data=c:newImageData();data:encode('png','sky-boss-'..name..'.png');data:release();c:release()
 end
 local function advance(t)while B.active and B.age<t-1e-6 do App.simulate(math.min(1/60,t-B.age))end end
 advance(1);capture('hidden');advance(2.4);capture('dive');advance(2.8);capture('impact');advance(4.8);capture('emerging');advance(6.6);capture('closing')
 assert(B.captures==1 and B.boss.active,'The sky arena is captured once')
 assert(not B.pose(1).visible and B.pose(2.4).visible and B.pose(2.8).burrowing,'Hidden boss dives into the ground')
 assert(B.pose(5.3).hole>B.pose(6.6).hole and B.pose(7.6).hole==0,'The temporary hole closes gradually')
 assert(boss.hp==hp and player.death==deaths and boss.clock==0 and #boss.holes==0,'Cinematic leaves combat and terrain untouched')
 assert(love.math.getRandomState()==rng,'Cinematic consumes no simulation RNG')
 advance(7.8);local p=B.pose(7.8);assert(not p.visible and p.hole==0,'Bird leaves the arena after emerging from the hole')
 assert(not H.unlocked(scene),'Unlock waits for the ending')
 advance(8.6);assert(not B.active and H.unlocked(scene) and writes==1)
 App.respawn();assert(not B.active,'Death retries do not replay the film')
 App.state='menu';local world,level,biome=Campaign.world,player.level,Campaign.biome
 local state=love.math.getRandomState();H.play('boss_sky');assert(B.active and H.bossPreview=='sky')
 local ticks=0
 while App.historyPreview do love.update(1/30);ticks=ticks+1;assert(ticks<300);assert(B.active or App.state=='history')end
 assert(Campaign.world==world and Campaign.biome==biome and player.level==level and love.math.getRandomState()==state and writes==1)
 H.play('boss_sky');love.keypressed('escape');assert(not B.active and App.state=='history')
 Profile.transitionsSeen={};Campaign.select(6);player.level=10
 local replayData=Replay.data;Replay.data={layouts={['6:10']=require('sky').layout(10,Arena.width)}}
 Replay.playing=true;reset_level();assert(B.active,'Recorded sky layout launches the same film')
 while B.active do B.update(.05) end
 assert(not H.unlocked(scene));Replay.playing=false;Replay.data=replayData
 App.preview=true;reset_level();assert(not B.active,'Editor previews skip the movie');App.preview=false
 Profile.save=save;Profile.transitionsSeen=seen
 print('PASS Sky boss arrival: dive, tethered snail, closing hole, return, frozen combat, deterministic visuals, discovery, retry, History, Escape and replay isolation')
 love.event.quit()
end
return T
