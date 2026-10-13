local T={}
function T.run()
 local motion=require('render_motion');local g=love.graphics
 Online.enabled=false;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end
 App.singleLevel=true;App.practice=9;App.start(1)
 require('run_start').active=false
 local actor={x=100,y=100};local originalPlayer,originalMobs=player,mobs
 local move,slow=Input.move,Input.slow
 Input.move=function()return 1,0 end;Input.slow=function()return true end
 player=actor;mobs={actor}
 -- Exercise the actual recorder at several display rates. After the first tick,
 -- every displayed position must advance at the same speed, including frames
 -- on which no physics tick occurred.
 for _,fps in ipairs({60,120,144,400}) do
  Replay.frame=0;Replay.accumulator=0;Replay.recording=true;Replay.playing=false;Replay.disabled=false
  Replay.data.inputs={};Replay.data.checks={};Replay.data.frames=0
  actor.x=100;actor.y=100;actor.level=9;actor.death=0;motion.reset()
  local previous,frames=0,0
  for i=1,math.floor(fps*.5) do
   Replay.update(1/fps,function(dt)motion.capture();actor.x=actor.x+120*dt end)
   local dx,dy=motion.offset(actor);local visual=actor.x+dx
   if i>math.ceil(fps/60)+1 then
    assert(math.abs(visual-previous-120/fps)<1e-7,'Uneven presentation at '..fps..' FPS')
    frames=frames+1
   end
   assert(dy==0);previous=visual
  end
  assert(frames>0)
  print('PASS smooth movement at '..fps..' FPS with unchanged 60 Hz simulation')
 end
 motion.capture();actor.x=actor.x+100
 assert(motion.offset(actor)==0,'Teleports must not sweep across the arena')
 motion.capture();actor.x=actor.x+2;Replay.accumulator=0
 assert(motion.offset(actor)==-2)
 Replay.paused=true;assert(motion.offset(actor)==0);Replay.paused=false
 motion.reset();assert(motion.offset(actor)==0,'Respawns must discard previous positions')
 player,mobs=originalPlayer,originalMobs
 Input.move,Input.slow=move,slow
 App.start(1)
 motion.capture();player.x=player.x+2;mobs[1].x=mobs[1].x+1;Replay.accumulator=Replay.step*.5
 local before=LevelLayouts.snapshot();local json=require('json');before=json.encode(before)
 local rng=love.math.getRandomState();local x,y=player.x,player.y
 local tx,ty=g.transformPoint(0,0)
 love.draw()
 assert(player.x==x and player.y==y,'Rendering cannot modify the collision position')
 assert(json.encode(LevelLayouts.snapshot())==before,'Rendering cannot modify entities')
 assert(love.math.getRandomState()==rng,'Rendering cannot consume gameplay randomness')
 local ax,ay=g.transformPoint(0,0);assert(ax==tx and ay==ty,'Rendering must restore transforms')
 reset_level();assert(motion.offset(player)==0,'Level reset must clear interpolation')
 print('PASS presentation isolation: teleports, pauses, respawns, collision state, RNG and graphics transforms')
 io.stdout:flush();love.event.quit()
end
return T
