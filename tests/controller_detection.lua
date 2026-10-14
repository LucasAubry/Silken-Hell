local T={}
function T.run()
    io.stdout:setvbuf('no');love.focus=function() end
    Online.enabled=false;Replay.playing=false;Replay.input=nil
    local C=require('controller_setup');local Pad=require('pad_controls')
    local saved=love.filesystem.read(C.file)
    love.filesystem.remove(C.file);C.load();C.block=0
    Profile.padBindings=Pad.load();Profile.language='fr';Input.pad=nil;Input.device=nil
    print('PHYSICAL_CONTROLLERS='..#love.joystick.getJoysticks())
    local enumerate=love.joystick.getJoysticks
    local a={connected=true};local b={connected=true}
    for _,j in ipairs({a,b}) do
        function j:isConnected() return self.connected end
        function j:isGamepad() return true end
        function j:getName() return 'Test controller' end
        function j:getGamepadAxis() return 0 end
        function j:isGamepadDown() return false end
    end
    local devices={};love.joystick.getJoysticks=function() return devices end
    App.state='playing';Input.active=false;Input.scan();assert(not Input.pad)
    devices={a};Input.update(1.1);assert(Input.pad==a and not Input.active,'Missed add event recovered without stealing keyboard focus')
    devices={a,b};Input.scan();assert(Input.pad==a,'Background detection preserves active controller')
    Input.axisHeld={triggerleft=true};Input.use(b);assert(Input.pad==b and not next(Input.axisHeld),'Switch clears held axes')
    Input.beginBinding('dash','pad');b.connected=false;devices={a}
    Input.update(1.1);assert(Input.pad==a and App.state=='pause' and not UI.binding,'Missed removal pauses and selects backup')
    love.joystick.getJoysticks=enumerate;Input.pad=nil;Input.device=nil;Input.scan()

    -- Exercise actual SDL mappings and LÖVE callbacks with an unrecognized virtual HID.
    local ffi=require('ffi')
    ffi.cdef[[
        int SDL_SetHint(const char *name, const char *value);
        int SDL_JoystickAttachVirtual(int type, int naxes, int nbuttons, int nhats);
        int SDL_JoystickDetachVirtual(int device_index);
        void *SDL_JoystickOpen(int device_index);
        void SDL_JoystickClose(void *joystick);
        int SDL_JoystickSetVirtualAxis(void *joystick, int axis, short value);
        int SDL_JoystickSetVirtualButton(void *joystick, int button, unsigned char value);
        int SDL_JoystickSetVirtualHat(void *joystick, int hat, unsigned char value);
        void SDL_JoystickUpdate(void);
    ]]
    local framework=love.filesystem.getExecutablePath():match('^(.*)/MacOS/')..'/Frameworks/SDL2.framework/Versions/A/SDL2'
    local sdl=ffi.load(framework)
    sdl.SDL_SetHint('SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS','1')
    local function pump()
        love.event.pump()
        for name,a1,a2,a3 in love.event.poll() do
            if name=='joystickadded' or name=='joystickremoved' or name=='gamepadpressed' or name=='gamepadaxis' then
                if love[name] then love[name](a1,a2,a3) end
            end
        end
    end
    local id=sdl.SDL_JoystickAttachVirtual(0,3,10,1);assert(id>=0,'SDL virtual joystick available')
    local handle=sdl.SDL_JoystickOpen(id);pump()
    local j
    for _,candidate in ipairs(enumerate()) do if candidate:getName():find('Virtual') then j=candidate end end
    assert(j and not j:isGamepad(),'Virtual HID starts without a standard layout')
    Input.scan();Input.device=j
    App.state='settings';UI.settingsPage='shortcuts';UI.bindingTab='pad';UI.bindingPage=1
    C.begin(j)
    local function tick() sdl.SDL_JoystickUpdate();C.update(.016) end
    local function axis(n,value) assert(sdl.SDL_JoystickSetVirtualAxis(handle,n,value)==0);tick() end
    local function button(n,value) assert(sdl.SDL_JoystickSetVirtualButton(handle,n,value)==0);tick() end
    -- Noise does not bind, and a held direction cannot bind the following step.
    axis(1,-4000);assert(C.wizard.index==1)
    axis(1,-32767);assert(C.wizard.index==2,'Native axis capture: '..j:getAxis(2)..', step '..C.wizard.index);tick();assert(C.wizard.index==2)
    axis(1,0);axis(1,32767);assert(C.wizard.index==3);axis(1,0)
    -- A hat and buttons can be mixed with signed analog axes.
    sdl.SDL_JoystickSetVirtualHat(handle,0,8);tick();assert(C.wizard.index==4)
    sdl.SDL_JoystickSetVirtualHat(handle,0,0);tick()
    sdl.SDL_JoystickSetVirtualHat(handle,0,2);tick();assert(C.wizard.index==5)
    sdl.SDL_JoystickSetVirtualHat(handle,0,0);tick()
    for _,n in ipairs({0,1,7,2,3,6,4,5}) do button(n,1);button(n,0) end
    assert(not C.wizard and not C.error and j:isGamepad(),'Custom mapping activates a previously unknown physical layout')
    assert(Input.pad==j and love.filesystem.read(C.file),'Mapping is saved and selected')
    local line=C.custom[j:getGUID()];assert(line:find('dpup:-a1',1,true) and line:find('dpleft:h0.8',1,true))
    C.load();assert(C.custom[j:getGUID()]==line,'Mapping survives reload')
    C.block=.25;pump();C.block=0
    axis(1,-32767);local x,y=Input.move();assert(x==0 and y==-1,'Native signed axis moves up')
    axis(1,32767);x,y=Input.move();assert(x==0 and y==1,'Native signed axis moves down')
    axis(1,0);sdl.SDL_JoystickSetVirtualHat(handle,0,8);tick();x,y=Input.move();assert(x==-1 and y==0,'Native hat moves left')
    sdl.SDL_JoystickSetVirtualHat(handle,0,0);tick();button(0,1);assert(Input.speedHeld(),'Native captured button controls speed');button(0,0)
    C.block=.25;pump();C.block=0;App.state='playing'
    button(7,1);pump();assert(App.state=='pause','Native callback pauses');button(7,0);pump()
    button(7,1);pump();assert(App.state=='playing','Native callback resumes');button(7,0);pump()
    App.state='settings';C.begin(j);C.skip();assert(C.wizard.index==1,'Required directions cannot be skipped')
    local original=love.filesystem.read(C.file);love.keypressed('escape');assert(not C.wizard and love.filesystem.read(C.file)==original,'Cancel preserves saved mapping')
    -- Resting -1 triggers should be capturable even through gradual movement.
    axis(2,-32767);C.begin(j)
    for _,v in ipairs({-20000,-10000,0,10000,20000,30000}) do axis(2,v) end
    assert(C.wizard.index==2 and C.wizard.bindings.dpup=='+a2','Gradual trigger movement is detected')
    C.cancel();axis(2,-32767)
    App.state='playing';C.begin(j);sdl.SDL_JoystickClose(handle);sdl.SDL_JoystickDetachVirtual(id);pump()
    assert(not C.wizard and App.state=='pause' and Input.pad~=j,'Native disconnect cancels capture and pauses')
    C.block=0;C.error=nil
    if saved then love.filesystem.write(C.file,saved) else love.filesystem.remove(C.file) end
    print('PASS controller hot-plug recovery, focus, switching, disconnect; real SDL unknown HID calibration, axes, hats, buttons, persistence, cancellation, trigger noise and native pause callbacks')
    local frame=0
    love.update=function()
        frame=frame+1
        if frame==1 then
            App.state='settings';Input.device=nil;Input.pad=nil;App.capture='controller-detection-empty.png'
        elseif frame==3 then
            Input.device=a;Input.pad=a;App.capture='controller-detection-ready.png'
        elseif frame==5 then
            C.wizard={pad=a,index=5};App.capture='controller-detection-setup.png'
        elseif frame==7 then C.wizard=nil;print('PASS controller settings captures');love.event.quit() end
    end
end
return T
