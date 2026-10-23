local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false
 Profile.save=function()end;Profile.record=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end
 local kill=Hazards.kill;Hazards.kill=function()end
 local function setup(world,kind)
  require('boss_liberation').reset()
  App.sessionLayout={world=world,level=10,width=960,height=600,environment={lightning=false},entities={{kind='spawn',x=650,y=300},{kind='boss',type=kind,x=480,y=300}}}
  App.singleLevel=true;LevelLayouts.disabled=false;App.start(world);require('run_start').active=false;require('retry_wait').reset();player.reset=false
  return Bosses.items[1].boss
 end
 local g=love.graphics
 local function screenshot(name,boss)
  local c=g.newCanvas(Arena.width,600);g.push('all');g.setCanvas(c);g.origin();draw_level();boss.draw();draw_player('down');if boss.drawFog then boss.drawFog()end;g.pop()
  local d=c:newImageData();d:encode('png',name);d:release();c:release()
 end
 local o=setup(4,'octopus');o.shot=999
 player.x=o.x+180-15;player.y=o.y-12;o.startStrike(1,true)
 assert(o.wrapArms[1].phase=='raise');o.update(.81);assert(o.wrapArms[1].phase=='slam')
 o.update(.17);assert(o.grip and o.hp==8,'Ground tip can be grabbed')
 -- Retracing an arc cannot accumulate a full winding.
 for i=1,100 do local a=(i%2)*.1;player.x=o.x+180*math.cos(a)-15;player.y=o.y+180*math.sin(a)-12;o.update(.01)end
 assert(o.hp==8 and o.grip.progress<.2)
 o.grip=nil;o.rider=nil;o.wrapArms={}
 for hit=1,8 do
  player.x=o.x+180-15;player.y=o.y-12
  o.wrapArms[1]={arm=1,tx=o.x+180,ty=o.y,phase='ground',grabbable=true,age=0};o.grab(o.wrapArms[1])
  o.guardClock=0;o.update(.01)
  local count=0;for arm,p in pairs(o.wrapArms)do if arm~=1 then count=count+1 end end
  assert(count==hit-1,'One extra attacking arm per lost life')
  for i=1,180 do
   local a=i*math.pi*2/180;player.x=o.x+180*math.cos(a)-15;player.y=o.y+180*math.sin(a)-12;o.update(1/120)
   if hit==3 and i==130 then screenshot('new-poulpe-wrap.png',o)end
  end
  assert(o.hp==8-hit and o.unwind,'Exactly one damage for a complete winding')
  local a=o.angle;local dir=o.unwind.dir;o.update(.1);assert((o.angle-a)*dir<0,'Unwind turns the opposite way')
  for i=1,100 do o.update(.01)end
  assert(#o.crabs==0,'Boss never summons crabs')
 end
 assert(o.liberating or o.defeated,'Final full winding ends the fight')
 o=setup(4,'octopus');o.shot=999;o.attackClock=999
 o.inkPools={{x=player.x+15,y=player.y+12,rx=42,ry=30,life=6,seed=1}}
 o.update(.01);assert(player.inkCoat>2 and #o.blots==0,'Ink coats player without a screen overlay')
 screenshot('new-poulpe-ink.png',o)
 local hp=o.hp;o.hurt({inked=true},1);assert(o.hp==hp,'Crab impacts cannot bypass winding')
 local canvas=g.newCanvas(Arena.width,600);g.push('all');g.setCanvas(canvas);g.origin()
 o.draw();local start=love.timer.getTime()
 for i=1,30 do o.draw()end
 local elapsed=love.timer.getTime()-start;g.pop();canvas:release()
 print(string.format('POULPE cached SVG render %.2f ms/frame',elapsed/30*1000))
 
 local move=Input.move;Input.move=function()return 1,0 end
 local x,y=player.x,player.y;player.inkWobble=.12;App.move(.03)
 assert(player.x>x and math.abs(player.y-y)>1,'Coated input deviates but keeps forward motion');Input.move=move
 -- Flight remains straight between borders, then aims at the player's new position.
 local s=setup(6,'storm');s.x=250;s.y=250;player.x=700;player.y=350;s.setPhase('hunt')
 local vx,vy=s.vx,s.vy;local heading=s.flightHeading
 for i=1,25 do player.y=100;s.update(.01);assert(s.flightHeading==heading,'Player movement does not redirect the current run')end
 local changed=false
 for i=1,400 do s.update(.01);if s.flightHeading~=heading then changed=true;break end end
 assert(changed,'Border chooses a new straight run')
 s.holes={{x=200,y=220,tx=350,ty=220,radius=15,age=0}};s.snails={};s.phase='return';s.phaseTime=999
 screenshot('new-storm-holes.png',s)
 for i=1,100 do s.update(.01)end
 assert(#s.holes==1 and s.holes[1].radius>0 and s.holes[1].radius<12,'Holes shrink progressively before disappearing')
 assert(not s.holeAt(275,233),'The shrinking rim frees the passage')
 for i=1,120 do s.update(.01)end
 assert(#s.holes==0,'Trail fully heals within 2.2 seconds')
 local sweep=require('mobs.bosses.storm.sweep')
 for _,dt in ipairs({1/120,1/60,1/30})do
  local state={x=480,y=300,holes={},fogAmount=1,fogTarget=1,groundRevision=0};sweep.begin(state)
  local elapsed=0;local done=false
  while not done and elapsed<2 do done=sweep.update(state,dt);elapsed=elapsed+dt end
  assert(done and math.abs(elapsed-1.5)<=dt+.0001,'Full-screen sweep lasts 1.5 seconds: '..elapsed)
  assert(state.fogAmount==0 and state.fogRows==5)
 end
 Hazards.kill=kill;require('boss_liberation').reset()
 print('PASS new bosses: eight full windings, no backtracking exploit, eight-arm escalation, reverse unwinding, no crabs, ink coating and input wobble, straight pursuit, healing cloud holes, 1.5s sweep at 30/60/120 FPS')
 love.event.quit()
end
return T
