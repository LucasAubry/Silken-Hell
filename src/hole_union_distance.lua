-- GPU distance transform of the completed union: internal rims disappear when
-- trails overlap. Recomputed only when the mask changes, never read back by Lua.
local D={}
function D.build(mask,owner,dirty)
 local g=love.graphics;local w,h=mask:getDimensions()
 if not owner.distanceA or owner.distanceA:getWidth()~=w or owner.distanceA:getHeight()~=h then
  for _,key in ipairs({'distanceA','distanceB','distanceResult'}) do if owner[key] then owner[key]:release() end end
  dirty=nil
  local format=g.getCanvasFormats().rgba16f and 'rgba16f' or 'rgba8'
  owner.distanceA=g.newCanvas(w,h,{format=format,dpiscale=1});owner.distanceB=g.newCanvas(w,h,{format=format,dpiscale=1})
  owner.distanceResult=g.newCanvas(w,h,{dpiscale=1})
  owner.distanceA:setFilter('nearest','nearest');owner.distanceB:setFilter('nearest','nearest');owner.distanceResult:setFilter('linear','linear')
 end
 local function region(pad)
  if not dirty then return 0,0,w,h end
  local x,y=math.max(0,math.floor(dirty[1]-pad)),math.max(0,math.floor(dirty[2]-pad))
  local right,bottom=math.min(w,math.ceil(dirty[3]+pad)),math.min(h,math.ceil(dirty[4]+pad))
  return x,y,math.max(0,right-x),math.max(0,bottom-y)
 end
 -- Only distances within 64 pixels of changed coverage can change. Scratch
 -- passes get another 64 pixels of boundary context; all other pixels persist.
 local x,y,rw,rh=region(128);local ox,oy,ow,oh=region(64)
 owner.distancePixels=rw*rh*8+ow*oh;owner.distanceFullPixels=w*h*9
 D.shader=D.shader or g.newShader('assets/shaders/hole_union_distance.glsl')
 local shader=D.shader;g.push('all');g.origin();g.setScissor(x,y,rw,rh);g.setShader(shader);g.setBlendMode('replace','premultiplied');g.setColor(1,1,1)
 shader:send('dimensions',{w,h});shader:send('shape',mask);shader:send('stage',0);shader:send('jump',1)
 g.setCanvas(owner.distanceA);g.clear();g.draw(mask)
 local source,target=owner.distanceA,owner.distanceB
 shader:send('stage',1)
 for _,jump in ipairs({64,32,16,8,4,2,1}) do
  shader:send('jump',jump);g.setCanvas(target);g.clear();g.draw(source);source,target=target,source
 end
 shader:send('stage',2);g.setScissor(ox,oy,ow,oh);g.setCanvas(owner.distanceResult);g.clear();g.draw(source);g.pop()
 return owner.distanceResult
end
return D
