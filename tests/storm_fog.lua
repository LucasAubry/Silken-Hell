local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false
 Profile.save=function()end;Profile.record=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end
 local layout={world=6,level=10,width=960,height=600,environment={lightning=false},entities={{kind='spawn',x=480,y=300},{kind='boss',type='storm',x=480,y=140}}}
 App.sessionLayout=layout;App.singleLevel=true;LevelLayouts.disabled=false
 App.start(6);require('run_start').active=false;require('retry_wait').reset()
 local s=Bosses.items[1].boss;local Fog=require('mobs.bosses.storm.fog')
 -- Ordinary ocean crabs accelerate only while physically in black ink.
 local pools=Octopus.inkPools;Octopus.inkPools={{x=400,y=300,rx=40,ry=30,life=5}}
 local crab={x=400,y=300,speed=120,age=0}
 Octopus.inkCrab(crab,.01);assert(crab.inked and crab.frenzy)
 local fast=Octopus.crabSpeed(crab);crab.x=700;Octopus.inkCrab(crab,.01)
 assert(not crab.inked and not crab.frenzy and Octopus.crabSpeed(crab)<fast)
 local calm=Octopus.crabSpeed(crab);player.ink=4;Octopus.crabRage=5;crab.frenzy=true
 assert(Octopus.crabSpeed(crab)==calm,'Only ink under the crab changes its speed')
 player.ink=0;Octopus.crabRage=0;Octopus.inkPools=pools
 local smoke={x=320,y=250,age=.1};local sx,sy,r1=Fog.smokePuff(smoke,1)
 assert(math.abs(sx-320)<5 and math.abs(sy-250)<5,'Smoke starts at the explosion')
 smoke.age=1;local _,_,r2=Fog.smokePuff(smoke,1);assert(r2>r1,'Smoke swells gradually')

 local kill=Hazards.kill;Hazards.kill=function()end
 s.wave=4;s.setPhase('tell');s.setPhase('hunt');s.x=480;s.y=250;s.hp=4;s.releaseSnails()
 local previous=0
 for i=1,3 do
  local snail=s.snails[i];snail.phase='strike';snail.x=s.x;snail.y=s.y;snail.age=0
  s.updateSnails(1/120)
  assert(s.fogTarget>previous,'Each explosion raises the fog target');previous=s.fogTarget
  local before=s.fogAmount;Fog.update(s,.1);assert(s.fogAmount==before,'Smoke emerges locally before filling the map')
  Fog.update(s,2.4)
 end
 assert(s.fogAmount==.72 and s.snails[4].phase=='ready','Last snail stays usable in readable fog')
 -- Combat fog preserves contrast with the arena underneath.
 local g=love.graphics
 local function fogPixels(background)
  local canvas=g.newCanvas(Arena.width,600)
  g.push('all');g.setCanvas(canvas);g.origin();g.clear(background,background,background,1);Fog.draw(s);g.pop()
  local data=canvas:newImageData();local bytes=data:getString();data:release();canvas:release();return bytes
 end
 assert(fogPixels(0)~=fogPixels(1),'Arena stays visible through combat fog')
 for y=0,599,30 do for x=0,959,40 do assert(Fog.alphaAt(s,x,y)==.72) end end
 -- Fog parcels physically travel towards the exit, in both dash directions.
 for _,dir in ipairs({1,-1}) do
  local state={cleanStage='dash',sweepDir=dir,fogRows=0,fogAmount=1,fogFront=dir==1 and 200 or Arena.width-200}
  local x1,y1,r1=Fog.pushedCloud(state,1);assert(x1 and r1>20)
  state.fogFront=state.fogFront+dir*180
  local x2=Fog.pushedCloud(state,1)
  assert((x2-x1)*dir>150,'The same cloud parcel is pushed towards the map edge')
  state.fogFront=dir==1 and Arena.width+110 or -110
  for i=1,Fog.parcelCount do
   local x,y,r=Fog.pushedCloud(state,i)
   assert(x and (dir==1 and x-r>Arena.width or dir==-1 and x+r<0),'Clouds leave the map before their pass ends')
  end
 end
 -- Both drawing and physics use the transformed tail attachment, not the centre.
 for _,angle in ipairs({0,math.pi/3,math.pi,math.pi*1.4}) do
  s.angle=angle;s.flightRoll=math.cos(angle)<0 and -1 or 1;local ax,ay=s.anchor();local flap=1+math.sin(s.clock*14)*.025
  local flip=math.cos(angle)<0 and -1 or 1
  assert(math.abs(ax-s.x+60*flap*flip)<.001)
  assert(math.abs(ay-s.y-58/flap)<.001)
 end
 local last=s.snails[4];last.phase='strike';last.x=s.x;last.y=s.y;last.age=0
 s.updateSnails(1/120);s.updateSnails(1/120)
 for i=1,230 do if s.phase=='clean' then break end;s.updateSnails(1/120)end
 assert(s.hp==0 and not s.defeated and s.phase=='clean','Final victory waits for the clearing dashes')
 s.holes={{x=120,y=55,tx=130,ty=55,radius=8},{x=820,y=540,tx=830,ty=540,radius=8}}
 local near,far=s.holes[1],s.holes[2]
 s.update(.04)
 assert(s.cleanStage=='approach' and s.fogAmount==.72 and not s.holes[1].closing,'Short approach before the first dash')
 local passes={};local partial=false;local captured=false
 for i=1,2400 do
  s.update(1/60)
  if s.cleanStage=='dash' then
   passes[s.cleanIndex]=true
   if s.cleanIndex==1 and s.x>400 and s.x<560 then
    assert((near.closing or false)==(s.sweepDir==1) and not far.closing,'Only the traversed portion closes its holes')
    assert(Fog.alphaAt(s,s.sweepDir==1 and 100 or 860,60)==0,'Wake clears behind the boss')
    assert(Fog.alphaAt(s,480,540)==.72,'Untouched bands keep their fog')
    partial=true
    if not captured then
     local canvas=g.newCanvas(Arena.width,600)
     g.push('all');g.setCanvas(canvas);g.origin();draw_level();s.draw();Fog.draw(s);g.pop()
     canvas:newImageData():encode('png','storm-fog-sweep.png');canvas:release();captured=true
    end
   end
  end
  if s.defeated then break end
 end
 for i=1,5 do assert(passes[i],'All five dash bands are visited') end
 local front=s.fogFront;s.resize(1.25);assert(s.fogFront==front*1.25,'Fog sweep follows arena resize');s.resize(.8)
 assert(partial and s.defeated and s.fogAmount==0 and #s.holes==0,'Final map clear of fog and snail holes before victory')
 love.draw()
 Hazards.kill=kill;require('boss_liberation').reset()
 print('PASS storm fog: visible transported cloud parcels, progressive opacity, usable last snail, tail attachment, five dash sweeps, local hole removal, delayed victory and render')
 love.event.quit()
end
return T
