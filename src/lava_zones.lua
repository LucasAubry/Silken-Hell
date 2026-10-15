-- Share the same molten banks in the editor and arena.
local L={}
function L.draw(zone,time,alpha)
 require('terrain_surface').draw({zone},'lava',time,alpha)
end
function L.drawAll(zones,time,alpha)
 require('terrain_surface').draw(zones,'lava',time,alpha)
end
return L
