local T={}
local F=require 'psychedelic_fx'
local function setup()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 LevelLayouts.disabled=true;Profile.save=function()end;Bestiary.save=function()end
 Profile.character=1;Profile.name='Essai psychédélique';Profile.language='fr';Profile.unlocked=7
 Graphics.psychedelic=2;Graphics.showFPS=false;App.hardcore=false
 App.practice=9;App.singleLevel=true;App.start(1);love.focus=function()end
end
function T.demo()
 setup()
 local key=love.keypressed
 love.keypressed=function(k,...)
  if App.state=='playing' and k=='f7' then Hazards.kill();App.resolveDeath();return end
  if App.state=='playing' and k=='f8' then F.collect(player.x+15,player.y+12);return end
  key(k,...)
 end
 love.window.setTitle('Silken Hell · Psychédélique · F7 mort · F8 larme')
 print('Essai psychédélique ouvert : déplacement rapide, F7 mort, F8 aperçu larme. Réglage dans Graphismes.')
end
function T.run()
 setup()
 local g=love.graphics;local move,slow=Input.move,Input.slow
 Input.move=function() return 0,0 end;Input.slow=function() return false end
 local randomState=love.math.getRandomState()
 local deaths=player.death
 Hazards.kill();assert(F.deathPulse,'Real death must trigger a pulse')
 local impact=F.deathPulse;App.resolveDeath()
 assert(player.death==deaths+1 and F.deathPulse==impact and not player.reset,'Pulse must survive immediate respawn')
 App.resolveDeath();assert(player.death==deaths+1)
 F.update(.8);assert(not F.active(),'Death pulse must end')
 -- Slow movement and blocked movement must not produce a speed tunnel.
 player.dashing=true
 for _=1,60 do F.update(1/60);F.motion(0,0,1/60) end
 assert(F.speed<.001)
 for _=1,60 do F.update(1/60);F.motion(4,0,1/60) end
 assert(F.speed<.001)
 for _=1,60 do F.update(1/60);F.motion(9,0,1/60) end
 assert(F.speed>.6)
 F.update(2);assert(not F.active(),'Speed effect must settle after stopping')
 assert(love.math.getRandomState()==randomState,'Visuals cannot consume gameplay random numbers')
 -- Use the real collection path, including the immediate level reset.
 local function collect(single)
  App.singleLevel=single;Campaign.select(1);player.level=1;reset_level();F.reset()
  mobs={};Campaign.carrier=nil;objet.larme.taken=false;objet.larme_dropped=true
  player.x=objet.larme.x;player.y=objet.larme.y;App.state='playing';larme_timer=0
  App.simulate(1/60)
  assert(F.pickupPulse,'Real tear pickup must trigger a pulse')
  assert(single and App.state=='customVictory' or not single and player.level==2,'Collection must retain normal progression')
 end
 collect(false);F.update(.15);assert(F.pickupPulse)
 collect(true);love.update(.2);assert(F.pickupPulse and F.pickupPulse.age>=.2,'Final pickup must animate in results')
 love.update(1);assert(not F.pickupPulse)
 -- Pausing freezes the pulse; starting a new run clears it.
 F.death(200,200);App.state='pause';love.update(.2);assert(F.deathPulse.age==0)
 App.start(1);assert(not F.active())
 F.collect(200,200);Graphics.psychedelic=0
 assert(not F.bind(),'Off must bypass the shader');Graphics.psychedelic=1
 assert(F.strength()==.45);Graphics.psychedelic=2
 Input.move,Input.slow=move,slow
 App.practice=9;App.singleLevel=true;App.start(1)
 -- Warm unrelated scene renderers before checking that these effects allocate no GPU resources.
 love.draw()
 local image,shader,canvas=g.newImage,g.newShader,g.newCanvas
 local uploads,compiles,canvases=0,0,0
 g.newImage=function(...) uploads=uploads+1;return image(...) end
 g.newShader=function(...) compiles=compiles+1;return shader(...) end
 g.newCanvas=function(...) canvases=canvases+1;return canvas(...) end
 local draw=love.draw;local index=0;local drawn=true
 local names={'repos','vitesse','mort','larme','victoire','graphismes'}
 local function capture(name)
  local dir=os.getenv('SILKEN_STYLE_CAPTURE_DIR');if not dir then return end
  g.captureScreenshot(function(data)
   local encoded=data:encode('png');local f=assert(io.open(dir..'/'..name..'.png','wb'))
   f:write(encoded:getString());f:close();encoded:release();data:release()
  end)
 end
 love.update=function()
  if not drawn then return end;drawn=false;index=index+1;F.reset();UI.clock=3
  if index==2 then
   -- The first event-loop frame can still deliver the initial window resize.
   uploads,compiles,canvases=0,0,0
   player.dashing=true;F.speed=.8;F.clock=2;F.vx=1;F.vy=0
   ghosts={};for i=1,5 do ghosts[i]={x=player.x-i*18,y=player.y,alpha=.45-i*.055,time=i*.03,direction='right'} end
   direction='right'
  elseif index==3 then ghosts={};F.death(player.x+15,player.y+12);F.update(.13)
  elseif index==4 then F.collect(player.x+15,player.y+12);F.update(.12)
  elseif index==5 then
   g.newImage=image;g.newShader=shader;g.newCanvas=canvas
   assert(uploads==0 and compiles==0 and canvases==0,string.format('Effects allocated %d images, %d shaders, %d canvases',uploads,compiles,canvases))
   App.state='customVictory';F.collect(player.x+15,player.y+12);F.update(.15)
  elseif index==6 then App.state='graphics'
  elseif index>6 then
   g.newImage=image;g.newShader=shader;g.newCanvas=canvas
   print('PASS psychedelic: real death/respawn, real tear/level transition/results, actual speed, expiration, pause, settings, RNG isolation; no runtime image/shader/canvas creation')
   love.event.quit()
  end
 end
 love.draw=function() if index<=6 then draw();capture(names[index] or 'repos') end;drawn=true end
end
return T
