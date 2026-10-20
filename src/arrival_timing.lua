-- Keep each journey's choreography, with the same pace and handoff as Paradise → Sky.
local T={duration=6.7,settle=.7,reveal=1.4}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function T.fit(scene)
 local finish=scene.impact or scene.duration
 local rawDuration=scene.duration
 local landing=T.duration-T.settle
 local function toSource(t)
  if t<=landing then return t*finish/landing end
  return finish+(t-landing)*(rawDuration-finish)/T.settle
 end
 local function toScreen(t)
  if t<=finish then return t*landing/finish end
  return landing+(t-finish)*T.settle/(rawDuration-finish)
 end
 local pose=scene.pose
 scene.pose=function(t)
  local p=pose(t)
  local alpha=ease((toScreen(t)-(landing-T.reveal))/T.reveal)
  p.mapAlpha=alpha;p.actorsAlpha=alpha
  return p
 end
 local proxy={duration=T.duration,impact=landing,timelineTime=toScreen}
 function proxy.begin(...)
  scene.begin(...);return T.duration
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
