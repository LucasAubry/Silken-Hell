local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 local C=require('mobs.bosses.abyss.pattern_cycle');local M=require('mobs.bosses.abyss.web_charge')
 local function reset()
  App.abyssPhysicsTest=false;Replay.recording=false;Replay.input=nil;Replay.playing=false;App.sessionLayout=nil;App.state='playing';App.preview=false
  Campaign.select(7);player.level=10;reset_level();player.reset=false;require('run_start').active=false
  player.x=850;player.y=500;player.abyssGrace=10
 end
 reset();assert(Abyss.webMode and Abyss.hp==8 and #Abyss.bombs==0 and #Abyss.webAnchors==1)
 assert(Abyss.head.w==189,'Boss keeps a moderate proportional size')
 local sx,sy=Abyss.swimHead.x,Abyss.swimHead.y
 M.update(Abyss,.5)
 local distance=((Abyss.swimHead.x-sx)^2+(Abyss.swimHead.y-sy)^2)^.5
 assert(distance>85 and distance<100,'Pursuit restores its original 190 pixels per second speed')
 Abyss.webAnchors[2]={x=600,y=430,parts={}}
 local p,q=Abyss.webAnchors[1],Abyss.webAnchors[2]
 player.x=p.x-15;player.y=p.y-12;M.weave(Abyss);assert(Abyss.webHeld==1 and #Abyss.webLinks==0,'One bone only gives an unfinished thread')
 player.x=q.x-15;player.y=q.y-12;M.weave(Abyss);assert(#Abyss.webLinks==1,'Second bone completes a trap')
 M.weave(Abyss);assert(#Abyss.webLinks==1,'Standing on an anchor never duplicates a link')
 reset();Abyss.webAnchors={};Abyss.webLinks={};Abyss.swimHead={x=400,y=300};Abyss.swimAngle=0;Abyss.swimPath={};Abyss.buildBones()
 player.x=850;player.y=288;Abyss.webTimer=.001
 M.update(Abyss,.01);assert(Abyss.webCharge,'Boss starts a rapid charge')
 local angle=Abyss.swimAngle;player.y=450;M.update(Abyss,.01);assert(Abyss.swimAngle==angle,'Charge commits to one direction')
 local x=Abyss.swimHead.x;local hp=Abyss.hp;local count=#Abyss.bones;local wait=M.delay(Abyss)
 local anchor={x=x+70,y=300,parts={}};Abyss.webAnchors={anchor}
 M.update(Abyss,.08);assert(Abyss.hp==hp-1 and not Abyss.webCharge,'Swept collision stops the charge and removes one HP')
 assert(#Abyss.bones==count-1 and not Abyss.webTail,'First hit sheds the tail')
 assert(Abyss.swimHead.x<anchor.x and M.delay(Abyss)<wait,'Boss stops at impact and recovers sooner')
 local dropped=Abyss.webAnchors[#Abyss.webAnchors];local dx,dy=dropped.x,dropped.y
 hp=Abyss.hp;M.update(Abyss,.2);assert(Abyss.hp==hp and dropped.x==dx and dropped.y==dy,'Detached body stays put without repeated damage')
 reset();Abyss.swimHead={x=400,y=300};Abyss.swimAngle=0;Abyss.swimPath={};Abyss.buildBones()
 Abyss.webAnchors={{x=500,y=180,parts={}},{x=500,y=420,parts={}}};Abyss.webLinks={{a=1,b=2}};Abyss.webCharge=true;Abyss.webTimer=.8
 hp=Abyss.hp;M.update(Abyss,.08)
 assert(Abyss.hp==hp-1 and Abyss.webLinks[1].broken,'A completed silk trap catches the charge and snaps')
 reset();local hp=Abyss.hp
 for _=1,7 do Abyss.webCharge=true;M.hit(Abyss)end
 assert(Abyss.hp==1 and #Abyss.bones==1 and Abyss.webSegments==0,'Damage progressively dismantles the whole body down to its head')
 local killed=false;local kill=Hazards.kill;local overlaps=Abyss.overlapsBone
 Hazards.kill=function()killed=true end;Abyss.overlapsBone=function()return true end
 M.contact(Abyss);assert(killed,'Contact with the boss is lethal even between charges')
 Hazards.kill=kill;Abyss.overlapsBone=overlaps
 reset();Abyss.webAnchors={};Abyss.swimHead={x=500,y=300};Abyss.swimAngle=0;Abyss.swimPath={};Abyss.buildBones()
 player.x=700;player.y=400
 M.update(Abyss,.1);assert(Abyss.swimAngle>0,'Slow swimming turns toward the player')
 Abyss.webCharge=true;M.hit(Abyss)
 local wait=Abyss.webTimer
 assert(Abyss.webFlee>0,'Losing a body part starts a short escape')
 M.update(Abyss,.85)
 assert(not Abyss.webCharge and Abyss.swimHead.x<500,'Boss swims away after shedding a part')
 assert(Abyss.webTimer>wait-.02,'Escape finishes before the next charge countdown')
 M.update(Abyss,.1);assert(Abyss.webFlee==0 and Abyss.webTimer<wait,'Pursuit and charge countdown resume after escape')
 reset();C.togglePhysics(Abyss);local x=Abyss.swimHead.x;C.update(Abyss,.2);assert(Abyss.swimHead.x==x,'Test toggle still disables the boss');C.togglePhysics(Abyss)
 print('PASS bone/web charges: anchor pairing, committed dash, swept trap collision, stopped impact, permanent body drops, shorter recovery and lethal contact')
 reset()
 for _,heading in ipairs({0,.8,2.5,-2,math.pi})do
  Abyss.swimAngle=heading;Abyss.buildBones()
  local previous
  for _,bone in ipairs(Abyss.bones)do if bone.key=='skeleton_spine' then
   if previous then
    local d=((bone.x-previous.x)^2+(bone.y-previous.y)^2)^.5
    assert(d<=46*Abyss.webScale+.01,'Vertebrae stay connected through turns')
   else
    local nx=Abyss.head.x-math.cos(heading)*60*Abyss.webScale
    local ny=Abyss.head.y-math.sin(heading)*60*Abyss.webScale
    local d=((bone.x-nx)^2+(bone.y-ny)^2)^.5
    assert(math.abs(d-23*Abyss.webScale)<.01,'First vertebra stays attached to the neck')
   end
   previous=bone
  end end
 end
 local tick=0;love.update=function()
  tick=tick+1
  if tick==1 then
   reset();Abyss.webHeld=1
   player.x=700;player.y=440;App.capture='abyss-web-charge.png'
  elseif tick==2 then Abyss.webCharge=true;M.hit(Abyss);Abyss.webLinks={{a=1,b=2}};App.capture='abyss-web-detached.png'
  elseif tick==4 then love.event.quit()end
 end
end
return T
