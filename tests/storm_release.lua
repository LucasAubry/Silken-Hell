local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true
 local s=require('mobs.bosses.storm');local feathers=require('mobs.bosses.storm.feathers')
 local kill=Hazards.kill;local hits=0;Hazards.kill=function()hits=hits+1 end
 for _,width in ipairs({720,960,1500})do
  Arena.width=width
  for wave=1,4 do
   player.x=width/2-15;player.y=288;player.reset=false
   s.reset(true);s.wave=wave;s.setPhase('tell');s.setPhase('charge')
   while s.phase=='charge' do s.update(1/120)end
   assert(s.phase=='lap')
   local shots=0
   while s.phase=='lap' do
    assert(s.snails[1].phase=='tethered','Keep the snails attached for the full lap')
    s.update(1/120);shots=math.max(shots,#s.projectiles)
   end
   assert(s.phase=='hunt' and shots>=3,'Fire feathers during the lap')
   for _,p in ipairs(s.snails)do
    assert(p.phase=='ready' and p.x>25 and p.x<width-25 and p.y>25 and p.y<575,'Release on the playable terrain')
   end
   local p=s.snails[1];local x,y=p.x,p.y
   s.updateSnails(.2);assert(p.x==x and p.y==y,'Released snails wait for contact')
   player.x=p.x-15;player.y=p.y-12
   local before=hits;s.contact()
   assert(p.phase=='strike' and hits==before,'Touch launches a snail without hurting the player')
   local hp=s.hp
   for i=1,600 do s.updateSnails(1/120);if p.phase=='spent' then break end end
   assert(p.phase=='spent' and s.hp==hp-1 and #s.smoke>0,'A snail hits once and produces smoke')
   assert(s.fogTarget<=.72,'Smoke leaves the arena readable')
   s.updateSnails(.1);assert(s.hp==hp-1,'No repeated damage from an exploded snail')
  end
 end
 Arena.width=960;s.reset(true);s.phase='hunt';s.x=200;s.y=200;s.featherClock=0
 player.x=600;player.y=400;feathers.update(s,.01)
 assert(s.featherWarning and #s.projectiles==0,'Warn before firing')
 local aim=s.featherAim;player.x=600;player.y=30
 feathers.update(s,.46)
 assert(#s.projectiles==3 and s.projectiles[2].angle==aim,'Volley keeps its announced aim')
 local p=s.projectiles[2];p.age=1;p.x=player.x+15;p.y=player.y+12
 local before=hits;feathers.update(s,.001);assert(hits>before,'Feathers damage on contact')
 s.setPhase('clean');assert(#s.projectiles==0 and not s.featherWarning,'Clear projectiles for the sweep')
 s.advanceWave=true
 for i=1,240 do s.update(1/120);if s.phase~='clean' then break end end
 assert(s.phase=='charge' and s.wave==2,'Return immediately with the next wave')
 -- Exercise all new drawing paths with the real renderer and sprites.
 s.phase='hunt';s.releaseSnails();s.fogAmount=.72;s.featherClock=0
 player.x=480;player.y=300;feathers.update(s,.01)
 s.draw();s.drawFog();feathers.update(s,.5);s.drawFog()
 Hazards.kill=kill
 print('PASS storm release: 12 laps, safe grounded snails, single hits, smoke, warned feathers, collisions, immediate return and rendering')
 love.event.quit()
end
return T
