-- Transparent PNG assets. Alpha bounds are used as sprite quads, without altering files.
local A={images={}}
-- Some recovered sprites are RGB exports. Decode their white exterior as
-- transparency without removing enclosed white details such as eye highlights.
function A.imageData(path)
    local data=love.image.newImageData(path)
    if path:match('/worm_left%.png$') then
        local w,h=data:getDimensions(); local queue={0}; local seen={[0]=true}; local head=1
        while head<=#queue do
            local i=queue[head]; head=head+1; local x,y=i%w,math.floor(i/w)
            local r,g,b=data:getPixel(x,y)
            if math.min(r,g,b)>.87 then
                data:setPixel(x,y,0,0,0,0)
                for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
                    local nx,ny=x+d[1],y+d[2]; local ni=ny*w+nx
                    if nx>=0 and nx<w and ny>=0 and ny<h and not seen[ni] then seen[ni]=true; queue[#queue+1]=ni end
                end
            end
        end
    end
    return data
end
function A.add(key,path)
    local data=A.imageData(path)
    local w,h=data:getDimensions(); local x0,y0,x1,y1=w,h,0,0
    for y=0,h-1 do for x=0,w-1 do
        local _,_,_,alpha=data:getPixel(x,y)
        if alpha>0.12 then x0=math.min(x0,x); y0=math.min(y0,y); x1=math.max(x1,x); y1=math.max(y1,y) end
    end end
    if x1<x0 then x0,y0,x1,y1=0,0,w-1,h-1 end
    local image=love.graphics.newImage(data); image:setFilter('nearest','nearest')
    A.images[key]={image=image,quad=love.graphics.newQuad(x0,y0,x1-x0+1,y1-y0+1,w,h),w=x1-x0+1,h=y1-y0+1}
    data:release()
end
function A.load()
    for _,name in ipairs({'merle','wasp_ground','wasp','nest','lava','black_feather','raven','wheel','serpent','imp','wall','spider','feather'}) do A.add(name,'assets/sprites/'..name..'.png') end
    for _,name in ipairs({'spider','imp','serpent','merle','wasp','wasp_ground','hell_spider','ocean_spider','crown_spider','jelly','fish','worm','mole','gull'}) do
        for _,dir in ipairs({'up','down','left','right'}) do
            A.add(name..'_'..dir,'assets/sprites/directional/'..name..'_'..dir..'.png')
        end
    end
    A.add('skull','texture/hud/death.png'); A.add('clock','texture/hud/time.png')
    A.add('catalog_ange','texture/mob/ange_down.png'); A.add('catalog_snake','texture/mob/snake_down.png'); A.add('catalog_trap','texture/mob/piege.png')
    A.add('original','texture/spider_down.png')
end
function A.draw(key,x,y,width,angle,height)
    local a=assert(A.images[key],key)
    local sx=width/a.w; local sy=height and height/a.h or sx
    love.graphics.draw(a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2)
end
function A.direction(dx,dy,previous)
    if math.abs(dx)+math.abs(dy)<.001 then return previous or 'down' end
    if math.abs(dx)>math.abs(dy) then return dx>0 and 'right' or 'left' end
    return dy>0 and 'down' or 'up'
end
function A.drawFacing(name,dir,x,y,size)
    local key=name..'_'..(dir or 'down'); local a=assert(A.images[key],key)
    local scale=size/math.max(a.w,a.h)
    love.graphics.draw(a.image,a.quad,x,y,0,scale,scale,a.w/2,a.h/2)
end
return A
