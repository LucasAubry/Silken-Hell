local T={}
local function reset(w)
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
 Campaign.select(w);player.level=10;reset_level();App.state='playing';player.reset=false;shader_effect_timer=0
end
function T.run()
 io.stdout:setvbuf('no');reset(6)
 local kill=Hazards.kill;local deaths=0;Hazards.kill=function() deaths=deaths+1 end
 local b=Storm;player.x=450;player.y=430;b.fire();b.fire();b.fire()
 assert(#b.projectiles==3 and not b.projectiles[1].golden and not b.projectiles[2].golden and b.projectiles[3].golden)
 player.dashing=true;player.lastMoveX=-1;player.lastMoveY=0
 local black={x=player.x+15,y=player.y+12,vx=280,vy=0,age=0,life=4,golden=false}
 b.projectiles={black};b.contact();assert(not black.returned and not b.canReflect(black))
 b.shot=100;b.bolt=100;local before=deaths;b.update(.001);assert(deaths>before,'Black feathers kill even while dashing head-on')
 local gold={x=player.x+15,y=player.y+12,vx=280,vy=0,age=0,life=4,golden=true}
 b.projectiles={gold};b.contact();assert(gold.returned,'Gold is reflectable')
 for _,heading in ipairs({{0,0},{1,0},{0,1},{-1,0}}) do
  player.dashing=false;player.lastMoveX=heading[1];player.lastMoveY=heading[2]
  local p={x=player.x+15,y=player.y+12,vx=280,vy=0,age=0,life=4,golden=true}
  b.projectiles={p};b.contact();assert(p.returned,'Every contact reflects gold, without a cooldown or heading requirement')
 end
 b.reset(true);b.setPhase('flightTell');b.phaseTime=100;player.x=450;player.y=350
 b.projectiles={};for i=1,3 do local p={x=player.x+15,y=player.y+12,vx=280,vy=0,age=0,life=4,golden=true};b.projectiles[i]=p;b.reflect(p) end
 local hp=b.hp
 for _=1,90 do b.update(.1) end
 assert(#b.projectiles==3 and b.hp==hp,'Collected feathers persist without homing or expiring')
 for _,p in ipairs(b.projectiles) do assert(math.abs(math.sqrt((p.x-player.x-15)^2+(p.y-player.y-12)^2)-88)<.01,'Feathers orbit the player') end
 player.x=player.x+100;b.contact();local p=b.projectiles[1];assert(math.abs(math.sqrt((p.x-player.x-15)^2+(p.y-player.y-12)^2)-88)<.01,'Orbit follows player movement')
 b.hidden=false;b.x=p.x;b.y=p.y;b.contact();assert(b.hp==hp-1 and #b.projectiles==2,'One orbiting feather deals one damage and is consumed')
 b.contact();assert(b.hp==hp-1,'One contact cannot drain multiple lives')
 b.reset(true);player.x=500;player.y=324;b.startX=440;b.endX=640;b.startY=400;b.endY=400;b.x=440;b.y=400;b.setPhase('flight')
 b.projectiles={{x=515,y=400,vx=0,vy=0,age=0,life=4,golden=true,returned=true,orbitAngle=math.pi/2,orbitRadius=88}}
 hp=b.hp;b.update(.08);assert(b.hp==hp-1 and #b.projectiles==0,'Fast dash still collides with an orbiting feather')
 b.reset(true);b.round=1;b.pass=0;b.setPhase('flightTell');b.setPhase('flight')
 assert(b.flightDuration<.5,'Dash crosses the arena in under half a second')
 b.phaseAge=b.flightDuration-.02;b.phaseTime=.02;b.x=b.endX-100;b.y=b.endY
 player.x=b.endX-55;player.y=b.endY-12;before=deaths;b.update(.03)
 assert(deaths>before,'Final dash segment still checks collisions before phase transition')
 b.hp=1;assert(b.speed()>4900,'Low-health dashes accelerate further')
 b.reset(true);b.shot=100;b.bolt=100;player.x=450;player.y=430
 local lastX,lastY=b.x,b.y;local maxStep=0
 for i=1,250 do
  if i==100 then player.x=100;player.y=100 end
  b.update(.02);maxStep=math.max(maxStep,math.sqrt((b.x-lastX)^2+(b.y-lastY)^2));lastX,lastY=b.x,b.y
 end
 assert(maxStep<13,'Orbit stays continuous when player changes position')
 b.reset(true);b.summon();b.shot=100;b.bolt=100;b.update(.9);assert(#b.holes>0 and b.charges==0)
 local hole=b.holes[1];local radius=hole.r;b.update(.1);assert(hole.r<radius)
 local dirs={};for i=1,4 do b.round=1;b.pass=i-1;b.setPhase('flightTell');dirs[b.dir]=true end
 assert(dirs.up and dirs.down and dirs.left and dirs.right)
 reset(7);local a=Abyss;local C=require 'mobs.bosses.abyss.light_cycle'
 assert(a.hp==6 and #a.octopuses==0 and #a.debris==0 and #a.lightTrail==0 and #a.lumenParticles==90)
 player.x=600;player.y=350;C.enter(a,'tell');local angle=a.beams[1].angle;local mx,my=a.mouth();before=deaths
 player.x=mx+math.cos(angle)*300-15;player.y=my+math.sin(angle)*300-12;a.contact();assert(deaths==before,'Warning is safe')
 a.update(.2);assert(a.beams[1].angle==angle,'Warning locks aim')
 C.enter(a,'fire');a.contact();assert(deaths>before,'Laser is lethal')
 before=deaths;player.x=600;player.y=520;a.contact();assert(deaths==before,'Outside laser is safe')
 a.volley=2;C.enter(a,'tell');assert(#a.beams==3,'Third volley forms a fan')
 C.enter(a,'suction');player.x=600;player.y=420;local x=player.x;C.suction(a,.03);assert(player.x<x)
 local move,slow=Input.move,Input.slow;Input.move=function() return 1,0 end;Input.slow=function() return false end
 x=player.x;App.move(.03);C.suction(a,.03);Input.move=move;Input.slow=slow;assert(player.x>x,'Running resists current')
 local particle=a.lumenParticles[1];particle.x=600;particle.y=350;local d=(particle.x-mx)^2+(particle.y-my)^2;a.update(.02)
 assert((particle.x-mx)^2+(particle.y-my)^2<d,'Particles follow suction')
 Hazards.kill=kill;player.x=mx-15;player.y=my-12;a.contact();assert(player.reset,'Suction mouth causes real death')
 Hazards.kill=function() deaths=deaths+1 end;reset(7);a=Abyss;C.enter(a,'recover');local tx,ty=C.target(a);player.x=tx-15;player.y=ty-12;player.dashing=false
 local hp=a.hp;a.contact();assert(a.hp==hp);player.dashing=true;a.contact();assert(a.hp==hp-1);a.contact();assert(a.hp==hp-1,'One hit per recovery')
 for _=1,5 do C.enter(a,'recover');a.contact() end
 assert(a.defeated and #a.bones==0 and not objet.larme.taken,'Combat has a working victory condition')
 reset(7);a=Abyss;local visits={}
 for i=1,2200 do player.x=650;player.y=510;player.dashing=false;a.update(.02);visits[a.phase]=true;assert(#a.lumenParticles==90 and #a.beams<=3) end
 for _,phase in ipairs({'rest','tell','fire','gap','inhaleTell','suction','recover'}) do assert(visits[phase],phase) end
 reset(6);Bosses.load({{type='skeleton_fish',x=200,y=300},{type='storm',x=500,y=170}},{},{})
 local custom=Bosses.items[1].boss;local old=custom.lumenParticles[1].x;Bosses.resize(1.1);assert(math.abs(custom.lumenParticles[1].x-old*1.1)<.001)
 Hazards.kill=kill
 print('PASS: black/gold feathers, persistent orbiting gold, contact damage and consumption, fast swept dashes, smooth orbit, closing holes, four directions; locked laser warning, lethal beams, fan, resistible suction, particles, recovery damage, victory, cycles, custom resize')
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1
  if frame==1 then reset(7);a=Abyss;player.x=650;player.y=400;a.volley=2;C.enter(a,'tell');a.phaseTime=.7;a.energy=.8;App.capture='abyss-simple-warning.png'
  elseif frame==3 then C.enter(a,'fire');App.capture='abyss-simple-lasers.png'
  elseif frame==5 then C.enter(a,'suction');local k=Hazards.kill;Hazards.kill=function() end;for _=1,40 do player.x=650;player.y=430;a.update(.02) end;Hazards.kill=k;App.capture='abyss-simple-suction.png'
  elseif frame==7 then C.enter(a,'recover');App.capture='abyss-simple-recovery.png'
  elseif frame==9 then reset(6);b=Storm;b.x=650;b.y=210;b.dir='left';b.projectiles={};for i=1,6 do b.projectiles[i]={x=350+i*55,y=320+math.sin(i)*35,vx=-220,vy=80,life=4,age=1,golden=i%3==0} end;App.capture='sky-two-feathers.png'
  elseif frame==11 then b.projectiles={};player.x=500;player.y=350;for i=1,3 do local p={x=515,y=362,vx=0,vy=0,age=0,life=4,golden=true};b.projectiles[i]=p;b.reflect(p);p.orbitAngle=i*math.pi*2/3;p.orbitRadius=88;p.x,p.y=b.orbitPosition(p) end;App.capture='sky-orbit-feathers.png'
  elseif frame==13 then b.round=1;b.pass=0;b.setPhase('flightTell');App.capture='sky-beak-right-larger.png'
  elseif frame==15 then b.round=1;b.pass=1;b.setPhase('flightTell');App.capture='sky-beak-left-larger.png'
  elseif frame==17 then love.event.quit(0) end
 end
end
return T
