local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 App.practice=1;App.start(6);require('run_start').active=false
 local N=require('cloud_snail');local W=require('sky_weather');local G=require('mobs.moth_gust');local F=require('mob_edge_fall');local D=require('hole_union_distance')
 Arena.walls={};Realms.holes={};W.reset();W.storm=false
 local g=love.graphics;local canvas=g.newCanvas(Arena.width,600)
 local function render()g.push('all');g.setCanvas(canvas);g.origin();N.drawTrail();g.pop() end
 N.trail(180,280,210,280,1);render()
 N.trail(210,280,220,282,1);render()
 assert(N.distancePixels<N.distanceFullPixels*.4,'Growing trails update a bounded region, not the entire screen')
 local localPixels=N.distanceResult:newImageData();local full={};D.build(N.union,full);local fullPixels=full.distanceResult:newImageData();local maxError=0
 for y=0,599,2 do for x=0,math.floor(Arena.width)-1,2 do
  local a=localPixels:getPixel(x,y);local b=fullPixels:getPixel(x,y);maxError=math.max(maxError,math.abs(a-b))
  assert((a>=.5)==(b>=.5),'Incremental update preserves hole coverage')
 end end
 assert(maxError<.025,'Incremental distances match a full rebuild: '..maxError)
 localPixels:release();fullPixels:release()
 local dirty={180,250,250,315}
 local function bench(region)
  local start=love.timer.getTime()
  for i=1,10 do D.build(N.union,full,region);local fence=full.distanceResult:newImageData(1,1,0,0,1,1);fence:release() end
  return (love.timer.getTime()-start)*100
 end
 local old=bench(nil);local fast=bench(dirty)
 print(string.format('Snail distance GPU + synchronization: full %.3f ms/frame, local %.3f ms/frame; processed pixels %.1f%%; max distance error %.4f',old,fast,100*full.distancePixels/full.distanceFullPixels,maxError))
 local snail={type='cloud_snail',x=Arena.width-1,y=300,age=0,speed=66,has_larme=true,hitBox_width=32,hitBox_height=30,hitBox_offset_x=-16,hitBox_offset_y=-15}
 local moth={type='mist_moth',x=Arena.width-100,y=300,age=1,phase='gust',phaseTime=2,vx=1,vy=0,hitBox_width=32,hitBox_height=30}
 mobs={moth,snail};objet.larme_dropped=false;player.x=100;player.y=100
 G.update(moth,.05);assert(snail.edgeFall~=nil and snail.falling,'Pushed snail falls as soon as it leaves the arena')
 assert(objet.larme_dropped and objet.larme.x>=0 and objet.larme.x<Arena.width-30,'Carrier tear stays reachable')
 F.update(snail,.6);assert(snail.edgeGone and snail.dead and not isTouching(player,snail),'Fallen creature disappears and loses collision')
 -- A nearby island across a hole is not a recoverable drop location.
 Realms.custom=true;Realms.holes={{x=Arena.width/2,y=300,rx=45,ry=320,points={0,-300,0,300}}}
 Arena.walls={};player.x=90;player.y=280;objet.larme_dropped=false
 local carrier={x=Arena.width/2+30,y=300,has_larme=true,falling=true}
 Campaign.dropTear(carrier)
 local tx,ty=objet.larme.x+15,objet.larme.y+20
 assert(tx<Arena.width/2-45,'Tear stays on the reachable side of the void')
 assert(require('tear_safe_drop').safe(tx,ty),'Dropped tear has room for the player away from holes')
 local previousX=objet.larme.x;Campaign.dropTear(carrier);assert(objet.larme.x==previousX,'Tear drops only once')
 for _,kind in ipairs({'wind_bat','mist_moth','dragonfly','waspling','ange','blackbird_chick'}) do
  local actor={type=kind,x=-20,y=200};assert(not F.check(actor) and not actor.falling,'Flying monster remains airborne: '..kind)
 end
 for _,kind in ipairs({'snake','spinner','worm','mole','lava_scorpion','crab'}) do
  local actor={type=kind,x=200,y=601};assert(F.check(actor),'Ground monster falls: '..kind)
 end
 -- Stress real collision queries used by the tear-drop search and gust substeps.
 Realms.holes={};W.holes={};W.snailHoles={};Arena.walls={};Realms.custom=true
 local H=require('ground_holes')
 for i=1,20 do
  local points={};local cx=90+(i%8)*(Arena.width-180)/8;local cy=180+math.floor((i-1)/8)*110
  for j=0,95 do local angle=j/95*math.pi*2;points[#points+1]=cx+math.cos(angle)*22;points[#points+1]=cy+math.sin(angle)*22 end
  local hole=H.stroke(points,10);Realms.holes[#Realms.holes+1]=hole;H.geometry(hole)
 end
 for i=1,1200 do N.trail(120+i%400,470+math.floor(i/400)*24,126+i%400,470+math.floor(i/400)*24,i%4) end
 player.x=90;player.y=60
 local drop=require('tear_safe_drop');local start=love.timer.getTime();local x,y=drop.position(Arena.width+3,300)
 local elapsed=(love.timer.getTime()-start)*1000
 assert(drop.safe(x,y),'Stress drop remains recoverable')
 print(string.format('Carrier drop stress: %.3f ms, 20 complex holes and 1200 trail samples',elapsed))
 local start=love.timer.getTime()
 for i=1,500 do Realms.fallAt(100+i%(Arena.width-200),120) end
 print(string.format('Wind collision stress: %.3f ms for 500 queries',(love.timer.getTime()-start)*1000))
 for _,hole in ipairs(Realms.holes) do
  for j=1,40 do
   local x=hole.x-50+(j*17)%100;local y=hole.y-50+(j*31)%100
   assert(H.contains(hole,x,y)==H.containsFast(hole,x,y),'Accelerated collision matches authored strokes and filled pockets')
  end
 end
 local shape=H.stroke({100,100,160,100,160,160,100,160,100,100},10)
 H.containsFast(shape,130,130);H.resize(shape,1.4)
 assert(H.contains(shape,182,130)==H.containsFast(shape,182,130),'Resized collision cache is invalidated')
 shape.rx=18;assert(H.contains(shape,150,140)==H.containsFast(shape,150,140),'Changed radii invalidate collision cache')
 local pushed={type='cloud_snail',x=180,y=120,age=0,has_larme=true,hitBox_width=32,hitBox_height=30,hitBox_offset_x=-16,hitBox_offset_y=-15}
 local blower={type='mist_moth',x=80,y=120,age=1,phase='gust',phaseTime=10,vx=1,vy=0,hitBox_width=32,hitBox_height=30}
 mobs={blower,pushed};objet.larme_dropped=false;local peak=0
 for i=1,180 do
  blower.y=pushed.y;local start=love.timer.getTime();G.update(blower,1/60);peak=math.max(peak,(love.timer.getTime()-start)*1000)
  if pushed.falling then break end
 end
 print(string.format('Wind-pushed carrier stress: peak %.3f ms per tick',peak))
 print('PASS wind/snail performance, incremental terrain equivalence, falling creatures, flying exemptions and reachable tears');love.event.quit()
end
return T
