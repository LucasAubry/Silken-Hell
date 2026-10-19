-- Reserve landing space through the actors' existing jump destinations.
local J={}
function J.choose(f,actor)
 local best,score
 for row=0,4 do for col=0,7 do
  local x=90+col*(Arena.width-180)/7;local y=95+row*100
  if not Arena.blocked(x-29,y-25,58,50) then
   local clearance=math.huge
   local function avoid(other)
    if other~=actor and not other.dead then
     local j=other.jump
     local tx,ty=j and j.tx or other.x,j and j.ty or other.y
     clearance=math.min(clearance,(x-tx)^2+(y-ty)^2,(x-other.x)^2+(y-other.y)^2)
    end
   end
   avoid(f);for _,b in ipairs(f.babies) do avoid(b) end
   local travel=(x-actor.x)^2+(y-actor.y)^2
   local value=(clearance>=110^2 and 1e9 or clearance*100)+math.min(clearance,180^2)*8+travel
   if not score or value>score then best={x=actor.x,y=actor.y,tx=x,ty=y};score=value end
  end
 end end
 return best or {x=actor.x,y=actor.y,tx=actor.x,ty=actor.y}
end
return J
