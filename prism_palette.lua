-- Shared material and effect colors; IDs match the biome, not progression order.
local P={colors={
 [1]={{.98,.91,.75},{.24,.94,1},{.85,.48,1}},
 [2]={{1,.15,.055},{1,.17,.48},{1,.73,.19}},
 [3]={{.18,.94,.42},{.75,1,.32},{1,.66,.83}},
 [4]={{.07,.93,.86},{.18,.48,1},{.65,.96,1}},
 [5]={{.96,.40,.17},{1,.77,.28},{.30,.82,.57}},
 [6]={{.62,.91,1},{.42,.57,1},{.95,.93,1}},
 [7]={{.62,.26,1},{.12,.44,1},{.18,1,.88}},
 [8]={{.80,.32,1},{.94,.82,1},{.30,.84,1}},
}}
function P.current()
 if App and App.state=='bossWorld' then return 8 end
 return Campaign and Campaign.biome or 1
end
function P.get(id) return P.colors[id or P.current()] or P.colors[1] end
function P.sample(phase,id)
 local p=P.get(id);local q=(phase%1)*3;local i=math.floor(q)+1
 local t=q-math.floor(q);t=t*t*(3-2*t)
 local a,b=p[i],p[i%3+1]
 return a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t
end
function P.send(shader,id,prefix)
 local p=P.get(id);prefix=prefix or 'palette_'
 shader:send(prefix..'a',p[1]);shader:send(prefix..'b',p[2]);shader:send(prefix..'c',p[3])
end
return P
