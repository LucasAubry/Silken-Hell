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
    if Campaign.world==2 or Campaign.world==5 then
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
    end
    Walls=A.walls
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
function A.drawFloor(hell)
    local g=love.graphics
    if Campaign.world>=4 then
        g.setColor(1,1,1); g.draw(Realms.floor,0,0)
    elseif hell then
        g.setColor(1,1,1); g.draw(Campaign.floor,0,0,0,A.width/800,1)
    else
        local img=world.background_lv
        g.setColor(1,1,1); g.draw(img,0,0,0,A.width/img:getWidth(),600/img:getHeight())
    end
end
function A.drawWall(r,hell)
    local g=love.graphics
    if Campaign.world>=4 then Realms.drawWall(r)
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
