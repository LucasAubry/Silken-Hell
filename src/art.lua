-- Transparent PNG assets. Alpha bounds are used as sprite quads, without altering files.
local A={images={},metadata={},pending={}}
function A.register(key,loader)
    if not rawget(A.images,key) then A.pending[key]=loader end
end
setmetatable(A.images,{__index=function(_,key)
    local loader=A.pending[key]
    if not loader then return end
    A.pending[key]=nil
    if type(loader)=='function' then A.images[key]=loader() else A.add(key,loader) end
    return rawget(A.images,key)
end})
local cached={}
local raw=love.filesystem.read('assets/art-metadata.json')
if raw and os.getenv('SILKEN_EXPORT_ART')~='1' then local ok,data=pcall(require('json').decode,raw); if ok then cached=data end end
-- Some recovered sprites are RGB exports. Decode their white exterior as
-- transparency without removing enclosed white details such as eye highlights.
function A.imageData(path)
    path=require("asset_paths").resolve(path)
    local data=love.image.newImageData(path)
    local checker=path:match('/waspling_left%.png$') and not require('art_filter').pixelArt[path]
    if checker then
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
    if rawget(A.images,key) then return end
    if A.defer then A.register(key,path);return end
    A.pending[key]=nil
    if A.onLoad then A.onLoad() end
    path=require("asset_paths").resolve(path)
    local saved=cached[path]
    if saved and saved.fileSize==love.filesystem.getInfo(path).size and (require('art_filter').pixelArt[path] or not path:match('/waspling_left%.png$')) then
        local image=require('art_filter').image(path)
        local iw,ih=image:getDimensions()
        local a={image=image,quad=love.graphics.newQuad(saved.x,saved.y,saved.w,saved.h,iw,ih),w=saved.w,h=saved.h,glow=saved.glow}
        if saved.mask then a.mask={}; a.maskSize=192; for i=1,#saved.mask do a.mask[i-1]=saved.mask:byte(i)==49 end end
        A.images[key]=a; return
    end
    local data=A.imageData(path)
    local w,h=data:getDimensions(); local x0,y0,x1,y1=w,h,0,0
    local alphaThreshold=require('art_filter').binaryAlpha(path) and .5 or .12
    for y=0,h-1 do for x=0,w-1 do
        local _,_,_,alpha=data:getPixel(x,y)
        if alpha>alphaThreshold then x0=math.min(x0,x); y0=math.min(y0,y); x1=math.max(x1,x); y1=math.max(y1,y) end
    end end
    if x1<x0 then x0,y0,x1,y1=0,0,w-1,h-1 end
    local image=require('art_filter').image(path,data)
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
function A.shadowAllowed()
    local actor=require('servant_art').current
    return not (actor and actor.has_larme)
end
function A.shadow(...)
    if not A.shadowAllowed() then return end
    if not App or App.state~='playing' then return end
    local g=love.graphics;local r,green,b,alpha=g.getColor()
    if math.max(r,green,b)<.25 then return end -- Do not shadow existing dark silhouettes.
    if Campaign and Campaign.biome==1 and not (Secret and Secret.inArena()) then
        A.paradiseShadowShader=A.paradiseShadowShader or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px) {
            vec2 d=vec2(.007);
            float a=Texel(tex,uv).a*4.;
            a+=(Texel(tex,uv+vec2(d.x,0.)).a+Texel(tex,uv-vec2(d.x,0.)).a+Texel(tex,uv+vec2(0.,d.y)).a+Texel(tex,uv-vec2(0.,d.y)).a)*2.;
            a+=Texel(tex,uv+d).a+Texel(tex,uv-d).a+Texel(tex,uv+vec2(d.x,-d.y)).a+Texel(tex,uv+vec2(-d.x,d.y)).a;
            return vec4(.24,.18,.105,a/16.*color.a*.30);
        }]])
        g.push('all');g.setShader(A.paradiseShadowShader);g.setBlendMode('alpha');g.setColor(1,1,1,alpha)
        local ox,oy=g.transformPoint(0,0)
        local dx,dy=g.inverseTransformPoint(ox+7,oy+13)
        g.translate(dx,dy);g.draw(...);g.pop();return
    end
    A.shadowShader=A.shadowShader or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px) {
        return vec4(.025,.018,.025,((Texel(tex,uv).a*2.+Texel(tex,uv+vec2(.002,0.)).a+Texel(tex,uv-vec2(.002,0.)).a+Texel(tex,uv+vec2(0.,.002)).a+Texel(tex,uv-vec2(0.,.002)).a)/6.)*color.a*.075);
    }]])
    g.push('all');g.setShader(A.shadowShader);g.setBlendMode('alpha');g.setColor(1,1,1,alpha)
    g.translate(1.5,2.5);g.draw(...);g.pop()
end
-- A single feathered contact ellipse; no stacked solid oval outlines.
function A.contactShadow(x,y,rx,ry,opacity)
    if not A.shadowAllowed() then return end
    if not App or App.state~='playing' then return end
    local g=love.graphics;g.push('all');g.setShader();g.setBlendMode('alpha')
    local _,_,_,alpha=g.getColor()
    if Campaign and Campaign.biome==1 and not (Secret and Secret.inArena()) then
        if not A.paradiseContact then
            local vertices={{0,0,0,0,1,1,1,1}}
            for i=0,32 do
                local angle=i*math.pi/16
                vertices[#vertices+1]={math.cos(angle),math.sin(angle),0,0,1,1,1,0}
            end
            A.paradiseContact=g.newMesh(vertices,'fan','static')
        end
        g.setColor(.24,.18,.105,(opacity or .11)*alpha*2.2)
        local ox,oy=g.transformPoint(0,0)
        local dx,dy=g.inverseTransformPoint(ox+4,oy+7)
        g.draw(A.paradiseContact,x+dx,y+dy,0,rx*1.12,ry*1.18)
        g.pop();return
    end
    for i=12,1,-1 do
        local scale=i/12
        g.setColor(.025,.018,.025,(opacity or .10)*alpha*2/12*(1-scale*.7))
        g.ellipse('fill',x,y,rx*scale,ry*scale)
    end
    g.pop()
end
local function creature(key)
    return key=='abyss_fish' or key=='magma_larva' or key=='abyss_octopus' or key=='wheel'
        or key:match('^crab_') or key:match('^skeleton_')
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
    require('servant_art').web(a,a.swimMesh,x,y,angle,scale,scale)
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
        g.setColor(.035,.018,.012,.065*alpha);g.ellipse('fill',p[1]+1.5,p[2]+2,size*.035,p[3])
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
function A.load(defer)
    A.defer=defer
    require('integrated_skins').load(A)
    A.add('ocean_coral_wall','assets/environments/ocean/coral-wall.png')
    for _,pose in ipairs({'down','up','profil'}) do
        A.add('player_skin_'..pose,'assets/skins/commun/'..pose..'.png')
        for _,skin in ipairs({'base_marron','maxance','cocon'}) do
            A.add('player_skin_'..skin..'_'..pose,'assets/skins/'..skin..'/'..pose..'.png')
        end
    end
    for _,key in ipairs({'white_spider','white_egg','brown_egg'}) do
        A.add('rebirth_'..key,'assets/sprites/renaissance/'..key..'.png')
    end
    A.add('map_cloud','assets/sprites/map_cloud.png')
    A.add('cave_wall','assets/environments/terre/soil-wall.png')
    A.add('magma_larva','assets/monstres/enfer/larve/magma_larva.png')
    A.add('merle_flight','assets/monstres/paradis/merle/merle_flight.png')
    for _,dir in ipairs({'left','up','down'}) do A.add('merle_flight_'..dir,'assets/sprites/merle_flight_'..dir..'.png') end
    A.add('magma_nest','assets/monstres/enfer/larve/magma_nest.png')
    A.add('octopus_extended_down','assets/monstres/ocean/poulpe/octopus_extended_down.png')
    A.add('abyss_octopus','assets/monstres/abysse/pieuvre/abyss_octopus.png')
    for _,name in ipairs({'nest','lava','black_feather','wheel','wall','feather'}) do A.add(name,'assets/sprites/'..name..'.png') end
    for _,name in ipairs({'spider','serpent','merle','wasp','wasp_ground','hell_spider','ocean_spider','crown_spider','jelly','fish','worm','mole','waspling','hedgehog','hedgehog_ball','lanternfish'}) do
        for _,dir in ipairs({'up','down','left','right'}) do
            A.add(name..'_'..dir,'assets/sprites/directional/'..name..'_'..dir..'.png')
        end
    end
    for _,name in ipairs({'cloud_snare','ink_splatter'}) do A.add(name,'assets/sprites/'..name..'.png') end
    A.add('skull','assets/textures/hud/death.png'); A.add('clock','assets/textures/hud/time.png')
    A.add('catalog_ange','assets/monstres/paradis/ange/ange_down.png'); A.add('catalog_snake','assets/monstres/paradis/serpent/snake_down.png'); A.add('catalog_trap','assets/monstres/paradis/pieges/piege.png')
    A.add('original','assets/skins/base_marron/down.png')
    A.add('earth_tunnel','assets/monstres/terre/taupe/earth_tunnel.png')
    for _,key in ipairs({'skeleton_head','skeleton_open','skeleton_rib','skeleton_spine','skeleton_tail','abyss_fish'}) do A.add(key,'assets/sprites/'..key..'.png') end
    for _,pose in ipairs({'open','closed','dead'}) do A.add('crab_'..pose,'assets/sprites/crab_'..pose..'.png') end
    A.add('electric_anemone','assets/sprites/electric_anemone.png')
    A.add('tear_ring','assets/textures/aureole.png')
    A.defer=false
end
function A.drawAnemone(x,y,width,height,time)
    require('anemone_art').draw(A.images.electric_anemone,x,y,width,height,time)
end
function A.fishPalette()
 A.fishShader=A.fishShader or love.graphics.newShader('assets/shaders/fish_palette.glsl');love.graphics.setShader(A.fishShader)
end
function A.draw(key,x,y,width,angle,height,time)
    if key=='earth_tunnel' or key=='earth_mound' then return require('earth_mound').draw(x,y,width,height,angle,true) end
    if key=='electric_anemone' then
        local a=A.images[key]
        local h=height or width*a.h/a.w;time=time or (UI and UI.clock) or love.timer.getTime()
        A.drawAnemone(x,y,width,h,time)
        return require('anemone_art').electric(x,y,width,h,time)
    end
    local servants=require('servant_art')
    if not servants.variant(key) and require('paradise_ink').art(key,x,y,width,angle,height) then return end
    local a=assert(servants.image(key),key)
    local sx=width/a.w; local sy=height and height/a.h or sx
    if key=='wheel' or key=='wall' or key=='nest' or key=='magma_nest' or key=='final_web_shot' or key=='final_egg' or key:match('^final_egg_crack') then
        return require('sprite_relief').draw(a,x,y,width,angle,height)
    end
    if creature(key) then A.shadow(a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2) end
    local previous=love.graphics.getShader()
    if key:match('^fish_') then A.fishPalette() end
    if key=='black_feather' or key:match('^merle_') then
        require('paradise_style').bind(a,'bird')
    end
    love.graphics.draw(a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2)
    love.graphics.setShader(previous)
    require('servant_art').web(a,a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2)
end
function A.drawTinted(key,x,y,width,angle,height)
    A.tintShader=A.tintShader or love.graphics.newShader([[vec4 effect(vec4 color,Image image,vec2 uv,vec2 px) {
        vec4 t=Texel(image,uv); float light=max(t.r,max(t.g,t.b));
        return vec4(color.rgb*(0.7+0.3*light),color.a*t.a);
    }]])
    local old=love.graphics.getShader(); love.graphics.setShader(A.tintShader)
    A.draw(key,x,y,width,angle,height); love.graphics.setShader(old)
end
-- Bone shots retain their original art independently of the pixel-art boss.
function A.drawBoneProjectile(name,x,y,width,angle,height)
    local key='projectile_'..name
    if not A.images[key] then A.add(key,'assets/effects/projectiles/'..name..'.png') end
    A.draw(key,x,y,width,angle,height)
end
function A.direction(dx,dy,previous)
    if math.abs(dx)+math.abs(dy)<.001 then return previous or 'down' end
    if math.abs(dx)>math.abs(dy) then return dx>0 and 'right' or 'left' end
    return dy>0 and 'down' or 'up'
end
function A.drawFacing(name,dir,x,y,size)
    local key=name..'_'..(dir or 'down');local servants=require('servant_art')
    if not servants.variant(key) and require('paradise_ink').facing(name,dir,x,y,size) then return end
    local a=assert(servants.image(key),key)
    local scale=size/math.max(a.w,a.h)
    if not name:find('spider') then A.shadow(a.image,a.quad,x,y,0,scale,scale,a.w/2,a.h/2) end
    local previous=love.graphics.getShader()
    if name=='fish' then A.fishPalette() end
    if name=='merle' then require('paradise_style').bind(a,'bird') end
    love.graphics.draw(a.image,a.quad,x,y,0,scale,scale,a.w/2,a.h/2)
    love.graphics.setShader(previous)
    require('servant_art').web(a,a.image,a.quad,x,y,0,scale,scale,a.w/2,a.h/2)
end
function A.drawWorm(dir,x,y,size,time)
    local a=A.images['worm_'..dir]; local qx,qy,qw,qh=a.quad:getViewport()
    local iw,ih=a.image:getDimensions(); local scale=size/math.max(a.w,a.h)
    a.strips=a.strips or {}
    local vertical=dir=='up' or dir=='down'
    A.shadow(a.image,a.quad,x,y,0,scale,scale,a.w/2,a.h/2)
    for i=0,11 do
        local t=i/12; local endpoint=(i+1)/12
        local sx,sy=qx+(vertical and 0 or qw*t),qy+(vertical and qh*t or 0)
        local sw,sh=vertical and qw or qw/12,vertical and qh/12 or qh
        if not a.strips[i] then a.strips[i]=love.graphics.newQuad(sx,sy,sw,sh,iw,ih) end
        local wiggle=math.sin(time*10+t*math.pi*3)*size*(vertical and .014 or .035)*math.sin((t+endpoint)*math.pi/2)
        love.graphics.draw(a.image,a.strips[i],x-qw*scale/2+(vertical and wiggle or qw*t*scale),y-qh*scale/2+(vertical and qh*t*scale or wiggle),0,scale,scale)
        require('servant_art').web(a,a.image,a.strips[i],x-qw*scale/2+(vertical and wiggle or qw*t*scale),y-qh*scale/2+(vertical and qh*t*scale or wiggle),0,scale,scale)
    end
end
-- Reveal the original proportions above the soil line as the body moves vertically.
function A.drawBurrowing(name,dir,x,y,size,amount)
    local a=require('servant_art').image(name..'_'..dir); amount=math.max(.001,math.min(1,amount))
    local qx,qy,qw,qh=a.quad:getViewport(); local iw,ih=a.image:getDimensions()
    a.burrowQuad=a.burrowQuad or love.graphics.newQuad(qx,qy,qw,qh,iw,ih)
    a.burrowQuad:setViewport(qx,qy,qw,qh*amount,iw,ih)
    local scale=size/math.max(qw,qh)
        A.shadow(a.image,a.burrowQuad,x-qw*scale/2,y+qh*scale/2-qh*amount*scale,0,scale,scale)
    love.graphics.draw(a.image,a.burrowQuad,x-qw*scale/2,y+qh*scale/2-qh*amount*scale,0,scale,scale)
    require('servant_art').web(a,a.image,a.burrowQuad,x-qw*scale/2,y+qh*scale/2-qh*amount*scale,0,scale,scale)
end
return A
