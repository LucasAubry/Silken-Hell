local P={}
local warm={.13,.10,.075};local cool={.055,.085,.12};local neutral={.075,.085,.09}
function P.color()
 local biome=Campaign and Campaign.biome
 if biome==1 or biome==2 or biome==5 then return warm end
 if biome==4 or biome==6 or biome==7 then return cool end
 return neutral
end
return P
