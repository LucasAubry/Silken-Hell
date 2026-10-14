local T={}
function T.run()
 love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 App.sessionLayout=nil;App.hardcore=false;Secret.duel=nil;App.state='playing'
 local W=require('retry_wait')
 local function level(w,n)
  Campaign.select(w);player.level=n;reset_level();timer=0;Replay.input={0,0,false}
 end
 local function snapshot()
  local out={timer=timer,level=player.level,x=player.x,y=player.y,death=player.death,
   realm=Realms.clock,wind=Realms.wind,lightning=Realms.lightningClock,rain=Realms.rainClock,tear=larme_timer,mobs={},bosses={}}
  for _,m in ipairs(mobs) do out.mobs[#out.mobs+1]={kind=m.type,x=m.x,y=m.y,timer=m.timer,phase=m.phase} end
  for _,b in ipairs({Raven,Wasp,Hedgehog,Octopus,Storm,Abyss}) do
   out.bosses[#out.bosses+1]={x=b.x,y=b.y,clock=b.clock,hp=b.hp,phase=b.phase,phaseTime=b.phaseTime,shot=b.shot,returnShot=b.returnShotTimer,head=b.swimHead}
  end
  local function finite(value)
   if type(value)=='number' and (value==math.huge or value==-math.huge) then return tostring(value) end
   if type(value)=='table' then local copy={};for k,v in pairs(value) do copy[k]=finite(v) end;return copy end
   return value
  end
  return Replay.canonical(finite(out))
 end
 for _,w in ipairs({1,2,3,4,5,6,7}) do
  for _,n in ipairs(w==3 and {1} or {1,10}) do
   level(w,n);assert(not W.active,'First entry starts immediately')
   App.simulate(1/60);assert(timer>0,'First entry runs without movement')
   App.respawn();assert(W.active,'Death arms the wait')
   local before=snapshot();local rng=love.math.getRandomState();local bob=larme_float_timer
   for _=1,120 do App.simulate(1/60) end
   assert(snapshot()==before,'Gameplay stays frozen in biome '..w..' level '..n)
   assert(love.math.getRandomState()==rng,'Waiting does not change gameplay RNG')
   assert(larme_float_timer>bob and W.age>1.9,'Cosmetic time continues')
   local clock=Realms.clock;W.beginDraw();assert(Realms.clock>clock,'Drawing uses live animation clocks');W.endDraw()
   assert(snapshot()==before,'Rendering restores all simulation clocks')
   love.draw();assert(snapshot()==before,'Full scene rendering cannot start an encounter')
   local moved=false
   for _,v in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
    Replay.input={v[1],v[2],false}
    if W.canMove(1/60) then
     local x,y=player.x,player.y;App.simulate(1/60)
     assert(not W.active and (player.x~=x or player.y~=y),'Movement resumes gameplay immediately')
     moved=true;break
    end
   end
   assert(moved,'Spawn allows movement')
   Replay.input={0,0,false};local elapsed=timer;App.simulate(1/60)
   assert(timer>elapsed,'Stopping after movement does not freeze the world again')
   reset_level();assert(not W.active,'Next level clears retry state')
   print('PASS retry waiting biome '..w..' level '..n)
  end
 end
 level(1,1);App.respawn();player.x=23;player.y=23;Replay.input={-1,0,false}
 App.simulate(.05);assert(W.active,'Pushing into a boundary is not movement')
 Replay.input={0,0,true};App.simulate(.05);assert(W.active,'Speed key alone does not resume')
 Replay.input={.5,.5,false};App.simulate(.05);assert(not W.active,'Analog diagonal input resumes')
 level(6,1);player.falling=true;player.fallTimer=.03;player.reset=true;Replay.input={0,0,false}
 App.simulate(.05);assert(W.active and not player.falling,'Fall animation completes before waiting')
 level(6,3);App.hardcore=true;App.respawn()
 assert(player.level==2 and W.active,'Hardcore rollback also waits after death');App.hardcore=false
 level(7,10);App.respawn();assert(not require('mobs.bosses.abyss.arrival').current,'Retry skips Abyss introduction')
 reset_level();assert(not W.active and require('mobs.bosses.abyss.arrival').current,'Fresh Abyss entry keeps introduction')
 print('PASS idle retries: all biomes and bosses, live presentation, no RNG drift, movement, walls, falls, hardcore and fresh entries')
 love.event.quit()
end
return T
