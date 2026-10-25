local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 LevelLayouts.disabled=true;App.preview=false;App.practice=nil;App.singleLevel=false;App.hardcore=false;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
 local H=require('history');local R=require('run_start');local V=require('ambient_motion')
 local save=Profile.save;Profile.save=function()end
 Profile.transitionsSeen=Profile.transitionsSeen or {};Profile.transitionsSeen['3']=true
 H.play('hell_renaissance')
 assert(R.arrivalKind=='renaissance' and not require('queen_boss_arrival').current(),'Fin is not replaced by the queen movie')
 for i=1,60 do love.update(1/30) end
 assert(R.arrival and R.scene().age>0 and not require('queen_boss_arrival').current())
 love.draw();H.close()
 for _,world in ipairs({1,2,3,4,5,6,7}) do
  for _,level in ipairs({1,5,10}) do
   App.practiceLevel(world,level,true)
   local before=V.offset;local elapsed=timer;local clock=Realms.clock;local rng=love.math.getRandomState()
   -- The actual particle system is userdata; inspect visual clocks and frozen simulation instead.
   for i=1,5 do R.advance(.04) end
   assert(V.offset>before and timer==elapsed and Realms.clock==clock and love.math.getRandomState()==rng,'Training ambience advances without starting gameplay')
   V.beginDraw();assert(timer>elapsed and Realms.clock>clock);V.endDraw()
   assert(timer==elapsed and Realms.clock==clock,'Draw restores simulation clocks')
  end
 end
 local bird=require('mobs.bosses.storm.init');bird.reset(true);bird.clock=.2;bird.x=500;bird.y=300
 bird.angle=math.pi/2-.001;local x1,y1=bird.anchor()
 bird.angle=math.pi/2+.001;local x2,y2=bird.anchor()
 assert((x2-x1)^2+(y2-y1)^2<1,'Tail anchor rotates continuously instead of mirroring')
 local draw=Art.draw;local width,angle
 Art.draw=function(key,x,y,w,a,...)if key=='merle_flight' then width,angle=w,a end end
 bird.phase='hunt';bird.angle=2;bird.draw();Art.draw=draw
 assert(width>0 and angle==2,'Bird rotates with its flight direction, never flips its texture')
 local hover=require('wasp_hover');assert(hover.offset(.1,1)~=hover.offset(.2,1))
 Profile.save=save
 print('PASS Cinematic motion: Fin priority, all training biomes at levels 1/5/10, frozen physics, restored clocks, continuous bird rotation, shared wasp hover')
 love.event.quit()
end
return T
