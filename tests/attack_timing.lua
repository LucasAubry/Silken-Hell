local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 App.practice=1;App.start(6);require('run_start').active=false
 local B=require('mobs.sky_insects');local G=require('mobs.moth_gust');local A=require('mob_attack_timing')
 local kill,contact=Hazards.kill,Hazards.contact;Hazards.kill=function()end;Hazards.contact=function()end
 Arena.walls={};Arena.interior={};mobs={};Realms.holes={};require('sky_weather').reset()
 local e={kind='mob',type='mist_moth',x=220,y=250,speed=55,attackDelay=4,attackDuration=10,attackInterval=1}
 LevelLayouts.spawn(e);local m=mobs[1]
 player.x=700;player.y=500;player.reset=false;player.falling=false
 local first,last
 for frame=1,850 do
  B.update(m,1/60)
  if m.phase=='gust' then first=first or frame/60;last=frame/60 end
 end
 assert(first and math.abs(first-4)<.02,'First gust at four seconds: '..tostring(first))
 assert(math.abs(last-14)<.02,'Ten seconds of uninterrupted wind: '..tostring(last))
 assert(m.phase=='recover','The configured gust ends normally')
 for _,field in ipairs({'whirl','throw','skyWhirl','skyThrow'}) do
  player.x=355;player.y=288;player[field]={vx=0,vy=-1050,time=1}
  m.x=220;m.y=300;m.vx=1;m.vy=0;m.phase='gust';m.phaseTime=2
  G.update(m,.05)
  assert(player.x==355 and player.y==288,'Wind must not deflect '..field)
  assert(player[field].vx==0 and player[field].vy==-1050,'Launch heading remains locked')
  player[field]=nil
 end
 m.x=220;m.y=300;mobs={m};G.update(m,.05)
 local vx=G.playerVelocity(0,0,false,540);assert(vx>0,'Wind resumes pushing after the projection ends')
 for _,kind in ipairs({'jelly','light_jelly','worm'}) do
  local a={type=kind,attackDelay=4,attackInterval=2};local shots={}
  for frame=1,600 do if A.due(a,1/60,3,3) then shots[#shots+1]=frame/60 end end
  assert(#shots==4 and math.abs(shots[1]-4)<.02 and math.abs(shots[4]-10)<.02,'Custom projectile schedule: '..kind)
  assert(A.due({type=kind},.1,3,3)==nil,'Unconfigured attacks use their original implementation')
 end
 local fish={type='fish',x=100,y=100,attackDelay=4,attackDuration=10,attackInterval=2}
 for frame=1,240 do A.charge(fish,1/60) end
 assert(fish.attackActive,'Timed fish starts its charge at four seconds')
 local angle=fish.attackAngle;player.x=30;player.y=40
 for frame=1,590 do A.charge(fish,1/60) end
 assert(fish.attackActive and fish.attackAngle==angle,'Timed charge keeps its aim throughout its duration')
 for frame=1,20 do A.charge(fish,1/60) end;assert(not fish.attackActive,'Timed charge ends')
 local layout={world=6,level=1,width=960,height=600,entities={{kind='spawn',x=100,y=100},e}}
 assert(require('layout_schema').validate(layout))
 local snapshot=LevelLayouts.snapshot();local found=false
 for _,item in ipairs(snapshot.entities) do if item.type=='mist_moth' then found=item.attackDelay==4 and item.attackDuration==10 end end
 assert(found,'Timings survive snapshots')
 e.attackDuration=0;assert(not require('layout_schema').validate(layout),'Zero duration is rejected')
 Hazards.kill,Hazards.contact=kill,contact
 print('PASS attack timings: 4-second delay, 10-second wind, projectile cycles, fixed charges, all tornado projections, validation and snapshots');love.event.quit()
end
return T
