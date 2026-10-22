local W={}
function W.begin(s)
 s.cleanIndex=1;s.fogRows=0;s.fogFront=0;s.cleanStage='hold';s.cleanClock=.8
 s.sweepDir=s.x<Arena.width/2 and 1 or -1
end
function W.update(s,dt,moveToward)
 local y=(s.cleanIndex-.5)*120
 for _,p in ipairs(s.holes) do if p.closing and p.radius>0 then
  p.radius=math.max(0,p.radius-100*dt);s.groundRevision=s.groundRevision+1
 end end
 if s.cleanStage=='hold' then
  s.cleanClock=s.cleanClock-dt
  if s.cleanClock<=0 then s.cleanStage='approach' end
 elseif s.cleanStage=='approach' then
  local start=s.sweepDir==1 and -110 or Arena.width+110
  if moveToward(start,y,1050,dt) then
   s.x=start;s.y=y;s.vx=s.sweepDir*1450;s.vy=0;s.angle=s.sweepDir==1 and 0 or math.pi
   s.cleanStage='dash';s.fogFront=start
  end
 elseif s.cleanStage=='dash' then
  local before=s.x
  s.vx=s.sweepDir*1450;s.vy=0;s.x=s.x+s.vx*dt;s.y=y;s.fogFront=s.x
  -- The broad air wake seals only scars crossed by this pass.
  local left,right=math.min(before,s.x)-65,math.max(before,s.x)+65
  for _,p in ipairs(s.holes) do
   local x,py=(p.x+p.tx)/2,(p.y+p.ty)/2
   if x>=left and x<=right and math.abs(py-y)<=72 then p.closing=true end
  end
  if s.sweepDir==1 and s.x>Arena.width+110 or s.sweepDir==-1 and s.x< -110 then
   s.fogRows=s.cleanIndex
   if s.cleanIndex==5 then s.cleanStage='settle';s.cleanClock=.18
   else s.cleanIndex=s.cleanIndex+1;s.sweepDir=-s.sweepDir;s.cleanStage='approach' end
  end
 elseif s.cleanStage=='settle' then
  s.cleanClock=s.cleanClock-dt
  if s.cleanClock<=0 then
   s.holes={};s.trailKeys={};s.fogAmount=0;s.groundRevision=s.groundRevision+1
   s.cleanStage=nil;return true
  end
 end
 return false
end
return W
