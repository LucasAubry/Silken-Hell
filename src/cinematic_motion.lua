-- Cubic trajectories share endpoint velocities, including across animation phases.
local M={}
function M.sample(keys,t)
 if t<=keys[1][1] then return keys[1][2] end
 for i=2,#keys do
  local a,b=keys[i-1],keys[i]
  if t<=b[1] then
   local span=b[1]-a[1];local u=(t-a[1])/span;local u2,u3=u*u,u*u*u
   return (2*u3-3*u2+1)*a[2]+(u3-2*u2+u)*span*a[3]+(-2*u3+3*u2)*b[2]+(u3-u2)*span*b[3]
  end
 end
 return keys[#keys][2]
end
return M
