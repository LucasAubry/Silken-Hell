local W={}
local function curve(s,t,x0,y0,x1,y1,x2,y2,x3,y3,duration)
 local u=1-t
 s.x=u*u*u*x0+3*u*u*t*x1+3*u*t*t*x2+t*t*t*x3
 s.y=u*u*u*y0+3*u*u*t*y1+3*u*t*t*y2+t*t*t*y3
 s.vx=(3*u*u*(x1-x0)+6*u*t*(x2-x1)+3*t*t*(x3-x2))/duration
 s.vy=(3*u*u*(y1-y0)+6*u*t*(y2-y1)+3*t*t*(y3-y2))/duration
 if s.vx*s.vx+s.vy*s.vy>1 then s.angle=math.atan2(s.vy,s.vx)end
end
-- 0.30s approach + five 0.20s sweeps + four 0.05s edge turns = 1.50s.
function W.begin(s)
 s.cleanIndex=1;s.fogRows=0;s.fogFront=0;s.cleanStage='approach';s.cleanClock=0
 s.sweepDir=math.cos(s.angle or 0)>=0 and -1 or 1
 s.cleanFromX,s.cleanFromY=s.x,s.y;s.cleanFromAngle=s.angle or 0;s.cleanFromSpeed=math.sqrt((s.vx or 0)^2+(s.vy or 0)^2)
end
function W.update(s,dt)
 local y=(s.cleanIndex-.5)*120
 s.cleanClock=s.cleanClock+dt
 if s.cleanStage=='approach' then
  local duration=s.cleanIndex==1 and .30 or .05
  local start=s.sweepDir==1 and -110 or Arena.width+110
  local t=math.min(1,s.cleanClock/duration)
  if s.cleanIndex==1 then
   local a=s.cleanFromAngle;local entry=s.cleanFromSpeed*duration/3
   local exit=(Arena.width+220)/.20*duration/3
   curve(s,t,s.cleanFromX,s.cleanFromY,s.cleanFromX+math.cos(a)*entry,s.cleanFromY+math.sin(a)*entry,start-s.sweepDir*exit,y,start,y,duration)
  else
   -- A continuous U-turn outside the map, tangent to both horizontal passes.
   local outside=start-s.sweepDir*(Arena.width+220)/.20*duration/3
   curve(s,t,s.cleanFromX,s.cleanFromY,outside,s.cleanFromY,outside,y,start,y,duration)
  end
  if t>=1 then s.cleanStage='dash';s.cleanClock=s.cleanClock-duration;s.fogFront=s.x end
 elseif s.cleanStage=='dash' then
  local before=s.x;local start=s.sweepDir==1 and -110 or Arena.width+110
  s.vx=s.sweepDir*(Arena.width+220)/.20;s.vy=0
  s.x=start+s.vx*math.min(.20,s.cleanClock);s.y=y;s.fogFront=s.x;s.angle=s.sweepDir==1 and 0 or math.pi
  local left,right=math.min(before,s.x)-65,math.max(before,s.x)+65
  for _,p in ipairs(s.holes)do
   local x,py=(p.x+p.tx)/2,(p.y+p.ty)/2
   if x>=left and x<=right and math.abs(py-y)<=72 then p.closing=true;p.radius=0 end
  end
  if s.cleanClock>=.20 then
   s.fogRows=s.cleanIndex;s.cleanClock=s.cleanClock-.20
   if s.cleanIndex==5 then
    s.holes={};s.trailKeys={};s.fogAmount=0;s.fogTarget=0;s.smoke={};s.groundRevision=s.groundRevision+1;s.cleanStage=nil;return true
   end
   s.cleanIndex=s.cleanIndex+1;s.sweepDir=-s.sweepDir;s.cleanStage='approach'
   s.cleanFromX,s.cleanFromY=s.x,s.y
  end
 end
 return false
end
return W
