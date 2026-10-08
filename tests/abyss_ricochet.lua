local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 local R=require('mobs.bosses.abyss.ricochet');local F=require('mobs.bosses.abyss.charged_fish')
 local function reset()
  Replay.recording=false;Replay.input=nil;Replay.playing=false;App.sessionLayout=nil;App.state='playing';App.preview=false
  Campaign.select(7);player.level=10;reset_level();player.reset=false;require('run_start').active=false
  player.x=850;player.y=500;Abyss.returnPX=865;Abyss.returnPY=512
 end
 local function strike(id)
  for _,b in ipairs(Abyss.bones)do if b.part==id then R.hit(Abyss,b,{x=b.x,y=b.y,angle=0,tooth=true});return end end
 end
 reset();local lastSpeed,lastInterval=0,2
 for hp=8,1,-1 do
  Abyss.hp=hp;local speed,interval=R.pace(Abyss)
  assert(speed>lastSpeed and interval<lastInterval,'Every lost HP increases swimming speed and firing frequency')
  lastSpeed,lastInterval=speed,interval
 end
 reset();assert(Abyss.hp==8 and #Abyss.chargedFish==0 and #Abyss.lumenParticles==300)
 R.fire(Abyss);assert(Abyss.returnShots[1].lightning,'Opening volley offers a charge')
 R.fire(Abyss)
 local mx,my=Abyss.mouth();local teeth,bolts=0,0
 for _,p in ipairs(Abyss.returnShots)do
  assert((p.x-mx)^2+(p.y-my)^2<22^2)
  assert(math.abs(math.sqrt(p.vx*p.vx+p.vy*p.vy)-(p.lightning and 460 or 560))<.01)
  if p.tooth then teeth=teeth+1 else bolts=bolts+1;assert(math.abs(p.angle-Abyss.swimAngle)<.001,'Lightning travels straight ahead, never aimed at player') end
 end
 assert(teeth==1 and bolts==2,'Mixed volley fires teeth and lightning together')
 local B=require('mobs.bosses.abyss.bolt_motion')
 local bolt={x=100,y=100,vx=560,vy=0,life=5,bounces=0}
 local walls={{x=200,y=0,w=20,h=200},{x=0,y=0,w=20,h=200}}
 B.update(bolt,.2,walls);assert(bolt.bounces==1 and bolt.vx<0 and bolt.life>0,'First wall reflects lightning')
 B.update(bolt,.5,walls);assert(bolt.life>0 and bolt.bounces==2 and bolt.vx>0,'Second wall also reflects lightning')
 B.update(bolt,.5,walls);assert(bolt.life==0 and bolt.bounces==2,'Third wall absorbs lightning')
 local diagonal={x=100,y=100,vx=560,vy=0,life=5}
 B.update(diagonal,.3,{{x=200,y=40,w=20,h=120,rotation=45}})
 assert(diagonal.bounces==1 and math.abs(diagonal.vy)>500,'Rotated walls reflect with their actual normal')
 local killed=false;local kill=Hazards.kill;Hazards.kill=function()killed=true end
 for _,charged in ipairs({false,true})do
  reset();killed=false
  if charged then F.trigger(Abyss) end
  local p={x=865,y=512,vx=-560,vy=0,life=3,age=2,window=0,tooth=true,angle=0}
  Abyss.returnShots={p};R.update(Abyss,.01)
  assert(killed and not p.friendly and Abyss.hp==8,'Teeth kill even while charged and never damage the boss')
 end
 for _,angle in ipairs({0,math.pi/2,math.pi})do
  reset();killed=false;Abyss.swimAngle=angle;F.trigger(Abyss)
  local x,y=Abyss.mouth();player.x=x-15;player.y=y-12
  R.contact(Abyss)
  assert(killed and Abyss.hp==8,'Mouth contact kills a charged player in every orientation')
 end
 reset();killed=false
 local overlaps=Abyss.overlapsBone;local touching=true
 Abyss.overlapsBone=function(b)return touching and b.part=='head' end
 R.contact(Abyss);assert(killed,'Uncharged boss contact is lethal')
 killed=false;F.trigger(Abyss);local fishCount=#Abyss.chargedFish
 R.contact(Abyss)
 assert(not killed and Abyss.hp==7 and Abyss.fishCharge==0 and player.charges==0,'Charged ram removes one full HP and consumes the charge')
 assert(#Abyss.chargedFish==fishCount,'Fish keep pursuing after the discharge')
 local hx,hy=Abyss.swimHead.x,Abyss.swimHead.y
 local nx,ny=Abyss.returnKnockX,Abyss.returnKnockY
 assert(nx*(hx-player.x-15)+ny*(hy-player.y-12)>0,'Recoil points away from the charged player')
 Abyss.returnShotTimer=10;R.update(Abyss,.12)
 assert((Abyss.swimHead.x-hx)*nx+(Abyss.swimHead.y-hy)*ny>30000,'Boss visibly retreats immediately after a charged hit')
 assert(Abyss.returnKnockTime>0 and (Abyss.returnKnockX^2+Abyss.returnKnockY^2)<nx^2+ny^2,'Recoil eases progressively')
 R.contact(Abyss);R.contact(Abyss)
 assert(not killed and Abyss.hp==7,'Continuous overlap after impact is safe and cannot deal repeated damage')
 touching=false;R.contact(Abyss);touching=true;R.contact(Abyss)
 assert(not killed,'Brief separation during recoil does not cause an immediate lethal recontact')
 Abyss.clock=Abyss.clock+.6;touching=false;R.contact(Abyss);touching=true;R.contact(Abyss)
 assert(killed,'Returning uncharged to the boss is lethal')
 Abyss.overlapsBone=overlaps;killed=false
 for _,part in ipairs({'head',1,3,6,'tail'})do
  reset();killed=false;F.trigger(Abyss)
  Abyss.overlapsBone=function(b)return b.part==part end
  R.contact(Abyss)
  assert(not killed and Abyss.hp==7 and not Abyss.webTail and player.charges==0,'Any charged body contact damages once and consumes charge')
 end
 Abyss.overlapsBone=overlaps
 reset();local p={x=865,y=512,vx=560,vy=0,life=3,age=0,window=0,lightning=true,angle=0}
 Abyss.returnShots={p};R.update(Abyss,.01)
 assert(not p.friendly and #Abyss.returnShots==0 and Abyss.hp==8 and not killed,'Bolt is consumed without a counter or immediate death')
 assert(player.charges==1 and #Abyss.chargedFish==10,'Bolt charges the player and calls ten fish')
 local sides={};for _,f in ipairs(Abyss.chargedFish)do sides[f.side]=true end
 for i=1,4 do assert(sides[i],'Attackers arrive from every wall')end
 assert(F.visibility({x=0,y=0},500,500)==0 and F.visibility({x=490,y=500},500,500)==1,'Only eyes are shown until the fish is close')
 F.trigger(Abyss);F.trigger(Abyss);assert(#Abyss.chargedFish==10,'Repeated lightning never stacks overlapping schools')
 local first=Abyss.chargedFish
 Abyss.chargedFish={};F.trigger(Abyss)
 for i,f in ipairs(Abyss.chargedFish)do
  assert(f.x==first[i].x and f.y==first[i].y,'Same player position reproduces identical spawn positions')
 end
 for i=1,4 do
  local p,q=Abyss.chargedFish[i],Abyss.chargedFish[i+4]
  assert((p.x-q.x)^2+(p.y-q.y)^2>=230^2,'Each wall has a wide opening between its two fish')
  assert(q.delay-p.delay>.8,'Second row is delayed for breathing room')
 end
 player.x=400;player.y=300;Abyss.chargedFish={};F.trigger(Abyss)
 assert(Abyss.chargedFish[1].y~=first[1].y and Abyss.chargedFish[3].x~=first[3].x,'Formation follows the player position')
 player.x=850;player.y=500
 Abyss.chargedFish={{x=865,y=512,delay=0,age=0,life=2,angle=0,committed=true}}
 F.update(Abyss,.001,865,512);assert(killed,'Fish contact is lethal')
 local savedCharges=Abyss.fishCharge;Abyss.chargedFish={};F.update(Abyss,120,865,512);assert(player.charges==savedCharges and player.electrified>0,'Charge persists indefinitely until used')
 for _,count in ipairs({3,12})do
  reset();killed=false
  for i=1,count do F.trigger(Abyss)end
  F.update(Abyss,.01,865,512)
  assert(player.charges==count and Abyss.fishCharge==count,'Every lightning adds a persistent charge')
  Abyss.overlapsBone=function(b)return b.part=='head' end
  R.contact(Abyss)
  assert(not killed and Abyss.hp==math.max(0,8-count) and player.charges==0,'One ram consumes all charges and deals their combined damage')
  if count==3 then assert(not Abyss.webTail and Abyss.webSegments==4,'Multiple body pieces detach in the same impact')end
  Abyss.overlapsBone=overlaps
 end
 reset();for _,id in ipairs({'tail' ,6,5,4,3,2,1})do strike(id)end
 assert(Abyss.hp==1 and #Abyss.bones==1)
 player.x=Abyss.head.x-65;player.y=Abyss.head.y-12
 F.trigger(Abyss);Abyss.overlapsBone=function()return true end;R.contact(Abyss);Abyss.overlapsBone=overlaps; assert(Abyss.hp==0 and #Abyss.chargedFish==0 and player.charges==0,'Final charged ram ends the fight and clears attackers')
 assert(#Abyss.returnShots==0 and #Abyss.returnShards==0 and #Abyss.returnStuck==0 and player.abyssKnock==nil and Abyss.returnKnockTime==0,'Victory removes projectiles, bone fragments, embedded teeth and recoil immediately')
 R.fire(Abyss);assert(#Abyss.returnShots==0,'Dead boss cannot fire again')
 reset();local x=Abyss.swimHead.x;strike('tail');R.update(Abyss,.02)
 assert(Abyss.swimHead.x~=x,'Impact does not freeze swimming')
 reset();Abyss.returnShotTimer=10;Abyss.swimHead={x=Arena.width-2,y=250};Abyss.swimAngle=0;Abyss.returnTurn=0
 R.update(Abyss,.08);assert(Abyss.swimHead.x>Arena.width,'Boss can swim across arena walls without clamping')
 reset();strike(1);assert(Abyss.hp==8,'Middle vertebra cannot be removed before the tail')
 local function swim(px,py)
  reset();player.x=px;player.y=py;Abyss.returnPX=px+15;Abyss.returnPY=py+12;Abyss.returnShotTimer=100
  for i=1,240 do R.update(Abyss,1/120)end
  return Abyss.swimHead.x,Abyss.swimHead.y,Abyss.swimAngle
 end
 local ax,ay,aa=swim(60,500);local bx,by,ba=swim(850,500)
 assert(math.abs(ax-bx)<.001 and math.abs(ay-by)<.001 and math.abs(aa-ba)<.001,'Swimming route is independent of player position')
 reset();assert(Abyss.swimAngle==0,'Boss starts straight and upright')
 Abyss.returnShotTimer=100;Abyss.rearCooldown=100;Abyss.overlapsBone=function()return false end
 local visited={};local outside=false;local away,maxAway=0,0
 for i=1,2400 do
  R.update(Abyss,1/60);visited[Abyss.swimRouteIndex]=true
  local off=Abyss.swimHead.x<0 or Abyss.swimHead.x>Arena.width or Abyss.swimHead.y<0 or Abyss.swimHead.y>600
  outside=outside or off;away=off and away+1/60 or 0;maxAway=math.max(maxAway,away)
 end
 for i=1,#Abyss.swimRoute do assert(visited[i],'Boss completes horizontal, vertical and offscreen route leg '..i)end
 assert(maxAway<5,'Offscreen excursions stay brief: '..maxAway);print('Longest offscreen excursion: '..string.format('%.2f',maxAway)..'s')
 assert(outside,'Boss leaves the screen during its route');Abyss.overlapsBone=overlaps
 reset();Abyss.physicsTest=true;local x=Abyss.swimHead.x;R.update(Abyss,1);assert(Abyss.swimHead.x==x)
 Hazards.kill=kill
 local Wake=require('mobs.bosses.abyss.tooth_wake')
 local p={id=1,x=450,y=300,age=0,wakeVx=0,wakeVy=0};Abyss.lumenParticles={p}
 Wake.update(Abyss,1/60,{{ox=400,oy=300,x=500,y=300}})
 assert(math.abs(p.y-300)>=16.9,'Tooth wake still clears particles')
 reset();local Recoil=require('mobs.bosses.abyss.player_recoil')
 player.x=400;player.y=300
 Abyss.chargedFish={{x=495,y=312,angle=math.pi,delay=0,life=3,age=0}}
 Recoil.start(Abyss,1,0)
 local knock=player.abyssKnock
 assert(knock and knock.safeRecoil and math.abs(knock.vy)>1,'Player recoil chooses a clear direction instead of the fish ahead')
 local startX,startY=player.x,player.y
 Recoil.move(knock,knock.time)
 assert((player.x-startX)^2+(player.y-startY)^2>100 and player.abyssGrace>0,'Player is displaced and protected during release')
 assert(Recoil.clear(Abyss,player.x,player.y,0),'Recoil does not end on a fish or inside a wall')
 player.x=24;player.y=30;Abyss.chargedFish={};Recoil.start(Abyss,-1,0)
 if player.abyssKnock then Recoil.move(player.abyssKnock,player.abyssKnock.time)end
 assert(not Arena.blocked(player.x,player.y,30,24),'Recoil near arena edge stays inside the walls')
 reset();local Escape=require('mobs.bosses.abyss.rear_escape');local tail=Abyss.bones[#Abyss.bones]
 for i=1,20 do Escape.update(Abyss,.01,Abyss.head.x+100,Abyss.head.y)end
 assert(not Abyss.rearEscape,'Standing in front does not trigger the rear escape')
 local px,py=tail.x-math.cos(tail.angle)*70,tail.y-math.sin(tail.angle)*70
 local aim,speed,rate
 for i=1,20 do aim,speed,rate=Escape.update(Abyss,.01,px,py)end
 assert(Abyss.rearEscape and speed==390 and rate==0 and aim==Abyss.swimAngle,'Approaching behind triggers a straight acceleration')
 local lockedX,lockedY=Abyss.rearEscape.x,Abyss.rearEscape.y
 for i=1,50 do aim,speed,rate=Escape.update(Abyss,.01,px+300,py+200)end
 assert(rate==2.8 and speed==270 and Abyss.rearEscape.x==lockedX and Abyss.rearEscape.y==lockedY,'Return curve targets the captured position without tracking the player')
 for i=1,150 do Escape.update(Abyss,.01,px,py)end
 assert(not Abyss.rearEscape and Abyss.rearCooldown>0,'Escape ends and cannot immediately retrigger')
 reset();strike('tail');Escape.setup(Abyss)
 local rear
 for _,b in ipairs(Abyss.bones)do if b.part==6 and b.key=='skeleton_spine' then rear=b end end
 for i=1,20 do Escape.update(Abyss,.01,rear.x-math.cos(rear.angle)*70,rear.y-math.sin(rear.angle)*70)end
 assert(Abyss.rearEscape,'Rear detection stays correctly oriented after the tail is lost')
 local Star=require('abyss_light_fx')
 local star={x=100,y=110}
 Star.stir(star,.016,{{x=160,y=100,ox=40,oy=100,radius=60}})
 assert(star.wakeVy>0 and star.starVisibility<.5,'Fast crossing creates a swirling dark wake without skipping stars')
 local drift=star.wakeVx^2+star.wakeVy^2
 Star.stir(star,.1,{})
 assert(star.wakeVx^2+star.wakeVy^2<drift,'Stars settle once the actor has passed')
 print('PASS charged rams: lethal teeth with/without charge, lethal uncharged boss contact, one HP per charge, charge consumption, safe separation, persistent fish, lightning summons, head finish and particle wake')
 local ticks=0
 love.update=function()
  ticks=ticks+1
  if ticks==1 then
   reset();R.fire(Abyss);F.trigger(Abyss)
   Abyss.returnShots[1].x=740;Abyss.returnShots[1].y=450
   Abyss.returnVolley=2;R.fire(Abyss)
   for i,f in ipairs(Abyss.chargedFish)do f.delay=0;f.x=player.x+math.cos(i*math.pi/6)*(i%2==0 and 125 or 230);f.y=player.y+math.sin(i*math.pi/6)*(i%2==0 and 125 or 230);f.angle=math.atan2(player.y-f.y,player.x-f.x)end
   App.capture='abyss-teeth-lightning.png'
  elseif ticks==3 then love.event.quit()end
 end
end
return T
