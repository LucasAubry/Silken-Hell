local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 App.practice=1;App.start(1);mobs={}
 spawn_ange(300,300,1,false);spawn_snake(300,300,1)
 local statues=mobs
 for _,m in ipairs(statues) do
  m.hitBox_width=28;m.hitBox_height=42;m.hitBox_offset_x=-14;m.hitBox_offset_y=-21
  assert(m.img,'Statues must be visible before the first movement')
 end
 mobs={}
 local move,slow=Input.move,Input.slow
 local ix,iy=0,0
 Input.move=function()return ix,iy end;Input.slow=function()return true end
 player.x=500;player.y=300;player.speed=1
 App.move(1/60);assert(not player.has_moved)
 for _,m in ipairs(statues) do
  MobBehaviors[m.type].update(m,1/60)
  assert(m.x==300 and m.y==300 and m.floatTime==0,'Idle statues must stay still')
 end
 -- Each change of direction must immediately chase the current player centre.
 for _,target in ipairs({{500,300,1,0},{300,100,0,-1},{100,300,-1,0},{300,500,0,1}}) do
  player.x,player.y=target[1]-15,target[2]-12;ix,iy=target[3],target[4]
  App.move(1/60);assert(player.has_moved)
  for _,m in ipairs(statues) do
   local x,y=m.x,m.y;local dx,dy=player.x+15-x,player.y+12-y;local d=math.sqrt(dx*dx+dy*dy)
   MobBehaviors[m.type].update(m,1/60)
   assert(math.abs(m.x-x-dx/d)<1e-8 and math.abs(m.y-y-dy/d)<1e-8,'Turn must immediately target current centre')
   assert(m.img==m.imgs[Art.direction(dx,dy,m.dir)],'Sprite follows trajectory')
  end
 end
 ix,iy=0,0;App.move(1/60)
 for _,m in ipairs(statues) do
  local x,y,phase,dir=m.x,m.y,m.floatTime,m.dir
  MobBehaviors[m.type].update(m,.5)
  assert(m.x==x and m.y==y and m.floatTime==phase and m.dir==dir,'Release stops both displacement and floating')
 end
 player.x=23;player.y=300;ix=-1
 App.move(1/60);assert(not player.has_moved,'Pressing into boundary is not movement')
 for _,m in ipairs(statues) do
  local x,y=m.x,m.y;MobBehaviors[m.type].update(m,1/60)
  assert(m.x==x and m.y==y,'Blocked player must not move statues')
 end
 ix,iy=1,0;App.move(1/60);assert(player.has_moved)
 for _,m in ipairs(statues) do
  local x,y,phase=m.x,m.y,m.floatTime;freeze(m,2)
  MobBehaviors[m.type].update(m,1/60)
  assert(m.x==x and m.y==y and m.floatTime==phase,'Traps still freeze statues')
 end
 Input.move,Input.slow=move,slow
 print('PASS statues: visible at spawn, idle, immediate pursuit through four turns, sprite alignment, stop, blocked player, frozen traps')
end
return T
