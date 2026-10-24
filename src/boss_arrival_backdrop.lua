-- Freeze the actual fully lit arena once, without the arriving boss.
local B={}
function B.clear(scene)
 if scene.background then scene.background:release();scene.background=nil end
 scene.captures=0
end
function B.ready(scene,canvas)
 local bg=scene.background
 return bg and bg:getWidth()==canvas:getWidth() and bg:getHeight()==canvas:getHeight() and bg:getDPIScale()==canvas:getDPIScale()
end
function B.begin(scene)
 scene.hiddenMethods={}
 for _,key in ipairs({'draw','drawGround','drawFog','drawLights'}) do
  if scene.boss[key] then scene.hiddenMethods[key]=scene.boss[key];scene.boss[key]=function()end end
 end
end
function B.capture(scene,canvas)
 for key,method in pairs(scene.hiddenMethods) do scene.boss[key]=method end
 scene.hiddenMethods=nil
 local g=love.graphics
 if scene.background then scene.background:release() end
 scene.background=g.newCanvas(canvas:getWidth(),canvas:getHeight(),{dpiscale=canvas:getDPIScale()})
 local target=g.getCanvas();g.push('all');g.setCanvas(scene.background);g.origin();g.setShader();g.clear()
 g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(canvas);g.setCanvas(target);g.pop()
 scene.captures=(scene.captures or 0)+1
end
function B.draw(canvas,w,h)
 local g=love.graphics;local scale,x,y=App.viewport(w,h)
 -- Preserve the game's display shader, rather than recoloring the arena.
 g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(canvas,x,y,0,scale,scale)
 g.setBlendMode('alpha');g.setShader();g.translate(x,y);g.scale(scale)
 g.setScissor(x,y,Arena.width*scale,600*scale)
end
return B
