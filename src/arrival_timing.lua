-- Extend moving descents without stretching pickups or the final settled pose.
local T={duration=6.7,settle=.7,reveal=1.4}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function T.fit(scene,fall)
 local finish=scene.impact or scene.duration
 local rawDuration=scene.duration
 local extra=fall and fall.extra or 0
 local baseLanding=T.duration-T.settle
 local landing=baseLanding+extra
 local duration=T.duration+extra
 local function toScreen(t)
  if t<=finish then
   local extension=fall and extra*ease((t-fall.from)/(fall.to-fall.from)) or 0
   return t*baseLanding/finish+extension
  end
  return landing+(t-finish)*(rawDuration>finish and T.settle/(rawDuration-finish) or 1)
 end
 local function toSource(t)
  if t>=landing then return finish+(t-landing)*(rawDuration-finish)/T.settle end
  if t<=0 then return t*finish/baseLanding end
  -- The smooth, monotonic time map keeps speed continuous at both ends
  -- of the extended fall; invert it rather than switching playback rates.
  local lo,hi=0,finish
  for _=1,40 do
   local mid=(lo+hi)*.5
   if toScreen(mid)<t then lo=mid else hi=mid end
  end
  return (lo+hi)*.5
 end
 local pose=scene.pose
 scene.pose=function(t)
  local p=pose(t)
  local alpha=ease((toScreen(t)-(landing-T.reveal))/T.reveal)
  p.mapAlpha=alpha;p.actorsAlpha=alpha
  return p
 end
 local proxy={duration=duration,impact=landing,timelineTime=toScreen}
 function proxy.begin(...)
  scene.begin(...);return duration
 end
 function proxy.advance(age)scene.advance(toSource(age))end
 function proxy.pose(age)return scene.pose(toSource(age))end
 if scene.cloudState then function proxy.cloudState(index,age)return scene.cloudState(index,toSource(age))end end
 if scene.position then function proxy.position(age,...)return scene.position(toSource(age),...)end end
 return setmetatable(proxy,{__index=function(_,key)
  if key=='age' then return toScreen(scene.age or 0) end
  return scene[key]
 end})
end
return T
