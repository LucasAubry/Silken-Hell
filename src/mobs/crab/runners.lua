-- Fast wandering crabs for ordinary ocean levels, independent of the octopus fight.
local R={}
local function roll(seed,step)
 local n=math.sin(seed+step*12.9898)*43758.5453;return n-math.floor(n)
end
function R.turn(c)
 c.runnerStep=(c.runnerStep or 0)+1
 local a=roll(c.runnerSeed,c.runnerStep)*math.pi*2
 c.vx,c.vy=math.cos(a),math.sin(a)
 c.runnerTurn=.28+.34*roll(c.runnerSeed+19,c.runnerStep)
end
function R.spawn(level)
 local count=3+math.floor((level-1)/3)
 for i=1,count do
  local x,y
  for attempt=1,96 do
   local seed=level*43+i*107
   local xx=46+roll(seed,attempt)*(Arena.width-92)
   local yy=65+roll(seed+59,attempt)*485
   local safe=not Arena.blocked(xx-14,yy-12,28,24) and (xx-player.x-15)^2+(yy-player.y-12)^2>220^2
   if safe then for _,m in ipairs(mobs) do if (xx-m.x)^2+(yy-m.y)^2<60^2 then safe=false;break end end end
   if safe then x,y=xx,yy;break end
  end
  if x then
   Octopus.spawnCrab(x,y,390+level*18)
   local c=mobs[#mobs];c.oceanRunner=true;c.runnerSeed=level*51+i*137;c.runnerStep=0;R.turn(c)
  end
 end
end
function R.update(c,dt)
 if c.dead or c.is_frozen or c.tunnelTravel then return end
 c.runnerTurn=c.runnerTurn-dt
 if c.runnerTurn<=0 then R.turn(c) end
 local speed=c.speed;local steps=math.max(1,math.ceil(speed*dt/4))
 for _=1,steps do
  local hitX,hitY=Arena.move(c,c.vx*speed*dt/steps,c.vy*speed*dt/steps)
  if hitX then c.vx=-c.vx end
  if hitY then c.vy=-c.vy end
  if hitX or hitY then c.runnerTurn=math.min(c.runnerTurn,.14) end
  if (player.x+15-c.x)^2+(player.y+12-c.y)^2<27^2 then Hazards.kill('crab');return end
 end
 c.angle=math.atan2(c.vy,c.vx);c.dir=Art.direction(c.vx,c.vy,c.dir)
end
return R
