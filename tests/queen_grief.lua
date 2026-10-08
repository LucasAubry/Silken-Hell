local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;Profile.recordBoss=function()end
 App.sessionLayout=nil;App.singleLevel=false;App.preview=false;App.practice=nil;App.hardcore=false;Secret.duel=nil;LevelLayouts.disabled=true
 App.state='playing';Campaign.select(3);player.level=1;reset_level();require('run_start').active=false;require('run_start').goAge=nil
 local F=require('final_spider');local A=require('final_art');local L=require('boss_liberation')
 local function baby(x,y,webbed,seed)return{x=x,y=y,webbed=webbed,seed=seed or 1,variant='red',age=1,angle=0}end
 local function setup(children,x,y,px,py)
  L.reset();F.reset(true);F.engaged=true;F.x=x or 150;F.y=y or 300;F.jumpCooldown=10
  player.x=(px or 650)-15;player.y=(py or 300)-12;player.reset=false;player.falling=false
  F.babies=children or {};F.trap(player);F.phase='charge';F.phaseTime=0;F.contactGrace=0
 end
 local function untilPhase(phase,dt)
  for _=1,400 do if F.phase==phase or player.reset or F.defeated then break end;F.update(dt) end
  assert(F.phase==phase and not player.reset,'Expected '..phase..', got '..F.phase..' (dead='..tostring(player.reset)..')')
 end
 for _,dt in ipairs({1/120,1/60,1/30,.2})do
  setup({baby(300,300,true,1),baby(400,300,false,2),baby(520,300,true,3)})
  untilPhase('mourn',dt)
  assert(#F.chargeDeaths==3 and #F.babies==0 and F.hp==10,'All touched children die; each killed child damages queen')
  local distance=((F.x-(player.x+15))^2+(F.y-(player.y+12))^2)^.5
  assert(distance>=43.99 and distance<45,'Queen stops near the player without contact')
  assert(F.snare==0 and F.target==nil and #F.webs==0,'Player is released for the grieving pause')
  local x,y=F.x,F.y;F.update(.4)
  assert(F.x==x and F.y==y and A.facing(F.visualAngle())=='left','She stops and turns towards the dead children')
  F.trap(player);assert(F.phase=='mourn','Webs cannot interrupt grief')
  local count=#F.chargeDeaths;F.update(.35);assert(#F.chargeDeaths==count and F.hp==10,'No repeated kills or HP damage')
  untilPhase('recoil_jump',dt);assert(not player.reset and F.jump)
  local startDistance=((F.x-(player.x+15))^2+(F.y-(player.y+12))^2)^.5
  F.update(.3);assert(F.jumpHeight>60 and not F.walkMoving,'Backward leap has an airborne pose')
  untilPhase('recover',dt)
  local endDistance=((F.x-(player.x+15))^2+(F.y-(player.y+12))^2)^.5
  assert(endDistance>startDistance+120 and F.jumpHeight==0 and F.grief==nil and #F.chargeDeaths==0,'Leap retreats safely and clears grief state')
 end
 setup({baby(300,300,false)});untilPhase('mourn',.02);assert(F.hp==12 and #F.chargeDeaths==1,'Even an untrapped child triggers grief')
 untilPhase('recover',.02);F.x=150;F.y=300;F.trap(player);F.phase='charge';F.contactGrace=0
 for _=1,80 do F.update(.02);if player.reset then break end end
 assert(player.reset and #F.chargeDeaths==0,'A later dash cannot reuse children killed by an earlier dash')
 setup({});for _=1,80 do F.update(.02);if player.reset then break end end
 assert(player.reset and F.phase=='charge' and #F.chargeDeaths==0,'A charge without a child kill stays lethal')
 setup({baby(700,300,true)});F.update(.7)
 assert(player.reset and not F.babies[1].dead and #F.chargeDeaths==0,'A child beyond the player cannot retroactively save them')
 setup({baby(580,300,true)});F.update(.7)
 assert(not player.reset and F.phase=='mourn' and #F.chargeDeaths==1,'A kill before contact protects the player within one large frame')
 setup({baby(300,500,true)});for _=1,80 do F.update(.02);if player.reset then break end end
 assert(player.reset and #F.chargeDeaths==0,'Children off the dash path do not trigger retreat')
 setup({baby(300,300,true)});untilPhase('mourn',.02)
 player.x=F.x-15;player.y=F.y-12;F.update(.3);assert(not player.reset,'Queen contact is harmless during the turn')
 untilPhase('recoil_jump',.02);player.x=F.x-15;player.y=F.y-12;F.update(.2);assert(not player.reset,'Queen contact is harmless during the retreat jump')
 F.reset(true);assert(not F.grief and #F.chargeDeaths==0 and not F.jump and F.jumpHeight==0,'Reset clears the whole sequence')
 for _,direction in ipairs({{150,300,650,300},{650,300,150,300},{400,100,400,490},{400,490,400,100}})do
  local x,y,px,py=unpack(direction)
  setup({baby((x+px)/2,(y+py)/2,true)},x,y,px,py);untilPhase('mourn',.02);F.update(.4)
  local look=math.atan2(F.grief.y-F.y,F.grief.x-F.x)-math.pi/2
  assert(A.facing(F.angle)==A.facing(look),'Looks toward corpses for every charge direction')
  untilPhase('recoil_jump',.02)
  local oldWidth=Arena.width;local oldX,oldTarget=F.jump.x,F.jump.tx
  F.resize(.8);assert(math.abs(F.jump.x-oldX*.8)<.001 and math.abs(F.jump.tx-oldTarget*.8)<.001,'Resizing keeps jump endpoints aligned');F.resize(1.25)
  untilPhase('recover',.02);assert(not player.reset and F.x>=55 and F.x<=Arena.width-55 and F.y>=75 and F.y<=525)
 end
 setup({baby(300,300,true)});F.hp=1;F.update(.2)
 assert(F.defeated and L.busy() and F.hp==0,'A finishing hit preserves the liberation sequence')
 L.reset()
 -- Draw-only effects leave combat state and the random stream unchanged.
 setup({baby(300,300,true)});untilPhase('mourn',.02);F.update(.65)
 local rng=love.math.getRandomState();local time=F.phaseTime;F.draw();assert(love.math.getRandomState()==rng and F.phaseTime==time)
 print('PASS queen grief: single/multiple/webbed/free children, chronological swept collision, 4 time steps, lethal untouched charges, look-back, safe pause/jump, four directions, resize/reset and finishing hit')
 local g=love.graphics;local gallery=g.newCanvas(1200,500)
 g.push('all');g.setCanvas(gallery);g.clear(.035,.025,.04,1)
 for i,dir in ipairs({'down','left','right','up'})do
  F.reset(true);F.x=0;F.y=0;F.phase='mourn';F.phaseTime=.82;F.carried=0
  F.angle=({down=0,left=math.pi/2,right=-math.pi/2,up=math.pi})[dir]
  g.push();g.translate(150+(i-1)*300,220);g.scale(3,3);F.draw();g.pop()
 end
 g.pop();gallery:newImageData():encode('png','queen-tear-directions.png');gallery:release()
 local frame=0
 love.update=function()
  frame=frame+1;UI.clock=UI.clock+.016
  if frame==1 then
   setup({baby(300,300,true,1),baby(410,300,true,2),baby(520,300,true,3)});untilPhase('mourn',.02);F.update(.76);App.capture='queen-grief-turn.png'
  elseif frame==3 then untilPhase('recoil_jump',.02);F.update(.28);App.capture='queen-grief-jump.png'
  elseif frame==5 then untilPhase('recover',.02);App.capture='queen-grief-land.png'
  elseif frame==7 then print('PASS queen grief visual captures');love.event.quit()end
 end
end
return T
