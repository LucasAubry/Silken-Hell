-- macOS fallback for USB controllers absent from LÖVE's SDL 2.28 backend.
-- SDL3 reads the hardware; an SDL2 virtual gamepad preserves all normal LÖVE
-- callbacks, remapping, deadzones and disconnect handling. Video/audio stay in LÖVE.
local B={pads={},instances={}}
local ffi,s2,s3
local function libraries()
    if s3 then
        assert(s3.SDL_InitSubSystem(0x2000),ffi.string(s3.SDL_GetError()))
        s3.SDL_SetGamepadEventsEnabled(false);s3.SDL_SetJoystickEventsEnabled(false)
        B.ready=true;return
    end
    ffi=require('ffi')
    ffi.cdef[[
        typedef struct {
            unsigned short version,type,naxes,nbuttons,nhats,vendor_id,product_id,padding;
            unsigned int button_mask,axis_mask;
            const char *name;
            void *userdata; void *Update; void *SetPlayerIndex; void *Rumble;
            void *RumbleTriggers; void *SetLED; void *SendEffect;
        } SilkenVirtualPadDesc;
        int SDL_JoystickAttachVirtualEx(const SilkenVirtualPadDesc *desc);
        int SDL_JoystickDetachVirtual(int index);
        void *SDL_JoystickOpen(int index);
        void SDL_JoystickClose(void *pad);
        int SDL_JoystickInstanceID(void *pad);
        int SDL_JoystickGetDeviceInstanceID(int index);
        int SDL_NumJoysticks(void);
        int SDL_JoystickSetVirtualAxis(void *pad,int axis,short value);
        int SDL_JoystickSetVirtualButton(void *pad,int button,unsigned char value);
        void SDL_JoystickUpdate(void);
        bool SDL_InitSubSystem(unsigned int flags);
        void SDL_QuitSubSystem(unsigned int flags);
        unsigned int *SDL_GetGamepads(int *count);
        void *SDL_OpenGamepad(unsigned int id);
        void SDL_CloseGamepad(void *pad);
        bool SDL_GamepadConnected(void *pad);
        const char *SDL_GetGamepadName(void *pad);
        unsigned short SDL_GetGamepadVendor(void *pad);
        unsigned short SDL_GetGamepadProduct(void *pad);
        short SDL_GetGamepadAxis(void *pad,int axis);
        bool SDL_GetGamepadButton(void *pad,int button);
        void SDL_UpdateGamepads(void);
        void SDL_SetGamepadEventsEnabled(bool enabled);
        void SDL_SetJoystickEventsEnabled(bool enabled);
        void SDL_free(void *ptr);
        const char *SDL_GetError(void);
        bool SDL_SetHint(const char *name,const char *value);
    ]]
    local files={'libusb-1.0.0.dylib','libSDL3.0.dylib'};local data={}
    for _,name in ipairs(files) do data[#data+1]=assert(love.filesystem.read('assets/native/macos/'..name)) end
    local hash=love.data.encode('string','hex',love.data.hash('sha256',table.concat(data))):sub(1,16)
    local folder='native-input/'..hash
    assert(love.filesystem.createDirectory(folder))
    for i,name in ipairs(files) do
        if not love.filesystem.getInfo(folder..'/'..name) then assert(love.filesystem.write(folder..'/'..name,data[i])) end
    end
    local contents=assert(love.filesystem.getExecutablePath():match('^(.*)/MacOS/'))
    s2=ffi.load(contents..'/Frameworks/SDL2.framework/Versions/A/SDL2')
    s3=ffi.load(love.filesystem.getSaveDirectory()..'/'..folder..'/libSDL3.0.dylib')
    -- The SDL2 virtual device still obeys LÖVE's focus/background policy.
    s3.SDL_SetHint('SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS','1')
    assert(s3.SDL_InitSubSystem(0x2000),ffi.string(s3.SDL_GetError()))
    s3.SDL_SetGamepadEventsEnabled(false);s3.SDL_SetJoystickEventsEnabled(false)
    B.ready=true
end
local function detach(p)
    -- Device indices shift as controllers disconnect; always resolve the instance.
    for index=0,s2.SDL_NumJoysticks()-1 do
        if s2.SDL_JoystickGetDeviceInstanceID(index)==p.instance then s2.SDL_JoystickDetachVirtual(index);break end
    end
    s2.SDL_JoystickClose(p.virtual);s3.SDL_CloseGamepad(p.source)
    B.instances[p.instance+1]=nil;B.pads[p.id]=nil
end
function B.attach(id)
    local source=s3.SDL_OpenGamepad(id);if source==nil then return end
    local name=ffi.string(s3.SDL_GetGamepadName(source))
    local d=ffi.new('SilkenVirtualPadDesc')
    d.version=1;d.type=1;d.naxes=6;d.nbuttons=15
    d.vendor_id=s3.SDL_GetGamepadVendor(source);d.product_id=s3.SDL_GetGamepadProduct(source)
    d.button_mask=32767;d.axis_mask=63;d.name=name
    local index=s2.SDL_JoystickAttachVirtualEx(d)
    if index<0 then s3.SDL_CloseGamepad(source);return end
    local virtual=s2.SDL_JoystickOpen(index)
    if virtual==nil then s2.SDL_JoystickDetachVirtual(index);s3.SDL_CloseGamepad(source);return end
    local p={id=id,source=source,virtual=virtual,instance=tonumber(s2.SDL_JoystickInstanceID(virtual))}
    -- LÖVE exposes SDL instance IDs plus one to Lua.
    B.pads[id]=p;B.instances[p.instance+1]=true
    -- SDL2 virtual triggers rest at -32768, unlike SDL3's gamepad trigger values.
    for axis=4,5 do s2.SDL_JoystickSetVirtualAxis(virtual,axis,-32768) end
end
function B.scan(native)
    if B.disabled or love.system.getOS()~='OS X' then return end
    if os.getenv('SILKEN_TEST')=='1' and os.getenv('SILKEN_CONTROLLER_HARDWARE_TEST')~='1' then return end
    -- Never take a working native/Steam Input controller away from SDL2.
    if not B.ready then
        if #native>0 or B.failed then return end
        local ok,err=pcall(libraries)
        if not ok then B.failed=tostring(err);return end
    end
    local present={}
    for _,j in ipairs(native) do
        local _,instance=j:getID()
        if not B.instances[instance] then
            local vendor,product=j:getDeviceInfo();present[vendor..':'..product]=true
        end
    end
    s3.SDL_UpdateGamepads()
    local count=ffi.new('int[1]');local ids=s3.SDL_GetGamepads(count)
    if ids~=nil then
        for n=0,count[0]-1 do
            local id=tonumber(ids[n])
            if not B.pads[id] then
                local source=s3.SDL_OpenGamepad(id)
                if source~=nil then
                    local key=tonumber(s3.SDL_GetGamepadVendor(source))..':'..tonumber(s3.SDL_GetGamepadProduct(source))
                    s3.SDL_CloseGamepad(source)
                    if not present[key] then B.attach(id) end
                end
            end
        end
        s3.SDL_free(ids)
    end
end
function B.update()
    if not B.ready then return end
    s3.SDL_UpdateGamepads()
    for _,p in pairs(B.pads) do
        if not s3.SDL_GamepadConnected(p.source) then detach(p)
        else
            for axis=0,5 do
                local value=tonumber(s3.SDL_GetGamepadAxis(p.source,axis))
                if axis>=4 then value=math.min(32767,value*2-32768) end
                s2.SDL_JoystickSetVirtualAxis(p.virtual,axis,value)
            end
            for button=0,14 do s2.SDL_JoystickSetVirtualButton(p.virtual,button,s3.SDL_GetGamepadButton(p.source,button) and 1 or 0) end
        end
    end
    s2.SDL_JoystickUpdate()
end
function B.retry()
    if B.ready and not next(B.pads) then
        s3.SDL_QuitSubSystem(0x2000);B.ready=false
        B.ready=s3.SDL_InitSubSystem(0x2000)
        if B.ready then s3.SDL_SetGamepadEventsEnabled(false);s3.SDL_SetJoystickEventsEnabled(false) end
    end
end
function B.quit()
    if not B.ready then return end
    for _,p in pairs(B.pads) do detach(p) end
    s3.SDL_QuitSubSystem(0x2000);B.ready=false
end
return B
