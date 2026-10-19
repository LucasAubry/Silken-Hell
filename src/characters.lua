local C={names={'Soie','Perle','Braise','Écume','Royale','Auréole','Zéphyr','Ambre','Corail','Lanterne','Cendre','Renouveau','Gil','C’est que le début'},keys={'original','spider','hell_spider','ocean_spider','crown_spider','spider','spider','spider','ocean_spider','spider','hell_spider','crown_spider','crown_spider','crown_spider'}}
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
C.names[23]='Cocon';C.keys[23]='cocon'
C.names[24]='Champagne';C.keys[24]='champagne'
C.names[25]='Sauge';C.keys[25]='sage'
C.names[26]='Pétrole';C.keys[26]='petrol'
C.names[27]='Hardie';C.keys[27]='amir'
-- Menu silk colors share the authored spider rig, including its gold markings.
C.materials={
 [24]={body={.98,.85,.65},markings={1,.72,.24},iris={1,.72,.22},effect={.98,.81,.51}},
 [25]={body={.58,.73,.43},markings={1,.87,.54},iris={.71,.90,.35},effect={.65,.79,.46}},
 [26]={body={.18,.42,.43},markings={1,.84,.45},iris={.40,.91,.88},effect={.30,.69,.68}},
}
-- Render palettes are separate from unlock rules and stable profile/replay IDs.
C.silkPalettes={}
local silkBodies={
 [2]={.94,.92,.82},[3]={1,.40,.06},[4]={.36,.69,.77},
 [5]={.60,.43,.72},[6]={.95,.82,.50},[7]={.98,.98,.94},
 [8]={.74,.55,.33},[9]={.32,.73,.62},[10]={.43,.49,.76},
 [11]={.93,.12,.05},[12]={.94,.92,.85},[13]={.90,.16,.07},
}
local silkGold={1,.78,.35}
for index,body in pairs(silkBodies) do
 C.silkPalettes[index]={body=body,markings=silkGold,iris={.43,.78,.83},effect=body}
end
C.silkPalettes[7].markings={1,1,.025}
C.silkPalettes[7].iris={1,.94,.06}
C.silkPalettes[13].markings={1,.34,.08}
C.silkPalettes[13].iris={1,.49,.15}
function C.material(index) return C.materials[index] or C.silkPalettes[index] end
C.customSprites={[1]='base_marron',[14]='maxance',[23]='cocon'}
for index,name in pairs(require('integrated_skins').names) do C.customSprites[index]=name end
-- Retired Braise ID stays readable in old scores/replays, using Cendre artwork.
C.customSprites[3]='cendre';C.names[3]='Cendre'
C.variants={}
for reward,base in pairs(C.crowned) do C.variants[base]=reward end
function C.demonCompleted(world)
 if Hardcore and (Hardcore.completed[tostring(world)] or Hardcore.completed[world]) then return true end
 for secret,biome in pairs(Worlds.secretBiomes) do if biome==world and Profile.hasCompleted(secret) then return true end end
 return false
end
-- All spider skins are crown-free; reward IDs remain stable.
C.nativeCrown={}
C.baseIndices={1,2,4,5,6,7,8,10,11,12,13,14,23,24,25,26,27}
C.baseCount=#C.baseIndices
function C.unlocked(index)
    if index==3 or index==9 then return false end
    if not C.names[index] then return false end
    if index==5 or index==26 then return require('demo_progress').unlocked() or Profile.devProgress==true end
    if index==4 then return Profile.hasCompleted(4) end
    if index==24 then return Profile.achievements.workshop_publish==true end
    if index==25 then return Profile.achievements.workshop_test==true end
    if index==27 then return require('achievements').unlocked({id='hardcore_all'}) end
    if index==23 then return require('achievements').unlocked({id='flawless_all'}) end
    if (Profile.skinGrants or {})[tostring(index)]==true then return true end
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
    local selected=C.menuIndex()
    local base=C.crowned[selected] or selected
    local position=1
    for i,index in ipairs(C.baseIndices) do if index==base then position=i;break end end
    C.select(C.baseIndices[(position-1+step)%C.baseCount+1])
end
function C.menuIndex() return C.browsed~=3 and C.browsed~=9 and C.browsed or C.selected() end
function C.select(index)
    index=C.crowned[index] or index
    C.browsed=index
    if not C.unlocked(index) then return false end
    Profile.character=index;Profile.save();return true
end
function C.selectVariant(gold)
    return require('skin_effects').equip('hardcore',gold)
end
function C.variantHint(reward)
    if not reward then return 'Ce skin ne possède pas de variante.' end
    return require('skin_effects').unlocked('hardcore') and 'Auréole hardcore débloquée' or 'Termine un parcours en hardcore.'
end
C.playerWidth=59
-- Authored PNGs: Perle's front/back silhouette, Soie's profile silhouette.
C.skinColors={original={.61,.33,.14},spider={1,1,1},hell_spider={1,.25,.08},ocean_spider={.2,.75,1},crown_spider={.67,.42,.9}}
local white={1,1,1}
local blueIris={.35,.8,1}
local brownIris={1,.65,.12}
local eyePositions={.40,.60}
-- Reuse these uniform vectors in the moving sprite and its dash ghosts.
C.drawColors={}
for index,key in ipairs(C.keys) do
 local material=C.material(index)
 if material then C.drawColors[index]=material.body
 elseif C.skinColors[key] then
  local body=C.skinColors[key];local tint=C.tints[index] or white
  C.drawColors[index]={body[1]*tint[1],body[2]*tint[2],body[3]*tint[3]}
 end
end
function C.model(dir,index)
    dir=dir or 'down'
    if (C.crowned[index] or index)==12 then
        for _,name in ipairs({'partner','partner_up','partner_left'}) do
            local key='final_'..name;if not Art.images[key] then Art.add(key,'assets/sprites/final/'..name..'.png') end
        end
        return ({down='final_partner',up='final_partner_up',left='final_partner_left',right='final_partner_left'})[dir]
    end
    local custom=C.customSprites[C.crowned[index] or index]
    return 'player_skin_'..(custom and custom..'_' or '')..((dir=='left' or dir=='right') and 'profil' or dir)
end
function C.portrait(index,x,y,size,dir,locked,walk,marineOverlay)
    index=math.max(1,math.min(#C.keys,tonumber(index) or 1));dir=dir or 'down'
    local g=love.graphics;local red,green,blue,alpha=g.getColor()
    if alpha<1 and C.crowned[index] then
        -- Fade body and its accessories/FX together, including overlaps in trails.
        C.fadeCanvas=C.fadeCanvas or g.newCanvas(200,200)
        local target=g.getCanvas()
        g.push('all');g.setCanvas(C.fadeCanvas);g.origin();g.setScissor();g.setShader()
        g.clear(0,0,0,0);g.setColor(1,1,1);g.setBlendMode('alpha')
        C.portrait(index,100,100,100,dir,locked,walk,marineOverlay)
        g.setCanvas(target);g.pop()
        g.push('all');g.setColor(red*alpha,green*alpha,blue*alpha,alpha)
        g.setBlendMode('alpha','premultiplied');g.draw(C.fadeCanvas,x,y,0,size/100,size/100,100,100);g.pop()
        return
    end
    -- Resolve tiny leaderboard portraits from the complete eye artwork, rather
    -- than letting nearest-neighbour sampling select only their dark pupils.
    if size<=32 and not walk and (C.crowned[index] or index)~=1 then
        C.smallPortraits=C.smallPortraits or {}
        local cacheKey=index..':'..dir..':'..tostring(locked)..':'..tostring(marineOverlay)
        local canvas=C.smallPortraits[cacheKey]
        if not canvas then
            canvas=g.newCanvas(384,384,{mipmaps='auto',dpiscale=1})
            canvas:setFilter('linear','linear');canvas:setMipmapFilter('linear')
            g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.setShader()
            g.clear(0,0,0,0);g.setColor(1,1,1);g.setBlendMode('alpha')
            C.portrait(index,192,192,224,dir,locked,nil,marineOverlay)
            g.pop();C.smallPortraits[cacheKey]=canvas
        end
        g.push('all');g.setShader();g.setBlendMode('alpha','premultiplied')
        g.setColor(red*alpha,green*alpha,blue*alpha,alpha)
        g.draw(canvas,x,y,0,size/224,size/224,192,192)
        if dir=='down' and (C.crowned[index] or index)~=12 and not locked and not C.customSprites[C.crowned[index] or index] then
            -- Keep the iris and catchlight legible below one source eye pixel.
            local a=Art.images[C.model(dir)];local qx,qy=a.quad:getViewport()
            local iw,ih=a.image:getDimensions();local scale=size/math.max(a.w,a.h)
            local base=C.crowned[index] or index
            local iris=C.material(base) and C.material(base).iris or base==1 and brownIris or blueIris
            g.setBlendMode('alpha')
            for _,u in ipairs(eyePositions) do
                local ex=x+(u*iw-qx-a.w/2)*scale;local ey=y+(.595*ih-qy-a.h/2)*scale
                g.setColor(iris[1],iris[2],iris[3],alpha)
                g.ellipse('fill',ex,ey,size*.022,size*.03)
                g.setColor(1,.98,.9,alpha);g.circle('fill',ex-.18,ey-.35,.3)
            end
        end
        g.pop();return
    end
    index=C.crowned[index] or index
    require('skin_accessories').draw(index,x,y,size,dir,locked,false,alpha,marineOverlay)
    local g=love.graphics;g.push('all')
    local key=C.model(dir,index)
    local a=Art.images[key];local pose=dir=='right' and 'left' or dir
    if index==1 then
        -- Soie's exported pixel sprites already contain their brown body and amber eyes.
        g.setShader()
        if locked then require('locked_art').bind() end
    elseif C.customSprites[index] or index==12 then
        -- Keep each custom source and accessories, with the same softened ink finish.
        C.customSkinShader=C.customSkinShader or g.newShader('assets/shaders/custom_skin_material.glsl')
        C.customSkinShader:send('brownBody',index==8)
        g.setShader(C.customSkinShader)
        if locked then
            require('locked_art').bind()
        end
    else
        local material=C.material(index)
        C.skinShader=C.skinShader or g.newShader('assets/shaders/player_skin.glsl')
        C.skinShader:send('bodyColor',C.drawColors[index])
        C.skinShader:send('paletteSkin',material~=nil)
        if material then
            C.skinShader:send('markingColor',material.markings)
            C.skinShader:send('irisColor',material.iris)
        end
        C.skinShader:send('sideView',pose=='left')
        C.skinShader:send('frontView',pose=='down')
        C.skinShader:send('brownSkin',index==1)
        C.skinShader:send('locked',locked==true)
        g.setShader(C.skinShader)
    end
    g.translate(x,y);if dir=='right' then g.scale(-1,1) end
    local width=size*a.w/math.max(a.w,a.h)*(a.renderScale or 1)
    if not (walk and require('brown_walk').draw(a.image,pose,0,0,width,walk,a.quad)) then Art.draw(key,0,0,width,0) end
    g.pop()
    require('skin_accessories').draw(index,x,y,size,dir,locked,true,alpha,marineOverlay)
    if locked then
        require('locked_art').question(x,y,size,alpha)
    end
end
-- Dedicated selection artwork; movement sprites and gameplay animation stay separate.
function C.selectionPortrait(x,y,size)
    local g=love.graphics;local selected=C.menuIndex();local base=C.crowned[selected] or selected
    local locked=not C.unlocked(selected)
    local x0,y0=g.transformPoint(0,0);local x1,y1=g.transformPoint(1,0)
    local scale=math.max(.25,math.sqrt((x1-x0)^2+(y1-y0)^2))
    local density=g.getPixelWidth()/g.getWidth()
    local pixels=math.ceil(size*scale*density);local key=base..':'..pixels..':'..tostring(locked)
    -- Resolve the large PNG once at display resolution. Moving the cached image
    -- smoothly no longer selects different source pixels inside the gold markings.
    if C.menuCacheKey~=key then
        if C.menuCache then C.menuCache:release() end
        C.menuCache=g.newCanvas(pixels*2+8,pixels*2+8,{dpiscale=1})
        C.menuCache:setFilter('nearest','nearest')
        g.push('all');g.setCanvas(C.menuCache);g.origin();g.setScissor();g.setShader();g.clear(0,0,0,0)
        g.setBlendMode('alpha');g.setColor(1,1,1)
        C.portrait(base,pixels+4,pixels+4,pixels,'down',locked)
        g.pop();C.menuCacheKey=key
    end
    local effects=require('skin_effects')
    if not locked then effects.behind(x,y,size) end
    g.push('all');g.setShader();g.setBlendMode('alpha','premultiplied')
    local r,green,b,a=g.getColor();g.setColor(r*a,green*a,b*a,a)
    g.draw(C.menuCache,x,y,0,size/pixels,size/pixels,pixels+4,pixels+4);g.pop()
    if not locked then effects.front(x,y,size,nil,'down',selected) end
    if not locked then require('skin_extension').draw(x,y,size,'down',false,true,selected) end
end
function C.shadow(x,y,size,dir,walk)
    local g=love.graphics
    C.shadowShader=C.shadowShader or g.newShader([[
        vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel) {
            float radius=length((uv-.5)*2.);
            float shade=1.-smoothstep(.35,1.,radius);
            return vec4(.012,.009,.007,shade*color.a);
        }
    ]])
    g.push('all');g.setShader(C.shadowShader);g.setBlendMode('alpha');g.setColor(1,1,1,.78)
    local rx,ry=size*.48,size*.245
    g.draw(UI.pixel,x-rx,y+size*.20-ry,0,rx*2,ry*2)
    g.pop()
end
function C.draw(x,y,width,dir,walk,marineOverlay)
    local selected=C.selected()
    local effects=require('skin_effects');effects.behind(x,y,width)
    C.portrait(selected,x,y,width,dir,nil,walk,marineOverlay)
    effects.front(x,y,width,nil,dir)
    require('skin_extension').draw(x,y,width,dir,false,true)
end
-- Score portraits use the run's cosmetics, never the current viewer's toggles.
function C.scorePortrait(score,x,y,size)
    local effects=score.effects or {};local fx=require('skin_effects')
    if effects.gold then fx.behind(x,y,size,'gold') end
    C.portrait(score.skin or 1,x,y,size)
    if effects.hardcore then fx.front(x,y,size,'hardcore','down',score.skin or 1) end
    if effects.gold then fx.front(x,y,size,'gold') end
    if effects.heartbreak then require('skin_extension').draw(x,y,size,'down',true,true,score.skin or 1) end
end
-- Crown variants retain the body color of their base skin.
C.bodyColors={original={.57,.29,.10},spider={.94,.90,.79},hell_spider={1,.20,.055},ocean_spider={.15,.68,.91},crown_spider={.94,.90,.79}}
C.bodyColors.cocon={.94,.94,.90}
C.bodyColors.amir={1,.23,.035}
for index,material in pairs(C.materials) do C.bodyColors[C.keys[index]]=material.effect end
function C.effectColor(index)
    index=index or C.selected();index=C.crowned[index] or index
    local material=C.material(index)
    if material then return material.effect end
    local body=C.bodyColors[C.keys[index]] or C.bodyColors.original
    if index==5 then return {.60,.32,.90} end
    local tint=C.tints[index] or {1,1,1}
    return {body[1]*tint[1],body[2]*tint[2],body[3]*tint[3]}
end
return C
