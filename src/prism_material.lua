-- Shared painted-ink rendering. PNGs, silhouettes, palettes and spider art stay intact.
local M={paths=setmetatable({},{__mode='k'}),surfaceShaders=setmetatable({},{__mode='k'}),enabled=true}
local g=love.graphics
function M.register(image,path) M.paths[image]=path end
function M.drawPreview(callback)
 local previous=M.preview;M.preview=true;callback();M.preview=previous
end
function M.protected(path)
 return path and (path:match('^assets/skins/') or path:find('spider',1,true) or path:find('/original_',1,true)
  or path:find('/reine/',1,true) or path:find('/pieges/',1,true))
end
function M.surfaceShader(source)
 M.inkSource=M.inkSource or assert(love.filesystem.read('assets/shaders/ink_material.glsl'))
 local base=source:gsub('vec4%s+effect%s*%(','vec4 baseEffect(',1)
 local ink=M.inkSource:gsub('inkSurface%(Texel%(tex,uv%),tex,uv%)%*color','inkSurface(baseEffect(color,tex,uv,screen),tex,uv)')
 local shader=g.newShader(base..'\n'..ink);M.surfaceShaders[shader]=true
 shader:send('strength',0)
 return shader
end
local function ground(texture,path)
 if texture:typeOf('Canvas') then
  if (path and path:find('generated/actor/',1,true)) or (Octopus and texture==Octopus.armRaster) then return false end
  return true
 end
 return path and (path:find('wall',1,true) or path:find('floor',1,true)
  or path:find('ground',1,true) or path:find('border',1,true)
  or path:find('soil',1,true) or path:find('nest',1,true)
  or path:find('tunnel',1,true))
end
function M.load()
 if M.shader then return end
 M.shader=g.newShader('assets/shaders/prism_material.glsl')
 M.inkShader=g.newShader('assets/shaders/ink_material.glsl')
 local draw=g.draw
 g.draw=function(drawable,...)
  local current=g.getShader()
  local scope=M.preview or (M.target and g.getCanvas()==M.target)
  if current and M.surfaceShaders[current] then current:send('strength',0) end
  if not scope or not M.enabled or current and not M.surfaceShaders[current] then return draw(drawable,...) end
  local texture=drawable
  if drawable:typeOf('Mesh') then texture=drawable:getTexture() end
  if not texture or not texture:typeOf('Texture') then return draw(drawable,...) end
  local path=M.paths[texture]
  if path and (path:match('^assets/skins/') or path:match('^assets/effects/')) then return draw(drawable,...) end
  if M.preview and M.protected(path) then return draw(drawable,...) end
  local blend,alpha=g.getBlendMode()
  if blend~='alpha' then return draw(drawable,...) end
  local r,green,b=g.getColor()
  if math.max(r,green,b)<.25 then return draw(drawable,...) end
  local iw,ih=texture:getDimensions();local x,y,w,h=0,0,iw,ih
  local quad=select(1,...)
  if type(quad)=='userdata' and quad:typeOf('Quad') then x,y,w,h=quad:getViewport() end
  -- Unregistered canvases include lights and composited FX; retain their old pass.
  local s=current or (path and not M.protected(path) and M.inkShader or M.shader)
  s:send('sprite_rect',{x/iw,y/ih,w/iw,h/ih})
  s:send('texel_step',{math.max(1,w/192)/iw,math.max(1,h/192)/ih})
  s:send('scenery',ground(texture,M.paths[texture]) and 1 or 0)
  s:send('premultiplied',alpha=='premultiplied' and 1 or 0)
  s:send('strength',1)
  g.setShader(s);draw(drawable,...);g.setShader(current)
 end
end
function M.beginScene(target)
 M.target=target
 M.shader:send('clock',Graphics.effects and UI.clock or 0)
 M.shader:send('strength',1)
end
function M.endScene() M.target=nil end
return M
