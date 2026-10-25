-- Shared painted-ink rendering. PNGs, silhouettes, palettes and spider art stay intact.
local M={paths=setmetatable({},{__mode='k'}),surfaceShaders=setmetatable({},{__mode='k'}),enabled=true}
local g=love.graphics
local textures=setmetatable({},{__mode='k'})
local uniforms=setmetatable({},{__mode='k'})
function M.register(image,path) M.paths[image]=path;textures[image]=nil end
local function state(shader)
 local values=uniforms[shader]
 if not values then values={};uniforms[shader]=values end
 return values
end
local function scalar(shader,values,name,value)
 if values[name]~=value then shader:send(name,value);values[name]=value end
end
local function rect(shader,values,x,y,w,h)
 local value=values.sprite_rect
 if not value then value={};values.sprite_rect=value end
 if value[1]~=x or value[2]~=y or value[3]~=w or value[4]~=h then
  value[1],value[2],value[3],value[4]=x,y,w,h;shader:send('sprite_rect',value)
 end
end
local function step(shader,values,x,y)
 local value=values.texel_step
 if not value then value={};values.texel_step=value end
 if value[1]~=x or value[2]~=y then value[1],value[2]=x,y;shader:send('texel_step',value) end
end
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
 scalar(shader,state(shader),'strength',0)
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
local function textureInfo(texture)
 local info=textures[texture]
 if not info then
  local path=M.paths[texture]
  local iw,ih=texture:getDimensions()
  info={width=iw,height=ih,protected=M.protected(path),ink=path~=nil,
   skip=path and (path:match('^assets/skins/') or path:match('^assets/effects/') or require('art_filter').pixelArt[path]),
   scenery=ground(texture,path) and 1 or 0}
  textures[texture]=info
 end
 return info
end
function M.load()
 if M.shader then return end
 M.shader=g.newShader('assets/shaders/prism_material.glsl')
 M.inkShader=g.newShader('assets/shaders/ink_material.glsl')
 local draw=g.draw
 local function plain(drawable,current,surface,...)
  if surface then scalar(current,state(current),'strength',0) end
  return draw(drawable,...)
 end
 g.draw=function(drawable,...)
  local current=g.getShader()
  local scope=M.preview or (M.target and g.getCanvas()==M.target)
  local surface=current and M.surfaceShaders[current]
  -- Composed shaders only need to disable their ink pass when bypassed.
  -- Sending 0 then 1 around every styled sprite needlessly flushes batches.
  if not scope or not M.enabled or current and not surface then return plain(drawable,current,surface,...) end
  local texture=drawable
  if drawable:typeOf('Mesh') then texture=drawable:getTexture() end
  if not texture or not texture:typeOf('Texture') then return plain(drawable,current,surface,...) end
  local info=textureInfo(texture)
  if info.skip or M.preview and info.protected then return plain(drawable,current,surface,...) end
  local blend,alpha=g.getBlendMode()
  if blend~='alpha' then return plain(drawable,current,surface,...) end
  local r,green,b=g.getColor()
  if math.max(r,green,b)<.25 then return plain(drawable,current,surface,...) end
  local iw,ih=info.width,info.height;local x,y,w,h=0,0,iw,ih
  local quad=select(1,...)
  if type(quad)=='userdata' and quad:typeOf('Quad') then x,y,w,h=quad:getViewport() end
  -- Unregistered canvases include lights and composited FX; retain their old pass.
  local s=current or (info.ink and not info.protected and M.inkShader or M.shader)
  local values=state(s)
  rect(s,values,x/iw,y/ih,w/iw,h/ih)
  -- A square source-pixel footprint keeps outlines equal on long sprites.
  local pixel=math.max(1,math.max(w,h)/192)
  step(s,values,pixel/iw,pixel/ih)
  scalar(s,values,'scenery',info.scenery)
  scalar(s,values,'premultiplied',alpha=='premultiplied' and 1 or 0)
  scalar(s,values,'strength',1)
  g.setShader(s);draw(drawable,...);g.setShader(current)
 end
end
function M.beginScene(target)
 M.target=target
 local values=state(M.shader)
 scalar(M.shader,values,'strength',1)
end
function M.endScene() M.target=nil end
return M
