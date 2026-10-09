local I={}
-- Keep the neck behind the left wall while the head spits into the arena.
local entranceX=35
local function pose(a,x)
 a.swimHead={x=x,y=300};a.swimAngle=0;a.swimPath={};a.returnPosePositions={};a.returnPoseAngles={}
 for d=700,0,-6 do a.swimPath[#a.swimPath+1]={x=x-d,y=300} end
 a.buildBones()
end
function I.start(a)
 I.current=a
 a.arrival={age=0};a.lumenParticles={};a.returnShots={};a.open=false
 pose(a,-180);player.x=Arena.width/2-15;player.y=300-12
end
function I.finish(a)
 I.current=nil;a.arrival=nil;a.open=false;a.returnMouth=0;a.returnShotTimer=1.4
 require('mobs.bosses.abyss.tooth_wake').setup(a)
 a.returnPX,a.returnPY=player.x+15,player.y+12
end
function I.retry(a)
 pose(a,entranceX);player.x=Arena.width/2-15;player.y=300-12
 I.finish(a)
end
function I.update(a,dt)
 local intro=a.arrival;if not intro then return false end
 intro.age=intro.age+dt;a.clock=a.clock+dt
 local t=intro.age
 if t>.65 then
  local u=math.min(1,(t-.65)/1.4)
  local x=-180+u*u*(3-2*u)*(180+entranceX)
  local last=a.swimHead.x
  for px=last+3,x,3 do a.swimPath[#a.swimPath+1]={x=px,y=300} end
  a.swimHead.x=x
 end
 a.open=t>=1.8 and t<2.85
 a.returnBuildDt=dt;a.buildBones();a.returnBuildDt=nil
 if t>=2.15 and not intro.spit then
  intro.spit=true;require('mobs.bosses.abyss.tooth_wake').setup(a)
  intro.mx,intro.my=a.mouth()
  for _,p in ipairs(a.lumenParticles) do p.tx,p.ty=p.x,p.y;p.x,p.y=intro.mx,intro.my end
 end
 if intro.spit then
  local u=math.min(1,(t-2.15)/.85);local ease=1-(1-u)^3
  local mx,my=intro.mx,intro.my
  -- The player and the cloud leave the same mouth in the same burst.
  player.x=mx+(Arena.width/2-mx)*ease-15
  player.y=my+(300-my)*ease-42*math.sin(math.pi*ease)-12
  for _,p in ipairs(a.lumenParticles) do
   local v=math.min(1,math.max(0,(t-2.15-(p.id%13)*.006)/(.65+(p.id%7)*.025)))
   local q=1-(1-v)^2;local r=1-q
   local ox,oy=p.x,p.y
   -- Forward jet, then curling spread into the surrounding water.
   p.x=r*r*mx+2*r*q*(mx+160+p.id%60)+q*q*p.tx
   p.y=r*r*my+2*r*q*(my+math.sin(p.id*2.4)*65)+q*q*p.ty
   p.wakeVx=(p.x-ox)/math.max(dt,.001);p.wakeVy=(p.y-oy)/math.max(dt,.001);p.age=p.age+dt
  end
 end
 if t>=3.15 then
  I.current=nil;a.arrival=nil;a.open=false;a.returnMouth=0;a.returnShotTimer=1.3
  a.returnPX=player.x+15;a.returnPY=player.y+12
  for _,p in ipairs(a.lumenParticles) do p.wakeVx=0;p.wakeVy=0 end
 end
 return true
end
return I
