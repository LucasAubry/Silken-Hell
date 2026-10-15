local B={}
local function release(surface)
    if surface.paradise then surface.paradise:release() end
    surface.canvas:release()
end
local function paradiseBase(cache)
    if B.paradiseSupported==nil then B.paradiseSupported=love.graphics.getCanvasFormats().rgba16f==true end
    if not B.paradiseSupported then return end
    local g=love.graphics
    B.paradiseBaseShader=B.paradiseBaseShader or g.newShader('assets/shaders/paradise_floor_base.glsl')
    B.paradiseLightShader=B.paradiseLightShader or g.newShader('assets/shaders/paradise_floor_light.glsl')
    if not cache.paradise then
        -- Keep static marble at the very same pixel density as the final floor.
        -- Half floats avoid an extra 8-bit quantization before the animated wash.
        cache.paradise=g.newCanvas(cache.w,cache.h,{format='rgba16f',dpiscale=1})
        cache.paradise:setFilter('nearest','nearest')
        local previous=g.getCanvas();g.push('all');g.setCanvas(cache.paradise);g.origin();g.setScissor()
        g.setBlendMode('replace','premultiplied');g.setColor(1,1,1)
        B.paradiseBaseShader:send('dimensions',cache.dimensions)
        g.setShader(B.paradiseBaseShader);g.rectangle('fill',0,0,cache.w,cache.h)
        g.setCanvas(previous);g.pop()
    end
    return cache.paradise
end
function B.draw(world,width,height,time)
    local g=love.graphics
    B.shader=B.shader or g.newShader('assets/shaders/biome_floor.glsl')
    -- Only the background is downsampled; actors, walls, lights and UI retain
    -- their original resolution. The cave is static and keeps its fine grain.
    local ch=Graphics and Graphics.floorHeight() or 360
    if world==1 then local target=g.getCanvas();ch=target and target:getPixelHeight() or love.graphics.getPixelHeight() end
    local cw=math.max(300,math.min(2400,math.floor(width/height*ch+.5)))
    -- Two bounded surfaces keep a custom-width arena and its letterbox
    -- backdrop resident together, instead of reallocating them every frame.
    B.surfaces=B.surfaces or {}
    local cache
    for i,surface in ipairs(B.surfaces) do
        if surface.w==cw and surface.h==ch then cache=table.remove(B.surfaces,i);break end
    end
    if not cache then
        if #B.surfaces>=2 then release(table.remove(B.surfaces,1)) end
        cache={canvas=g.newCanvas(cw,ch),w=cw,h=ch,dimensions={cw,ch}}
        cache.canvas:setFilter('linear','linear')
        require('prism_material').register(cache.canvas,'generated/floor')
    end
    B.surfaces[#B.surfaces+1]=cache;B.cache=cache
    local hz=Graphics and Graphics.backgroundHz() or 60
    local tick=(world==5 or world==4 and Graphics and not Graphics.effects) and 0 or math.floor((time or 0)*hz)
    if cache.tick~=tick or cache.world~=world then
        local base=world==1 and paradiseBase(cache)
        local previous=g.getCanvas();g.push('all');g.setCanvas(cache.canvas);g.origin();g.setScissor();g.clear();g.setColor(1,1,1)
        if base then
            B.paradiseLightShader:send('clock',tick/hz);B.paradiseLightShader:send('dimensions',cache.dimensions)
            g.setShader(B.paradiseLightShader);g.draw(base)
        elseif world==4 then
            B.oceanShader=B.oceanShader or g.newShader('assets/shaders/ocean_floor.glsl')
            B.oceanShader:send('clock',tick/hz);B.oceanShader:send('dimensions',cache.dimensions)
            g.setShader(B.oceanShader);g.rectangle('fill',0,0,cw,ch)
        else
            B.shader:send('biome',world);B.shader:send('clock',tick/hz);B.shader:send('dimensions',cache.dimensions)
            g.setShader(B.shader);g.rectangle('fill',0,0,cw,ch)
        end
        g.setCanvas(previous);g.pop()
        cache.tick=tick;cache.world=world
    end
    g.push('all');g.setShader();g.setColor(1,1,1);g.draw(cache.canvas,0,0,0,width/cw,height/ch);g.pop()
end
return B
