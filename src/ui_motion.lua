-- Presentation only; never changes gameplay timers, RNG or input dispatch.
local M={values={}}
function M.enabled() return not Graphics or Graphics.effects~=false end
function M.prepare()
 if M.state~=App.state then M.state=App.state;M.values={};M.pressed=nil end
 if M.cleanedAt==UI.clock then return end
 M.cleanedAt=UI.clock
 -- Dropdowns, pages and changing layouts cannot grow the cache indefinitely.
 for key,value in pairs(M.values) do if UI.clock-value.at>2 then M.values[key]=nil end end
end
function M.key(x,y,w,h) return table.concat({x,y,w,h},':') end
function M.focus(key,hover)
 M.prepare()
 local target=hover and 1 or 0
 if not M.enabled() then M.values[key]=nil;return target end
 local s=M.values[key] or {value=0,at=UI.clock,target=target}
 local dt=math.max(0,UI.clock-s.at)
 s.value=s.value+(s.target-s.value)*(1-math.exp(-dt/0.045))
 s.at=UI.clock;s.target=target;M.values[key]=s
 return s.value
end
function M.press(x,y,w,h)
 M.prepare();M.pressed={key=M.key(x,y,w,h),at=UI.clock}
end
function M.pressAmount(key)
 M.prepare()
 local p=M.pressed;if not p or p.key~=key or not M.enabled() then return 0 end
 local t=math.max(0,math.min(1,(UI.clock-p.at)/.22))
 return math.sin(t*math.pi)*(1-t)
end
function M.reveal(at,duration)
 if not M.enabled() then return 1 end
 local t=math.max(0,math.min(1,(UI.clock-at)/duration))
 return 1-(1-t)^3
end
return M
