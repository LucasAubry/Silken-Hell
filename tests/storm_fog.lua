local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false
 Profile.save=function()end;Profile.record=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end
 local layout={world=6,level=10,width=960,height=600,environment={lightning=false},entities={{kind='spawn',x=480,y=300},{kind='boss',type='storm',x=480,y=140}}}
 App.sessionLayout=layout;App.singleLevel=true;LevelLayouts.disabled=false
 App.start(6);require('run_start').active=false;require('retry_wait').reset()
 local s=Bosses.items[1].boss;local Fog=require('mobs.bosses.storm.fog')
 local kill=Hazards.kill;Hazards.kill=function()end
 s.wave=4;s.setPhase('tell');s.setPhase('hunt');s.x=480;s.y=250;s.hp=4
 local previous=0
 for i=1,3 do
  local snail=s.snails[i];snail.phase='strike';snail.x=s.x;snail.y=s.y;snail.age=0
  s.updateSnails(1/120)
  assert(s.fogAmount>previous,'Each explosion thickens the fog');previous=s.fogAmount
 end
 assert(s.fogAmount==1 and s.snails[4].phase=='tethered','Last snail remains in opaque fog')
 -- Fully opaque fog produces identical pixels over black and white backgrounds.
 local g=love.graphics
 local function fogPixels(background)
  local canvas=g.newCanvas(Arena.width,600)
  g.push('all');g.setCanvas(canvas);g.origin();g.clear(background,background,background,1);Fog.draw(s);g.pop()
  local data=canvas:newImageData();local bytes=data:getString();data:release();canvas:release();return bytes
 end
 assert(fogPixels(0)==fogPixels(1),'No arena pixels visible through full fog')
 for y=0,599,30 do for x=0,959,40 do assert(Fog.alphaAt(s,x,y)==1) end end
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
  s.angle=angle;local ax,ay=s.anchor();local flap=1+math.sin(s.clock*14)*.025
  local flip=math.cos(angle)<0 and -1 or 1
  assert(math.abs((ax-s.x)*math.cos(angle)+(ay-s.y)*math.sin(angle)+60*flap)<.001)
  assert(math.abs(-(ax-s.x)*math.sin(angle)+(ay-s.y)*math.cos(angle)-58*flip/flap)<.001)
 end
 local last=s.snails[4];last.phase='strike';last.x=s.x;last.y=s.y;last.age=0
 s.updateSnails(1/120);s.updateSnails(1/120)
 assert(s.hp==0 and not s.defeated and s.phase=='clean','Final victory waits for the clearing dashes')
 s.holes={{x=120,y=55,tx=130,ty=55,radius=8},{x=820,y=540,tx=830,ty=540,radius=8}}
 s.update(.2)
 assert(s.cleanStage=='hold' and s.fogAmount==1 and not s.holes[1].closing,'Opaque beat before the first dash')
 local passes={};local partial=false;local captured=false
 for i=1,2400 do
  s.update(1/60)
  if s.cleanStage=='dash' then
   passes[s.cleanIndex]=true
   if s.cleanIndex==1 and s.x>400 and s.x<560 then
    assert(s.holes[1].closing and not s.holes[2].closing,'Only the swept band closes its holes')
    assert(Fog.alphaAt(s,s.sweepDir==1 and 100 or 860,60)==0,'Wake clears behind the boss')
    assert(Fog.alphaAt(s,480,540)==1,'Untouched bands stay opaque')
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
 print('PASS storm fog: visible transported cloud parcels, progressive opacity, hidden last snail, tail attachment, five dash sweeps, local hole removal, delayed victory and render')
 love.event.quit()
end
return T
