local C={names={'Soie','Perle','Braise','Écume','Royale','Auréole','Zéphyr','Ambre','Corail','Lanterne','Cendre','Renouveau','Gillou','Maxance'},keys={'original','spider','hell_spider','ocean_spider','crown_spider','spider','spider','spider','ocean_spider','spider','hell_spider','crown_spider','crown_spider','crown_spider'}}
C.tints={[6]={1,.9,.55},[7]={.58,.83,1},[8]={.8,.49,.21},[9]={.25,1,.82},[10]={.43,.45,1},[11]={1,.25,.12},[12]={1,.63,.78},[13]={1,.68,.12},[14]={.7,1,.6}}
-- IDs 1–14 stay stable for existing profiles, leaderboards and replays.
-- Keep legacy reward IDs and lookup names for saved profiles and replays.
C.crowned={};C.crownedByWorld={}
for rank,world in ipairs(Worlds.order) do
 local base=rank+5;local index=14+rank
 C.names[index]=C.names[base]..' dorée';C.keys[index]=C.keys[base]
 C.crowned[index]=base;C.crownedByWorld[world]=index
end
C.names[22]='Soie dorée';C.keys[22]='original';C.crowned[22]=1
C.variants={}
for reward,base in pairs(C.crowned) do C.variants[base]=reward end
function C.demonCompleted(world)
 if Hardcore and (Hardcore.completed[tostring(world)] or Hardcore.completed[world]) then return true end
 for secret,biome in pairs(Worlds.secretBiomes) do if biome==world and Profile.hasCompleted(secret) then return true end end
 return false
end
-- All spider skins are crown-free; reward IDs remain stable.
C.nativeCrown={}
function C.unlocked(index)
    if index==22 then return Profile.hasCompleted(3) or (Hardcore and Hardcore.completed['3']==true) end
    if C.crowned[index] then return C.demonCompleted(Worlds.order[index-14]) end
    if index<=5 then return true end
    if index<=12 then return Profile.hasCompleted(Worlds.order[index-5]) end
    return Profile.achievements[index==13 and 'gillou' or 'maxance']==true
end
function C.selected()
    if Replay and Replay.playing and not Replay.ghost then return Replay.data.skin or 1 end
    local index=math.max(1,math.min(#C.keys,Profile.character or 1))
    return C.unlocked(index) and index or 1
end
function C.cycle(step)
    local selected=C.selected();local gold=C.crowned[selected]~=nil
    local base=C.crowned[selected] or selected
    repeat
        base=(base-1+step)%14+1
    until C.unlocked(base) or (C.variants[base] and C.unlocked(C.variants[base]))
    local variant=C.variants[base]
    Profile.character=(variant and C.unlocked(variant) and (gold or not C.unlocked(base))) and variant or base
    Profile.save()
end
function C.selectVariant(gold)
    local selected=C.selected();local base=C.crowned[selected] or selected
    local target=base
    if gold then target=C.variants[base] end
    if not target or not C.unlocked(target) then return false end
    Profile.character=target;Profile.save();return true
end
function C.variantHint(reward)
    if not reward then return 'Ce skin ne possède pas de variante.' end
    if C.unlocked(reward) then return 'Variante dorée débloquée' end
    if reward==22 then return 'Termine Renaissance en histoire ou en hardcore.' end
    local world=Worlds.order[reward-14]
    return 'Termine '..Worlds.names[world]..(world==3 and ' en hardcore.' or ' en hardcore ou son boss du Sanctuaire.')
end
C.playerWidth=59
-- Authored PNGs: Perle's front/back silhouette, Soie's profile silhouette.
C.skinColors={original={.61,.33,.14},spider={1,1,1},hell_spider={1,.25,.08},ocean_spider={.2,.75,1},crown_spider={.67,.42,.9}}
function C.model(dir)
    dir=dir or 'down'
    return 'player_skin_'..((dir=='left' or dir=='right') and 'profil' or dir)
end
function C.portrait(index,x,y,size,dir,locked,walk)
    index=math.max(1,math.min(#C.keys,tonumber(index) or 1));dir=dir or 'down'
    local g=love.graphics;local red,green,blue,alpha=g.getColor()
    if alpha<1 and C.crowned[index] then
        -- Fade body and its accessories/FX together, including overlaps in trails.
        C.fadeCanvas=C.fadeCanvas or g.newCanvas(160,160)
        local target=g.getCanvas()
        g.push('all');g.setCanvas(C.fadeCanvas);g.origin();g.setScissor();g.setShader()
        g.clear(0,0,0,0);g.setColor(1,1,1);g.setBlendMode('alpha')
        C.portrait(index,80,80,100,dir,locked,walk)
        g.setCanvas(target);g.pop()
        g.push('all');g.setColor(red*alpha,green*alpha,blue*alpha,alpha)
        g.setBlendMode('alpha','premultiplied');g.draw(C.fadeCanvas,x,y,0,size/100,size/100,80,80);g.pop()
        return
    end
    local reward=C.crowned[index]~=nil
    if reward then index=C.crowned[index] end
    local fx=require('skin_reward_fx')
    if reward then fx.orbit(x,y,size,false,locked) end
    local g=love.graphics;g.push('all')
    local key=C.model(dir)
    local a=Art.images[key];local pose=dir=='right' and 'left' or dir
    local body=C.skinColors[C.keys[index]];local tint=C.tints[index] or {1,1,1}
    C.skinShader=C.skinShader or g.newShader('assets/shaders/player_skin.glsl')
    C.skinShader:send('bodyColor',{body[1]*tint[1],body[2]*tint[2],body[3]*tint[3]})
    C.skinShader:send('sideView',pose=='left')
    C.skinShader:send('frontView',pose=='down')
    C.skinShader:send('brownSkin',index==1)
    C.skinShader:send('locked',locked==true)
    g.setShader(C.skinShader)
    g.translate(x,y);if dir=='right' then g.scale(-1,1) end
    local width=size*a.w/math.max(a.w,a.h)
    if not (walk and require('brown_walk').draw(a.image,pose,0,0,width,walk,a.quad)) then Art.draw(key,0,0,width,0) end
    g.pop()
    if reward then fx.orbit(x,y,size,true,locked) end
end
-- Dedicated selection artwork; movement sprites and gameplay animation stay separate.
function C.selectionPortrait(x,y,size)
    local g=love.graphics;local selected=C.selected();local base=C.crowned[selected] or selected
    local x0,y0=g.transformPoint(0,0);local x1,y1=g.transformPoint(1,0)
    local scale=math.max(.25,math.sqrt((x1-x0)^2+(y1-y0)^2))
    local pixels=math.ceil(size*scale);local key=base..':'..pixels
    -- Resolve the large PNG once at display resolution. Moving the cached image
    -- smoothly no longer selects different source pixels inside the gold markings.
    if C.menuCacheKey~=key then
        if C.menuCache then C.menuCache:release() end
        C.menuCache=g.newCanvas(pixels+8,pixels+8,{dpiscale=1})
        C.menuCache:setFilter('linear','linear')
        g.push('all');g.setCanvas(C.menuCache);g.origin();g.setScissor();g.setShader();g.clear(0,0,0,0)
        g.setBlendMode('alpha');g.setColor(1,1,1)
        C.portrait(base,(pixels+8)/2,(pixels+8)/2,pixels,'down')
        g.pop();C.menuCacheKey=key
    end
    local fx=require('skin_reward_fx');local reward=C.crowned[selected]~=nil
    if reward then
        if App.state=='menu' then fx.rays(x,y,size) end
        fx.orbit(x,y,size,false,false)
    end
    g.push('all');g.setShader();g.setBlendMode('alpha','premultiplied')
    local r,green,b,a=g.getColor();g.setColor(r*a,green*a,b*a,a)
    g.draw(C.menuCache,x,y,0,size/pixels,size/pixels,(pixels+8)/2,(pixels+8)/2);g.pop()
    if reward then fx.orbit(x,y,size,true,false) end
end
function C.draw(x,y,width,dir,walk)
    local selected=C.selected()
    if App.state=='playing' and C.crowned[selected] then require('skin_reward_fx').rays(x,y,width) end
    C.portrait(selected,x,y,width,dir,nil,walk)
end
-- Crown variants retain the body color of their base skin.
C.bodyColors={original={.57,.29,.10},spider={.94,.90,.79},hell_spider={1,.20,.055},ocean_spider={.15,.68,.91},crown_spider={.94,.90,.79}}
function C.effectColor(index)
    index=index or C.selected();index=C.crowned[index] or index
    local body=C.bodyColors[C.keys[index]] or C.bodyColors.original
    if index==5 then return {.60,.32,.90} end
    local tint=C.tints[index] or {1,1,1}
    return {body[1]*tint[1],body[2]*tint[2],body[3]*tint[3]}
end
return C
