-- Packed-earth lips and recessed shafts, baked once for every tunnel.
local M={}
local function surface()
 if M.canvas then return M.canvas end
 local g=love.graphics
 M.canvas=g.newCanvas(208,136,{dpiscale=1});M.canvas:setFilter('linear','linear')
 local shader=g.newShader('assets/shaders/earth_mound.glsl')
 local mesh=g.newMesh({{0,0,0,0},{208,0,1,0},{208,136,1,1},{0,136,0,1}},'fan','static')
 g.push('all');g.setCanvas(M.canvas);g.origin();g.setScissor();g.clear(0,0,0,0)
 g.setBlendMode('replace','premultiplied');g.setColor(1,1,1);g.setShader(shader);g.draw(mesh);g.pop()
 mesh:release();shader:release()
 return M.canvas
end
function M.draw(x,y,width,height,angle,tinted)
 local g=love.graphics;local canvas=surface();width=width or 104;height=height or width*68/104
 g.push('all');g.setShader();g.setBlendMode('alpha');if not tinted then g.setColor(1,1,1) end
 g.draw(canvas,x,y,angle or 0,width/208,height/136,104,68);g.pop()
end
return M
