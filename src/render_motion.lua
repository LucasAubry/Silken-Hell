-- Interpolate presentation between fixed ticks without changing simulation data.
local M={previous=setmetatable({},{__mode='k'})}
function M.reset() M.previous=setmetatable({},{__mode='k'}) end
local function remember(actor)
 if not actor or type(actor.x)~='number' or type(actor.y)~='number' then return end
 local pose=M.previous[actor]
 if not pose then pose={};M.previous[actor]=pose end
 pose.x,pose.y=actor.x,actor.y
end
function M.capture()
 remember(player)
 for _,actor in ipairs(mobs or {}) do remember(actor) end
end
function M.offset(actor)
 local r=Replay
 if not r or r.disabled or r.ghost or r.job or r.paused or not (r.recording or r.playing)
  or App.state~='playing' or require('run_start').active then return 0,0 end
 local pose=M.previous[actor]
 if not pose then return 0,0 end
 local dx,dy=pose.x-actor.x,pose.y-actor.y
 -- Teleports and knockbacks must appear at their destination immediately.
 if dx*dx+dy*dy>64*64 then return 0,0 end
 local remaining=1-math.max(0,math.min(1,r.accumulator/r.step))
 return dx*remaining,dy*remaining
end
function M.draw(actor,draw,...)
 local x,y=M.offset(actor)
 love.graphics.push();love.graphics.translate(x,y)
 draw(...)
 love.graphics.pop()
end
return M
