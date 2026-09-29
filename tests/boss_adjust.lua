local T={}
function T.run()
 Online.enabled=false;Profile.save=function() end;Replay.disabled=true
 App.start(5);player.level=10;reset_level();assert(Hedgehog.hp==10 and Hedgehog.maxHp==10)
 for i=1,9 do Hedgehog.finishRound();assert(not Hedgehog.defeated) end
 Hedgehog.finishRound();assert(Hedgehog.defeated)
 App.start(4);player.level=10;reset_level()
 local slow=Input.slow;local hazard=Hazards.speed
 local c={speed=251,inked=true,frenzy=true,age=.5};Octopus.crabRage=3;player.ink=3
 for _,s in ipairs({true,false}) do for _,h in ipairs({1,.4}) do
  Input.slow=function() return s end;Hazards.speed=function() return h end
  local limit=300*player.speed*h*(s and 1 or 1.8)
  assert(Octopus.crabSpeed(c)<=limit+.00001)
  local move=Arena.move;local moved=0;Arena.move=function(_,x,y) moved=moved+math.sqrt(x*x+y*y);return false,false end
  c.fling={vx=1800,vy=900,time=1};player.reset=false;Octopus.moveFlungCrab(c,.1,function() end);Arena.move=move
  assert(moved<=limit*.1+.0001,'Thrown crab speed cap')
 end end
 Input.slow=slow;Hazards.speed=hazard
 App.start(6);player.level=10;reset_level();Storm.strikes={{x=Arena.width*.5,y=330,age=.5,seed=3}}
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1;Storm.clock=2;Storm.phase='flightTell';Storm.hidden=true;Storm.y=330;Storm.x=Arena.width*.5
  if frame==1 then Storm.dir='right';App.capture='beak-right.png'
  elseif frame==4 then Storm.dir='left';App.capture='beak-left.png'
  elseif frame==7 then Storm.dir='up';App.capture='beak-bottom.png'
  elseif frame==10 then print('PASS: hedgehog 10 hits, crab walking/flung speed caps in slow/fast/terrain, three beak directions and gold lightning markers');love.event.quit() end
 end
end
return T
