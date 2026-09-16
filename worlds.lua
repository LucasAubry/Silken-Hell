local W={order={1,2,4,5,6},names={'Paradis','Enfer','Renaissance','Océan','Terre','Ciel'}}
W.palette={
 [1]={floor={.84,.78,.60},ink={.65,.48,.24},tear={1,1,1}},
 [2]={floor={.13,.03,.04},ink={.58,.08,.05},tear={1,.12,.1}},
 [4]={floor={.025,.16,.23},ink={.04,.43,.47},tear={.32,.94,1}},
 [5]={floor={.18,.105,.06},ink={.38,.25,.12},tear={1,.68,.3}},
 [6]={floor={.22,.40,.56},ink={.61,.75,.83},tear={.8,.92,1}}
}
function W.playable(id) return W.palette[id]~=nil end
function W.canEnter(id) return W.playable(id) and id<=Profile.unlocked end
function W.next(id) for i,w in ipairs(W.order) do if w==id then return W.order[i+1] end end end
function W.previous(id) for i,w in ipairs(W.order) do if w==id then return W.order[i-1] end end end
function W.color(id) return W.palette[id] or W.palette[1] end
return W
