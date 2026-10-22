local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Profile.save=function()end;Profile.record=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end
 Replay.disabled=true;Replay.playing=false;App.hardcore=false;App.practice=nil;Secret.duel=nil
 local json=require('json');local kill=Hazards.kill
 local layout={world=6,level=10,width=960,height=600,environment={lightning=false},entities={{kind='spawn',x=480,y=300},{kind='boss',type='storm',x=480,y=140}}}
 local function setup()
  require('boss_liberation').reset();App.sessionLayout=json.decode(json.encode(layout));App.singleLevel=true;LevelLayouts.disabled=false
  App.start(6);require('run_start').active=false;require('retry_wait').reset();Replay.input={0,0,true}
  return Bosses.items[1].boss
 end
 -- Cached erasure must match a fresh render, including removal without revision updates.
 local G=require('mobs.bosses.storm.ground');local g=love.graphics
 local function render(state)
  local c=g.newCanvas(Arena.width,600)
  g.push('all');g.setCanvas(c);g.origin();g.clear(0,0,0,0);G.draw(state);g.pop()
  local data=c:newImageData();local bytes=data:getString();data:release();c:release();return bytes
 end
 setup()
 local scars={holes={{x=140,y=160,tx=210,ty=170,radius=8},{x=200,y=170,tx=270,ty=180,radius=8},{x=700,y=450,tx=740,ty=450,radius=8}},groundRevision=0}
 local function checkGround()
  local actual=render(scars);local reference={holes=scars.holes,groundRevision=0}
  assert(actual==render(reference),'Cached holes must match fresh render after erasure')
  for _,v in pairs(reference.groundCache or {})do if type(v)=='userdata' and v.release then v:release()end end
 end
 checkGround();scars.holes[1].radius=4;checkGround()
 assert(scars.groundCache.distancePixels<scars.groundCache.distanceFullPixels*.4,'Local cleanup avoids a full-screen distance transform')
 print(string.format('MERLE_GROUND local cleanup uses %.1f%% of full-screen pixels',100*scars.groundCache.distancePixels/scars.groundCache.distanceFullPixels))
 scars.holes[1].radius=0;checkGround()
 table.remove(scars.holes,2);checkGround();scars.holes[1].radius=0;scars.holes[2].radius=0;checkGround()
 scars.holes[3]={x=480,y=200,tx=520,ty=210,radius=8};checkGround()
 scars.holes={};checkGround();scars.holes={{x=350,y=300,tx=390,ty=310,radius=8}};checkGround()
 local function flight(playerX)
  local boss=setup();local saved=Hazards.kill;Hazards.kill=function()end
  local route={}
  for tick=1,800 do
   player.x=playerX;player.y=560;boss.playerX=playerX+15;boss.playerY=572
   local angle=boss.angle;local phase=boss.phase;boss.update(1/120)
   if phase=='hunt' and boss.phase=='hunt' then
    local delta=(boss.angle-angle+math.pi)%(2*math.pi)-math.pi
    assert(math.abs(delta)<.021,'Flight turns remain gradual')
    assert(boss.x>0 and boss.x<Arena.width and boss.y>0 and boss.y<600,'Hunting flight remains in the arena')
   end
   route[tick]=string.format('%.9f,%.9f',boss.x,boss.y)
  end
  Hazards.kill=saved;return table.concat(route,';')
 end
 assert(flight(20)==flight(900),'Merle trajectory must not track the player')
 local lethal=setup();lethal.setPhase('hunt');lethal.x=480;lethal.y=300
 player.x=465;player.y=288;player.reset=false;lethal.contact();assert(player.reset,'Touching the Merle hurts the player')
 local b=setup();assert(b.wave==1 and #b.snails==1 and b.x<0,'First wave starts offscreen with one snail')
 Hazards.kill=function()end
 for _=1,180 do b.update(1/60)end
 assert(#b.holes>0,'Dragging excavates a narrow trail')
 assert(b.holes[1].radius==(require('cloud_snail').width+require('cloud_snail').mergeMargin)/2,'Hole radius halved')
 b.spawnSnails();local p=b.snails[1];local beforeX,beforeY=p.x,p.y
 b.angle=b.angle+.02;b.vx=0;b.vy=350;b.updateSnails(1/120)
 assert(math.sqrt((p.x-beforeX)^2+(p.y-beforeY)^2)<20,'Turn does not teleport the snail')
 local ax,ay=b.anchor();local dx,dy=p.x-ax,p.y-ay
 assert(math.sqrt(dx*dx+dy*dy)<p.rope*1.2,'Rope constrains sliding cargo')
 -- Capture the new fight with a curved trail and distinct small shell.
 local g=love.graphics;local c=g.newCanvas(Arena.width,600)
 g.push('all');g.setCanvas(c);g.origin();draw_level();b.draw();g.pop();c:newImageData():encode('png','storm-silk-fight.png');c:release()
 Hazards.kill=kill
 player.reset=false;player.x=p.x-15;player.y=p.y-12;b.contact();assert(player.reset,'Tethered snail is lethal')
 b=setup();Hazards.kill=function()end;b.setPhase('charge');b.x=600;b.y=300;b.angle=0;b.vx=300;b.vy=0
 p=b.snails[1];p.x=340;p.y=300;p.vx=100;p.vy=0
 local tailX,tailY=b.anchor();local crossX,crossY=(tailX+p.x)/2,(tailY+p.y)/2
 player.x=crossX-15;player.y=crossY-12;b.playerX=crossX;b.playerY=crossY;b.contact()
 assert(p.phase=='tethered','Stationary contact does not cut a moving rope for free')
 player.x=player.x+3;b.contact()
 assert(p.phase=='rise' and b.hp==10,'Crossing silk liberates the snail without direct damage')
 for i=1,300 do b.update(1/60);if b.hp<10 then break end end
 assert(b.hp==9 and p.phase=='spent','Freed snail rises and hits boss exactly once')
 -- Cleanup is now five broad dash passes, never a tour of individual scars.
 b.holes={{x=100,y=100,tx=120,ty=100,radius=7.74},{x=800,y=480,tx=820,ty=480,radius=7.74}}
 b.x=110;b.y=100;b.advanceWave=true;b.setPhase('clean');b.update(.01)
 assert(not b.holes[1].closing and not b.holes[2].closing,'Fog hold leaves holes intact until the dash')
 local passes={}
 for i=1,2400 do
  b.update(1/60)
  if b.cleanStage=='dash' then passes[b.cleanIndex]=true end
  if b.wave==2 then break end
 end
 for i=1,5 do assert(passes[i],'Five cleaning dashes cross the map') end
 assert(b.wave==2 and #b.snails==2 and #b.holes==0 and b.fogAmount==0,'Dashes seal trails, expel fog and return with two snails')
 local hp=b.hp;b.setPhase('hunt');player.throw={vx=1050,vy=0,time=1.5};player.x=b.x-15;player.y=b.y-12;b.contact()
 assert(b.hp==hp,'Direct tornado body impacts no longer damage the boss');player.throw=nil
 -- Complete a full four-wave encounter: 1+2+3+4 rescued snails.
 b=setup();Hazards.kill=function()end;local waves={};local maxTick=0;local captured=false
 for tick=1,10000 do
  b.update(1/60);waves[b.wave]=true
  if b.phase=='hunt' and b.phaseAge>.5 then
   if b.wave==3 and not captured then
    captured=true
    local canvas=g.newCanvas(Arena.width,600)
    g.push('all');g.setCanvas(canvas);g.origin();draw_level();b.draw();g.pop()
    canvas:newImageData():encode('png','storm-silk-wave-three.png');canvas:release()
   end
   for _,s in ipairs(b.snails)do b.cut(s)end
  end
  maxTick=tick;if b.defeated then break end
 end
 assert(b.defeated and b.hp==0 and waves[1] and waves[2] and waves[3] and waves[4],'All freed snails complete four escalating waves')
 Hazards.kill=kill;require('boss_liberation').reset()
 print('PASS silk Merle: physical cargo, lethal snails, cut silk, rising homing explosion, halved trails, fog-clearing dashes, escalating waves and victory ('..maxTick..' ticks)')
 love.event.quit()
end
return T
