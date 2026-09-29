local I={}
function I.progress()
 local world=1
 for _,w in ipairs(Worlds.order) do if Worlds.canEnter(w) then world=w end end
 return world
end
function I.complete(world)
 if Replay.playing then return end
 I.install(I.progress())
end
function I.install(world)
 world=world or I.progress()
 if I.world==world then return I.applied end
 local image=require('icon_composer').make(world)
 local encoded=image:encode('png');local raw=encoded:getString()
 love.window.setIcon(image);image:release();encoded:release();I.world=world
 I.applied=true
 if love.system.getOS()~='OS X' then return true end
 -- SDL's window icon does not update the macOS Dock. Set this process's
 -- application image directly, without modifying the shared LÖVE runtime.
 local ok,why=pcall(function()
  local ffi=require 'ffi'
  ffi.cdef[[void *objc_getClass(const char *name); void *sel_registerName(const char *name); void objc_msgSend(void);]]
  local objc=ffi.load('/usr/lib/libobjc.A.dylib')
  local send=ffi.cast('void *(*)(void *, void *)',objc.objc_msgSend)
  local arg=ffi.cast('void *(*)(void *, void *, void *)',objc.objc_msgSend)
  local bytes=ffi.cast('void *(*)(void *, void *, const void *, unsigned long)',objc.objc_msgSend)
  local set=ffi.cast('void (*)(void *, void *, void *)',objc.objc_msgSend)
  local sel=objc.sel_registerName
  local data=bytes(objc.objc_getClass('NSData'),sel('dataWithBytes:length:'),raw,#raw)
  local icon=arg(send(objc.objc_getClass('NSImage'),sel('alloc')),sel('initWithData:'),data)
  assert(icon~=nil,'Unable to decode Dock icon')
  local app=send(objc.objc_getClass('NSApplication'),sel('sharedApplication'))
  set(app,sel('setApplicationIconImage:'),icon)
  local current=send(app,sel('applicationIconImage'))
  I.applied=current~=nil
  ffi.cast('void (*)(void *, void *)',objc.objc_msgSend)(icon,sel('release'))
 end)
 I.error=not ok and tostring(why) or nil
 return ok and I.applied
end
return I
