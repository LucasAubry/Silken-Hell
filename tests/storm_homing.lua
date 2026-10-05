local T={}
local function reset()
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
 Campaign.select(6);player.level=10;reset_level();App.state='playing';player.reset=false
 return Storm
end
local function gold(x,y) return {x=x,y=y,vx=280,vy=0,age=0,life=4,golden=true} end
function T.run()
 io.stdout:setvbuf('no')
 local b=reset();local counts={}
 for _,hp in ipairs({10,8,5,2}) do
  b.reset(true);b.hp=hp
  for i=1,60 do b.fire() end
  local n=0;for _,p in ipairs(b.projectiles) do
   if p.golden then n=n+1 end
   local speed=math.sqrt(p.vx*p.vx+p.vy*p.vy)
   assert(speed>=(255+110*(1-hp/10))*1.25,'Both feather colors travel noticeably faster')
  end
  counts[#counts+1]=n;assert(#b.projectiles==60 and n>0 and n<60,'Every health tier mixes black and gold feathers')
 end
 assert(counts[1]==40 and counts[2]==40 and counts[3]==24 and counts[4]==24,'Exactly two gold feathers per salvo, independent of health')
 b=reset();player.x=450;player.y=420;local p=gold(465,432);b.projectiles={p};player.dashing=false;b.contact()
 assert(p.returned and (p.vx~=0 or p.vy~=0),'Touch launches gold immediately without a dash')
 local oldX,oldY=p.x,p.y;player.x=80;b.shot=100;b.bolt=100;b.update(.02)
 assert(p.x~=oldX or p.y~=oldY,'Feather flies independently instead of orbiting player')
 for _=1,60 do b.update(.01);if #b.projectiles==0 then break end end
 assert(b.hp==9 and #b.projectiles==0 and not player.reset,'Collected feather deals exactly one HP')
 b=reset();b.setPhase('flightTell');b.phaseTime=100;player.x=450;player.y=400
 for i=1,3 do local f=gold(465,412);b.projectiles[i]=f;b.reflect(f) end
 for _=1,100 do b.update(.01);if #b.projectiles==0 then break end end
 assert(b.hp==7 and #b.projectiles==0,'Three simultaneous feathers each hit, including offscreen boss')
 b=reset();local f=gold(b.x,b.y);f.returned=true;b.hitGrace=1
 assert(b.featherHit(f) and b.hp==9 and not b.featherHit(f) and b.hp==9,'Spent feather cannot hit twice; each hit bypasses unrelated grace')
 b=reset();player.x=450;player.y=400;b.shot=100;b.bolt=100
 b.projectiles={{x=465,y=412,vx=0,vy=0,age=0,life=4,golden=false}};player.dashing=true;b.update(.001)
 assert(player.reset and not b.projectiles[1],'Black feather stays lethal')
 b=reset();b.featherSalvos=3;b.setPhase('return');b.setPhase('orbit');assert(b.featherSalvos==3,'Rarity cadence persists between rounds')
 b.setPhase('flightTell');b.phaseTime=100;player.x=450;player.y=400
 for i=1,10 do local f=gold(465,412);b.projectiles[i]=f;b.reflect(f) end
 for _=1,100 do b.update(.01);if b.defeated then break end end
 assert(b.defeated and b.hp==0 and #b.projectiles==0 and objet.larme.taken,'Ten collected feathers win and start liberation')
 require('boss_liberation').update(2)
 assert(not objet.larme.taken,'Reward appears after liberation')
 b=reset();Bosses.load({{type='storm',x=200,y=150},{type='storm',x=700,y=150}},{},{})
 local first,second=Bosses.items[1].boss,Bosses.items[2].boss
 first.hp=2;for _=1,5 do first.fire() end
 assert(first.featherSalvos==1 and second.featherSalvos==0 and second.hp==10,'Custom encounters retain separate feather cadence')
 local p=gold(first.x,first.y);p.returned=true;first.featherHit(p);assert(first.hp==1 and second.hp==10,'Returned feather damages its owner only')
 print('PASS sky boss: immediate gold homing, one HP per feather, simultaneous hits, offscreen pursuit, lethal black feathers, two gold feathers per salvo, persistent cadence, victory/reset, custom instances')
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1
  if frame==1 then b=reset();b.x=740;b.y=200;player.x=320;player.y=450;b.projectiles={}
   for i=1,10 do b.projectiles[i]={x=360+i*32,y=330+math.sin(i)*55,vx=-220,vy=100,age=1,life=4,golden=i==4} end
   App.capture='sky-black-feather-salvo.png'
  elseif frame==3 then b.projectiles={gold(450,390)};b.reflect(b.projectiles[1]);App.capture='sky-gold-return.png'
  elseif frame==5 then love.event.quit() end
 end
end
return T
