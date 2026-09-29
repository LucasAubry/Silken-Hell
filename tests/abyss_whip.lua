local T={}
local C=require 'mobs.bosses.abyss.whip_cycle'
local function reset()
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
 Campaign.select(7);player.level=10;reset_level();App.state='playing';player.reset=false;shader_effect_timer=0
 return Abyss
end
function T.run()
 io.stdout:setvbuf('no')
 local a=reset()
 assert(a.hp==6 and a.head.x-a.head.w/2<0,'Head cropped on left')
 C.enter(a,'windup');a.update(.8);assert(a.head.y>460 and a.head.x==35)
 C.enter(a,'whip');player.abyssGrace=10;a.update(.35)
 assert(#a.bones>18 and #a.plankton>=6,'Whip skeleton and simultaneous energy')
 local minX,maxX=10000,-10000
 for _,b in ipairs(a.bones) do minX=math.min(minX,b.x);maxX=math.max(maxX,b.x) end
 assert(maxX>Arena.width-80 and minX<60,'Body spans arena')
 local ribX={};for _,b in ipairs(a.bones) do if b.key=='skeleton_spine' then ribX[#ribX+1]=b.x end end
 assert(ribX[2]-ribX[1]>70,'Passages between thin bones')
 a=reset();player.x=500;player.y=330
 for i=1,5 do a.plankton={{x=515,y=342,r=9,red=false}};a.contact() end
 assert(player.charges==3 and player.illuminated>0,'Blue charge capped at three and lights player')
 a.update(0);Abyss.updatePlayer(120);assert(player.charges==3,'Charges persist')
 a.plankton={{x=515,y=342,r=9,red=true}};a.contact();assert(player.reset,'Red energy kills')
 for charge=0,3 do
  a=reset();player.charges=charge;player.electrified=charge>0 and 60 or 0
  C.enter(a,'suction');local mx,my=a.mouth();player.x=mx-15;player.y=my-12;a.contact()
  if charge==0 then assert(player.reset,'Uncharged swallow kills')
  else assert(not player.reset and a.hp==6-charge and player.charges==0 and a.phase=='recover','One boss life per stored charge') end
 end
 a=reset();player.charges=1;player.electrified=60;player.x=Arena.width-60;player.y=520
 C.enter(a,'suction');local move=Input.move;Input.move=function() return 1,0 end
 local x=player.x;App.move(.1);assert(player.x==x and C.lockPlayer(a),'Input cannot resist suction');Input.move=move
 local particle=a.lumenParticles[1];particle.x=600;particle.y=400
 a.update(.1);assert(player.x<x and particle.x<600,'Player and light pulled together')
 for _=1,60 do a.update(.05);Abyss.updatePlayer(.05);if a.phase~='suction' then break end end
 assert(a.hp==5 and not player.reset and a.phase=='recover','Unavoidable swallow reaches mouth')
 a=reset();C.enter(a,'hide');player.abyssGrace=10;a.update(.66);assert(a.phase=='barrage' and a.head.x+a.head.w/2<0,'Boss disappears entirely left')
 a.update(.05);assert(#a.debris==4,'Broadside with escape lanes')
 local p=a.debris[1];local y=p.y;local old=p.x;a.update(.05);assert(p.y==y and p.x>old,'Bones move horizontally')
 player.abyssGrace=0;player.x=p.x-15;player.y=p.y-12;a.contact();assert(player.reset,'Bone projectile kills')
 a=reset();C.enter(a,'barrage');a.debris={{x=200,y=300,vx=520,w=58,h=17}};a.shotTimer=10;player.x=235;player.y=288;a.update(.2);assert(player.reset,'Fast projectile cannot tunnel')
 a=reset();player.charges=3;C.enter(a,'suction');local mx,my=a.mouth();player.x=mx-15;player.y=my-12;a.contact()
 player.abyssSpit=nil;player.abyssGrace=0;player.charges=3;C.enter(a,'suction');player.x=mx-15;player.y=my-12;a.contact()
 assert(a.defeated and a.hp==0 and #a.bones==0 and not objet.larme.taken and not C.lockPlayer(a),'Charged victory releases movement and reward')
 a=reset();local kill=Hazards.kill;Hazards.kill=function() end;local phases={}
 for _=1,1000 do player.abyssGrace=10;player.charges=1;a.update(.02);Abyss.updatePlayer(.02);phases[a.phase]=true end
 for _,phase in ipairs({'rest','windup','whip','retract','inhaleTell','suction','recover','hide','barrage','returning'}) do assert(phases[phase],phase) end
 Hazards.kill=kill
 a=reset();Bosses.load({{type='skeleton_fish',x=200,y=300}},{},{})
 local custom=Bosses.items[1].boss;player.charges=2;player.electrified=60;Abyss.updatePlayer(120);assert(player.charges==2)
 C.enter(custom,'suction');assert(Abyss.cagePlayer(),'Authored encounter also locks input')
 local before=custom.lumenParticles[1].x;Bosses.resize(1.1);assert(math.abs(custom.lumenParticles[1].x-before*1.1)<.01)
 print('PASS abyss whip: head, skeleton gaps, simultaneous energy, cap, red death, persistent charges, damage 1/2/3, unavoidable suction, particles, horizontal bones, swept collision, victory, full cycle, custom instance')
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1
  if frame==1 then a=reset();player.abyssGrace=10;C.enter(a,'windup');a.update(.84);C.enter(a,'whip');a.update(.38);player.x=500;player.y=430;player.charges=3;player.electrified=60;a.refreshLight();App.capture='abyss-whip.png'
  elseif frame==3 then C.enter(a,'retract');a.update(.76);C.enter(a,'suction');player.x=650;player.y=420;a.update(.15);App.capture='abyss-whip-suction.png'
  elseif frame==5 then C.enter(a,'hide');a.update(.66);a.update(.7);player.x=600;player.y=300;App.capture='abyss-whip-bones.png'
  elseif frame==7 then love.event.quit() end
 end
end
return T
