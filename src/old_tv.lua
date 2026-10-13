-- One overlay pass: no scene copy, extra canvas or per-frame texture upload.
local T={size={0,0}}
function T.load()
 T.shader=T.shader or love.graphics.newShader('assets/shaders/old_tv.glsl')
end
function T.draw(w,h)
 local g=love.graphics
 T.load()
 T.size[1],T.size[2]=g.getPixelDimensions()
 T.shader:send('screenSize',T.size)
 T.shader:send('clock',UI.clock or 0)
 g.push('all');g.origin();g.setScissor();g.setShader(T.shader)
 g.setBlendMode('alpha');g.setColor(1,1,1)
 g.draw(UI.pixel,0,0,0,w,h)
 g.pop()
end
return T
