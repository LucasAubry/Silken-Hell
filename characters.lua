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
 -- These portraits already contain a crown in all four directional PNGs.
 if C.nativeCrown[base] then return end
 if not Art.images.reward_crown then Art.add('reward_crown','assets/skins/accessoires/couronne.png') end
 local g=love.graphics;g.push('all');local _,_,_,alpha=g.getColor()
 g.setColor(locked and .5 or 1,locked and .5 or 1,locked and .5 or 1,alpha)
 if locked then
  C.gray=C.gray or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 sc){vec4 p=Texel(tex,uv);float v=dot(p.rgb,vec3(.299,.587,.114));return vec4(vec3(v*.65),p.a)*color;}]])
  g.setShader(C.gray)
 end
 local a=(C.crownAnchors[C.keys[base]] or C.crownAnchors.spider)[dir]
 local image=Art.images.reward_crown;local width=size*a[3];local height=width*image.h/image.w
 -- Keep the same jewel and lighting in every view; only the perspective narrows.
 Art.draw('reward_crown',x+size*a[1],y+size*a[2]-height*.5,width,0,height)
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
function C.portrait(index,x,y,size,dir,locked)
    index=math.max(1,math.min(#C.keys,tonumber(index) or 1))
    if C.crowned[index] then
        C.portrait(C.crowned[index],x,y,size,dir,locked);C.crown(x,y,size,dir,locked,C.crowned[index]);return
    end
    local g=love.graphics;g.push('all');local red,green,blue,alpha=g.getColor()
    if locked then
        C.gray=C.gray or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 sc){vec4 p=Texel(tex,uv);float v=dot(p.rgb,vec3(.299,.587,.114));return vec4(vec3(v*.65),p.a)*color;}]])
        g.setShader(C.gray)
    elseif C.tints[index] then local tint=C.tints[index];g.setColor(red*tint[1],green*tint[2],blue*tint[3],alpha) end
    if index==1 then
        dir=dir or 'down'
        local pose=dir=='right' and 'left' or dir
        local key='original_'..pose
        if not Art.images[key] then Art.add(key,'texture/spider_'..pose..'.png') end
        g.translate(x,y);if dir=='right' then g.scale(-1,1) end
        Art.draw(key,0,0,size,0)
    else
        g.translate(x,y);if dir=='right' then g.scale(-1,1) end
        Art.drawFacing(C.keys[index],dir=='right' and 'left' or (dir or 'down'),0,0,size)
    end
    g.pop()
end
-- Dedicated selection artwork; movement sprites and gameplay animation stay separate.
function C.selectionPortrait(x,y,size)
    return C.portrait(C.selected(),x,y,size,'down')
end
function C.draw(x,y,width,dir)
    local selected=C.selected()
    if (selected==1 or selected==22) and width<100 and player then
        local g=love.graphics;g.push();g.translate(x,y)
        if dir=='right' then g.scale(-1,1) end
        local pose=dir=='right' and 'left' or (dir or 'down')
        local key='original_'..pose
        if not Art.images[key] then Art.add(key,'texture/spider_'..pose..'.png') end
        local art=Art.images[key]
        local walking=require('brown_walk').draw(art.image,pose,0,0,width,player,art.quad)
        if not walking then Art.draw(key,0,0,width) end
        g.pop()
        if selected==22 then
            g.push();g.translate(x,y)
            if walking then
                local phase=player.walkPhase or 0
                g.translate(0,math.cos(phase*2)*.55*width/62)
                g.rotate(math.sin(phase)*.012*(dir=='right' and -1 or 1))
            end
            C.crown(0,0,width,dir);g.pop()
        end
    else C.portrait(selected,x,y,width,dir) end
end
return C
