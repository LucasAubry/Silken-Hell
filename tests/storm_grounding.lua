local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true;love.focus=function()end
 App.practice=10;App.singleLevel=true;App.start(6);require('run_start').active=false
 local C=require('mobs.bosses.storm.conductors');local s=Storm
 local function at(x,y) player.x=x-15;player.y=y-12 end
 local function reset()
  require('boss_liberation').reset();s.reset(true);player.reset=false;player.death=0
  at(100,500);s.x=100;s.y=100;s.shot=100;s.bolt=100;Realms.holes={};Arena.interior={}
  C.place(s)
 end
 local function collect(n)
  for i=1,n do local p=s.pickups[i];at(p.x,p.y);s.contact() end
 end
 reset();assert(#s.pickups==3 and #s.rods==2 and s.hp==10)
 for n=1,3 do
  reset();collect(n);assert(not player.reset and s.charges==n,'Collect each spark once')
  s.contact();assert(s.charges==n,'Standing on a collected spark cannot farm charges')
  local p=s.rods[1];at(p.x,p.y);s.contact()
  assert(s.hp==10-(n==3 and 4 or n) and s.charges==0 and s.overload==0,'Charge count controls discharge damage')
  assert(s.phase=='flightTell' and s.dir=='right' and s.hidden,'A beak telegraphs the retaliatory dash from the rod side')
  s.contact();assert(s.hp==10-(n==3 and 4 or n),'One discharge cannot hit twice')
  at(Arena.width/2,500);s.update(s.phaseTime+.001);assert(s.phase=='flight')
  s.update(s.flightDuration+.001);assert(s.phase=='return' and not player.reset,'Dash crosses only its warned lane')
  s.update(.66);assert(s.phase=='orbit','Attacks resume after the counterattack')
 end
 reset();collect(3);at(100,500);C.update(s,3.9)
 assert(not player.reset and s.overload>0,'Overload has a four-second escape window')
 C.update(s,.11);assert(player.reset,'Keeping three charges kills by overload')
 reset();collect(3);s.overload=.001;local rod=s.rods[2];at(rod.x,rod.y);C.update(s,.02)
 assert(not player.reset and s.hp==6 and s.phase=='flightTell' and s.dir=='left','Last-moment grounding saves the player')
 reset();collect(2);at(100,500);C.update(s,15);assert(not player.reset and s.charges==2,'One or two charges never overload')
 reset();at(s.x,s.y);s.contact();assert(player.reset and s.hp==10,'Body contact is lethal and cannot damage the bird')
 reset();at(100,480);s.summon();s.update(.86);assert(player.reset,'Marked lightning remains lethal')
 for hp=10,1,-1 do
  reset();s.hp=hp;s.summon();assert(s.strikeCount()==(hp>=7 and 1 or hp>=4 and 2 or 3))
 end
 reset();s.fire();local speed=math.sqrt(s.projectiles[1].vx^2+s.projectiles[1].vy^2)
 s.charges=3;s.fire();local p=s.projectiles[2]
 assert(math.sqrt(p.vx^2+p.vy^2)>speed*1.3 and not p.golden,'Charges accelerate black feathers')
 reset();at(100,500);s.update(.1);local uncharged=s.bolt
 reset();s.charges=2;s.update(.1);assert(s.bolt<uncharged,'Charges accelerate lightning')
 reset();local old=s.pickups[1];local x,y=old.x,old.y
 Realms.holes={{x=x,y=y,rx=40,ry=40}};C.place(s)
 assert(old.x~=x or old.y~=y,'Lost ground relocates a spark safely')
 assert(s.targetSafe(old.x,old.y),'Relocated spark is reachable on solid ground')
 reset();collect(1);at(100,500);C.update(s,6.1);assert(s.pickups[1].cooldown==0,'Sparks replenish')
 reset();s.hp=4;collect(3);at(s.rods[1].x,s.rods[1].y);s.contact()
 assert(s.hp==0 and require('boss_liberation').busy(),'Final discharge starts liberation')
 require('boss_liberation').update(2);assert(not objet.larme.taken,'Defeating the bird releases the tear')
 reset();Bosses.load({{type='storm',x=100,y=100},{type='storm',x=700,y=100}},{},{})
 local a,b=Bosses.items[1].boss,Bosses.items[2].boss;C.place(a);C.place(b)
 a.charges=2;C.discharge(a,a.rods[1]);assert(a.hp==8 and b.hp==10 and b.charges==0,'Custom bosses own their charges and health')
 local x=b.pickups[1].x;Bosses.resize(1.1);assert(math.abs(b.pickups[1].x-x*1.1)<.001,'Resize moves pickups and rods')
 Bosses.reset();reset();Graphics.effects=true
 local lighting=require('world_lighting');local apply=lighting.apply;local canvas
 lighting.apply=function(scene) canvas=apply(scene);return canvas end
 collect(3);at(Arena.width*.6,410);s.overload=2.5
 love.draw();local pixels=canvas:newImageData();pixels:encode('png','storm-conductors.png');pixels:release()
 lighting.apply=apply
 print('PASS storm conductors: 1/2/3 charges, boosted damage, overload and last-moment grounding, locked counter-dash, lethal body and bolts, attack pressure, relocation, respawn, victory, custom instances, resize and rendered capture')
 love.event.quit()
end
return T
