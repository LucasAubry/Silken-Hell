-- Purpose-built reader for assets/vector/tentacle.svg, not a general SVG parser.
-- Standard SVG paths provide the preview; data-left/right bind each shading
-- band to the animated centerline. Ellipses stay independent of skin tension.
local V={path='assets/vector/tentacle.svg'}
local function attributes(tag)
    local values={}
    for k,v in tag:gmatch('([%w%-]+)="([^"]*)"') do values[k]=v end
    return values
end
local function color(hex)
    assert(hex and hex:match('^#%x%x%x%x%x%x$'),'Tentacle SVG needs six-digit fill colors')
    local r,g,b=tonumber(hex:sub(2,3),16)/255,tonumber(hex:sub(4,5),16)/255,tonumber(hex:sub(6,7),16)/255
    return {r*.83,g*1.19,math.min(1,b*1.055)}
end
function V.load()
    if V.bands then return end
    local svg=assert(love.filesystem.read(V.path))
    V.bands={};V.suckers={};V.pattern={}
    for tag in svg:gmatch('<path%s+([^>]+)>') do
        local a=attributes(tag)
        if a['data-left'] then V.bands[#V.bands+1]={left=assert(tonumber(a['data-left'])),right=assert(tonumber(a['data-right'])),color=color(a.fill)} end
    end
    local symbol=assert(svg:match('<g id="sucker">(.-)</g>'),'Missing SVG sucker')
    for tag in symbol:gmatch('<ellipse%s+([^>]+)>') do
        local a=attributes(tag)
        V.suckers[#V.suckers+1]={x=assert(tonumber(a.cx)),y=assert(tonumber(a.cy)),rx=assert(tonumber(a.rx)),ry=assert(tonumber(a.ry)),color=color(a.fill)}
    end
    local patternTag,pattern=svg:match('<g (id="skin%-pattern"[^>]+)>(.-)</g>')
    V.patternSpacing=assert(tonumber(attributes(assert(patternTag))['data-spacing']))
    for tag in pattern:gmatch('<ellipse%s+([^>]+)>') do
        local a=attributes(tag)
        V.pattern[#V.pattern+1]={offset=assert(tonumber(a['data-offset'])),size=assert(tonumber(a['data-size'])),color=color(a.fill)}
    end
    local layout=attributes(assert(svg:match('<g (id="suckers"[^>]+)>')))
    V.spacing=assert(tonumber(layout['data-spacing']));V.offset=assert(tonumber(layout['data-offset']))
    assert(#V.bands>0 and #V.suckers>0 and V.spacing>0,'Invalid tentacle SVG')
    local fleck=attributes(assert(svg:match('<circle (id="skin%-fleck"[^>]+)>')))
    V.fleck=color(fleck.fill);V.fleckAlpha=tonumber(fleck.opacity) or 1
end
-- Bake vector primitives into one mesh per arm instead of issuing thousands
-- of individual polygon/ellipse calls every frame. Moving arms reuse their mesh.
local function meshBuilder(reusable)
    local vertices=reusable or {};local count=0;local tr,tg,tb,ta=1,1,1,1;local x,y,angle=0,0,0;local stack={}
    local g={}
    function g.setColor(r,b,c,a) tr,tg,tb,ta=r,b,c,a end
    function g.push() stack[#stack+1]={x,y,angle} end
    function g.pop() local t=table.remove(stack);x,y,angle=t[1],t[2],t[3] end
    function g.translate(dx,dy) x=x+math.cos(angle)*dx-math.sin(angle)*dy;y=y+math.sin(angle)*dx+math.cos(angle)*dy end
    function g.rotate(a) angle=angle+a end
    local function vertex(px,py)
        count=count+1
        local v=vertices[count]
        if not v then v={0,0,0,0,1,1,1,1};vertices[count]=v end
        v[1]=x+math.cos(angle)*px-math.sin(angle)*py;v[2]=y+math.sin(angle)*px+math.cos(angle)*py
        v[5],v[6],v[7],v[8]=tr,tg,tb,ta
    end
    function g.polygon(mode,...)
        local p={...}
        for i=3,#p-2,2 do vertex(p[1],p[2]);vertex(p[i],p[i+1]);vertex(p[i+2],p[i+3]) end
    end
    function g.ellipse(mode,cx,cy,rx,ry,segments)
        for i=0,segments-1 do
            local a,b=i*math.pi*2/segments,(i+1)*math.pi*2/segments
            vertex(cx,cy);vertex(cx+math.cos(a)*rx,cy+math.sin(a)*ry);vertex(cx+math.cos(b)*rx,cy+math.sin(b)*ry)
        end
    end
    function g.circle(mode,cx,cy,r,segments) g.ellipse(mode,cx,cy,r,r,segments) end
    function g.finish() for i=#vertices,count+1,-1 do vertices[i]=nil end end
    return g,vertices
end
function V.build(points,damage,reusable)
    V.load();local g,vertices=meshBuilder(reusable);local alpha=1
    for _,band in ipairs(V.bands) do
        local c=band.color;local left,right=band.left,band.right
        g.setColor(c[1],c[2]*(1-damage*.6),c[3]*(1-damage*.5),alpha)
        for i=1,#points-1 do local a,b=points[i],points[i+1]
            g.polygon('fill',a.x+a.nx*a.width*left,a.y+a.ny*a.width*left,
                b.x+b.nx*b.width*left,b.y+b.ny*b.width*left,
                b.x+b.nx*b.width*right,b.y+b.ny*b.width*right,
                a.x+a.nx*a.width*right,a.y+a.ny*a.width*right)
        end
    end
    -- Fixed-size angular pigment spots follow the skin without being stretched.
    local nextSpot=V.patternSpacing
    for i=2,#points do local a,b=points[i-1],points[i]
        while nextSpot<=b.distance do
            local q=(nextSpot-a.distance)/math.max(.001,b.distance-a.distance)
            local width=a.width+(b.width-a.width)*q
            local x=a.x+(b.x-a.x)*q;local y=a.y+(b.y-a.y)*q
            for lane,spot in ipairs(V.pattern) do
                local offset=spot.offset+math.sin(nextSpot*.63+(lane-1)*2)*.19
                local radius=math.min(spot.size*(.85+.4*math.sin(nextSpot*.37)^2),width*.19)
                local c=spot.color
                g.setColor(c[1],c[2]*(1-damage*.6),c[3]*(1-damage*.5),alpha)
                local px,py=x+b.nx*width*offset,y+b.ny*width*offset
                local r=radius;local h=r*.45
                g.polygon('fill',px-r,py-h,px+r,py-h,px+r,py+h,px-r,py+h)
                g.polygon('fill',px-h,py-r,px+h,py-r,px+h,py+r,px-h,py+r)
            end
            nextSpot=nextSpot+V.patternSpacing
        end
    end
    local nextSucker=V.spacing
    for i=2,#points do local a,b=points[i-1],points[i]
        while nextSucker<=b.distance do
            local q=(nextSucker-a.distance)/math.max(.001,b.distance-a.distance)
            local width=a.width+(b.width-a.width)*q
            local x=a.x+(b.x-a.x)*q;local y=a.y+(b.y-a.y)*q
            local r=math.min(4.2,width*.35)
            g.push();g.translate(x+b.nx*width*V.offset,y+b.ny*width*V.offset);g.rotate(math.atan2(b.ny,b.nx))
            for _,s in ipairs(V.suckers) do
                g.setColor(s.color[1],s.color[2],s.color[3],alpha)
                g.ellipse('fill',s.x*r,s.y*r,s.rx*r,s.ry*r,8)
            end
            g.pop()
            nextSucker=nextSucker+V.spacing
        end
    end
    g.finish();return vertices
end
function V.draw(points,alpha,damage,cache)
    cache=cache or {}
    if cache.points~=points or cache.damage~=damage then
        local vertices=V.build(points,damage,cache.vertices);cache.vertices=vertices
        if not cache.mesh or cache.capacity<#vertices then
            if cache.mesh then cache.mesh:release() end
            cache.capacity=math.max(12000,#vertices*2)
            cache.mesh=love.graphics.newMesh(cache.capacity,"triangles","dynamic")
        end
        cache.mesh:setVertices(vertices);cache.mesh:setDrawRange(1,#vertices)
        cache.points=points;cache.damage=damage
    end
    love.graphics.setColor(1,1,1,alpha);love.graphics.draw(cache.mesh)
    return cache
end
return V
