local T={}
local C=require 'mobs.bosses.abyss.pattern_cycle'
local function reset()
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
 Campaign.select(7);player.level=10;reset_level();App.state='playing';player.reset=false
 player.x=Arena.width-60;player.y=300;return Abyss
end
local function body(b)
 b.phase='traverse';b.open=false;b.swimDir=1;b.swimY=140;b.swimHead.x=Arena.width-140;b.swimHead.y=140;b.phaseTime=3;b.passDuration=6;b.buildBones()
end
function T.run()
 io.stdout:setvbuf('no')
 local b=reset();assert(b.hp==10 and b.maxHp==10 and b.head.w==300 and b.head.h==365)
 body(b);assert(#b.bones==29 and b.bones[2].w==68 and C.targetPart(b)=='tail')
 local torso=b.bones[2];player.dashing=true;assert(not C.bodyContact(b,torso) and b.hp==10,'Body protected until tail gone')
 for hit=1,10 do
  body(b);local target=C.targetPart(b);local piece
  for _,v in ipairs(b.bones) do if v.part==target then piece=v;break end end
  assert(piece,'Next damage target exists')
  player.dashing=true;b.bodyHitCooldown=0;b.bodyContactLatched=false
  assert(C.bodyContact(b,piece));assert(b.hp==10-hit and b.damageProgress==hit)
  if hit<10 then
   body(b)
   if hit>=2 then for _,v in ipairs(b.bones) do assert(v.part~='tail') end end
   if hit==9 then assert(#b.bones==1 and C.targetPart(b)=='head') end
  end
 end
 assert(b.defeated and not objet.larme.taken,'Ten hits win')
 b=reset();b.damageProgress=6;b.hp=4;body(b);local count=#b.bones;b.hp=7;b.buildBones();assert(#b.bones==count,'Healing never regrows detached bones')
 -- Exercise the real pixel-mask contact path, not only the damage callback.
 b=reset()
 for hit=1,10 do
  local target=C.targetPart(b)
  local distance=target=='tail' and 770 or type(target)=='number' and (120+target*62) or 0
  body(b);b.swimHead.x=Arena.width*.45+distance;b.buildBones();b.debris={};b.bodyHitCooldown=0;b.bodyContactLatched=false
  local piece;for _,v in ipairs(b.bones) do if v.part==target and v.key~='skeleton_rib' then piece=v;break end end
  local found=false
  for yy=piece.y-40,piece.y+40,3 do
   for xx=piece.x-35,piece.x+35,3 do
    player.x=xx-15;player.y=yy-12
    local safe=b.overlapsBone(piece)
    for _,v in ipairs(b.bones) do if v.part~=target and b.overlapsBone(v) then safe=false end end
    if safe then found=true;break end
   end
   if found then break end
  end
  assert(found,'Vulnerable part remains physically accessible')
  player.dashing=true;C.contact(b);assert(b.hp==10-hit and not player.reset,'Actual weak-point contact removes one HP')
  C.contact(b);assert(b.hp==10-hit,'Repeated overlap does not remove extra HP')
 end
 assert(b.defeated)
 local kill=Hazards.kill;Hazards.kill=function() end
 for round=1,2 do
  b=reset();b.round=round;C.enter(b,'traverse');assert(b.swimY==(round==1 and 140 or 445))
  local seen,last=0,nil
  for i=1,700 do
   C.update(b,1/120)
   if b.lastDropX and b.lastDropX~=last then seen=seen+2;last=b.lastDropX end
   for _,p in ipairs(b.debris) do assert(math.abs(p.vy)==900 and (round==1 and p.vy>0 or round==2 and p.vy<0)) end
  end
  assert(seen>=12,'Dense spike volleys in both lanes')
 end
 b=reset();local phases={}
 for _=1,1500 do
  C.update(b,1/60);phases[b.phase]=true
  assert(b.phase~='fire' and #b.beams==0,'No laser phase')
 end
 assert(phases.bones and phases.suction and phases.spit and phases.recover,'Full cycle with exhale')
 Hazards.kill=kill
 b=reset();b.hp=5;player.charges=2;C.enter(b,'suction')
 local mx,my=C.mouth(b);player.x=mx-15;player.y=my-12;b.plankton={{x=mx,y=my,r=9,vx=0,vy=0}}
 C.suction(b,.01);assert(b.hp==7 and b.absorbed and b.phase=='suction' and not player.abyssSpit)
 b.debris={{x=mx,y=my,w=18,h=50,vx=0,vy=0}};player.x=mx-15;player.y=my-12
 C.update(b,.6);assert(b.phase=='spit' and player.abyssSpit and player.abyssSpit.duration==.7)
 C.update(b,.1);assert(#b.plankton>0 and #b.debris>0 and player.charges==0 and b.hp==7,'Progressive spit returns swallowed cargo without extra healing')
 local flight=player.abyssSpit;local fromX=flight.fromX;b.updatePlayer(.35);assert(player.x>fromX and player.x<flight.toX and player.abyssSpit,'Player follows a smooth ejection arc');b.updatePlayer(.36);assert(not player.abyssSpit and math.abs(player.x-flight.toX)<.01)
 local exhaled=0;for _,p in ipairs(b.lumenParticles) do if p.exhaled then exhaled=exhaled+1 end end;assert(exhaled>0 and exhaled<90)
 print('PASS tail progression: 10 HP, tail then seven sections then head, irreversible detachment, smaller head/unchanged body, upper/lower dense spikes, no lasers, complete cycle, healing once, smooth timed player spit and gradual cargo/light return')
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1
  if frame==1 then b=reset();b.round=2;C.enter(b,'traverse');local old=Hazards.kill;Hazards.kill=function() end;C.update(b,3);Hazards.kill=old;App.capture='abyss-lower-spikes.png'
  elseif frame==3 then b.damageProgress=5;b.hp=5;b.buildBones();App.capture='abyss-dismantled.png'
  elseif frame==5 then b=reset();C.enter(b,'suction');b.absorbed=true;b.cargoBlue=10;b.cargoBones=7;C.enter(b,'spit');for _=1,36 do C.update(b,1/60);b.updatePlayer(1/60) end;App.capture='abyss-natural-spit.png'
  elseif frame==7 then love.event.quit() end
 end
end
return T
