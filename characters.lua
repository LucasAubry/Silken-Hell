local C={names={'Soie','Perle','Braise','Écume','Royale','Auréole','Zéphyr','Ambre','Corail','Lanterne','Cendre','Renouveau','Gillou','Maxance'},keys={'original','spider','hell_spider','ocean_spider','crown_spider','spider','spider','spider','ocean_spider','spider','hell_spider','crown_spider','crown_spider','crown_spider'}}
C.tints={[6]={1,.9,.55},[7]={.58,.83,1},[8]={.8,.49,.21},[9]={.25,1,.82},[10]={.43,.45,1},[11]={1,.25,.12},[12]={1,.63,.78},[13]={1,.68,.12},[14]={.7,1,.6}}
function C.unlocked(index)
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
    local g=love.graphics;g.push('all');local red,green,blue,alpha=g.getColor()
    if locked then
        C.gray=C.gray or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 sc){vec4 p=Texel(tex,uv);float v=dot(p.rgb,vec3(.299,.587,.114));return vec4(vec3(v*.65),p.a)*color;}]])
        g.setShader(C.gray)
    elseif C.tints[index] then local tint=C.tints[index];g.setColor(red*tint[1],green*tint[2],blue*tint[3],alpha) end
    if index==1 then Art.draw('original',x,y,size) else Art.drawFacing(C.keys[index],dir or 'down',x,y,size) end
    g.pop()
end
function C.draw(x,y,width,dir)
    if C.selected()==1 and width<100 and player then
        local img=player['img_'..(dir or 'down')] or player.img_down;local scale=width/img:getWidth()
        love.graphics.draw(img,x,y,0,scale,scale,img:getWidth()/2,img:getHeight()/2)
    else C.portrait(C.selected(),x,y,width,dir) end
end
return C
