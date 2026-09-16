local C={names={'Soie','Perle','Braise','Écume','Royale'},keys={'original','spider','hell_spider','ocean_spider','crown_spider'}}
function C.selected() return math.max(1,math.min(#C.keys,Profile.character or 1)) end
function C.cycle(step) Profile.character=(C.selected()-1+step)%#C.keys+1; Profile.save() end
function C.draw(x,y,width,dir)
    local index=C.selected()
    if index==1 and width<100 then
        local img=player['img_'..(dir or 'down')] or player.img_down
        local scale=width/img:getWidth()
        love.graphics.draw(img,x,y,0,scale,scale,img:getWidth()/2,img:getHeight()/2)
    else
        if index==1 then Art.draw('original',x,y,width)
        else Art.drawFacing(C.keys[index],width<100 and (dir or 'down') or 'down',x,y,width) end
    end
end
function C.portrait(index,x,y,size)
    index=math.max(1,math.min(#C.keys,tonumber(index) or 1))
    if index==1 then Art.draw('original',x,y,size) else Art.drawFacing(C.keys[index],'down',x,y,size) end
end
return C
