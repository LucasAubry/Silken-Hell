local T={}
function T.run(reset)
 local savedWalls,savedInterior=Arena.walls,Arena.interior
 local savedActive=Octopus.active;Octopus.active=false
 local function setup(walls,x,y,tx,ty)
  Arena.walls={{x=0,y=0,w=Arena.width,h=22},{x=0,y=578,w=Arena.width,h=22},{x=0,y=0,w=22,h=600},{x=Arena.width-22,y=0,w=22,h=600}}
  for _,w in ipairs(walls)do Arena.walls[#Arena.walls+1]=w end
  Walls=Arena.walls;Arena.navigationVersion=(Arena.navigationVersion or 0)+1
  player.x=tx-15;player.y=ty-12;player.reset=false;player.ink=0
  Octopus.rider=nil;Octopus.crabRage=0
  return {x=x,y=y,vx=1,vy=0,speed=150,age=0,hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
 end
 for _,case in ipairs({
  {wall={x=390,y=180,w=20,h=240},x=200,y=300,tx=600,ty=300},
  {wall={x=280,y=290,w=240,h=20,rotation=90},x=200,y=300,tx=600,ty=300},
  {wall={x=280,y=290,w=240,h=20},x=400,y=150,tx=400,ty=450}
 })do
  local c=setup({case.wall},case.x,case.y,case.tx,case.ty);local reached=false
  for _=1,900 do
   Octopus.walkCrab(c,1/120,function()end)
   assert(not Arena.blocked(c.x-14,c.y-12,28,24),'Crab never crosses a wall during its detour')
   assert(not c.dead,'Walking into a wall never explodes the crab')
   if (c.x-case.tx)^2+(c.y-case.ty)^2<20^2 then reached=true;break end
  end
  assert(reached,'Crab reaches the player around horizontal, vertical and rotated walls')
 end
 local c=setup({{x=300,y=180,w=20,h=240}},200,300,800,500)
 c.oceanRunner=true;c.runnerSeed=11;c.runnerStep=0;c.runnerTurn=100
 for _=1,900 do
  require('mobs.crab.runners').update(c,1/120)
  assert(not Arena.blocked(c.x-14,c.y-12,28,24),'Wandering crab stays outside walls')
  if c.x>360 then break end
 end
 assert(c.x>360,'Wandering crab follows a detour instead of bouncing forever')
 Arena.walls=savedWalls;Walls=savedWalls;Arena.interior=savedInterior;Arena.navigationVersion=Arena.navigationVersion+1;Octopus.active=savedActive
 reset()
 print('PASS crab detours: horizontal, vertical, rotated walls, contact-safe pursuit and wandering')
end
return T
