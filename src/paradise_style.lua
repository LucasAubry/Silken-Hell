-- The Paradise palette is a render treatment of the original artwork.
local S={enabled=true,tear={1,.84,.46},kinds={border=1,nest=2,bird=3,black_feather=3,ring=4,cloud=5}}
local g=love.graphics
local rect,step={0,0,0,0},{0,0}
function S.active()
    return S.enabled and Campaign and Campaign.biome==1 and not (Secret and Secret.inArena())
end
function S.load()
    S.shader=S.shader or g.newShader('assets/shaders/paradise_material.glsl')
    require('storm_lightning').load()
end
function S.bind(frame,kind)
    local previous=g.getShader()
    if require('art_filter').pixelArt[require('prism_material').paths[frame.image]] then return previous end
    -- Attack flashes, white boss feathers and the collectible retain their own material.
    if not S.active() or previous and previous~=S.shader then return previous end
    S.load()
    local x,y,w,h=frame.quad:getViewport();local iw,ih=frame.image:getDimensions()
    local rx,ry,rw,rh=x/iw,y/ih,w/iw,h/ih
    if rect[1]~=rx or rect[2]~=ry or rect[3]~=rw or rect[4]~=rh then
        rect[1],rect[2],rect[3],rect[4]=rx,ry,rw,rh;S.shader:send('sprite_rect',rect)
    end
    local sx,sy=math.max(1,w/192)/iw,math.max(1,h/192)/ih
    if step[1]~=sx or step[2]~=sy then step[1],step[2]=sx,sy;S.shader:send('texel_step',step) end
    local material=type(kind)=='number' and kind or S.kinds[kind] or 0
    if S.material~=material then S.material=material;S.shader:send('material_kind',material) end
    g.setShader(S.shader)
    return previous
end
function S.ring(x,y,width)
    local a=require('paradise_ink').frame('tear_ring')
    local w=width*1.14;local h=w*a.h/a.w
    g.push('all');g.setShader();g.setBlendMode('alpha')
    Art.contactShadow(x,y+1,w*.57,h*.61,.25)
    if not Graphics or Graphics.effects then
        g.setColor(1,.74,.23,.09);g.setLineWidth(7);g.ellipse('line',x,y,w*.45,h*.37)
        g.setColor(1,.88,.40,.17);g.setLineWidth(3.5);g.ellipse('line',x,y,w*.44,h*.36)
    end
    g.setColor(.07,.045,.018,1);g.ellipse('fill',x,y,w*.40,h*.40)
    g.setColor(1,1,1);S.bind(a,'ring')
    g.draw(a.image,a.quad,x,y,0,w/a.w,h/a.h,a.w/2,a.h/2)
    g.pop()
end
function S.mobGlow(x,y,radius,green)
    if Graphics and not Graphics.effects then return end
    g.push('all');g.setShader();g.setBlendMode('alpha')
    for i=6,1,-1 do
        local t=i/6
        if green then g.setColor(.61,.72,.37,.012*(1-t*.7))
        else g.setColor(1,.88,.53,.017*(1-t*.7)) end
        g.ellipse('fill',x,y,radius*t,radius*t*.8)
    end
    g.pop()
end
return S
