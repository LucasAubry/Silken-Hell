local E={}
function E.draw()
 if Campaign.biome~=5 or Graphics and not Graphics.effects then return end
 local g=love.graphics
 E.shader=E.shader or g.newShader('assets/shaders/earth_light.glsl')
 g.push('all');g.setShader(E.shader);g.setBlendMode('add')
 E.shader:send('clock',Realms.clock or 0);g.setColor(1,1,1)
 g.draw(UI.pixel,0,0,0,Arena.width,600);g.pop()
end
return E
