local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;App.preview=false;App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;App.hardcore=false;Secret.duel=nil;LevelLayouts.disabled=true
 Profile.bossKills={};Profile.biomeStats={};Profile.completed={[1]=true};Profile.scores={};Profile.achievements={}
 assert(Profile.bossVictories(1)==1 and Profile.bossVictories(4)==0)
 App.state='playing';Campaign.select(1);Profile.recordBoss('merle');assert(Profile.bossVictories(1)==2)
 Profile.bossKills={storm=4};Profile.scores={{world=6},{world=6}};assert(Profile.bossVictories(6)==4,'Historic scores never double-count recorded wins')
 for _,cat in ipairs({'boss','traps','creatures'})do
  local rank=0;Bestiary.worldFilter=nil;Bestiary.levelFilter=nil
  for _,row in ipairs(Bestiary.list(cat))do assert(Worlds.rank(row.entry.world)>=rank);rank=Worlds.rank(row.entry.world)end
  Bestiary.worldFilter=7;for _,row in ipairs(Bestiary.list(cat))do assert(row.entry.world==7)end
 end
 Bestiary.worldFilter=nil
 local C=require('mobs.bosses.abyss.pattern_cycle')
 local function reset()Replay.recording=false;Replay.input=nil;App.sessionLayout=nil;App.state='playing';Campaign.select(7);player.level=10;reset_level();player.reset=false;player.falling=false;require('run_start').active=false end
 reset();C.enter(Abyss,'bones');local mx,my=C.mouth(Abyss);player.x=mx-15;player.y=my-12;player.charges=3;player.dashing=true;player.abyssGrace=10
 C.contact(Abyss);assert(Abyss.hp==18 and player.charges==3,'Dash no longer spends the stored charges')
 C.enter(Abyss,'suction');mx,my=C.mouth(Abyss);player.x=mx-15;player.y=my-12;C.suction(Abyss,.1);assert(Abyss.hp==18 and player.charges==0 and Abyss.absorbed)
 C.suction(Abyss,.1);assert(Abyss.hp==18,'Survival never damages the boss')
 reset();C.enter(Abyss,'suction');mx,my=C.mouth(Abyss);player.x=mx-15;player.y=my-12;player.abyssGrace=0;C.suction(Abyss,.1);assert(Abyss.hp==18 and not player.reset and Abyss.absorbed,'Absorption no longer requires a light charge')
 reset();C.enter(Abyss,'suction');mx,my=C.mouth(Abyss);player.x=mx-15;player.y=my-12;player.charges=1;C.suction(Abyss,.1)
 assert(Abyss.hp==18 and Abyss.absorbed and player.charges==0 and not player.reset,'One light charge is enough to survive without damage')
 reset();Abyss.round=1;C.enter(Abyss,'traverse')
 assert(Abyss.swimHead.y==300 and Abyss.swimHead.x==35,'Boss enters from the side at mid-height')
 local Bombs=require('mobs.bosses.abyss.bombs');assert(#Abyss.bombs==6)
 Abyss.bombs={};Abyss.swimHead.x=200;player.x=600;player.y=420
 local startX,startY=Abyss.swimHead.x,Abyss.swimHead.y
 for _=1,60 do C.swim(Abyss,.01)end
 assert(Abyss.swimSpeed>145 and Abyss.swimHead.x>startX and Abyss.swimHead.y>startY,'Accelerating pursuit')
 player.x=0;player.y=100;for _=1,100 do C.swim(Abyss,.01)end;assert(Abyss.swimDir==-1)
 Abyss.bombs={{x=500,y=300,r=15}};Abyss.lastMouthX=420;Abyss.lastMouthY=300
 local hp=Abyss.hp;Bombs.mouth(Abyss,580,300,.01)
 assert(Abyss.hp==hp and Abyss.swallowBomb==Abyss.bombs[1] and Abyss.open,'Capture opens mouth without immediate explosion')
 local swallowed=Abyss.swallowBomb;local angle=Abyss.swimAngle
 Bombs.mouth(Abyss,600,320,.06);assert(Abyss.open and not swallowed.hit and Abyss.hp==hp,'Bomb travels with moving mouth')
 Bombs.mouth(Abyss,620,340,.07)
 assert(not Abyss.open and swallowed.inside and not swallowed.hit and Abyss.hp==hp,'Jaw closes before explosion')
 assert(math.abs(swallowed.x-(620-math.cos(angle)*72))<.001 and math.abs(swallowed.y-(340-math.sin(angle)*72))<.001,'Bomb reaches the back of the rotating mouth')
 Bombs.mouth(Abyss,620,340,.08);assert(Abyss.hp==hp-1 and swallowed.hit and not Abyss.swallowBomb,'Explosion damages only after swallowing and closing')
 Bombs.mouth(Abyss,620,340,.01);assert(Abyss.hp==hp-1,'Bomb explodes once')
 Abyss.bombs={{x=660,y=300,r=15}};Abyss.swimAngle=0;Abyss.lastMouthX=nil;Abyss.biteTime=0
 for _=1,90 do Bombs.mouth(Abyss,580,300,.01)end
 assert(Abyss.bombs[1].x==660 and Abyss.bombs[1].y==300 and not Abyss.swallowBomb and not Abyss.bombs[1].hit,'Nearby bombs remain stationary despite open mouth')
 Bombs.mouth(Abyss,640,300,.01);assert(Abyss.swallowBomb==Abyss.bombs[1],'Swallowing starts only at mouth contact')
 for _=1,60 do Bombs.mouth(Abyss,640,300,.01)end;assert(Abyss.bombs[1].hit,'Contact still completes swallowing and explosion')
 local kill=Hazards.kill;local killed=0;Hazards.kill=function(reason)assert(reason=='abyss_bomb');killed=killed+1 end
 Abyss.bombs={{x=500,y=300,r=15}};Abyss.bombPlayerX=400;Abyss.bombPlayerY=300;player.x=585;player.y=288;player.abyssGrace=0;player.abyssSpit=nil
 Bombs.player(Abyss);Bombs.player(Abyss);Hazards.kill=kill;assert(killed==1 and Abyss.bombs[1].hit,'Dash across bomb kills player once')
 reset();C.enter(Abyss,'bones');assert(not Abyss.open and Abyss.head.y==115 and #Abyss.bones>20,'Closed head above horizontal body')
 C.fireBones(Abyss);assert(#Abyss.debris==2 and Abyss.debris[1].key=='skeleton_rib' and Abyss.debris[1].vy>0)
 local count=#Abyss.bones;Abyss.buildBones();assert(#Abyss.bones==27 and #Abyss.bones==count,'Launched ribs leave body')
 player.abyssGrace=20;C.update(Abyss,2);assert(#Abyss.plankton==0,'Barrage emits no lightning')
 reset();C.enter(Abyss,'traverse');Abyss.swimHead={x=500,y=300};Abyss.swimAngle=math.pi*.75;Abyss.swimDir=-1;Abyss.swimPath={};Abyss.buildBones()
 for i=0,7 do
  Abyss.swimAngle=i*math.pi/4;Abyss.swimDir=math.cos(Abyss.swimAngle)>=0 and 1 or -1;Abyss.buildBones()
  assert(Abyss.head.angle==Abyss.swimAngle and not Abyss.bones[1].flip,'Head rotates with the body without mirroring')
  local mx,my=C.swimMouth(Abyss);local bx,by=C.mouth(Abyss)
  assert(math.abs(mx-bx)<.001 and math.abs(my-by)<.001,'Bomb interaction stays aligned with the rotating mouth')
 end
 local oldEye
 for _,angle in ipairs({math.pi/2-.001,math.pi/2+.001})do
  Abyss.swimAngle=angle;Abyss.swimDir=math.cos(angle)>=0 and 1 or -1;Abyss.buildBones()
  local eye=Abyss.bones[1]
  if oldEye then assert((eye.gx-oldEye.x)^2+(eye.gy-oldEye.y)^2<1,'Eye never jumps across its socket when direction changes')end
  oldEye={x=eye.gx,y=eye.gy}
 end
 local spine,upper,lower=Abyss.bones[2],Abyss.bones[3],Abyss.bones[4]
 assert(math.abs((upper.x-spine.x)*math.cos(spine.angle)+(upper.y-spine.y)*math.sin(spine.angle))<.001,'Ribs stay perpendicular to backbone in turns')
 assert(math.abs((upper.x+lower.x)*.5-spine.x)<.001 and math.abs((upper.y+lower.y)*.5-spine.y)<.001)
 reset();C.enter(Abyss,'traverse');player.x=0;player.y=500
 Abyss.swimHead.x=600;Abyss.swimHead.y=300;Abyss.swimAngle=0;Abyss.swimPath={};Abyss.buildBones();local before=#Abyss.bones
 assert(C.shedBone(Abyss) and #Abyss.debris==1,'Pursuit sheds one of its own ribs')
 Abyss.buildBones();assert(#Abyss.bones==before-1,'Shed rib disappears from body')
 assert(Abyss.debris[1].shed and Abyss.debris[1].stockId~=nil and Abyss.debris[1].armTime>0,'Dropped ribs retain their inventory identity and warning time')
 player.abyssGrace=20;C.update(Abyss,4.1);for _,p in ipairs(Abyss.debris)do assert(not p.life or p.life>0,'No expired rib remains')end
 reset();C.enter(Abyss,'spit');Abyss.cargoBlue=7;Abyss.cargoBones=9;C.spit(Abyss,.001)
 assert(#Abyss.plankton==0 and #Abyss.debris==9 and Abyss.cargoBlue==0 and Abyss.cargoBones==0,'All cargo expelled at once')
 local minX,maxX,minY,maxY=9999,0,9999,0
 for _,p in ipairs(Abyss.lumenParticles)do assert(not p.consumed and p.exhaled and p.scatter==0);minX=math.min(minX,p.tx);maxX=math.max(maxX,p.tx);minY=math.min(minY,p.ty);maxY=math.max(maxY,p.ty)end
 assert(maxX-minX>Arena.width*.8 and maxY-minY>450,'Particles scatter across whole arena');assert(#Abyss.bombs==6 and Abyss.bombs[1].flight==0,'Bombs are spat out too')
 C.spit(Abyss,.1);assert(#Abyss.debris==9,'Single burst')
 reset();C.enter(Abyss,'traverse');Abyss.swimHead.x=400;Abyss.swimHead.y=300;C.enter(Abyss,'exitSwim');player.abyssGrace=20
 C.update(Abyss,.15);local x=Abyss.swimHead.x;C.update(Abyss,.15);assert(math.abs(Abyss.swimHead.x-x)>math.abs(x-400),'Exit accelerates')
 C.update(Abyss,.249);assert(Abyss.swimHead.x< -900 or Abyss.swimHead.x>Arena.width+900,'Entire boss leaves screen')
 reset();Abyss.round=1;C.enter(Abyss,'rest');player.abyssGrace=20;C.update(Abyss,1);assert(Abyss.phase=='retreat','Repulsion happens only on first round')
 reset();local seen={};local roars=0;local last
 for _=1,1900 do
  player.abyssGrace=20;player.charges=1;Abyss.bombs={};player.x=600;player.y=450
  C.update(Abyss,.02);seen[Abyss.phase]=true;if Abyss.phase=='roar' and last~='roar' then roars=roars+1 end;last=Abyss.phase
 end
 for _,phase in ipairs({'traverse','bombRain','exitSwim'})do assert(seen[phase],'Complete cycle: '..phase)end
 assert(not seen.bones and not seen.suction,'New combat cycle replaces the horizontal barrage')
 assert(roars==0 and seen.openingSpit,'Opening expulsion replaces repulsion')
 reset();C.enter(Abyss,'traverse');player.abyssGrace=20
 local initialSpeed,initialMax=Abyss.swimSpeed,Abyss.swimMaxSpeed
 for _,b in ipairs(Abyss.bombs)do b.hit=true end
 Abyss.bombs[1].hit=false;Abyss.bombs[1].x=900;Abyss.bombs[1].y=50;Abyss.phaseTime=Abyss.passDuration+1
 C.update(Abyss,.01);assert(Abyss.phase=='traverse','Pursuit waits for the last bomb, regardless of timer')
 Abyss.bombs[1].hit=true;C.update(Abyss,.01);assert(Abyss.phase=='exitSwim' and Abyss.nextPhase=='bombRain','Last exploded bomb starts the new minefield phase')
 C.enter(Abyss,'traverse');assert(Abyss.swimSpeed==initialSpeed and Abyss.swimMaxSpeed==initialMax,'Phase changes do not regenerate bones or add artificial speed')
 Abyss.swimHead.x=400;player.x=500;player.y=400;C.transition(Abyss,'bones');assert(Abyss.exitDir==-1 and Abyss.exitY==100,'Exit heads away from player')
 local originalKill=Hazards.kill;Hazards.kill=function()error('Transition must not damage player')end
 for _,phase in ipairs({'exitSwim','returnHead','retreat'})do
  C.enter(Abyss,phase);player.abyssGrace=0;player.abyssSpit=nil;player.x=Abyss.head.x-15;player.y=Abyss.head.y-12;C.contact(Abyss)
 end
 Hazards.kill=originalKill
 C.enter(Abyss,'returnHead');assert(Abyss.returnFrom>Arena.width,'Top barrage enters from its nearby right edge')
 reset();for _,p in ipairs(Abyss.lumenParticles)do assert(p.consumed,'Arena starts without loose particles')end
 player.x=600;player.y=400;C.enter(Abyss,'openingSpit');C.update(Abyss,.1)
 assert(player.abyssSpit and player.abyssSpit.toX==Arena.width-65,'Spit sends player to far end')
 for _,b in ipairs(Abyss.bombs)do assert(player.abyssSpit.toX-b.tx>=200,'Bombs stay away from landing area')end
 C.update(Abyss,.81);assert(Abyss.phase=='traverse' and Abyss.swimDir==1 and Abyss.swimHead.x<60,'Immediate return on left after spit')
 assert(#Abyss.bombs==6 and Abyss.spitDone,'Opening burst scatters bombs and particles')
 reset();C.enter(Abyss,'bones');player.abyssGrace=20;C.update(Abyss,.35);assert(Abyss.volley==1);C.update(Abyss,.9);assert(Abyss.volley==1,'Full dodge interval between bone waves');C.update(Abyss,.15);assert(Abyss.volley==2,'Next wave resumes after dodge interval')
 reset();C.enter(Abyss,'traverse');Abyss.swimAngle=0;Abyss.swimHead.x=500;Abyss.swimHead.y=300
 Abyss.clock=0;Abyss.buildBones();local t0=Abyss.bones[#Abyss.bones].angle
 Abyss.clock=.2;Abyss.buildBones();assert(math.abs(Abyss.bones[#Abyss.bones].angle-t0)>.02,'Tail gently sways during swimming')
 Abyss.bombs={{x=510,y=312.6,r=15}};Abyss.lastMouthX=nil;Abyss.biteTime=.04
 Bombs.mouth(Abyss,566,312.6,.01);assert(Abyss.swallowBomb,'Bomb inside jaw is caught even immediately after previous bite')
 reset();C.enter(Abyss,'traverse');Abyss.swimHead={x=500,y=300};Abyss.swimAngle=math.pi/2
 local mx,my=C.swimMouth(Abyss);Abyss.lastMouthX=nil;Abyss.lastMouthAngle=nil
 Abyss.bombs={{x=mx-65,y=my,r=15}};Bombs.mouth(Abyss,mx,my,.01)
 assert(not Abyss.swallowBomb,'Bomb beside cheek is not swallowed through skull')
 Abyss.bombs={{x=mx-48,y=my-26,r=15}};Bombs.mouth(Abyss,mx,my,.01)
 assert(Abyss.swallowBomb,'Expanded rotated jaw catches bombs near its edge')
 reset();C.enter(Abyss,'bones');player.x=200;player.y=420;C.fireBones(Abyss)
 assert(#Abyss.debris==2,'Exactly two bones per wave')
 assert(math.abs(Abyss.debris[1].vx^2+Abyss.debris[1].vy^2-680^2)<.01,'Faster aimed bones')
 for _,p in ipairs(Abyss.debris)do local dx,dy=player.x+15-p.x,player.y+12-p.y
  assert(math.abs(dx*p.vy-dy*p.vx)<.001 and dx*p.vx+dy*p.vy>0,'Each bone aims at player position')
 end
 reset();C.enter(Abyss,'traverse');Abyss.swimAngle=0;local speed=Abyss.swimSpeed
 for i=1,6 do
  local mx,my=C.swimMouth(Abyss);for j,b in ipairs(Abyss.bombs)do if j==i then b.x=mx;b.y=my else b.x=2000;b.y=2000 end end
  Abyss.lastMouthX=nil;Abyss.biteTime=0;Bombs.mouth(Abyss,mx,my,0);Bombs.mouth(Abyss,mx,my,.21)
  assert(Abyss.swimSpeed>speed,'Each swallowed bomb accelerates the boss');speed=Abyss.swimSpeed
 end
 assert(math.abs(speed-567)<.01,'Six swallowed bombs reach just above player speed')
 reset();C.enter(Abyss,'traverse');Abyss.swimHead={x=600,y=300};Abyss.swimPath={};Abyss.swimAngle=0
 for _,case in ipairs({{x=400,y=100,side=-1},{x=400,y=500,side=1},{x=900,y=300,count=2}})do
  player.x=case.x-15;player.y=case.y-12;Abyss.debris={};Abyss.shedSerial=0
  local bodyCount=#Abyss.bones
  assert(C.shedBone(Abyss),'Shed case '..case.x..','..case.y..' bones '..#Abyss.bones);assert(#Abyss.debris==(case.count or 1),'Rib count follows player position')
  for _,b in ipairs(Abyss.debris)do
   assert(not case.side or b.side==case.side,'Rib comes from the side facing the player')
   assert(math.abs(b.vx*b.vx+b.vy*b.vy-640*640)<.01,'Pursuit bones travel much faster')
   local dx,dy=case.x-b.x,case.y-b.y;assert(b.tooth or (math.abs(dx*b.vy-dy*b.vx)<.001 and dx*b.vx+dy*b.vy>0),'Pursuit bones aim at player')
  end
  if case.count==2 then
   assert(Abyss.debris[1].tooth and Abyss.debris[2].tooth and not Abyss.debris[1].stockId,'Frontal attacks fire teeth instead of ribs')
   assert(#Abyss.bones==bodyCount,'Frontal tooth attacks leave the body stock intact')
   local mx,my=C.swimMouth(Abyss);for _,p in ipairs(Abyss.debris)do assert(math.abs(p.x-(mx-48))<.01 and math.abs(p.y-my)<=3 and Abyss.open,'Teeth originate at the back of the open mouth')end
  end
 end
 require('tests.bone_stock_revision').run(reset)
 require('tests.anemone_walls').run(reset)
 require('tests.crab_walls').run(reset)
 require('tests.bomb_rain').run(reset)
 require('tests.tooth_bombs').run(reset)
 local fx=require('abyss_light_fx');local p={x=player.x+25,y=player.y+12};local x0=p.x;fx.stir(p,.1);assert(p.x>x0 and p.wakeVx>0)
 player.x=900;player.y=500;local speed=p.wakeVx;fx.stir(p,.2);assert(p.wakeVx<speed,'Particles settle smoothly')
 reset();Abyss.boss=false;Abyss.giant=false;Realms.fireflies={{x=player.x+15,y=player.y+12,angle=0,turn=10,phase=1,radius=1}}
 Realms.updateFireflies(.1);assert(#Realms.fireflies==1,'Blue ambient particles move instead of disappearing')
 print('PASS dev revision: coherent historic victories, world-sorted bestiary, charged suction, bomb ingestion and player collision, whole-arena scatter, closed barrage, rapid transitions, articulated body and reactive motes')
 local tick=0;love.update=function()
  tick=tick+1;UI.clock=UI.clock+.1
  if tick==1 then reset();C.enter(Abyss,'bombRain');player.x=600;player.y=400;player.abyssGrace=10;C.update(Abyss,.6);App.capture='abyss-bomb-rain.png'
  elseif tick==2 then reset();C.enter(Abyss,'spit');Abyss.cargoBlue=7;Abyss.cargoBones=9;player.abyssGrace=10;C.update(Abyss,.14);App.capture='oct8-expulsion.png'
  elseif tick==3 then reset();Abyss.round=1;C.enter(Abyss,'traverse');Abyss.swimHead.x=Arena.width*.4;Abyss.swimHead.y=300;Abyss.swimAngle=.4;Abyss.buildBones();App.capture='oct8-steering.png'
  elseif tick==4 then
   reset();C.enter(Abyss,'traverse');Abyss.swimHead.x=600;Abyss.swimHead.y=300;Abyss.buildBones();local S=require('mobs.bosses.abyss.bone_stock')
   for _=1,28 do S.launch(Abyss,S.choose(Abyss,nil,false),640);Abyss.buildBones()end;Abyss.debris={};App.capture='abyss-head-only.png'
  elseif tick==5 then App.state='bestiary';for _,e in ipairs(Bestiary.entries)do Bestiary.seen[e.id]=true end;UI.bestCategory='boss';UI.bestSelected=Bestiary.list('boss')[1].index;UI.bestPage=1;App.capture='oct8-bestiary.png'
  elseif tick==6 then
   reset();C.enter(Abyss,'traverse');Abyss.swimHead.x=650;Abyss.swimHead.y=300;Abyss.buildBones();local S=require('mobs.bosses.abyss.bone_stock')
   S.launch(Abyss,S.choose(Abyss,nil,false),640);Abyss.buildBones();local p=Abyss.debris[1];p.recoverTime=0;p.angle=.7;p.x=650;p.y=300;S.recover(Abyss,p,850,300);Abyss.debris={};Abyss.buildBones();App.capture='abyss-planted-bone.png'
  elseif tick==7 then
   reset();C.enter(Abyss,'traverse');Abyss.swimHead={x=500,y=300};Abyss.swimAngle=0;Abyss.swimPath={};Abyss.bombs={{x=100,y=100,r=15}};player.x=850;player.y=288;player.abyssGrace=10;C.shedBone(Abyss);C.update(Abyss,.16);App.capture='abyss-mouth-teeth.png'
  elseif tick==8 then
   reset();Abyss.boss=false;Abyss.giant=false;Abyss.bones={};Abyss.debris={};Abyss.bombs={};Abyss.phase=nil;player.abyssGrace=0;player.x=400;player.y=320
   Realms.vents={{x=480,y=300,rx=30,ry=23},{x=580,y=350,rx=30,ry=23}};Arena.interior={{x=650,y=300,w=150,h=24,rotation=45}};Arena.walls=Arena.interior;Walls=Arena.walls;App.capture='anemone-rotated-wall.png'
  elseif tick==9 then love.event.quit()end
 end
end
return T
