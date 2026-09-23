-- Transparent PNG assets. Alpha bounds are used as sprite quads, without altering files.
local A={images={},metadata={}}
local cached={}
local raw=love.filesystem.read('assets/art-metadata.json')
if raw and os.getenv('SILKEN_EXPORT_ART')~='1' then local ok,data=pcall(require('json').decode,raw); if ok then cached=data end end
-- Some recovered sprites are RGB exports. Decode their white exterior as
-- transparency without removing enclosed white details such as eye highlights.
function A.imageData(path)
    local data=love.image.newImageData(path)
    local checker=path:match('/waspling_left%.png$')
    if path:match('/worm_left%.png$') or checker then
        local w,h=data:getDimensions(); local queue={0}; local seen={[0]=true}; local head=1
        while head<=#queue do
            local i=queue[head]; head=head+1; local x,y=i%w,math.floor(i/w)
            local r,g,b=data:getPixel(x,y)
            local low,high=math.min(r,g,b),math.max(r,g,b)
            if (checker and low>.6 and high-low<.08) or (not checker and low>.87) then
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
    local saved=cached[path]
    if saved and saved.fileSize==love.filesystem.getInfo(path).size and not path:match('/worm_left%.png$') and not path:match('/waspling_left%.png$') then
        local image=love.graphics.newImage(path); image:setFilter('nearest','nearest')
        local iw,ih=image:getDimensions()
        local a={image=image,quad=love.graphics.newQuad(saved.x,saved.y,saved.w,saved.h,iw,ih),w=saved.w,h=saved.h,glow=saved.glow}
        if saved.mask then a.mask={}; a.maskSize=192; for i=1,#saved.mask do a.mask[i-1]=saved.mask:byte(i)==49 end end
        A.images[key]=a; return
    end
    local data=A.imageData(path)
    local w,h=data:getDimensions(); local x0,y0,x1,y1=w,h,0,0
    for y=0,h-1 do for x=0,w-1 do
        local _,_,_,alpha=data:getPixel(x,y)
        if alpha>0.12 then x0=math.min(x0,x); y0=math.min(y0,y); x1=math.max(x1,x); y1=math.max(y1,y) end
    end end
    if x1<x0 then x0,y0,x1,y1=0,0,w-1,h-1 end
    local image=love.graphics.newImage(data); image:setFilter('nearest','nearest')
    A.images[key]={image=image,quad=love.graphics.newQuad(x0,y0,x1-x0+1,y1-y0+1,w,h),w=x1-x0+1,h=y1-y0+1}
    if key:match('^octopus_extended_') or key:match('^skeleton_') then
        local a=A.images[key]; a.mask={}; a.maskSize=192
        for y=0,191 do for x=0,191 do
            local r,g,b,alpha=data:getPixel(math.min(w-1,x0+math.floor((x+.5)*a.w/192)),math.min(h-1,y0+math.floor((y+.5)*a.h/192)))
            a.mask[y*192+x]=alpha>.3
            if key:match('^skeleton_') and alpha>.8 and b>r*1.2 and g>r*1.1 then
                local score=g+b-r
                if not a.glow or score>a.glow.score then a.glow={u=(x+.5)/192,v=(y+.5)/192,score=score} end
            end
        end end
    end
    if os.getenv('SILKEN_EXPORT_ART')=='1' then
        local a=A.images[key]; local meta={x=x0,y=y0,w=a.w,h=a.h,glow=a.glow,fileSize=love.filesystem.getInfo(path).size}
        if a.mask then local chars={}; for i=0,192*192-1 do chars[#chars+1]=a.mask[i] and '1' or '0' end; meta.mask=table.concat(chars) end
        A.metadata[path]=meta
    end
    data:release()
end
-- Subtle contact shadow copied from the actual transparent sprite/mesh.
function A.shadow(...)
    if not App or App.state~='playing' then return end
    local g=love.graphics;local r,green,b,alpha=g.getColor()
    if math.max(r,green,b)<.25 then return end -- Do not shadow existing dark silhouettes.
    A.shadowShader=A.shadowShader or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px) {
        return vec4(.025,.018,.025,Texel(tex,uv).a*color.a*.13);
    }]])
    g.push('all');g.setShader(A.shadowShader);g.setBlendMode('alpha');g.setColor(1,1,1,alpha)
    g.translate(2,4);g.draw(...);g.pop()
end
local function creature(key)
    return key=='abyss_fish' or key=='magma_larva' or key=='abyss_octopus' or key=='wheel'
        or key:match('^crab_') or key:match('^skeleton_') or key:match('^storm_')
end
-- A subdivided sprite lets the mantle pulse and the arms undulate while swimming.
function A.drawSwimmer(key,x,y,size,angle,time)
    local a=A.images[key]; local n=12; local vertices={}
    local qx,qy,qw,qh=a.quad:getViewport(); local iw,ih=a.image:getDimensions()
    local function vertex(u,v)
        local arm=math.min(1,math.abs(u-.5)*2+math.max(0,v-.45))
        return {(u-.5)*a.w+math.sin(time*5+v*8+u*3)*a.w*.025*arm,
            (v-.5)*a.h+math.sin(time*4+u*9)*a.h*.018*arm,
            (qx+u*qw)/iw,(qy+v*qh)/ih,1,1,1,1}
    end
    for j=0,n-1 do for i=0,n-1 do
        local u,v=i/n,j/n; local a1=vertex(u,v); local b=vertex(u+1/n,v)
        local c=vertex(u,v+1/n); local d=vertex(u+1/n,v+1/n)
        for _,p in ipairs({a1,b,c,b,d,c}) do vertices[#vertices+1]=p end
    end end
    if not a.swimMesh then a.swimMesh=love.graphics.newMesh(vertices,'triangles','stream'); a.swimMesh:setTexture(a.image)
    else a.swimMesh:setVertices(vertices) end
    local scale=size/math.max(a.w,a.h)
    A.shadow(a.swimMesh,x,y,angle,scale,scale)
    love.graphics.draw(a.swimMesh,x,y,angle,scale,scale)
end
-- A traveling contraction wave thickens and shortens each ring in turn.
function A.drawLarva(x,y,size,angle,time)
    local g=love.graphics;local _,_,_,alpha=g.getColor()
    g.push('all');g.translate(x,y);g.rotate(angle or 0)
    local rings={};local xx=-size*.43
    for i=0,17 do
        local t=i/17;local wave=.5+.5*math.sin((time or 0)*5-t*math.pi*3)
        local radius=size*(.060+.030*math.sin(math.pi*t))*(1+.22*wave)
        local yy=math.sin(t*math.pi)*math.sin((time or 0)*1.7-t*2)*size*.028
        rings[#rings+1]={xx,yy,radius,i};xx=xx+size*.052*(1-.2*wave)
    end
    -- The shadow follows the same articulated body, rather than a generic oval.
    for _,p in ipairs(rings) do
        g.setColor(.035,.018,.012,.12*alpha);g.ellipse('fill',p[1]+1.5,p[2]+2,size*.035,p[3])
    end
    for _,p in ipairs(rings) do
        local band=p[4]>=4 and p[4]<=6
        g.setColor(band and .52 or .43,band and .32 or .24,band and .22 or .16,alpha)
        g.ellipse('fill',p[1],p[2],size*.036,p[3])
        g.setColor(.64,.41,.28,.52*alpha)
        g.ellipse('fill',p[1]-.2,p[2]-p[3]*.28,size*.024,p[3]*.47)
    end
    g.pop()
end
function A.load()
    A.add('map_cloud','assets/sprites/map_cloud.png')
    A.add('cave_wall','assets/sprites/cave_wall-v2.png')
    A.add('magma_larva','assets/sprites/magma_larva.png')
    A.add('magma_nest','assets/sprites/magma_nest.png')
    A.add('octopus_extended_down','assets/sprites/directional/octopus_extended_down.png')
    A.add('abyss_octopus','assets/sprites/abyss_octopus.png')
    for _,name in ipairs({'nest','lava','black_feather','wheel','wall','feather'}) do A.add(name,'assets/sprites/'..name..'.png') end
    for _,name in ipairs({'storm','spider','imp','serpent','merle','wasp','wasp_ground','hell_spider','ocean_spider','crown_spider','jelly','fish','worm','mole','gull','waspling','hedgehog','hedgehog_ball','lanternfish'}) do
        for _,dir in ipairs({'up','down','left','right'}) do
            A.add(name..'_'..dir,'assets/sprites/directional/'..name..'_'..dir..'.png')
        end
    end
    for _,name in ipairs({'cloud_snare','ink_splatter'}) do A.add(name,'assets/sprites/'..name..'.png') end
    A.add('skull','texture/hud/death.png'); A.add('clock','texture/hud/time.png')
    A.add('catalog_ange','texture/mob/ange_down.png'); A.add('catalog_snake','texture/mob/snake_down.png'); A.add('catalog_trap','texture/mob/piege.png')
    A.add('original','texture/spider_down.png')
    A.add('earth_tunnel','assets/sprites/earth_tunnel.png')
    for _,key in ipairs({'skeleton_head','skeleton_open','skeleton_rib','skeleton_spine','skeleton_tail','abyss_fish'}) do A.add(key,'assets/sprites/'..key..'.png') end
    for _,pose in ipairs({'open','closed','dead'}) do A.add('crab_'..pose,'assets/sprites/crab_'..pose..'.png') end
    for _,key in ipairs({'electric_vent_idle','electric_vent_charge','electric_vent_active','electric_vent_spent'}) do A.add(key,'assets/sprites/'..key..'.png') end
    A.add('tear_ring','texture/aureole.png')
end
function A.draw(key,x,y,width,angle,height)
    local a=assert(A.images[key],key)
    local sx=width/a.w; local sy=height and height/a.h or sx
    if creature(key) then A.shadow(a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2) end
    love.graphics.draw(a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2)
end
function A.drawTinted(key,x,y,width,angle,height)
    A.tintShader=A.tintShader or love.graphics.newShader([[vec4 effect(vec4 color,Image image,vec2 uv,vec2 px) {
        vec4 t=Texel(image,uv); float light=max(t.r,max(t.g,t.b));
        return vec4(color.rgb*(0.7+0.3*light),color.a*t.a);
    }]])
    local old=love.graphics.getShader(); love.graphics.setShader(A.tintShader)
    A.draw(key,x,y,width,angle,height); love.graphics.setShader(old)
end
function A.direction(dx,dy,previous)
    if math.abs(dx)+math.abs(dy)<.001 then return previous or 'down' end
    if math.abs(dx)>math.abs(dy) then return dx>0 and 'right' or 'left' end
    return dy>0 and 'down' or 'up'
end
function A.drawFacing(name,dir,x,y,size)
    local key=name..'_'..(dir or 'down'); local a=assert(A.images[key],key)
    local scale=size/math.max(a.w,a.h)
    if not name:find('spider') then A.shadow(a.image,a.quad,x,y,0,scale,scale,a.w/2,a.h/2) end
    love.graphics.draw(a.image,a.quad,x,y,0,scale,scale,a.w/2,a.h/2)
end
function A.drawWorm(dir,x,y,size,time)
    local a=A.images['worm_'..dir]; local qx,qy,qw,qh=a.quad:getViewport()
    local iw,ih=a.image:getDimensions(); local scale=size/math.max(a.w,a.h)
    a.strips=a.strips or {}
    local vertical=dir=='up' or dir=='down'
    for i=0,11 do
        local t=i/12; local endpoint=(i+1)/12
        local sx,sy=qx+(vertical and 0 or qw*t),qy+(vertical and qh*t or 0)
        local sw,sh=vertical and qw or qw/12,vertical and qh/12 or qh
        if not a.strips[i] then a.strips[i]=love.graphics.newQuad(sx,sy,sw,sh,iw,ih) end
        local wiggle=math.sin(time*10+t*math.pi*3)*size*.055*math.sin((t+endpoint)*math.pi/2)
        A.shadow(a.image,a.strips[i],x-qw*scale/2+(vertical and wiggle or qw*t*scale),y-qh*scale/2+(vertical and qh*t*scale or wiggle),0,scale,scale)
        love.graphics.draw(a.image,a.strips[i],x-qw*scale/2+(vertical and wiggle or qw*t*scale),y-qh*scale/2+(vertical and qh*t*scale or wiggle),0,scale,scale)
    end
end
-- Reveal the original proportions above the soil line as the body moves vertically.
function A.drawBurrowing(name,dir,x,y,size,amount)
    local a=A.images[name..'_'..dir]; amount=math.max(.001,math.min(1,amount))
    local qx,qy,qw,qh=a.quad:getViewport(); local iw,ih=a.image:getDimensions()
    a.burrowQuad=a.burrowQuad or love.graphics.newQuad(qx,qy,qw,qh,iw,ih)
    a.burrowQuad:setViewport(qx,qy,qw,qh*amount,iw,ih)
    local scale=size/math.max(qw,qh)
        A.shadow(a.image,a.burrowQuad,x-qw*scale/2,y+qh*scale/2-qh*amount*scale,0,scale,scale)
    love.graphics.draw(a.image,a.burrowQuad,x-qw*scale/2,y+qh*scale/2-qh*amount*scale,0,scale,scale)
end
return A
