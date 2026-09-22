local B={}
function B.draw(world,width,height,time)
    if world==6 then return end
    local g=love.graphics
    B.shader=B.shader or g.newShader('biome_floor.glsl')
    -- Only the background is downsampled; actors, walls, lights and UI retain
    -- their original resolution. The cave is static and keeps its fine grain.
    local ch=world==5 and 600 or 300
    local cw=math.max(300,math.min(2400,math.floor(width/height*ch+.5)))
    -- Two bounded surfaces keep a custom-width arena and its letterbox
    -- backdrop resident together, instead of reallocating them every frame.
    B.surfaces=B.surfaces or {}
    local cache
    for i,surface in ipairs(B.surfaces) do
        if surface.w==cw and surface.h==ch then cache=table.remove(B.surfaces,i);break end
    end
    if not cache then
        if #B.surfaces>=2 then table.remove(B.surfaces,1).canvas:release() end
        cache={canvas=g.newCanvas(cw,ch),w=cw,h=ch}
        cache.canvas:setFilter('linear','linear')
    end
    B.surfaces[#B.surfaces+1]=cache;B.cache=cache
    local tick=world==5 and 0 or math.floor((time or 0)*30)
    if cache.tick~=tick or cache.world~=world then
        local previous=g.getCanvas();g.push('all');g.setCanvas(cache.canvas);g.origin();g.setScissor();g.clear();g.setColor(1,1,1)
        B.shader:send('biome',world);B.shader:send('clock',tick/30);B.shader:send('dimensions',{cw,ch})
        g.setShader(B.shader);g.rectangle('fill',0,0,cw,ch);g.setCanvas(previous);g.pop()
        cache.tick=tick;cache.world=world
    end
    g.push('all');g.setShader();g.setColor(1,1,1);g.draw(cache.canvas,0,0,0,width/cw,height/ch);g.pop()
end
return B
