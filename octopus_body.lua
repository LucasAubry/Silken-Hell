-- Native vector rendering of the authored body SVG: compiled once, no bitmap.
local B={path='assets/vector/octopus_body.svg'}
function B.load()
    if B.mesh then return end
    local source=assert(love.filesystem.read(B.path));local vertices={}
    for kind,tag in source:gmatch('<(%w+)%s+([^>]-)/>') do
        if kind=='polygon' or kind=='ellipse' then
            local a={};for key,value in tag:gmatch('([%w%-]+)="([^"]*)"') do a[key]=value end
            local hex=assert(a.fill);local color={tonumber(hex:sub(2,3),16)/255,tonumber(hex:sub(4,5),16)/255,tonumber(hex:sub(6,7),16)/255}
            local points={}
            if kind=='polygon' then
                for number in a.points:gmatch('[-%d%.]+') do points[#points+1]=tonumber(number) end
            else
                local cx,cy,rx,ry=tonumber(a.cx),tonumber(a.cy),tonumber(a.rx),tonumber(a.ry)
                for i=0,11 do local angle=i*math.pi/6;points[#points+1]=cx+math.cos(angle)*rx;points[#points+1]=cy+math.sin(angle)*ry end
            end
            for _,triangle in ipairs(love.math.triangulate(points)) do
                for i=1,6,2 do vertices[#vertices+1]={triangle[i],triangle[i+1],0,0,color[1],color[2],color[3],1} end
            end
        end
    end
    assert(#vertices>0,'Empty octopus body SVG')
    B.mesh=love.graphics.newMesh(vertices,'triangles','static')
end
function B.draw(x,y,angle,flash)
    B.load();local g=love.graphics
    g.push('all');g.setShader();g.setColor(1,1-flash,1-flash)
    g.draw(B.mesh,x,y,angle);g.pop()
end
return B
