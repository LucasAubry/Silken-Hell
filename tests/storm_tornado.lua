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
 player.x=435;player.y=288;b.playerX=450;b.playerY=300;b.contact()
 assert(p.phase=='tethered','Stationary contact does not cut a moving rope for free')
 player.x=438;b.contact()
 assert(p.phase=='rise' and b.hp==10,'Crossing silk liberates the snail without direct damage')
 for i=1,300 do b.update(1/60);if b.hp<10 then break end end
 assert(b.hp==9 and p.phase=='spent','Freed snail rises and hits boss exactly once')
 -- Cleanup cannot erase a distant scar before the bird reaches it.
 b.holes={{x=100,y=100,tx=120,ty=100,radius=7.74},{x=800,y=480,tx=820,ty=480,radius=7.74}}
 b.x=110;b.y=100;b.advanceWave=true;b.setPhase('clean');b.update(.01)
 assert(b.holes[1].closing and not b.holes[2].closing,'Only overflown holes close')
 for i=1,1800 do b.update(1/60);if b.wave==2 then break end end
 assert(b.wave==2 and #b.snails==2 and #b.holes==0,'Bird seals trails, leaves, and returns with two snails')
 local hp=b.hp;b.setPhase('hunt');player.throw={vx=1050,vy=0,time=1.5};player.x=b.x-15;player.y=b.y-12;b.contact()
 assert(b.hp==hp,'Direct tornado body impacts no longer damage the boss');player.throw=nil
 -- Complete a full four-wave encounter: 1+2+3+4 rescued snails.
 b=setup();Hazards.kill=function()end;local waves={};local maxTick=0
 for tick=1,10000 do
  b.update(1/60);waves[b.wave]=true
  if b.phase=='hunt' and b.phaseAge>.5 then
   if b.wave==3 then
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
 print('PASS silk Merle: physical cargo, lethal snails, cut silk, rising homing explosion, halved trails, local cleanup, escalating waves and victory ('..maxTick..' ticks)')
 love.event.quit()
end
return T
