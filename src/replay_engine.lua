-- Historical simulations have private globals/modules. Only trusted bundled or
-- locally archived game sources are loaded; a downloaded replay supplies data only.
local E={}
local json=require 'json'
local function copy(t)
 local out={};for k,v in pairs(t) do out[k]=v end;return out
end
local function clone(t)
 if type(t)~='table' then return t end
 local out={};for k,v in pairs(t) do out[k]=clone(v) end;return out
end
function E.catalog()
 if not E.history then
  E.history=json.decode(love.data.decompress('string','zlib',assert(love.filesystem.read('assets/replay_engines/history.dat'))))
 end
 return E.history
end
function E.remember(build)
 local path='replay-engines/'..build..'.dat'
 if love.filesystem.getInfo(path) then return end
 local files={}
 local function walk(dir)
  for _,name in ipairs(love.filesystem.getDirectoryItems(dir)) do
   local p=dir..'/'..name;local info=love.filesystem.getInfo(p)
   if info.type=='directory' then walk(p)
   elseif p:match('%.lua$') or p:match('%.glsl$') or p:match('%.json$') then files[p]=love.filesystem.read(p) end
  end
 end
 walk('src');walk('assets')
 for _,p in ipairs({'assets/art-metadata.json','assets/pixel-art.json'}) do files[p]=love.filesystem.read(p) end
 love.filesystem.createDirectory('replay-engines')
 love.filesystem.write(path,love.data.compress('string','zlib',json.encode({build=build,entry='game',files=files})))
end
function E.find(build)
 local path='replay-engines/'..build..'.dat'
 if love.filesystem.getInfo(path) then
  local ok,data=pcall(function()return json.decode(love.data.decompress('string','zlib',love.filesystem.read(path)))end)
  if ok and data.build==build then return data end
 end
 local history=E.catalog()
 for _,engine in ipairs(history.engines) do if engine.build==build then return engine end end
end
function E.source(engine,path)
 local value=engine.files[path]
 return value and (engine.revision and E.catalog().blobs[value] or value)
end
function E.create(engine,R)
 local env={};local modules={};local native=require;local host=love
 for _,key in ipairs({'assert','error','ipairs','next','pairs','pcall','xpcall','select','tonumber','tostring','type','unpack','setmetatable','getmetatable','rawget','rawset','rawequal','print','collectgarbage','setfenv','getfenv','loadstring','load','coroutine','string','table','debug','io','os','jit','bit'}) do env[key]=_G[key] end
 env._G=env;env.arg={};env.math=copy(math);env.love=copy(host)
 env.love.math=copy(host.math);env.love.filesystem=copy(host.filesystem);env.love.graphics=copy(host.graphics)
 local fs,g=env.love.filesystem,env.love.graphics
 local metadata=json.decode(E.source(engine,'assets/art-metadata.json') or E.source(engine,'art-metadata.json') or '{}')
 E.spriteHistory=E.spriteHistory or json.decode(host.filesystem.read('assets/replay_engines/sprite-history.json') or '{}')
 E.retiredSprites=E.retiredSprites or json.decode(host.filesystem.read('assets/replay_engines/retired-sprites.json') or '{}')
 local function archivedImage(path)
  local key=engine.images and engine.images[path]
  if key then return 'assets/replay_engines/images/'..key..'.png' end
  local resolved=native('asset_paths').resolve(path)
  local meta=metadata[path] or metadata[resolved]
  local versions=E.spriteHistory[resolved]
  return versions and meta and versions[tostring(meta.fileSize)] or E.retiredSprites[path] or E.retiredSprites[resolved]
 end
 local function imageData(path)
  local file=archivedImage(path)
  return file and host.filesystem.read(file)
 end
 local function read(path)return E.source(engine,path) or imageData(path) or host.filesystem.read(path)end
 fs.read=read
 fs.write=function()return true end;fs.append=fs.write;fs.remove=fs.write;fs.createDirectory=fs.write;fs.setIdentity=function()end
 fs.getInfo=function(path,...)
  local text=E.source(engine,path) or imageData(path)
  if text then return {type='file',size=#text} end
  for name in pairs(engine.files) do if name:sub(1,#path+1)==path..'/' then return {type='directory'} end end
  return host.filesystem.getInfo(native('asset_paths').resolve(path),...)
 end
 fs.getDirectoryItems=function(path)
  local names,seen={},{}
  for name in pairs(engine.files) do if name:sub(1,#path+1)==path..'/' then
   local leaf=name:sub(#path+2):match('^[^/]+');if not seen[leaf] then seen[leaf]=true;names[#names+1]=leaf end
  end end
  if path:match('^assets') or path:match('^texture') then
   for _,name in ipairs(host.filesystem.getDirectoryItems(path)) do if not seen[name] then seen[name]=true;names[#names+1]=name end end
   for name in pairs(engine.images or {}) do if name:sub(1,#path+1)==path..'/' then
    local leaf=name:sub(#path+2):match('^[^/]+');if not seen[leaf] then seen[leaf]=true;names[#names+1]=leaf end
   end end
  end
  table.sort(names);return names
 end
 local function compile(text,path)return setfenv(assert(loadstring(text,'@'..path)),env)end
 fs.load=function(path)return compile(assert(read(path),path),path)end
 g.newShader=function(a,b)
  if type(a)=='string' then a=E.source(engine,a) or a end
  if type(b)=='string' then b=E.source(engine,b) or b end
  if b then return host.graphics.newShader(a,b) end;return host.graphics.newShader(a)
 end
 -- Historical asset paths are resolved through the game's retained aliases.
 local function asset(path)
  if type(path)=='string' then
   local bytes=imageData(path);if bytes then return host.filesystem.newFileData(bytes,path) end
   if not host.filesystem.getInfo(path) then return native('asset_paths').resolve(path) end
  end
  return path
 end
 env.love.image=copy(host.image)
 env.love.image.newImageData=function(path,...)return host.image.newImageData(asset(path),...)end
 g.newImage=function(path,...)return host.graphics.newImage(asset(path),...)end
 g.newFont=function(path,...)return host.graphics.newFont(asset(path),...)end
 env.package={loaded=modules,path=package.path}
 env.require=function(name)
  if modules[name]~=nil then return modules[name] end
  local path=name:gsub('%.','/')
  for _,candidate in ipairs({'src/'..path..'.lua','src/'..path..'/init.lua',path..'.lua',path..'/init.lua'}) do
   local source=E.source(engine,candidate)
   if source then modules[name]=true;local value=compile(source,candidate)();if value~=nil then modules[name]=value end;return modules[name] end
  end
  if name=='ffi' or name=='bit' or name=='utf8' then return native(name) end
  error('Module historique absent : '..name)
 end
 -- Controllers and process/network startup belong to the live application.
 modules.controller_usb={scan=function()end,update=function()end,quit=function()end,retry=function()end}
 env.require(engine.entry)
 env.Replay=R;modules.replay=R
 env.love.math.random=function(...)return host.math.random(...)end;env.math.random=env.love.math.random
 env.Profile.load();env.Profile.save=function()end
 env.Graphics=env.Graphics or {}
 for k,v in pairs(Graphics) do if type(v)~='function' then env.Graphics[k]=v end end
 env.Graphics.pace=function()end
 env.Audio=copy(Audio)
 if R.recovery then for key,value in pairs(env.Audio) do if type(value)=='function' then env.Audio[key]=function()end end end end
 env.UI.fonts=UI.fonts;env.UI.fallbackFonts=UI.fallbackFonts;env.UI.pixel=UI.pixel;env.UI.shader=UI.shader
 env.font_demon=font_demon
 local add=env.Art.add
 env.Art.add=function(key,path)
  local archived=archivedImage(path)
  local present=not archived and Art.images[key]
  if not present then
   E.artCache=E.artCache or {}
   local cacheKey=(archived or engine.build..path)..':'..key
   if not E.artCache[cacheKey] then add(key,path);E.artCache[cacheKey]=env.Art.images[key] end
   env.Art.images[key]=copy(E.artCache[cacheKey]);return
  end
  local a=copy(present);local meta=metadata[path]
  if meta then
   a.w,a.h=meta.w,meta.h
   if meta.mask then a.mask={};a.maskSize=192;for i=1,#meta.mask do a.mask[i-1]=meta.mask:byte(i)==49 end end
  end
  env.Art.images[key]=a
 end
 env.Art.load()
 -- These render resources are local upvalues initialized by love.load in the
 -- standalone game. Initialize them without invoking window/network startup.
 for i=1,60 do
  local name=debug.getupvalue(env.love.draw,i);if not name then break end
  if name=='hitShader' then
   local path=engine.files['assets/shaders/hyper_demon_shader.glsl'] and 'assets/shaders/hyper_demon_shader.glsl' or 'hyper_demon_shader.glsl'
   local source=E.source(engine,path);if source then debug.setupvalue(env.love.draw,i,g.newShader(source)) end
  elseif name=='polishShader' then
   local path=engine.files['assets/shaders/polish.glsl'] and 'assets/shaders/polish.glsl' or engine.files['assets/polish.glsl'] and 'assets/polish.glsl' or 'polish.glsl'
   debug.setupvalue(env.love.draw,i,g.newShader(E.source(engine,path) or assert(read(path))))
  end
 end
 env.load_level();env.load_world();env.load_player();env.load_objet();env.load_mob();env.load_particles()
 env.Arena.width=R.data.width;env.Campaign.install()
 env.Online.enabled=false
 for key,value in pairs(env.Online) do if type(value)=='function' then env.Online[key]=function()end end end
 env.Bestiary.load();env.Bestiary.save=function()end
 for _,name in ipairs({'psychedelic_fx','prism_material','old_tv'}) do
  local ok,module=pcall(env.require,name);if ok and module.load then module.load() end
 end
 -- Install the same level wrapper without the obsolete sparse-JSON copy.
 local reset=env.reset_level
 env.reset_level=function(options)
  local ok,motion=pcall(env.require,'render_motion');if ok then motion.reset() end
  if env.Achievements.enterLevel then env.Achievements.enterLevel() end
  return reset(options)
 end
 local oldPlayer,oldLevels,oldWorld,oldBiome,oldWidth,oldTimer=player,levels,Campaign.world,Campaign.biome,Arena.width,timer
 local instance={env=env,engine=engine}
 function instance.start(session)
  env.Secret.duel=clone(R.data.duel);env.App.sessionLayout=session and R.data.layouts[R.data.world..':'..R.data.startLevel] or nil
  env.App.singleLevel=R.data.single;env.App.practice=R.data.startLevel;env.App.hardcore=R.data.hardcore==true
  env.App.start(R.data.world)
  instance.sync()
 end
 function instance.sync()
  player=env.player;timer=env.timer;App.state=env.App.state
 end
 function instance.tick(dt)env.App.simulate(dt);instance.sync()end
 function instance.checkpoint()
  return {R.frame,env.player.level,math.floor(env.player.x*100+.5),math.floor(env.player.y*100+.5),env.player.death,
   env.App.state=='victory' or env.App.state=='customVictory' or (env.App.state=='credits' and env.Ending.completed)}
 end
 function instance.stateHash()
  return env.require('replay_state').hash()
 end
 function instance.draw()
  env.UI.clock=UI.clock
  -- The old scene renderer remains in its own globals; live transport receives clicks.
  local oldControls,oldLegacy=R.controls,R.legacy;R.controls=function()end;R.legacy=nil
  -- A recent archived renderer also knows about historical playback. Suppress
  -- that outer dispatch while drawing its own scene to avoid recursive entry.
  local ok,err=xpcall(env.love.draw,debug.traceback);R.controls=oldControls;R.legacy=oldLegacy
  if not ok then error(err) end
  UI.buttons=env.UI.buttons
  local scale=math.min(host.graphics.getWidth()/1200,host.graphics.getHeight()/750)
  host.graphics.push('all');host.graphics.origin();host.graphics.setShader()
  host.graphics.translate((host.graphics.getWidth()-1200*scale)/2,(host.graphics.getHeight()-750*scale)/2);host.graphics.scale(scale)
  R.controls();host.graphics.pop()
 end
 function instance.close()
  player=oldPlayer;Campaign.select(oldWorld);Campaign.biome=oldBiome;levels=oldLevels;Arena.width=oldWidth;timer=oldTimer
 end
 return instance
end
return E
