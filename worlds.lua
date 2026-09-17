-- Stable IDs preserve saved scores; display/progression follow this separate order.
local W={order={1,6,5,4,7,2,3},names={'Paradis','Enfer','Renaissance','Océan','Terre','Ciel','Abysse'}}
W.palette={
 [3]={floor={.065,.018,.03},ink={.65,.08,.12},tear={1,.85,.88}},
 [1]={floor={.84,.78,.60},ink={.65,.48,.24},tear={1,1,1}},
 [2]={floor={.13,.03,.04},ink={.58,.08,.05},tear={1,.12,.1}},
 [4]={floor={.025,.16,.23},ink={.04,.43,.47},tear={.32,.94,1}},
 [5]={floor={.18,.105,.06},ink={.38,.25,.12},tear={.52,.28,.12}},
 [6]={floor={.22,.40,.56},ink={.61,.75,.83},tear={.8,.92,1}},
 [7]={floor={.018,.025,.09},ink={.13,.15,.36},tear={.62,.48,1}}
}
W.rush={1,6,5,4,7,2}
function W.levelCount(id) return id==3 and #W.rush or 10 end
function W.biome(id,level) return id==3 and W.rush[math.max(1,math.min(#W.rush,level or 1))] or id end
function W.playable(id) return W.palette[id]~=nil end
function W.rank(id) for i,w in ipairs(W.order) do if w==id then return i end end; return math.huge end
function W.canEnter(id) return W.playable(id) and W.rank(id)<=Profile.unlocked end
function W.next(id) for i=W.rank(id)+1,#W.order do if W.playable(W.order[i]) then return W.order[i] end end end
function W.previous(id) for i,w in ipairs(W.order) do if w==id then return W.order[i-1] end end end
function W.color(id) return W.palette[id] or W.palette[1] end
return W
