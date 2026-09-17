local B={}
function B.draw(world,width,height,time)
    if world==6 then return end
    local g=love.graphics
    B.shader=B.shader or g.newShader('biome_floor.glsl')
    B.shader:send('biome',world); B.shader:send('clock',time or 0)
    B.shader:send('dimensions',{width,height})
    g.push('all'); g.setColor(1,1,1); g.setShader(B.shader)
    g.rectangle('fill',0,0,width,height); g.pop()
end
return B
