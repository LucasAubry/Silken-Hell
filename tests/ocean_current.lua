local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;App.singleLevel=true;App.practice=1;App.start(4);require('run_start').active=false
 local C=require('ocean_current');local H=require('ground_holes')
 local zone=H.stroke({200,200,600,200,600,400},45,'current');zone.dx=1;zone.speed=80
 local layout={world=4,level=1,width=960,height=600,entities={{kind='spawn',x=300,y=200},zone}}
 assert(require('layout_schema').validate(layout))
 assert(C.contains(zone,300,200) and not C.contains(zone,300,400),'Painted L preserves its empty outside')
 local vx,vy=C.velocity(300,200,0,0,{zone});assert(vx==80 and vy==0,'Idle drift')
 assert(C.velocity(300,200,-300,0,{zone})==-115,'Swimming upstream slows down')
 assert(C.velocity(300,200,300,0,{zone})==275,'Swimming with the flow remains slowed')
 assert(C.velocity(300,200,0,0,{zone,zone})==80,'Overlaps do not stack')
 assert(C.velocity(300,400,300,0,{zone})==300,'No effect outside painted footprint')
 vx,vy=C.velocity(600,300,0,0,{zone});assert(math.abs(vx)<.001 and vy==80,'Flow follows the vertical bend')
 zone.dx=-1;vx,vy=C.velocity(600,300,0,0,{zone});assert(math.abs(vx)<.001 and vy==-80,'Reverse follows the path backwards')
 assert(C.velocity(300,200,0,0,{zone})==-80,'Reversing changes horizontal arrows and force too')
 local loop=H.stroke({200,200,500,200,500,400,200,400,200,200},20,'current');assert(not C.contains(loop,350,300),'Closed paths do not fill their interior')
 zone.dx=1
 local px,py=300,200
 for i=1,360 do local fx,fy=C.velocity(px,py,0,0,{zone});px,py=px+fx/60,py+fy/60 end
 assert(math.abs(px-600)<15 and py>330,'An idle player follows the bend instead of leaving the channel')
 LevelLayouts.apply(layout);Realms.holes={};Realms.vents={};mobs={};Arena.walls={};Arena.interior={}
 local oldMove,oldSlow=Input.move,Input.slow;Input.move=function()return 0,0 end;Input.slow=function()return true end
 player.reset=false;local x=player.x;App.move(.1);assert(player.x>x+7.9,'Actual idle player is carried')
 player.x=285;player.y=188;Arena.walls={{x=330,y=100,w=20,h=200}}
 App.move(1);assert(player.x<330,'Drift respects walls with substeps')
 Input.move,Input.slow=oldMove,oldSlow;Arena.walls={}
 local shots=0;local zap=Realms.zap;Realms.zap=function()shots=shots+1 end
 mobs={};LevelLayouts.spawn({kind='mob',type='jelly',x=600,y=400,speed=0});local jelly=mobs[1]
 for i=1,59 do MobBehaviors.jelly.update(jelly,1/60) end;assert(shots==0)
 MobBehaviors.jelly.update(jelly,1/60);assert(shots==1,'First default discharge after one second')
 for i=1,210 do MobBehaviors.jelly.update(jelly,1/60) end;assert(shots==2,'Regular interval remains 3.5 seconds')
 Realms.zap=zap
 App.practice=7;App.start(6);require('run_start').active=false
 Realms.holes={};Realms.vents={};Realms.tornadoes={};require('sky_weather').reset();mobs={}
 player.x=400;player.y=288;player.reset=false;Aftermath.cleared=false
 LevelLayouts.spawn({kind='mob',type='cloud_beast',x=415,y=300,speed=330});local larva=mobs[1]
 local kill=Hazards.kill;local hits=0;Hazards.kill=function()hits=hits+1 end
 for _,flight in ipairs({'whirl','throw','skyWhirl','skyThrow'}) do
  player[flight]={}
  for _,phase in ipairs({'dive','hidden','emerge'}) do larva.phase=phase;Realms.contact();assert(hits==0,'Invisible larva cannot hit during '..flight..' / '..phase) end
  for _,phase in ipairs({'surface','charge'}) do larva.phase=phase;Realms.contact() end
  assert(hits==2,'Visible larva remains dangerous');hits=0;player[flight]=nil
 end
 Hazards.kill=kill
 local g=love.graphics;local canvas=g.newCanvas(960,600);local rng=love.math.getRandomState()
 local nearest=C.nearest;local queries=0
 C.nearest=function(...)queries=queries+1;return nearest(...)end
 g.push('all');g.setCanvas(canvas);g.origin();require('biome_floor').draw(4,960,600,2);C.draw(zone,2);g.pop()
 C.nearest=nearest;assert(queries==0,'Current particles never scan the full path for collision')
 assert(love.math.getRandomState()==rng);canvas:newImageData():encode('png','ocean-current.png');canvas:release()
 print('PASS ocean currents: brush footprint, drift, drag, direction, overlaps, walls, jelly timing; hidden larva safe in every tornado state')
 love.event.quit()
end
return T
