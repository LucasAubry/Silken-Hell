-- Independently placed skeleton pieces: hazards, never boss encounters.
local T={parts={}}
local sizes={skeleton_tail={100,145},skeleton_rib={18,110},skeleton_spine={22,28}}
function T.reset() T.parts={} end
function T.add(e)
    local size=assert(sizes[e.type]);local b={type=e.type,key=e.type,x=e.x,y=e.y,w=e.w or size[1],h=e.h or size[2],rotation=e.rotation or 0}
    b.angle=b.rotation*math.pi/180;T.parts[#T.parts+1]=b;return b
end
function T.contact()
    for _,b in ipairs(T.parts) do
        local tailSafe=b.key=='skeleton_tail' and Abyss.triggerTail(b,b)
        local radius=math.sqrt(b.w*b.w+b.h*b.h)/2+30
        if not tailSafe and (player.x+15-b.x)^2+(player.y+12-b.y)^2<radius^2 then
            for y=player.y+2,player.y+22,4 do for x=player.x+2,player.x+28,4 do
                if Abyss.boneTouches(b,x,y) then Hazards.kill('bone');return end
            end end
        end
    end
end
function T.draw()
    love.graphics.setColor(1,1,1)
    for _,b in ipairs(T.parts) do Art.draw(b.key,b.x,b.y,b.w,b.angle,b.h) end
end
function T.addLights(lights)
    for _,b in ipairs(T.parts) do if #lights<24 then
        local spot=Art.images[b.key].glow or {u=.5,v=.5}
        local dx,dy=(spot.u-.5)*b.w,(spot.v-.5)*b.h
        lights[#lights+1]={b.x+math.cos(b.angle)*dx-math.sin(b.angle)*dy,b.y+math.sin(b.angle)*dx+math.cos(b.angle)*dy,80,.65}
    end end
end
function T.resize(ratio) for _,b in ipairs(T.parts) do b.x=b.x*ratio end end
return T
