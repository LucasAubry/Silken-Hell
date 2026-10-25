local T={}

function T.run()
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end
 local g=love.graphics
 local M=require('prism_material')
 local oldEnabled,oldPreview,oldTarget=M.enabled,M.preview,M.target
 local oldClock,oldEffects=UI.clock,Graphics.effects
 local owned={}
 local function own(object)owned[#owned+1]=object;return object end
 local inkSource=assert(love.filesystem.read('assets/shaders/ink_material.glsl'))
 local prismSource=assert(love.filesystem.read('assets/shaders/prism_material.glsl'))
 local baseSource='vec4 effect(vec4 c, Image tex, vec2 uv, vec2 px) { return Texel(tex,uv)*c; }'
 local surfaceSource='vec4 effect(vec4 c, Image tex, vec2 uv, vec2 px) { vec4 p=Texel(tex,uv); return vec4(p.rgb*vec3(.71,.93,.82),p.a)*c; }'
 local references={ink=own(g.newShader(inkSource)),prism=own(g.newShader(prismSource)),base=own(g.newShader(baseSource))}
 local composed=surfaceSource:gsub('vec4%s+effect%s*%(','vec4 baseEffect(',1)..'\n'..
  inkSource:gsub('inkSurface%(Texel%(tex,uv%),tex,uv%)%*color','inkSurface(baseEffect(color,tex,uv,screen),tex,uv)')
 references.surface=own(g.newShader(composed))
 local surface=own(M.surfaceShader(surfaceSource))
 local custom=own(g.newShader(surfaceSource))
 local data=own(love.image.newImageData(384,96))
 for y=0,95 do for x=0,383 do
  local light=.18+((x*7+y*11)%59)/80
  local alpha=(x%31<3 or y%23<2) and .35 or .9
  data:setPixel(x,y,light,light*.74,light*.43,alpha)
 end end
 local texture=own(g.newImage(data));texture:setFilter('nearest','nearest')
 local quad=own(g.newQuad(8,16,64,64,384,96))
 UI.clock=4.25;Graphics.effects=true

 -- Count only production shaders. Reference uniforms never enter this cache.
 local sends=0
 local tracked={[M.shader]=true,[M.inkShader]=true,[surface]=true}
 local meta=getmetatable(M.shader)
 local methods=type(meta)=='table' and (type(meta.__index)=='table' and meta.__index or meta)
 local originalSend=methods and methods.send
 local counting=false
 if type(originalSend)=='function' then
  counting=pcall(function()
   methods.send=function(shader,...)
    if tracked[shader] then sends=sends+1 end
    return originalSend(shader,...)
   end
  end)
 end

 local function sample(reference,options)
  options=options or {}
  M.enabled=options.enabled~=false;M.preview=options.preview or false;M.target=nil
  local canvas=g.newCanvas(160,128,{dpiscale=1})
  g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.clear(0,0,0,0)
  g.setBlendMode(options.blend or 'alpha',options.alpha or 'alphamultiply')
  g.setColor(unpack(options.color or {1,1,1,.73}))
  if options.scope~=false then M.beginScene(canvas) end
  local shader=reference and references[reference] or options.shader
  if reference then
   local x,y,w,h=quad:getViewport()
   if shader:hasUniform('sprite_rect') then shader:send('sprite_rect',{x/384,y/96,w/384,h/96}) end
   if shader:hasUniform('texel_step') then shader:send('texel_step',{math.max(1,math.max(w,h)/192)/384,math.max(1,math.max(w,h)/192)/96}) end
   if shader:hasUniform('scenery') then shader:send('scenery',options.scenery or 0) end
   if shader:hasUniform('premultiplied') then shader:send('premultiplied',options.alpha=='premultiplied' and 1 or 0) end
   if shader:hasUniform('strength') then shader:send('strength',options.strength==nil and 1 or options.strength) end
   if shader:hasUniform('clock') then shader:send('clock',Graphics.effects and UI.clock or 0) end
  end
  g.setShader(shader)
  local _,_,w,h=quad:getViewport();local scale=math.min(136/w,104/h)
  g.draw(texture,quad,12,12,0,scale,scale)
  assert(g.getShader()==shader,'Material rendering must restore the caller shader')
  M.endScene();g.pop()
  local result=canvas:newImageData();canvas:release();return result
 end
 local checks=0
 local function compare(label,reference,options)
  local expected=sample(reference,options)
  local actual=sample(nil,options)
  assert(actual:getString()==expected:getString(),'Cached material output differs from explicit reference: '..label)
  actual:release();expected:release();checks=checks+1
 end
 local function cached(label,reference,options)
  compare(label,reference,options)
  local before=sends
  local image=sample(nil,options);image:release()
  if counting then assert(sends==before,'Identical material draw must send no cached uniforms: '..label) end
 end

 local ok,err=xpcall(function()
  M.register(texture,'assets/monstres/cache-fixture.png')
  cached('ink first and repeated','ink')
  local before=sends
  quad:setViewport(32,20,320,48,384,96)
  local changed=sample(nil);changed:release()
  if counting then assert(sends>=before+2,'Mutating a Quad must update both its rectangle and texel step') end
  cached('mutable Quad position and large dimensions','ink')

  M.register(texture,'assets/monstres/paradis/pieges/cache-fixture.png')
  cached('same texture re-registered as protected art','prism')
  M.register(texture,'assets/skins/cache-fixture.png')
  cached('same texture re-registered as a skipped skin','base')
  M.register(texture,'generated/floor')
  cached('same texture re-registered as scenery','ink',{scenery=1})
  M.register(texture,nil)
  cached('same texture re-registered without a path','prism')
  M.register(texture,'assets/effects/cache-fixture.png')
  cached('same texture re-registered as a skipped effect','base')
  M.register(texture,'assets/monstres/cache-fixture.png')
  cached('same texture restored as ink','ink')
  cached('premultiplied alpha','ink',{alpha='premultiplied'})
  cached('return to regular alpha','ink')
  cached('additive blend bypass','base',{blend='add'})

  cached('composed surface active','surface',{shader=surface})
  cached('composed surface disabled','surface',{shader=surface,enabled=false,strength=0})
  cached('composed surface outside scene','surface',{shader=surface,scope=false,strength=0})
  cached('composed surface enabled again','surface',{shader=surface})
  cached('composed surface additive bypass','surface',{shader=surface,blend='add',strength=0})
  cached('composed surface dark tint bypass','surface',{shader=surface,color={.1,.12,.15,.73},strength=0})
  M.register(texture,'assets/monstres/paradis/pieges/cache-fixture.png')
  cached('composed protected preview bypass','surface',{shader=surface,preview=true,strength=0})
  M.register(texture,'assets/monstres/cache-fixture.png')
  cached('composed surface restored after bypasses','surface',{shader=surface})
  -- A caller shader that is not composed with the material remains untouched.
  local a=sample(nil,{shader=custom,enabled=false})
  local b=sample(nil,{shader=custom,enabled=true})
  assert(a:getString()==b:getString(),'An unrelated caller shader must bypass material treatment')
  a:release();b:release();checks=checks+1
 end,debug.traceback)

 if counting then methods.send=originalSend end
 M.enabled,M.preview,M.target=oldEnabled,oldPreview,oldTarget
 UI.clock,Graphics.effects=oldClock,oldEffects
 for i=#owned,1,-1 do owned[i]:release() end
 if not ok then error(err,0) end
 print(string.format('PASS material cache: %d explicit-reference pixel comparisons; mutable Quad; texture path invalidation; alpha and surface transitions; caller shader restoration; %s',
  checks,counting and 'identical draws send zero uniforms' or 'shader send instrumentation unavailable'))
 love.event.quit()
end

return T
