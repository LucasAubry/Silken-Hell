local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end
 App.practice=1;App.start(6);require('run_start').active=false
 local G=require('mobs.moth_gust');local V=require('wind_visibility');local F=require('final_spider');local H=require('queen_heirs');local Q=require('queen_escape')
 Arena.walls={{x=580,y=120,w=26,h=160},{x=730,y=370,w=35,h=150,rotation=32},{x=0,y=0,w=Arena.width,h=22}}
 for i=1,240 do
  local x,y=80+(i*79)%800,60+(i*47)%480
  local expected=Arena.direct(205,288,x-15,y-12);local actual=V.clear(220,300,x,y)
  assert(not (expected==false and actual==true),'Fast visibility must preserve wall shelter: '..i)
 end
 assert(V.clear(220,300,220,-50),'Sky edges remain open to wind')
 assert(not V.clear(220,300,850,500),'Rotated wall shelters the target')
 local g=love.graphics;local target=g.newCanvas(Arena.width,600)
 local flock={}
 for i=1,12 do flock[i]={type='mist_moth',x=80+i*40,y=70+i*31,vx=1,vy=0,age=i*.13,phase='gust'} end
 g.push('all');g.setCanvas(target);g.origin();g.clear()
 for _,m in ipairs(flock) do G.draw(m) end
 g.flushBatch();local before=g.getStats().drawcalls;local begun=love.timer.getTime()
 for _=1,60 do for _,m in ipairs(flock) do G.draw(m) end end
 g.flushBatch();local calls=g.getStats().drawcalls-before
 print(string.format('Gust stress: 12 moths, 60 frames, %.3f ms/frame CPU submission, %.1f draw calls/frame',(love.timer.getTime()-begun)*1000/60,calls/60))
 assert(calls<=12*60,'Each complete gust must use at most one GPU draw call')
 local batch=G.batch;local texture=G.cloud
 assert(batch:getBufferSize()==128,'Wind geometry stays bounded even during sustained gusts')
 local rng=love.math.getRandomState()
 for _,m in ipairs(flock) do G.draw(m) end
 assert(G.batch==batch and G.cloud==texture,'Sustained gusts reuse their GPU resources')
 assert(love.math.getRandomState()==rng,'Wind rendering must not consume gameplay randomness')
 g.pop();target:release()
 local m={type='mist_moth',x=220,y=300,vx=1,vy=0,age=1,phase='gust'}
 local blocked=Arena.blocked;local calls=0
 Arena.blocked=function(...)calls=calls+1;return blocked(...)end
 local start=love.timer.getTime()
 for _=1,15 do for i=1,70 do
  local d=(m.age*740+i*29)%G.range;local side=math.sin(i*13.7)*(G.width-4)
  Arena.direct(m.x-15,m.y-12,m.x+d-15,m.y+side-12)
 end end
 local oldTime=love.timer.getTime()-start;local oldCalls=calls;calls=0
 start=love.timer.getTime()
 for _=1,15 do for lane=1,9 do V.limit(m.x,m.y+(lane-5)*6,1,0,G.range) end end
 local newTime=love.timer.getTime()-start
 assert(oldCalls>10000 and calls==0,'Optimized wind eliminates sampled wall collision walks')
 Arena.blocked=blocked
 print(string.format('Wind visibility CPU / 15 frames: old %.3f ms, new %.3f ms; sampled collision calls %d -> 0',oldTime*1000,newTime*1000,oldCalls))
 mobs={m};local state=require('json').encode(require('replay_state').snapshot());local rng=love.math.getRandomState()
 local g=love.graphics;local canvas=g.newCanvas(Arena.width,600)
 g.push('all');g.setCanvas(canvas);g.origin();g.clear();require('biome_floor').draw(6,Arena.width,600,1);G.draw(m);g.pop()
 canvas:newImageData():encode('png','wind-cloud-particles.png');canvas:release()
 assert(state==require('json').encode(require('replay_state').snapshot()) and rng==love.math.getRandomState(),'Wind particles are visual only')
 Campaign.select(3);player.level=1;reset_level();F.reset(true);F.x=180;F.y=170;player.reset=false
 Arena.walls={{x=410,y=260,w=80,h=60}};F.babies={}
 for i=1,6 do H.hatch(F,{x=180,y=170,seed=i}) end
 F.leap('webs');for _,b in ipairs(F.babies)do H.jump(b,F) end
 local actors={F};for _,b in ipairs(F.babies)do actors[#actors+1]=b end
 for i,a in ipairs(actors)do
  assert(not Arena.blocked(a.jump.tx-29,a.jump.ty-25,58,50),'Landing avoids walls')
  for j=1,i-1 do local b=actors[j];assert((a.jump.tx-b.jump.tx)^2+(a.jump.ty-b.jump.ty)^2>=110^2,'Each spider has a separate landing')end
 end
 local move,slow=Input.move,Input.slow;local dx=0;Input.move=function()return dx,0 end;Input.slow=function()return true end
 Q.reset(F);F.snare=2.1;F.snareSource='shot';F.clock=0;F.defeated=false
 for i=1,5 do
  dx=0;F.clock=F.clock+.06;Q.struggle(F,.06)
  dx=1;F.clock=F.clock+.06;Q.struggle(F,.06)
  if i<5 then assert(F.snare>0,'One held key does not instantly free player');Q.struggle(F,.01);assert(#F.escapeTaps==i,'Holding is not another press')end
 end
 assert(F.snare==0 and F.webGrace>0,'Five separate presses release the player')
 Input.move,Input.slow=move,slow
 print('PASS wind performance, rotated shelter, cloud rendering, separate spider landings and five-press escape');love.event.quit()
end
return T
