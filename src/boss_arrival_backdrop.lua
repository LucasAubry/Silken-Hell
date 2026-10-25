-- Render the real lit arena without the arriving boss; reuse the surface at 30 Hz for living backdrops.
local B={}
function B.clear(scene)
 if scene.background then scene.background:release();scene.background=nil end
 scene.captures=0
end
function B.ready(scene,canvas)
 local bg=scene.background
 return (not scene.liveBackdrop or scene.backgroundTick==math.floor((scene.age or 0)*30)) and bg and bg:getWidth()==canvas:getWidth() and bg:getHeight()==canvas:getHeight() and bg:getDPIScale()==canvas:getDPIScale()
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
 local bg=scene.background
 if not bg or bg:getWidth()~=canvas:getWidth() or bg:getHeight()~=canvas:getHeight() or bg:getDPIScale()~=canvas:getDPIScale() then
  if bg then bg:release() end
  scene.background=g.newCanvas(canvas:getWidth(),canvas:getHeight(),{dpiscale=canvas:getDPIScale()})
 end
 scene.backgroundTick=math.floor((scene.age or 0)*30)
 local target=g.getCanvas();g.push('all');g.setCanvas(scene.background);g.origin();g.setShader();g.clear()
 g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(canvas);g.setCanvas(target);g.pop()
 scene.captures=(scene.captures or 0)+1
end
function B.draw(canvas,w,h,shakeX,shakeY)
 local g=love.graphics;local scale,x,y=App.viewport(w,h)
 local clipX,clipY=x,y;x=x+(shakeX or 0)*scale;y=y+(shakeY or 0)*scale
 -- Preserve the game's display shader, rather than recoloring the arena.
 g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(canvas,x,y,0,scale,scale)
 g.setBlendMode('alpha');g.setShader();g.translate(x,y);g.scale(scale)
 g.setScissor(clipX,clipY,Arena.width*scale,600*scale)
end
return B
