local T={}
local C=require 'mobs.bosses.abyss.pattern_cycle'
local J=C.jaw
local function reset()
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
 Campaign.select(7);player.level=10;reset_level();App.state='playing';player.reset=false;shader_effect_timer=0
 return Abyss
end
local function grab(a)
 local x,y=J.target(a);assert(x,'Available tooth')
 assert(not J.blocked(a,x-15,y-12),'Tooth approach must be reachable: '..x..','..y)
 player.x=x-15;player.y=y-12;player.dashing=true;a.contact();assert(a.grab,'Dash catches tooth: reset='..tostring(player.reset)..' index='..tostring(J.available(a))..' player='..player.x..','..player.y..' target='..x..','..y)
end
function T.run()
 io.stdout:setvbuf('no')
 local a=reset();local px,py=C.pivot(a)
 assert(not a.open and a.bones[1].key=='skeleton_head' and #a.beams==0,'Encounter starts mouth closed without laser')
 a.update(1.21);assert(a.open and a.phase=='rest','Mouth opens before first laser')
 assert(px==65 and py==329,'Pivot at marked back of throat')
 assert(a.head.w==414 and a.head.h==504 and a.hp==10)
 for index,attack in ipairs(C.sequence) do
  a=reset();a.attackIndex=index;C.enter(a,'fire')
  assert(#a.beams==0 and #a.zones>=2,'Arena bands replace mouth lasers')
  local z=a.zones[1];local originalX,originalY=z.x,z.y
  a.phaseTime=.3;a.buildBones();assert(a.zones[1].x==originalX and a.zones[1].y==originalY,'Bands stay fixed')
  local sx,sy
  for y=80,540,20 do for x=280,Arena.width-50,20 do
   if not sx and not C.dangerAt(a,x,y) then sx,sy=x,y end
  end end
  assert(sx,'Each pattern leaves space for the player')
  player.x=sx-15;player.y=sy-12;C.draw(a);a.phaseTime=.5;a.contact()
  assert(not player.reset,'Dark spaces are safe with armed zones')
  z=a.zones[1];player.x=z.x+z.w/2-15;player.y=z.y+z.h/2-12
  a.contact();assert(player.reset,'Standing on white band kills')
 end
 a=reset();C.enter(a,'fire');local z=a.zones[1]
 player.x=z.x+z.w/2-15;player.y=z.y+z.h/2-12
 a.contact();assert(not player.reset,'Undrawn zones cannot kill')
 C.draw(a);a.contact();assert(not player.reset,'Short visible lead-in')
 a.phaseTime=.13;a.contact();assert(player.reset,'Visible zone becomes lethal')
 a=reset();C.enter(a,'gap');assert(#a.zones==0 and C.duration(a)>=1.6,'Clear interval for repositioning')
 a=reset();C.enter(a,'gap')
 local mx,my=a.mouth();assert(not willCollide(mx-15,my-12),'Mouth centre accessible')
 -- The collision tests the visible alpha mask, not the old rectangular corridor.
 local solid,empty=false,false
 for y=180,460,8 do for x=70,220,8 do
  if J.solid(a,x,y) then solid=true;assert(J.blocked(a,x-15,y-12),'Visible jaw blocks player')
  elseif not J.blocked(a,x-15,y-12) then empty=true end
 end end
 assert(solid and empty,'Both real bone and open cavity tested')
 assert(willCollide(80,40) and willCollide(80,540),'Cannot circle around skull')
 local move=Input.move
 grab(a);local hp=a.hp;Input.move=function() return -1,0 end;a.update(.1);assert(a.grab.progress==0,'Pull must be outward')
 Input.move=function() return 1,0 end;a.update(.46)
 assert(a.hp==hp-1 and not a.grab and a.removedTeeth[4],'Tooth costs exactly one life and stays removed')
 a.contact();assert(a.hp==hp-1 and J.available(a)~=4,'Removed tooth cannot be extracted again')
 for _=1,9 do C.enter(a,'rest');grab(a);a.update(.46) end
 assert(a.defeated and a.hp==0 and not objet.larme.taken,'Ten extractions defeat boss after teeth regrow')
 a=reset();C.enter(a,'gap');grab(a);a.phaseTime=C.duration(a)-.002;a.grab.progress=.99;a.update(.01)
 assert(a.hp==9 and not a.grab,'Extraction completes across a phase boundary')
 for _,phase in ipairs({'rest','fire','gap','bones','settle','suction','recover'}) do
  a=reset();C.enter(a,phase);assert(J.available(a),'Tooth available in '..phase)
  grab(a);a.update(.46);assert(a.hp==9 and not player.reset,'Extraction works during '..phase)
 end
 a=reset();C.enter(a,'rest');local tx,ty=J.target(a,6);player.x=tx-15;player.y=ty-12;player.dashing=true;a.contact()
 assert(a.grab and a.grab.index==6,'Any remaining tooth can be chosen without a fixed order')
 a.update(.46);assert(a.hp==9 and a.removedTeeth[6],'Chosen tooth deals one damage')
 Input.move=move
 a=reset();C.enter(a,'bones')
 for volley=1,8 do
  a.debris={};C.fireBones(a)
  local top,bottom=false,false
  for _,bone in ipairs(a.debris) do top=top or bone.y==40;bottom=bottom or bone.y==560 end
  assert(top and bottom and #a.debris==7,'Both borders covered with two inner dodge lanes')
 end
 a.plankton={};C.fireEnergy(a)
 local top,bottom=false,false
 for _,orb in ipairs(a.plankton) do top=top or (orb.y==44 and orb.vy==0);bottom=bottom or (orb.y==556 and orb.vy==0) end
 assert(top and bottom,'Blue energy reaches both borders')
 local shots=0;local fireEnergy=C.fireEnergy;C.fireEnergy=function(b) shots=shots+1;fireEnergy(b) end
 player.x=700;player.y=300;player.abyssGrace=10
 a.update(2.8);C.fireEnergy=fireEnergy
 assert(shots==3,'Reduced energy cadence: three waves in 2.8 seconds')
 a.plankton={};a.debris={};player.charges=0;player.electrified=0;a.refreshLight()
 local ellipse=love.graphics.ellipse
 for _,edgeY in ipairs({25,550}) do
  player.x=700;player.y=edgeY;local revealed=false
  love.graphics.ellipse=function(mode,x,y,rx,ry)
   if x==player.x+15 and y==player.y+8 and rx>=31 and ry>=31 then revealed=true end
   return ellipse(mode,x,y,rx,ry)
  end
  C.drawMask(a);assert(revealed and not Abyss.playerHidden(),'Uncharged player revealed at both borders without projectiles')
 end
 love.graphics.ellipse=ellipse
 a=reset();C.enter(a,'bones');player.abyssGrace=10;a.update(.4)
 assert(#a.debris>0 and #a.plankton>0,'Bones and blue energy retained')
 for _,p in ipairs(a.plankton) do assert(not p.red) end
 a=reset();C.enter(a,'bones');player.x=500;player.y=330
 for _=1,5 do a.plankton={{x=515,y=342,r=9,red=false}};a.contact() end
 assert(player.charges==3 and player.illuminated>0);Abyss.updatePlayer(120);assert(player.charges==3)
 a.debris={{x=515,y=342,w=58,h=17,vx=440}};a.contact();assert(player.reset)
 -- Collected light heals only upon capture; the player remains visible throughout.
 for charges=0,3 do
  a=reset();a.hp=3;a.removedTeeth={[1]=true,[2]=true,[3]=true}
  player.x=700;player.y=400;player.charges=charges;player.electrified=charges>0 and 60 or 0
  C.enter(a,'suction');local oldX=player.x
  assert(not Abyss.playerHidden() and Abyss.playerLightRadius()>0,'Player stays visible during suction')
  assert(player.charges==charges and a.hp==3,'Charges persist until capture')
  a.update(.1);assert(player.x<oldX and a.hp==3,'Suction draws player without healing remotely')
  for _=1,200 do a.update(.01);if a.phase=='recover' then break end end
  assert(not player.reset and a.phase=='recover' and player.abyssSpit,'Player is safely expelled')
  assert(a.hp==3+charges and player.charges==0,'One health restored per consumed charge')
  local missing=0;for _ in pairs(a.removedTeeth) do missing=missing+1 end
  assert(missing==3-charges,'Healed teeth regrow to keep encounter winnable')
  assert(not Abyss.playerHidden(),'Player remains visible after capture')
 end
 a=reset();a.hp=9;a.removedTeeth={[4]=true};player.charges=3
 C.enter(a,'suction');local mx,my=a.mouth();player.x=mx-15;player.y=my-12;a.update(.01)
 assert(a.hp==10 and player.charges==0 and not a.removedTeeth[4],'Healing capped at maximum health')
 a=reset();C.enter(a,'suction');player.x=500;player.y=330
 a.plankton={{x=515,y=342,r=9,red=false}};a.contact()
 assert(not player.reset and player.charges==1,'Blue energy remains collectible during suction')
 local draw=Characters.draw;local count=0;Characters.draw=function() count=count+1 end
 draw_player('right');Characters.draw=draw;assert(count>0,'Player sprite is rendered during suction')
 a.debris={{x=515,y=342,w=58,h=17,vx=440}};a.contact();assert(player.reset,'Bones remain lethal')
 a=reset();Bosses.load({{type='skeleton_fish',x=200,y=300},{type='skeleton_fish',x=400,y=300}},{},{})
 local custom=Bosses.items[1].boss;C.enter(custom,'fire');Bosses.resize(1.1);px,py=C.pivot(custom)
 assert(#custom.beams==0 and #custom.zones==4,'Custom bosses use arena zones after resize')
 custom.removedTeeth[1]=true;assert(not Bosses.items[2].boss.removedTeeth[1],'Tooth state independent')
 print('PASS white bands, safe spaces, reduced energy, teeth, visible player, collectible energy, suction, healing 0-3, health cap, regrowing teeth, expulsion, bones, custom bosses')
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1
  if frame==1 then a=reset();C.enter(a,'fire');player.x=600;player.y=288;App.capture='abyss-white-frame.png'
  elseif frame==2 then C.enter(a,'gap');App.capture='abyss-white-zone-gap.png'
  elseif frame==3 then C.enter(a,'gap');local x,y=J.target(a);player.x=x+25;player.y=y-12;App.capture='abyss-tooth-ready.png'
  elseif frame==5 then grab(a);a.grab.progress=.5;App.capture='abyss-tooth-pull.png'
  elseif frame==7 then Input.move=function() return 1,0 end;a.update(.25);Input.move=move;App.capture='abyss-tooth-removed.png'
  elseif frame==9 then a=reset();C.enter(a,'suction');player.abyssGrace=10;player.x=650;player.y=435;player.charges=2;player.electrified=60;a.update(.1);App.capture='abyss-visible-inhale.png'
  elseif frame==11 then a.update(1.4);App.capture='abyss-darkness-orbs.png'
  elseif frame==13 then C.enter(a,'recover');App.capture='abyss-darkness-recover.png'
  elseif frame==15 then a=reset();App.capture='abyss-closed-start.png'
  elseif frame==17 then a=reset();a.attackIndex=4;C.enter(a,'fire');player.x=500;player.y=435;App.capture='abyss-white-cross.png'
  elseif frame==19 then a=reset();C.enter(a,'bones');player.x=700;player.y=25;App.capture='abyss-visible-top.png'
  elseif frame==21 then player.y=550;App.capture='abyss-visible-bottom.png'
  elseif frame==23 then a.debris={};C.fireBones(a);C.fireEnergy(a);for _,p in ipairs(a.debris) do p.x=450 end;App.capture='abyss-edge-lanes.png'
  elseif frame==25 then love.event.quit() end
 end
end
return T
