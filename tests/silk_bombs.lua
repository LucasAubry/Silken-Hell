local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 local C=require('mobs.bosses.abyss.pattern_cycle');local B=require('mobs.bosses.abyss.bombs')
 local function reset()
  Replay.recording=false;Replay.input=nil;Replay.playing=false;Replay.ghost=false;App.sessionLayout=nil;App.state='playing';App.preview=false
  Campaign.select(7);player.level=10;reset_level();player.reset=false;player.falling=false;player.abyssGrace=0;require('run_start').active=false
  C.enter(Abyss,'traverse');Abyss.bombs={};Abyss.bones={};player.x=485;player.y=288
 end
 local function bomb(x,y,vx)
  return {x=x,y=y,r=15,attached=true,ropeLength=160,pickupGrace=0,clearedPlayer=true,vx=vx or 0,vy=0}
 end
 reset();local kill=Hazards.kill;local deaths=0;Hazards.kill=function()deaths=deaths+1 end
 Abyss.bombs={{x=500,y=300,r=15},{x=503,y=300,r=15}};B.player(Abyss)
 assert(Abyss.bombs[1].attached and Abyss.bombs[2].attached and deaths==0,'Passing over bombs attaches multiple silk threads safely')
 assert(Abyss.bombs[2].ropeLength==160 and Abyss.bombs[1].ropeLength==160,'Both threads have the same fixed length')
 local b=Abyss.bombs[1]
 for i=1,60 do player.x=485+i*4;B.update(Abyss,1/180)end
 assert(b.x>500 and b.vx>0,'Taut silk accelerates the bomb')
 local x=b.x;B.update(Abyss,1/180);assert(b.x>x,'Bomb keeps momentum when player stops')
 reset();local capturedDeaths=deaths
 Abyss.bombs={{x=510,y=300,previousX=450,previousY=300,r=15,flight=.6,vx=640,vy=0}}
 B.player(Abyss);local caught=Abyss.bombs[1]
 assert(caught.attached and not caught.flight and not caught.hit and deaths==capturedDeaths,'Incoming boss bomb is safely caught with silk')
 assert(caught.x==510 and caught.y==300,'Pickup never teleports the bomb')
 B.update(Abyss,.01);assert(caught.x==510 and caught.y==300,'Next physics step does not teleport a newly collected bomb');assert(caught.attached and not caught.hit and deaths==capturedDeaths,'Captured projectile switches to tether physics')
 reset();Abyss.bombs={bomb(462,300,600)};B.update(Abyss,.02)
 assert(not Abyss.bombs[1].hit and (Abyss.bombs[1].x-500)^2+(Abyss.bombs[1].y-300)^2>=39^2-.01,'Attached bomb cannot hit its carrier on braking')
 reset();player.x=85;local n=deaths;Abyss.bombs={bomb(32,300,-500)};B.update(Abyss,.01)
 assert(Abyss.bombs[1].hit and deaths==n,'Wall impact explodes without killing a distant player')
 reset();Abyss.bombs={bomb(560,300,400),bomb(588,300,-400)};B.update(Abyss,.005)
 assert(Abyss.bombs[1].hit and Abyss.bombs[2].hit,'Fast bomb collision explodes')
 reset();Abyss.bombs={bomb(560,300,5),bomb(588,300,-5)};B.update(Abyss,.005)
 assert(not Abyss.bombs[1].hit and not Abyss.bombs[2].hit,'Slow bomb contact is tolerated')
 reset();Abyss.bombs={bomb(700,300)};n=deaths
 assert(B.tooth(Abyss,{tooth=true,x=750,y=300},650,300))
 assert(Abyss.bombs[1].hit and deaths==n+1,'A tooth breaking an attached bomb kills its carrier')
 reset();local touches=Abyss.boneTouches;Abyss.boneTouches=function()return true end
 Abyss.bones={{x=750,y=300,w=80,h=80}};Abyss.bombs={{x=750,y=300,r=15}};local hp=Abyss.hp
 B.update(Abyss,.005);assert(Abyss.hp==hp-1 and Abyss.bombs[1].hit,'Contact with any boss bone deals exactly one damage')
 B.update(Abyss,.005);assert(Abyss.hp==hp-1);Abyss.boneTouches=touches
 reset();Abyss.bombs={{x=100,y=100,r=15,hit=true}};player.abyssGrace=10
 C.update(Abyss,.01);assert(Abyss.phase=='exitSwim' and Abyss.exitDir==1,'Empty arena sends boss right')
 C.update(Abyss,.6);assert(Abyss.phase=='bombRain' and Abyss.swimHead.x==Arena.width-35 and Abyss.open)
 C.update(Abyss,.4);assert(#Abyss.bombs==1);b=Abyss.bombs[1];local tx,ty=b.tx,b.ty
 player.x=650;player.y=420;C.update(Abyss,.5)
 assert(b.tx==tx and b.ty==ty,'Each shot locks the player position at launch')
 assert(Abyss.bombs[2].tx==665 and Abyss.bombs[2].ty==432,'Later shots take a fresh aim')
 C.update(Abyss,.6);assert(not b.flight and b.x==tx and b.y==ty,'Bomb stops at the old player position')
 C.update(Abyss,3);assert(Abyss.phase=='traverse' and #Abyss.bombs==2,'Boss resumes chasing after two targeted bombs')
 reset();Abyss.bombs={bomb(420,300)};b=Abyss.bombs[1];b.pickupGrace=100
 local by=b.y
 for i=1,200 do
  player.x=485+math.sin(i/100)*50;player.y=288+i*.7
  B.update(Abyss,1/180)
  assert(not b.hit,'Turning test remains safe')
  local dx,dy=b.x-Abyss.ropeAnchorX,b.y-Abyss.ropeAnchorY
  assert(dx*dx+dy*dy<=160^2+.01 and b.ropeLength==160,'Thread never stretches while turning')
 end
 assert(math.abs(b.y-by)>5,'Bomb follows turns with momentum')
 local function simulate(fps)
  reset();Abyss.bombs={bomb(420,300)};local b=Abyss.bombs[1];b.pickupGrace=100
  B.beginFrame(Abyss,1/fps)
  for i=1,math.floor(fps*.8)do
   local t=i/fps;player.x=485+240*t;player.y=288+90*math.sin(t*2)
   B.beginFrame(Abyss,1/fps)
   local steps=math.ceil(180/fps)
   for _=1,steps do B.update(Abyss,1/fps/steps)end
  end
  return b.x,b.y
 end
 local x30,y30=simulate(30);local x120,y120=simulate(120)
 assert((x30-x120)^2+(y30-y120)^2<8^2,'Bomb motion stays consistent at 30 and 120 FPS')
 reset();local calls=0;local original=Abyss.boneTouches
 Abyss.boneTouches=function(...)calls=calls+1;return original(...)end
 Abyss.swimHead={x=100,y=100};Abyss.buildBones();Abyss.bombs={{x=800,y=500,r=15},{x=850,y=500,r=15}}
 local started=love.timer.getTime()
 for _=1,1800 do B.update(Abyss,1/180)end
 print(string.format('Bomb CPU: %.2f ms for 1800 steps; distant pixel checks: %d',(love.timer.getTime()-started)*1000,calls))
 assert(calls==0,'Distant bones skip expensive pixel-mask collisions');Abyss.boneTouches=original
 C.togglePhysics(Abyss);assert(Abyss.physicsTest and #Abyss.bombs==2 and #Abyss.bones==0)
 local phase=Abyss.phase;local clock=Abyss.phaseTime;C.update(Abyss,.2)
 assert(Abyss.phase==phase and Abyss.phaseTime==clock and #Abyss.debris==0,'Disabled boss never moves or shoots')
 C.togglePhysics(Abyss);assert(not Abyss.physicsTest and #Abyss.bones>0,'Boss can be reactivated')
 Hazards.kill=kill
 print('PASS silk bomb physics: pickup, multiple tethers, inertia, wall/fast/slow contacts, blast range, teeth, boss damage and targeted reload')
 local tick=0;love.update=function()
  tick=tick+1
  if tick==1 then
   reset();Abyss.swimHead={x=250,y=300};Abyss.swimAngle=0;Abyss.buildBones();player.x=620;player.y=300
   Abyss.bombs={bomb(540,355),bomb(590,410)};Abyss.ropeAnchorX=620;Abyss.ropeAnchorY=312;App.capture='silk-bombs.png'
  elseif tick==2 then
   C.togglePhysics(Abyss);Abyss.bombs={bomb(560,350),bomb(590,380)};Abyss.ropeAnchorX=620;Abyss.ropeAnchorY=312;App.capture='silk-bombs-disabled.png'
  elseif tick==4 then love.event.quit()end
 end
end
return T
