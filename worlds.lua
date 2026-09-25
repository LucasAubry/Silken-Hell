-- Stable IDs preserve saved scores; display/progression follow this separate order.
local W={order={1,6,5,4,7,2,3},names={'Paradis','Enfer','Renaissance','Océan','Terre','Ciel','Abysse'}}
W.palette={
 [3]={floor={.08,.36,.06},ink={.3,.75,.16},tear={.85,1,.5}},
 [1]={floor={.84,.78,.60},ink={.65,.48,.24},tear={1,1,1}},
 [2]={floor={.13,.03,.04},ink={.58,.08,.05},tear={1,.12,.1}},
 [4]={floor={.025,.16,.23},ink={.04,.43,.47},tear={.32,.94,1}},
 [5]={floor={.18,.105,.06},ink={.38,.25,.12},tear={.86,.65,.39}},
 [6]={floor={.22,.40,.56},ink={.61,.75,.83},tear={.8,.92,1}},
 [7]={floor={.018,.025,.09},ink={.13,.15,.36},tear={.08,.22,.48}}
}
W.selection={1,6,5,4,7,2,3,8}
W.names[8]='Le Sanctuaire';W.palette[8]={floor={.055,.035,.12},ink={.32,.22,.48},tear={.85,.72,1}}
W.rush={1,6,5,4,7,2}
W.secretBiomes={[9]=1,[10]=6,[11]=5,[12]=4,[13]=7,[14]=2}
for id,biome in pairs(W.secretBiomes) do W.palette[id]=W.palette[biome] end
W.names[9]='Merle Démon';W.names[10]='Merle des orages Démon';W.names[11]='Hérisson Démon';W.names[12]='Poulpe Démon';W.names[13]='Léviathan Démon';W.names[14]='Sœurs de lave Démon'
function W.isSecret(id) return W.secretBiomes[id]~=nil end
function W.levelCount(id) if W.isSecret(id) then return 1 end;return id==3 and #W.rush or 10 end
function W.biome(id,level) if id==8 then return 2 end;if W.secretBiomes[id] then return W.secretBiomes[id] end;return id end
function W.playable(id) return W.palette[id]~=nil end
function W.rank(id) for i,w in ipairs(W.order) do if w==id then return i end end; return math.huge end
function W.sanctuaryUnlocked()
    for _,id in ipairs(W.order) do if not Profile.hasCompleted(id) then return false end end
    return true
end
function W.canEnter(id)
    if id==8 or W.isSecret(id) then return W.sanctuaryUnlocked() end
    local previous=W.previous(id)
    return W.playable(id) and (not previous or Profile.hasCompleted(previous))
end
function W.canViewScores(id) return Profile.hasCompleted(id) end
function W.displayName(id) return W.canEnter(id) and W.names[id] or '???' end
function W.next(id) for i=W.rank(id)+1,#W.order do if W.playable(W.order[i]) then return W.order[i] end end end
function W.previous(id) for i,w in ipairs(W.order) do if w==id then return W.order[i-1] end end end
function W.color(id) return W.palette[id] or W.palette[1] end
return W
