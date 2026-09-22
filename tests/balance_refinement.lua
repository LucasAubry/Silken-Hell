local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;LevelLayouts.disabled=true
 Campaign.select(1);player.level=10;reset_level();App.state='playing'
 local b=Raven;local sequence={};local fire=b.fire
 b.fire=function(m) sequence[#sequence+1]=m.slot;fire(m) end
 local kill=Hazards.kill;Hazards.kill=function() end
 player.x=40;player.y=500
 for i=1,360 do b.update(1/60) end
 assert(#sequence>=7,'Shooters continue firing without egg hits')
 for i,slot in ipairs(sequence) do assert(slot==({1,3,5})[(i-1)%3+1],'Strict alternating shooter order') end
 b.fire=fire
 for hit=1,5 do b.hp=10-hit;b.hatch() end
 local followers=0;for _,m in ipairs(b.chicks) do if m.kind=='charger' then followers=followers+1 end end
 assert(followers==3 and #b.chicks==6,'At most three pursuing chicks')
 assert(b.featherSpeed==440)
 player.x=b.nests[1].x-15;player.y=b.nests[1].y-12;assert(Hazards.speed()==.4)
 Campaign.select(4);player.level=10;reset_level();player.x=90;player.y=400
 b=Octopus;b.inkPools={{x=player.x+140,y=player.y+12,rx=60,ry=65,life=10}}
 b.releaseCrabs();assert(#b.crabs>0)
 for _,c in ipairs(b.crabs) do
  local d=math.sqrt((c.x-player.x-15)^2+(c.y-player.y-12)^2)
  assert(d>=115 and d<=190,'Spawns remain near the player')
  assert(not Hazards.inEllipse(c.x,c.y,b.inkPools[1],20),'Crabs cannot emerge in ink')
 end
 local emerging=b.crabs[1];b.inkPools={{x=emerging.x,y=emerging.y,rx=50,ry=50,life=10}}
 b.updateCrabs(.1);for _,c in ipairs(b.crabs) do assert(c~=emerging,'Cancel emergence if fresh ink covers its site') end
 b.crabs={};b.inkPools={{x=player.x+15,y=player.y+12,rx=300,ry=300,life=10}};b.releaseCrabs();assert(#b.crabs==0,'No unsafe fallback when all nearby ground is inked')
 b.inkPools={}
 -- Static arms cannot be entered deliberately by a dry crab, from any direction.
 for i=0,23 do
  local a=i*math.pi/12;local c={x=b.x+math.cos(a)*220,y=b.y+math.sin(a)*220,speed=195,age=0,hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
  player.x=b.x-15;player.y=b.y-12
  if b.crabPathClear(c.x,c.y) then
   for frame=1,50 do b.walkCrab(c,1/60,function() b.crabContact(c) end);assert(not c.dead,'Dry crab must steer away from tentacles') end
  end
 end
 local layouts=require('json').decode(love.filesystem.read('tests/hell_cave_layouts.json'))
 LevelLayouts.disabled=false;Workshop.playLayout(layouts['2:10']);b=Bosses.items[1].boss
 assert(b.active and #b.bees==3 and Bosses.items[1].kind=='wasp')
 local draw=Art.drawFacing;local bees=0
 Art.drawFacing=function(key,...) if key=='wasp' or key=='wasp_ground' then bees=bees+1 end;return draw(key,...) end
 Bosses.draw(false);Bosses.draw(true);Art.drawFacing=draw
 assert(bees==3,'Saved Hell boss renders all three sisters')
 Workshop.playLayout(layouts['5:1']);assert(#Realms.rainSites==0,'No rain hazards in cave layouts')
 Realms.update(1);assert(#Realms.rain==0)
 local circle=love.graphics.circle;local bubbles=0
 love.graphics.circle=function(mode,x,y,r,...) if mode=='line' and r>=2 and r<=4 then bubbles=bubbles+1 end;return circle(mode,x,y,r,...) end
 Realms.drawGround();love.graphics.circle=circle;assert(bubbles==0,'Custom cave must not inherit ocean bubbles')
 assert(Atmosphere.settings(5,10).transmission>.5,'Brighter cave')
 Hazards.kill=kill
 print('PASS alternating shooters, follower cap, safe nearby crab spawns, dry arm avoidance, saved Hell boss draw, cave rain removal')
 local ticks=0
 love.update=function(dt)
  ticks=ticks+1;UI.clock=UI.clock+dt
  if ticks==1 then App.capture='refinement-earth.png'
  elseif ticks==3 then Workshop.playLayout(layouts['2:10']);App.capture='refinement-hell.png'
  elseif ticks==5 then Campaign.select(4);player.level=10;App.sessionLayout=nil;LevelLayouts.disabled=true;reset_level();App.capture='refinement-purple.png'
  elseif ticks==7 then Campaign.select(1);player.level=10;reset_level();App.capture='refinement-egg.png'
  elseif ticks==9 then io.stdout:flush();love.event.quit(0) end
 end
end
return T
