local T={}
local C=require 'mobs.bosses.abyss.pattern_cycle'
local function reset()
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
 Campaign.select(7);player.level=10;reset_level();App.state='playing';player.reset=false
 player.x=Arena.width-60;player.y=540;return Abyss
end
local function prepare(round)
 local b=reset();b.round=round or 1;C.enter(b,'traverse')
 local kill=Hazards.kill;Hazards.kill=function() end;C.update(b,2.6);Hazards.kill=kill;b.debris={}
 for i=2,#b.bones do local bone=b.bones[i]
  for y=math.max(35,bone.y-35),math.min(540,bone.y+35),5 do
   for x=math.max(40,bone.x-20),math.min(Arena.width-45,bone.x+20),5 do
    player.x=x-15;player.y=y-12
    if b.overlapsBone(bone) and not b.overlapsBone(b.bones[1]) then return b,x,y end
   end
  end
 end
 error('No accessible body collision found')
end
local function orb(x,y) return {x=x,y=y,vx=0,vy=0,r=9,red=false} end
function T.run()
 io.stdout:setvbuf('no')
 for round=1,2 do
  local b,x,y=prepare(round);assert(not b.open and b.bones[1].key=='skeleton_head','Closed swimming jaw')
  player.dashing=true;C.contact(b);assert(b.hp==9 and not player.reset and player.abyssKnock,'Dash inflicts one HP and safely recoils')
  for _=1,8 do player.dashing=true;C.contact(b) end;assert(b.hp==9,'Repeated contact cannot drain HP')
  for hp=8,0,-1 do
   player.x=Arena.width-60;player.y=540;C.contact(b);b.bodyHitCooldown=0
   player.x=x-15;player.y=y-12;player.dashing=true;C.contact(b);assert(b.hp==hp and not player.reset)
  end
  assert(b.defeated and not objet.larme.taken,'Ten separate body hits win')
 end
 local b=prepare();player.dashing=false;C.contact(b);assert(player.reset and b.hp==10,'Slow body contact is dangerous')
 b=reset();C.enter(b,'rest');local x,y=C.jaw.target(b);player.x=x-15;player.y=y-12;player.dashing=true;C.contact(b)
 assert(b.hp==10 and not b.grab,'Teeth no longer damage the boss')
 for _,phase in ipairs({'retreat','traverse','returnHead'}) do C.enter(b,phase);assert(not b.open and b.bones[1].key=='skeleton_head') end
 b=reset();C.enter(b,'bones');b.hp=5;player.charges=1;b.plankton={orb(player.x+15,player.y+12)};C.contact(b)
 assert(player.charges==2 and b.hp==5,'Collection alone never heals')
 C.enter(b,'suction');b.plankton={orb(player.x+15,player.y+12)};C.contact(b)
 assert(player.charges==2 and #b.plankton==1 and b.hp==5,'Suction forbids collection')
 b.charge(6);assert(player.charges==2,'Other energy sources cannot bypass suction lock')
 local mx,my=C.mouth(b);b.plankton={orb(mx,my)};C.update(b,.001);assert(#b.plankton==0 and b.hp==5 and player.charges==2,'Absorbed loose energy never heals')
 player.x=mx-15;player.y=my-12;C.suction(b,.01)
 assert(b.hp==7 and player.charges==0 and b.phase=='recover','Absorbed player heals one HP per carried charge')
 C.suction(b,.01);assert(b.hp==7,'Healing happens once')
 b=reset();b.hp=5;C.enter(b,'suction');mx,my=C.mouth(b);player.x=mx-15;player.y=my-12;C.suction(b,.01);assert(b.hp==5,'Uncharged player never heals')
 b=reset();b.hp=9;player.charges=3;C.enter(b,'suction');mx,my=C.mouth(b);player.x=mx-15;player.y=my-12;C.suction(b,.01);assert(b.hp==10 and player.charges==0,'Healing capped at maximum HP')
 print('PASS abyss damage: real body-mask impacts both directions, ten-hit victory, recoil/cooldown, closed moving jaw, dangerous slow contact, disabled tooth damage, blue pickup lock during suction, loose energy never heals, carried energy heals once with HP cap')
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1
  if frame==1 then b=prepare();player.dashing=true;C.contact(b);App.capture='abyss-body-charge.png'
  elseif frame==3 then love.event.quit() end
 end
end
return T
