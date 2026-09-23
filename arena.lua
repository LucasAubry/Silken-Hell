local A={width=960,height=600,walls={},interior={}}
function A.configure(w,h)
    A.height=600; A.width=math.max(600,math.floor(600*w/h+0.5))
end
function A.mapX(x) return 28+(x-50)/700*(A.width-56) end
function A.blocked(x,y,w,h,walls)
    for _,r in ipairs(walls or A.walls) do
        if x<r.x+r.w and r.x<x+w and y<r.y+r.h and r.y<y+h then return true end
    end
    return false
end
function A.direct(sx,sy,tx,ty,walls)
    -- Sweep the same player rectangle used by physics, including the dash.
    local steps=math.ceil(math.sqrt((tx-sx)^2+(ty-sy)^2)/3)
    for i=0,steps do local t=i/math.max(1,steps)
        if A.blocked(sx+(tx-sx)*t,sy+(ty-sy)*t,30,24,walls) then return false end
    end
    return true
end
function A.build(spawn,targets,boss)
    A.walls={{x=0,y=0,w=A.width,h=22},{x=0,y=578,w=A.width,h=22},{x=0,y=0,w=22,h=600},{x=A.width-22,y=0,w=22,h=600}}
    A.interior={}
    if Campaign.biome==2 or (Campaign.biome==5 and not boss) then
        local function wall(x,y,w,h)
            local r={x=x,y=y,w=w,h=h}; A.interior[#A.interior+1]=r; A.walls[#A.walls+1]=r
        end
        if boss then
            wall(A.width/2-55,430,110,18)
            wall(A.width*.22,260,22,75); wall(A.width*.78-22,260,22,75)
        else
            for _,p in ipairs(targets) do
                local sx,sy=spawn.x+15,spawn.y+12
                local tx,ty=p.x+15,p.y+20
                local x,y=sx+(tx-sx)*.53,sy+(ty-sy)*.53
                if math.abs(tx-sx)>math.abs(ty-sy) then wall(x-9,y-30,18,60)
                else wall(x-43,y-9,86,18) end
            end
        end
        if Campaign.biome==5 then
            for i=1,6 do
                local x=A.width*(.2+((i-1)%3)*.3); local y=i<=3 and 205 or 385
                wall(x-12,y-38,24,76)
            end
        end
    end
    Walls=A.walls
    A.navigationVersion=(A.navigationVersion or 0)+1
end
function A.clearSpot(x,y,w,h)
    x=math.max(26,math.min(A.width-w-26,x)); y=math.max(60,math.min(572-h,y))
    if not A.blocked(x,y,w,h) then return x,y end
    for radius=12,180,12 do for i=0,15 do
        local xx=x+math.cos(i*math.pi/8)*radius; local yy=y+math.sin(i*math.pi/8)*radius
        if xx>=26 and xx+w<A.width-26 and yy>=60 and yy+h<572 and not A.blocked(xx,yy,w,h) then return xx,yy end
    end end
    return x,y
end
function A.move(m,dx,dy)
    local ox,oy=m.hitBox_offset_x or 0,m.hitBox_offset_y or 0
    local w,h=m.hitBox_width,m.hitBox_height
    local hitX=A.blocked(m.x+ox+dx,m.y+oy,w,h)
    if not hitX then m.x=m.x+dx end
    local hitY=A.blocked(m.x+ox,m.y+oy+dy,w,h)
    if not hitY then m.y=m.y+dy end
    return hitX,hitY
end
-- Reserve the full visible footprints of fixed objects before placing interior walls.
function A.reconcile()
    local reserved={}
    local function box(x,y,w,h) reserved[#reserved+1]={x=x,y=y,w=w,h=h} end
    box(player.x-12,player.y-12,54,48)
    for _,boss in ipairs({Hedgehog,Wasp}) do
        if boss and boss.active then box(boss.x-65,boss.y-65,130,130) end
    end
    for _,p in ipairs(levels[player.level].larme_position) do box(p.x-42,p.y-30,114,100) end
    for _,m in ipairs(mobs) do
        if m.type=='piege' or m.capture then box(m.x-40,m.y-40,80,80)
        elseif m.type=='scie' then box(m.x-90,m.y-90,180,180) end
    end
    for _,p in ipairs(Hazards.lava) do box(p.x-p.rx-12,p.y-p.ry-12,p.rx*2+24,p.ry*2+24) end
    local candidates=A.interior; A.interior={}
    while #A.walls>4 do table.remove(A.walls) end
    for _,r in ipairs(candidates) do
        local function safe(x,y)
            return x>=55 and y>=90 and x+r.w<=A.width-55 and y+r.h<=545
                and not A.blocked(x-10,y-10,r.w+20,r.h+20,reserved)
                and not A.blocked(x-42,y-42,r.w+84,r.h+84)
        end
        local bx,by,best=nil,nil,math.huge
        if safe(r.x,r.y) then bx,by=r.x,r.y else
            for y=100,520-r.h,20 do for x=60,A.width-60-r.w,20 do
                local d=(x-r.x)^2+(y-r.y)^2
                if d<best and safe(x,y) then bx,by,best=x,y,d end
            end end
        end
        if bx then r.x,r.y=bx,by; A.interior[#A.interior+1]=r; A.walls[#A.walls+1]=r end
    end
    A.navigationVersion=(A.navigationVersion or 0)+1
    for _,m in ipairs(mobs) do
        if not m.ground and m.type~='piege' and m.type~='scie' then
            local ox,oy=m.hitBox_offset_x or 0,m.hitBox_offset_y or 0
            local x,y=A.clearSpot(m.x+ox,m.y+oy,m.hitBox_width,m.hitBox_height); m.x,m.y=x-ox,y-oy
        end
    end
end
-- Cache geometry by body size; intersect line segments analytically instead of sampling every six pixels.
function A.navGraph(m)
    if A.graphVersion~=A.navigationVersion or A.graphWalls~=A.walls then A.graphs={}; A.graphVersion=A.navigationVersion; A.graphWalls=A.walls end
    local ox,oy=m.hitBox_offset_x or 0,m.hitBox_offset_y or 0
    local w,h=m.hitBox_width,m.hitBox_height
    local key=table.concat({ox,oy,w,h},':'); if A.graphs[key] then return A.graphs[key] end
    local graph={nodes={},edges={},rects={}}; A.graphs[key]=graph
    local blocks={}; for _,r in ipairs(A.walls) do blocks[#blocks+1]=r end
    -- Lava is traversable by creatures; only solid walls shape their routes.
    for _,r in ipairs(blocks) do graph.rects[#graph.rects+1]={x=r.x-ox-w,y=r.y-oy-h,xx=r.x+r.w-ox,yy=r.y+r.h-oy} end
    function graph.clear(x,y)
        if x+ox<22 or y+oy<22 or x+ox+w>A.width-22 or y+oy+h>578 then return false end
        for _,r in ipairs(graph.rects) do if x>r.x and x<r.xx and y>r.y and y<r.yy then return false end end
        return true
    end
    function graph.line(x,y,xx,yy)
        local dx,dy=xx-x,yy-y
        for _,r in ipairs(graph.rects) do
            local enter,leave=0,1
            if math.abs(dx)<.00001 then
                if x<=r.x or x>=r.xx then leave=-1 end
            else local a,b=(r.x-x)/dx,(r.xx-x)/dx; if a>b then a,b=b,a end
                enter=math.max(enter,a); leave=math.min(leave,b)
            end
            if math.abs(dy)<.00001 then
                if y<=r.y or y>=r.yy then leave=-1 end
            else local a,b=(r.y-y)/dy,(r.yy-y)/dy; if a>b then a,b=b,a end
                enter=math.max(enter,a); leave=math.min(leave,b)
            end
            if enter<leave and leave>0 and enter<1 then return false end
        end
        return true
    end
    for i,r in ipairs(graph.rects) do if i>4 then
        for _,x in ipairs({r.x-5,r.xx+5}) do for _,y in ipairs({r.y-5,r.yy+5}) do
            if graph.clear(x,y) then graph.nodes[#graph.nodes+1]={x=x,y=y} end
        end end
    end end
    for i=1,#graph.nodes do graph.edges[i]={} end
    for i,a in ipairs(graph.nodes) do for j=i+1,#graph.nodes do local b=graph.nodes[j]
        if graph.line(a.x,a.y,b.x,b.y) then
            local distance=math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
            graph.edges[i][#graph.edges[i]+1]={j,distance}; graph.edges[j][#graph.edges[j]+1]={i,distance}
        end
    end end
    return graph
end
function A.route(m,tx,ty)
    local graph=A.navGraph(m); local ox,oy=m.hitBox_offset_x or 0,m.hitBox_offset_y or 0
    tx=math.max(26-ox,math.min(A.width-26-m.hitBox_width-ox,tx)); ty=math.max(26-oy,math.min(574-m.hitBox_height-oy,ty))
    if not graph.clear(tx,ty) then
        local found=false
        for radius=20,180,20 do
            for i=0,15 do local x,y=tx+math.cos(i*math.pi/8)*radius,ty+math.sin(i*math.pi/8)*radius
                if graph.clear(x,y) then tx,ty=x,y; found=true; break end
            end
            if found then break end
        end
    end
    if graph.line(m.x,m.y,tx,ty) then return {{x=tx,y=ty}} end
    local dist,prev,done,finish={},{},{},{}
    for i,p in ipairs(graph.nodes) do
        if graph.line(m.x,m.y,p.x,p.y) then dist[i]=math.sqrt((p.x-m.x)^2+(p.y-m.y)^2) end
        if graph.line(p.x,p.y,tx,ty) then finish[i]=math.sqrt((p.x-tx)^2+(p.y-ty)^2) end
    end
    local endNode,endDistance=nil,math.huge
    for _=1,#graph.nodes do
        local u,best=nil,math.huge
        for i=1,#graph.nodes do if not done[i] and (dist[i] or math.huge)<best then u,best=i,dist[i] end end
        if not u or best>=endDistance then break end
        done[u]=true
        if finish[u] and best+finish[u]<endDistance then endNode,endDistance=u,best+finish[u] end
        for _,edge in ipairs(graph.edges[u]) do local v,d=edge[1],best+edge[2]
            if d<(dist[v] or math.huge) then dist[v]=d; prev[v]=u end
        end
    end
    if not endNode then return {} end
    local path={{x=tx,y=ty}}; while endNode do table.insert(path,1,graph.nodes[endNode]); endNode=prev[endNode] end
    return path
end
function A.navigate(m,tx,ty,speed,dt)
    if m.is_frozen or speed<=0 then return end
    m.navTime=(m.navTime or 0)-dt
    local graph=A.navGraph(m)
    if graph.clear(tx,ty) and graph.line(m.x,m.y,tx,ty) then
        local dx,dy=tx-m.x,ty-m.y; local d=math.sqrt(dx*dx+dy*dy)
        if d>.01 then local step=math.min(d,speed*dt); A.move(m,dx/d*step,dy/d*step); m.dir=Art.direction(dx,dy,m.dir) end
        m.path=nil; return
    end
    if not m.path or #m.path==0 or m.navTime<=0 or m.navVersion~=A.navigationVersion then
        m.path=A.route(m,tx,ty); m.navTime=.55; m.navVersion=A.navigationVersion
    end
    local remaining=speed*dt
    while remaining>0 and #m.path>0 do
        local p=m.path[1]; local dx,dy=p.x-m.x,p.y-m.y; local d=math.sqrt(dx*dx+dy*dy)
        if d<1 then table.remove(m.path,1) else
            local step=math.min(remaining,d,5); local hx,hy=A.move(m,dx/d*step,dy/d*step)
            m.dir=Art.direction(dx,dy,m.dir); remaining=remaining-step
            if hx or hy then m.navTime=0; break end
        end
    end
end
function A.drawFloor(hell)
    local g=love.graphics
    if Campaign.world==3 then BiomeFloor.draw(3,A.width,600,UI.clock)
    elseif Campaign.biome==6 then
        g.setColor(1,1,1); g.draw(Realms.floor,0,0)
    else BiomeFloor.draw(Campaign.biome,A.width,600,UI.clock) end
end
function A.drawWall(r,hell)
    if Campaign.world==3 then Meadow.wall(r);return end
    local g=love.graphics
    if Campaign.biome>=4 then Realms.drawWall(r)
    elseif hell then
        g.setColor(1,1,1)
        if r.w>=r.h then Art.draw('wall',r.x+r.w/2,r.y+r.h/2,r.w,0,r.h+8)
        else Art.draw('wall',r.x+r.w/2,r.y+r.h/2,r.h,math.pi/2,r.w+8) end
    else
        g.setColor(0.43,0.31,0.17); g.rectangle('fill',r.x,r.y,r.w,r.h)
        g.setColor(0.86,0.76,0.52); g.rectangle('fill',r.x+2,r.y+2,r.w-4,r.h-4)
        g.setColor(1,0.94,0.73); g.line(r.x+2,r.y+2,r.x+r.w-2,r.y+2)
        g.setColor(0.58,0.45,0.26)
        if r.w>r.h then for x=r.x+24,r.x+r.w-4,28 do g.line(x,r.y+3,x,r.y+r.h-3) end
        else for y=r.y+24,r.y+r.h-4,28 do g.line(r.x+3,y,r.x+r.w-3,y) end end
    end
    g.setColor(1,1,1)
end
function A.drawWalls(hell) for _,r in ipairs(A.walls) do A.drawWall(r,hell) end end
return A
