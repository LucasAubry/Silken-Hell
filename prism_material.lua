-- Neutral sheen for scene textures, including cropped and mesh-based sprites.
-- HUD, lighting passes and existing gameplay/status shaders retain their colors.
local M={paths=setmetatable({},{__mode='k'}),enabled=true}
local g=love.graphics
function M.register(image,path) M.paths[image]=path end
local function ground(texture,path)
 if texture:typeOf('Canvas') then
  if Octopus and texture==Octopus.armRaster then return false end
  return true
 end
 return path and (path:find('wall',1,true) or path:find('floor',1,true)
  or path:find('ground',1,true) or path:find('border',1,true)
  or path:find('soil',1,true) or path:find('nest',1,true)
  or path:find('tunnel',1,true))
end
function M.load()
 if M.shader then return end
 M.shader=g.newShader('assets/prism_material.glsl')
 local draw=g.draw
 g.draw=function(drawable,...)
  if not M.target or not M.enabled or g.getCanvas()~=M.target or g.getShader() then return draw(drawable,...) end
  local texture=drawable
  if drawable:typeOf('Mesh') then texture=drawable:getTexture() end
  if not texture or not texture:typeOf('Texture') then return draw(drawable,...) end
  local path=M.paths[texture]
  if path and (path:match('^assets/skins/') or path:match('^assets/effects/')) then return draw(drawable,...) end
  local blend,alpha=g.getBlendMode()
  if blend~='alpha' then return draw(drawable,...) end
  local r,green,b=g.getColor()
  if math.max(r,green,b)<.25 then return draw(drawable,...) end
  local iw,ih=texture:getDimensions();local x,y,w,h=0,0,iw,ih
  local quad=select(1,...)
  if type(quad)=='userdata' and quad:typeOf('Quad') then x,y,w,h=quad:getViewport() end
  local s=M.shader
  s:send('sprite_rect',{x/iw,y/ih,w/iw,h/ih})
  s:send('texel_step',{math.max(1,w/192)/iw,math.max(1,h/192)/ih})
  s:send('scenery',ground(texture,M.paths[texture]) and 1 or 0)
  s:send('premultiplied',alpha=='premultiplied' and 1 or 0)
  g.setShader(s);draw(drawable,...);g.setShader()
 end
end
function M.beginScene(target)
 M.target=target
 M.shader:send('clock',Graphics.effects and UI.clock or 0)
 M.shader:send('strength',1)
end
function M.endScene() M.target=nil end
return M
