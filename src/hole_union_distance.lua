-- GPU distance transform of the completed union: internal rims disappear when
-- trails overlap. Recomputed only when the mask changes, never read back by Lua.
local D={}
function D.build(mask,owner)
 local g=love.graphics;local w,h=mask:getDimensions()
 if not owner.distanceA or owner.distanceA:getWidth()~=w or owner.distanceA:getHeight()~=h then
  for _,key in ipairs({'distanceA','distanceB','distanceResult'}) do if owner[key] then owner[key]:release() end end
  local format=g.getCanvasFormats().rgba16f and 'rgba16f' or 'rgba8'
  owner.distanceA=g.newCanvas(w,h,{format=format,dpiscale=1});owner.distanceB=g.newCanvas(w,h,{format=format,dpiscale=1})
  owner.distanceResult=g.newCanvas(w,h,{dpiscale=1})
  owner.distanceA:setFilter('nearest','nearest');owner.distanceB:setFilter('nearest','nearest');owner.distanceResult:setFilter('linear','linear')
 end
 D.shader=D.shader or g.newShader('assets/shaders/hole_union_distance.glsl')
 local shader=D.shader;g.push('all');g.origin();g.setScissor();g.setShader(shader);g.setBlendMode('replace','premultiplied');g.setColor(1,1,1)
 shader:send('dimensions',{w,h});shader:send('shape',mask);shader:send('stage',0);shader:send('jump',1)
 g.setCanvas(owner.distanceA);g.clear();g.draw(mask)
 local source,target=owner.distanceA,owner.distanceB
 shader:send('stage',1)
 for _,jump in ipairs({64,32,16,8,4,2,1}) do
  shader:send('jump',jump);g.setCanvas(target);g.clear();g.draw(source);source,target=target,source
 end
 shader:send('stage',2);g.setCanvas(owner.distanceResult);g.clear();g.draw(source);g.pop()
 return owner.distanceResult
end
return D
