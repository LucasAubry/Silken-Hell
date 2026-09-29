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
function C.crown(x,y,size,dir,locked)
 if not Art.images.reward_crown then Art.add('reward_crown','assets/sprites/reward-crown.png') end
 local g=love.graphics;g.push('all');local _,_,_,alpha=g.getColor()
 g.setColor(locked and .5 or 1,locked and .5 or 1,locked and .5 or 1,alpha)
 local angle=({down=0,up=math.pi,left=math.pi/2,right=-math.pi/2})[dir or 'down'] or 0
 -- The crown follows the head in every direction and keeps its gold color.
 g.translate(x,y)
 if dir=='left' or dir=='right' then
  g.scale(dir=='left' and -1 or 1,1);Art.draw('reward_crown',size*.19,-size*.13,size*.28)
 else Art.draw('reward_crown',0,dir=='up' and -size*.30 or -size*.08,size*.28) end
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
        C.portrait(C.crowned[index],x,y,size,dir,locked);C.crown(x,y,size,dir,locked);return
    end
    local g=love.graphics;g.push('all');local red,green,blue,alpha=g.getColor()
    if locked then
        C.gray=C.gray or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 sc){vec4 p=Texel(tex,uv);float v=dot(p.rgb,vec3(.299,.587,.114));return vec4(vec3(v*.65),p.a)*color;}]])
        g.setShader(C.gray)
    elseif C.tints[index] then local tint=C.tints[index];g.setColor(red*tint[1],green*tint[2],blue*tint[3],alpha) end
    if index==1 then
        if dir=='up' then
            if not Art.images.original_up then Art.add('original_up','texture/spider_up.png') end
            Art.draw('original_up',x,y,size,math.pi)
        else Art.draw('original',x,y,size) end
    else Art.drawFacing(C.keys[index],dir or 'down',x,y,size) end
    g.pop()
end
-- Dedicated selection artwork; movement sprites and gameplay animation stay separate.
function C.selectionPortrait(x,y,size)
    local selected=C.selected()
    if selected~=1 and selected~=22 then return C.portrait(selected,x,y,size,'down') end
    if not Art.images.brown_selection then Art.add('brown_selection','assets/sprites/brown-selection.png') end
    Art.draw('brown_selection',x,y,size)
    if selected==22 then C.crown(x,y,size,'down') end
end
function C.draw(x,y,width,dir)
    local selected=C.selected()
    if (selected==1 or selected==22) and width<100 and player then
        local g=love.graphics;g.push();g.translate(x,y);if dir=='up' then g.rotate(math.pi) end
        local img=player['img_'..(dir or 'down')] or player.img_down;local scale=width/img:getWidth()
        if not require('brown_walk').draw(img,dir or 'down',0,0,width,player) then
            love.graphics.draw(img,0,0,0,scale,scale,img:getWidth()/2,img:getHeight()/2)
        end
        g.pop()
        if selected==22 then C.crown(x,y,width,dir) end
    else C.portrait(selected,x,y,width,dir) end
end
return C
