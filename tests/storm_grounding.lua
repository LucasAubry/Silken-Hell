local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true;love.focus=function()end
 App.practice=10;App.singleLevel=true;App.start(6);require('run_start').active=false
 local b=Storm
 local function reset()
  require('boss_liberation').reset();b.reset(true);player.reset=false;player.death=0;player.dashing=false
  player.x=100;player.y=440;Realms.holes={};Arena.interior={}
  b.shot=100;b.bolt=100
 end
 local function playerAt(x,y)player.x=x-15;player.y=y-12 end
 local function tick(seconds,dt)
  dt=dt or .01
  for _=1,math.floor(seconds/dt+.5) do b.update(dt) end
 end
 for hp=10,1,-1 do
  reset();b.hp=hp;playerAt(100,480);b.summon()
  assert(#b.strikes==1 and b.strikes[1].x==100 and b.strikes[1].y==480,'First bolt targets the player immediately')
  playerAt(220,480);tick(.42)
  local expected=hp>=7 and 1 or hp>=4 and 2 or 3
  assert(#b.strikes==math.min(2,expected),'Second bolt starts only at lower health')
  if expected>=2 then assert(b.strikes[2].x==220,'Second bolt retargets the player') end
  playerAt(340,480);tick(.42)
  assert(#b.strikes==expected and b.boltsRemaining==0 and #b.rain==0,'Exactly one, two or three targeted bolts, without an extra rain wave')
  assert(b.strikes[1].x==100,'Warnings do not follow the player')
  if expected==3 then assert(b.strikes[3].x==340,'Third bolt retargets the player') end
  for _=1,15 do b.fire() end
  for _,p in ipairs(b.projectiles)do assert(not p.golden and not p.returned,'All feathers are black')end
 end
 reset();playerAt(100,480);b.summon();tick(.7)
 assert(not player.reset and b.hp==10,'Warning is harmless')
 tick(.2);assert(player.reset and b.hp==10,'A missed lightning bolt kills at its marked position')
 reset();b.contact();assert(b.target,'The target is available immediately, without waiting for an attack')
 local targetX,targetY=b.target.x,b.target.y
 local move,slow=Input.move,Input.slow
 playerAt(targetX-70,targetY);Input.move=function()return 1,0 end;Input.slow=function()return false end
 App.move(.25);Input.move=move;Input.slow=slow
 assert(b.phase=='grounded' and not player.reset,'Fast player movement cannot skip the target trigger')
 assert(b.phase=='grounded' and b.hp==10 and not b.target and not player.reset,'Touching the target grounds the boss without requiring a dash or damage')
 -- The target is relocated if lightning removes its support, and works with effects off.
 local landX,landY=b.x,b.y
 reset();b.contact();local old=b.target
 b.holes={{x=old.x,y=old.y,r=22,age=0,seed=1}};b.contact()
 assert(b.target and (b.target.x~=old.x or b.target.y~=old.y),'A target over a new hole moves to solid ground')
 assert(b.targetSafe(b.target.x,b.target.y),'Target has a safe landing footprint')
 local effects=Graphics.effects;Graphics.effects=false;playerAt(b.target.x,b.target.y);b.contact();Graphics.effects=effects
 assert(b.phase=='grounded' and not player.reset,'Gameplay target works independently of decorative effects')
 b.x,b.y=landX,landY;b.holes={}
 local x,y=b.x,b.y;tick(.3)
 assert(b.x==x and b.y==y,'Grounded boss stops patrolling')
 playerAt(x-30,y);b.contact()
 assert(b.phase=='knocked' and b.vx>1000 and b.hp==10 and not player.reset,'Ordinary contact pushes without direct damage or a dash')
 b.contact();assert(b.hp==10,'Repeated contact does not drain health')
 reset();playerAt(b.x,b.y);b.contact();assert(player.reset,'Flying body stays dangerous')
 for _,dash in ipairs({false,true}) do
  reset();player.dashing=dash;local px,py=require('collision_shapes').center()
  b.projectiles={{x=px,y=py,vx=0,vy=0,life=2,age=0}}
  b.update(.01);assert(player.reset,'Black feathers remain lethal with or without a dash')
 end
 local sides={{80,300,1,0,'right'},{Arena.width-80,300,-1,0,'left'},
  {Arena.width/2,80,0,1,'down'},{Arena.width/2,520,0,-1,'up'}}
 for i,p in ipairs(sides) do
  reset();b.x,b.y=p[1],p[2];b.land();playerAt(b.x+p[3]*30,b.y+p[4]*30);b.contact()
  assert(b.hp==10 and b.phase=='knocked');b.update(.08)
  assert(b.hp==9 and b.phase=='flightTell' and b.dir==p[5] and b.fallSide==i-1,'Fall costs one HP and immediately shows the beak on the same edge')
  b.contact();assert(b.hp==9 and not b.fall(),'One fall cannot count twice')
  local sx,sy,ex,ey=b.startX,b.startY,b.endX,b.endY
  playerAt(Arena.width/2,420);b.update(.01)
  assert(sx==b.startX and sy==b.startY and ex==b.endX and ey==b.endY,'Beak warning locks the dash lane')
  b.setPhase('flight')
  if sy==ey then playerAt(Arena.width/2,sy<300 and 480 or 100) else playerAt(sx<Arena.width/2 and Arena.width-100 or 100,300) end
  b.update(b.flightDuration+.001)
  assert(b.phase=='return' and not player.reset,'Existing dash makes exactly one crossing')
  b.update(.66);assert(b.phase=='orbit' and b.hp==9,'Boss resumes its attacks after returning')
 end
 reset();b.x=200;b.y=300;b.land();playerAt(170,300);b.contact()
 b.holes={{x=290,y=300,r=22,age=0,seed=1}};b.update(.2)
 assert(b.hp==9 and b.phase=='flightTell','Swept knockback catches narrow interior holes')
 reset();b.x=200;b.y=300;b.land();playerAt(170,300);b.contact()
 Arena.interior={{x=250,y=270,w=12,h=60}};b.update(.2)
 assert(b.hp==10 and b.phase=='grounded' and b.x<235,'A solid wall stops the slide without dealing damage')
 local function slide(dt)
  reset();b.x=Arena.width/2;b.y=300;b.land();playerAt(b.x-30,b.y);b.contact();playerAt(80,500)
  tick(.3,dt);return b.x,b.y
 end
 local ax,ay=slide(1/60);local bx,by=slide(1/120)
 assert(math.abs(ax-bx)+math.abs(ay-by)<.01,'Knockback is consistent at 60 and 120 FPS')
 reset();b.land();playerAt(100,480);tick(4)
 assert(b.phase=='orbit' and b.hp==10 and b.target,'Missing the push window returns to the attack cycle with a new target')
 reset()
 for hp=9,0,-1 do
  b.setPhase('orbit');b.x=80;b.y=300;b.land();playerAt(110,300);b.contact();b.update(.08)
  assert(b.hp==hp,'Each pushed fall removes exactly one life')
 end
 assert(b.defeated and require('boss_liberation').busy() and #b.projectiles==0 and #b.strikes==0,'Tenth fall starts liberation')
 require('boss_liberation').update(2)
 assert(not objet.larme.taken,'Victory releases the reward')
 reset();assert(b.hp==10 and b.phase=='orbit' and b.fallSide==nil and b.pushLock==0,'Reset clears all knockback and return state')
 Bosses.load({{type='storm',x=80,y=300},{type='storm',x=700,y=150}},{},{})
 local first,second=Bosses.items[1].boss,Bosses.items[2].boss
 first.land();playerAt(110,300);first.contact();first.update(.08)
 assert(first.hp==9 and second.hp==10 and second.phase=='orbit','Custom bosses have independent fall damage and phases')
 first.setPhase('orbit');first.x=400;first.y=300;first.placeTarget();local targetX=first.target.x
 Bosses.resize(1.1);assert(math.abs(first.target.x-targetX*1.1)<.001,'Resize moves the gameplay target with the arena')
 first.land();playerAt(first.x-30,first.y);first.contact()
 local vx=first.vx;Bosses.resize(1.1);assert(math.abs(first.vx-vx*1.1)<.001,'Resize scales knockback with the arena')
 Bosses.reset();reset()
 -- Capture actual scene output without opening a foreground window.
 local L=require('world_lighting');local apply=L.apply;local canvas
 L.apply=function(scene)canvas=apply(scene);return canvas end
 local function capture(name)
  love.draw();local data=canvas:newImageData();data:encode('png',name);data:release()
 end
 b.hp=3;playerAt(340,420);b.summon();playerAt(460,420);tick(.42);playerAt(580,420);tick(.3);b.targetLightning()
 capture('storm-targeted-lightning.png')
 reset();b.x=Arena.width/2;b.y=300;b.land();playerAt(b.x-80,b.y+50);capture('storm-grounded.png')
 b.x=80;playerAt(110,300);b.contact();b.update(.08);capture('storm-fall-return.png')
 L.apply=apply
 print('PASS sky grounding: player-targeted 1/2/3 bolts, black feathers only, immediate touch target, safe contact push, four fall edges and locked return dashes, swept holes/walls, 60/120 FPS, timeout, victory, reset, independent custom bosses and scene captures')
 love.event.quit()
end
return T
