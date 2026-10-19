-- All lava shares one molten surface, including joined painted strokes.
local L={}
function L.draw(zone,time,alpha,biome)
 L.drawAll({zone},time,alpha,biome)
end
function L.drawAll(zones,time,alpha,biome)
 require('terrain_surface').draw(zones,'lava',time,alpha,biome)
 require('lava_sparks').draw(zones,time,alpha)
end
return L
