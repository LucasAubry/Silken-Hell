local C={names={'Soie','Perle','Braise','Écume','Royale','Auréole','Zéphyr','Ambre','Corail','Lanterne','Cendre','Renouveau','Gillou','Maxance'},keys={'original','spider','hell_spider','ocean_spider','crown_spider','spider','spider','spider','ocean_spider','spider','hell_spider','crown_spider','crown_spider','crown_spider'}}
C.tints={[6]={1,.9,.55},[7]={.58,.83,1},[8]={.8,.49,.21},[9]={.25,1,.82},[10]={.43,.45,1},[11]={1,.25,.12},[12]={1,.63,.78},[13]={1,.68,.12},[14]={.7,1,.6}}
-- IDs 1–14 stay stable for existing profiles, leaderboards and replays.
C.crowned={};C.crownedByWorld={}
for rank,world in ipairs(Worlds.order) do
 local base=rank+5;local index=14+rank
 C.names[index]=C.names[base]..' couronnée';C.keys[index]=C.keys[base]
 C.crowned[index]=base;C.crownedByWorld[world]=index
end
C.names[22]='Soie couronnée';C.keys[22]='original';C.crowned[22]=1
function C.demonCompleted(world)
 if Hardcore and (Hardcore.completed[tostring(world)] or Hardcore.completed[world]) then return true end
 for secret,biome in pairs(Worlds.secretBiomes) do if biome==world and Profile.hasCompleted(secret) then return true end end
 return false
end
-- Anchors are the bottom centre of the crown, on the forehead (not the body centre).
C.nativeCrown={[5]=true,[12]=true,[13]=true,[14]=true}
C.crownAnchors={
 original={down={0,.035,.23},up={0,-.265,.21},left={-.255,-.035,.19},right={.255,-.035,.19}},
 spider={down={0,.035,.23},up={0,-.265,.21},left={-.255,-.035,.19},right={.255,-.035,.19}},
 hell_spider={down={0,.015,.23},up={0,-.27,.21},left={-.245,-.055,.19},right={.245,-.055,.19}},
 ocean_spider={down={0,.055,.23},up={0,-.265,.21},left={-.255,-.035,.19},right={.255,-.035,.19}},
}
function C.crown(x,y,size,dir,locked,base)
 base=base or 1;dir=dir or 'down'
 if not Art.images.reward_crown then Art.add('reward_crown','assets/skins/accessoires/couronne.png') end
 local g=love.graphics;g.push('all');local _,_,_,alpha=g.getColor()
 g.setColor(locked and .5 or 1,locked and .5 or 1,locked and .5 or 1,alpha)
 if locked then
  C.gray=C.gray or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 sc){vec4 p=Texel(tex,uv);float v=dot(p.rgb,vec3(.299,.587,.114));return vec4(vec3(v*.65),p.a)*color;}]])
  g.setShader(C.gray)
 end
 g.translate(x,y);if dir=='right' then g.scale(-1,1);dir='left' end
 local a=C.crownAnchors.spider[dir]
 local image=Art.images.reward_crown;local width=size*a[3];local height=width*image.h/image.w
 -- Keep the same jewel and lighting in every view; only the perspective narrows.
 Art.draw('reward_crown',size*a[1],size*a[2]-height*.5,width,0,height)
 g.pop()
end
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
    local index=C.selected()
    repeat index=(index-1+step)%#C.keys+1 until C.unlocked(index)
    Profile.character=index;Profile.save()
end
C.playerWidth=59
-- Shared silhouettes: Perle from the front/back, Soie in profile.
C.skinColors={original={.61,.33,.14},spider={1,1,1},hell_spider={1,.25,.08},ocean_spider={.2,.75,1},crown_spider={.67,.42,.9}}
function C.model(dir)
    dir=dir or 'down'
    return (dir=='left' or dir=='right') and 'original_left' or 'spider_'..dir
end
function C.portrait(index,x,y,size,dir,locked,walk)
    index=math.max(1,math.min(#C.keys,tonumber(index) or 1));dir=dir or 'down'
    local g=love.graphics;local red,green,blue,alpha=g.getColor()
    if alpha<1 and (C.crowned[index] or C.nativeCrown[index]) then
        -- Fade body and crown as one silhouette, including their overlap in trails.
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
    if C.crowned[index] then
        local base=C.crowned[index]
        C.portrait(base,x,y,size,dir,locked,walk)
        if not C.nativeCrown[base] then C.crown(x,y,size,dir,locked,base) end
        return
    end
    local g=love.graphics;g.push('all')
    local key=C.model(dir)
    if not Art.images[key] then Art.add(key,'assets/skins/soie/profil.png') end
    local a=Art.images[key];local pose=dir=='right' and 'left' or dir
    local body=C.skinColors[C.keys[index]];local tint=C.tints[index] or {1,1,1}
    C.skinShader=C.skinShader or g.newShader('assets/shaders/player_skin.glsl')
    C.skinShader:send('bodyColor',{body[1]*tint[1],body[2]*tint[2],body[3]*tint[3]})
    C.skinShader:send('eyeColor',index==1 and {1,.53,.04} or {.12,.67,1})
    C.skinShader:send('sideView',pose=='left')
    C.skinShader:send('brownSkin',index==1)
    C.skinShader:send('locked',locked==true)
    g.setShader(C.skinShader)
    g.translate(x,y);if dir=='right' then g.scale(-1,1) end
    local width=size*a.w/math.max(a.w,a.h)
    if not (walk and require('brown_walk').draw(a.image,pose,0,0,width,walk,a.quad)) then Art.draw(key,0,0,width,0) end
    g.pop()
    if C.nativeCrown[index] then C.crown(x,y,size,dir,locked,index) end
end
-- Dedicated selection artwork; movement sprites and gameplay animation stay separate.
function C.selectionPortrait(x,y,size)
    return C.portrait(C.selected(),x,y,size,'down')
end
function C.draw(x,y,width,dir,walk)
    C.portrait(C.selected(),x,y,width,dir,nil,walk)
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
