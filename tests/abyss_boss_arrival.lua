local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 LevelLayouts.disabled=true;App.preview=false;App.practice=nil;App.singleLevel=false;App.hardcore=false;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
 local H=require('history');local B=require('abyss_boss_arrival');local I=require('mobs.bosses.abyss.arrival');local C=require('run_start')
 local read,saveProfile=love.filesystem.read,Profile.save
 local fixture
 Profile.save=function()end
 love.filesystem.read=function(name,...)
  if name=='profile.txt' then return 'statsVersion=1\nprogressVersion=2\n'..fixture end
  if name=='scores.tsv' then return '' end
  if name=='hardcore-scores.json' then return '[]' end
  return read(name,...)
 end
 for _,case in ipairs({{'level7=9',false},{'level7=10',true},{'completed7=1',true},{'level6=10',false}}) do
  fixture=case[1];Profile.load()
  assert((Profile.transitionsSeen.boss_abyss==true)==case[2],'Old saves unlock only the Abyss encounter already reached')
 end
 love.filesystem.read=read;Profile.load();Profile.save=saveProfile
 local save,seen=Profile.save,Profile.transitionsSeen;local writes=0
 Profile.save=function()writes=writes+1 end;Profile.transitionsSeen={}
 local scene;for _,s in ipairs(H.scenes) do if s.id=='boss_abyss' then scene=s end end
 assert(scene and not H.unlocked(scene) and H.play('boss_abyss')==false,'Undiscovered boss introduction is inaccessible')
 Campaign.select(7);player.level=9;reset_level();App.state='playing';C.active=false
 local gate=require('abyss_gate');assert(gate.active)
 player.x=gate.tx-15;player.y=gate.ty-12;gate.update(.01);gate.update(1.3)
 App.simulate(.01)
 assert(player.level==10 and I.current and I.current.arrival.cinematic,'Finishing level nine starts the cinematic')
 assert(B.current() and Abyss.playerHidden() and not H.unlocked(scene),'Discovery waits until the film has finished')
 assert(B.duration==10 and math.abs(B.lead+3.15-B.duration)<.001,'The slower film ends with the underlying arrival ready')
 assert(B.maps[7] and B.maps[8] and B.maps[9],'Travelling uses all three authored levels')
 assert(B.pose(0).camera==0 and math.abs(B.pose(4.65).camera-2*Arena.width)<.01,'Camera travels left to right through the adjoining arenas')
 assert(not B.pose(5.1).closed and B.pose(5.25).closed,'The player enters the mouth before it closes')
 assert(B.pose(5.25).offset==0 and B.pose(9.15).offset+B.tailLeft>3*Arena.width,'The entire body, including its tail, clears level nine')
 local moving
 for i,e in ipairs(B.maps[7].entities) do if e.kind=='mob' then
  local a,b=B.mobPose(e,i,0,B.width),B.mobPose(e,i,1,B.width)
  assert((a.x-b.x)^2+(a.y-b.y)^2>1,'Creatures keep moving during the travelling shot');moving=true;break
 end end
 assert(moving,'The authored level-seven creatures are present')
 local gateSize
 for _,e in ipairs(B.maps[9].entities) do if e.kind=='abyss_gate' then gateSize=e end end
 assert(gateSize and B.gate.w==gateSize.w and B.gate.h==gateSize.h,'The cinematic keeps the playable gate dimensions')

 local hp,deaths=Abyss.hp,player.death
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local set=g.setCanvas
  g.push('all');set(c);g.setCanvas=function(target,...)if target==nil then return set(c)end;return set(target,...)end
  love.draw();g.setCanvas=set;set();g.pop();local data=c:newImageData();data:encode('png','boss-arrival-'..name..'.png');data:release();c:release();collectgarbage('collect')
 end
 local function advanceTo(t)
  while I.current and I.current.arrival.elapsed<t-1e-6 do App.simulate(math.min(1/60,t-I.current.arrival.elapsed)) end
 end
 advanceTo(.35);capture('level-7');advanceTo(2.4);capture('level-8');advanceTo(4.9);capture('mouth-open');advanceTo(5.25);capture('mouth-closed');advanceTo(7.2);capture('body-crossing')
 assert(Abyss.hp==hp and player.death==deaths and not player.reset,'No combat or damage during the film')
 advanceTo(8.65);capture('tail-exit');advanceTo(9.65);capture('handoff')
 assert(I.current and B.pose(9.15).offset==B.pose(9.9).offset and B.pose(9.15).camera==B.pose(9.9).camera,'The final empty view holds briefly before combat')
 advanceTo(10.1);capture('ready')
 assert(not I.current and not B.current() and H.unlocked(scene) and #Abyss.lumenParticles==300,'Cinematic hands off to the real fight and unlocks History')
 local before=writes
 App.respawn();assert(not I.current and not B.current(),'Deaths do not replay the cinematic')
 assert(writes==before,'Retry does not unlock the movie again')
 App.state='menu';App.selectedWorld=5;local world,biome,level=Campaign.world,Campaign.biome,player.level
 local rng=love.math.getRandomState()
 H.play('boss_abyss');assert(H.bossPreview and player.level==10 and I.current.arrival.cinematic)
 local ticks=0
 while App.historyPreview do
  love.update(1/30);ticks=ticks+1;assert(ticks<400)
  assert(I.current or App.state=='history','History closes on the final cinematic tick without flashing combat')
 end
 assert(App.state=='history' and not I.current and not B.current(),'History automatically returns after the scene')
 assert(Campaign.world==world and Campaign.biome==biome and player.level==level and love.math.getRandomState()==rng,'History restores campaign and RNG')
 assert(writes==before,'Watching History never writes progression')
 H.play('boss_abyss');love.keypressed('escape');assert(App.state=='history' and not I.current,'Escape clears the cinematic')
 Profile.transitionsSeen={};Replay.playing=true;Campaign.select(7);player.level=10;reset_level();App.state='playing'
 assert(I.current and I.current.arrival.cinematic,'Replay uses the same arrival timing')
 while I.current do I.update(I.current,1/30) end
 assert(not H.unlocked(scene),'Replay cannot unlock history');Replay.playing=false
 App.preview=true;reset_level();assert(I.current and not I.current.arrival.cinematic,'Editor preview keeps its short entrance')
 I.retry(I.current);App.preview=false
 Profile.transitionsSeen=seen;Profile.save=save
 print('PASS Abyss boss cinematic: level 9 trigger, slower travelling and final pause, moving creatures, full-body exit, handoff, unlock, retry, history, Escape and replay isolation')
 love.event.quit()
end
return T
