-- SDL gamepad mappings also accept the virtual gamepad exposed by Steam Input.
local PadControls=require('pad_controls')
local I={active=false,index=1,repeatAt=0,deadzone=.2}
function I.add(j)
    if j:isGamepad() and not I.pad then I.pad=j end
end
function I.load() for _,j in ipairs(love.joystick.getJoysticks()) do I.add(j) end end
function I.remove(j)
    if j~=I.pad then return end
    I.pad=nil;I.active=false;I.cancelBinding();I.load()
    if App.state=='playing' then App.state='pause' end
end
function I.use(j) if j:isGamepad() then I.pad=j;I.active=true end end
function I.axes()
    local j=I.pad;if not j or not j:isConnected() then return 0,0 end
    local x,y=j:getGamepadAxis('leftx'),j:getGamepadAxis('lefty')
    local d=math.sqrt(x*x+y*y)
    if d<I.deadzone then x,y=0,0 else local n=math.min(1,(d-I.deadzone)/(1-I.deadzone));x,y=x/d*n,y/d*n end
    if j:isGamepadDown('dpleft') then x=-1 elseif j:isGamepadDown('dpright') then x=1 end
    if j:isGamepadDown('dpup') then y=-1 elseif j:isGamepadDown('dpdown') then y=1 end
    return x,y
end
function I.down(binding)
    local button=type(binding)=='string' and binding:match('^mouse:(%d+)$')
    if button then return love.mouse.isDown(tonumber(button)) end
    return love.keyboard.isDown(binding)
end
function I.cancelBinding() UI.binding=nil;UI.bindingDevice=nil;I.captureNeutral=nil end
function I.beginBinding(action,device)
    UI.binding=action;UI.bindingDevice=device;I.captureNeutral={}
    if device=='pad' and I.pad and I.pad:isConnected() then
        for _,axis in ipairs({'leftx','lefty','rightx','righty','triggerleft','triggerright'}) do I.captureNeutral[axis]=math.abs(I.pad:getGamepadAxis(axis))<.3 end
    end
end
function I.bind(key)
    if not UI.binding then return end
    local bindings=UI.bindingDevice=='pad' and Profile.padBindings or Profile.keys
    if UI.bindingDevice=='pad' and not PadControls.valid(key) then return end
    local old=bindings[UI.binding]
    for action,value in pairs(bindings) do if key~='none' and value==key then bindings[action]=old end end
    bindings[UI.binding]=key;I.cancelBinding();Profile.save()
end
function I.padAction(binding)
    if App.state=='playing' and not Replay.playing and PadControls.speedBinding(binding,Profile.padBindings) then require('run_start').press(Profile.keys.dash);return true end
    if binding=='b' and App.state=='playing' and not Replay.playing and Profile.padBindings.pause=='start' then
        local used=false;for _,value in pairs(Profile.padBindings) do if value=='b' then used=true end end
        if not used then I.action(Profile.keys.pause);return true end
    end
    for action,value in pairs(Profile.padBindings) do if value==binding then
        if Replay and Replay.playing then
            if action=='pause' or action=='dash' then if not Replay.job then Replay.paused=not Replay.paused end
            elseif action=='replaySlower' or action=='replayFaster' or action=='restartLevel' or action=='restartWorld' then Replay.key(Profile.keys[action]) end
        elseif App.state=='playing' or App.state=='pause' then
            if action=='dash' then require('run_start').press(Profile.keys.dash)
            elseif action=='bestiary' and App.state=='playing' then Bestiary.openLevel()
            elseif Profile.keys[action] then I.action(Profile.keys[action]) end
        end
        return true
    end end
    return false
end
function I.axis(j,axis,value)
    if math.abs(value)>.3 then I.use(j) end
    if I.pad~=j then return end
    if UI.binding then
        if UI.bindingDevice=='pad' then
            I.captureNeutral=I.captureNeutral or {}
            if math.abs(value)<.3 then I.captureNeutral[axis]=true end
            if math.abs(value)>.65 and I.captureNeutral[axis]~=false then I.bind('axis:'..axis..':'..(value>0 and '+' or '-')) end
        end
        return
    end
    I.axisHeld=I.axisHeld or {}
    local binding='axis:'..axis..':'..(value>0 and '+' or '-')
    if math.abs(value)<.3 then I.axisHeld[axis]=nil
    elseif math.abs(value)>.65 and I.axisHeld[axis]~=binding then I.axisHeld[axis]=binding;I.padAction(binding) end
end
function I.label(key)
    local b=key:match('^mouse:(%d+)$');return b and ('Souris '..b) or key:upper()
end
function I.action(key)
    if App.state~='playing' and App.state~='pause' and App.state~='customVictory' then return false end
    local k=Profile.keys
    if key==k.restartLevel then App.restartLevel()
    elseif key==k.restartWorld then App.restartWorld()
    elseif key==k.nextWorld then App.practiceWorld(1)
    elseif key==k.previousWorld then App.practiceWorld(-1)
    elseif key==k.pause then if App.state=='playing' then App.state='pause' elseif App.state=='pause' then App.state='playing' end
    else return false end
    return true
end
function I.move()
    if Replay and Replay.input then return Replay.input[1],Replay.input[2] end
    local k=Profile.keys
    local x=(I.down(k.right) and 1 or 0)-(I.down(k.left) and 1 or 0)
    local y=(I.down(k.down) and 1 or 0)-(I.down(k.up) and 1 or 0)
    if x==0 and y==0 then x,y=PadControls.move(I.pad,Profile.padBindings) end
    local d=math.sqrt(x*x+y*y);if d>1 then x,y=x/d,y/d end
    return x,y
end
function I.speedHeld()
    return I.down(Profile.keys.dash) or PadControls.speedHeld(I.pad,Profile.padBindings)
end
function I.slow()
    if Replay and Replay.input then return Replay.input[3] end
    local held=I.speedHeld()
    if Profile.speedMode=='slow' then return held end
    return not held
end
function I.navigate(dx,dy)
    local buttons=UI.buttons;local b=buttons[I.index]
    if not b or b.disabled then for n,v in ipairs(buttons) do if not v.disabled then I.index=n;return end end;return end
    local best,score
    for n,v in ipairs(buttons) do if n~=I.index and not v.disabled then
        local x,y=v.x+v.w/2-b.x-b.w/2,v.y+v.h/2-b.y-b.h/2
        local along=x*dx+y*dy;local across=math.abs(x*dy-y*dx)
        if along>1 then local cost=along+across*3;if not score or cost<score then best,score=n,cost end end
    end end
    if best then I.index=best end
end
function I.update(dt)
    if I.state~=App.state then I.state=App.state;I.index=1;I.repeatAt=0 end
    if UI.binding then return end
    local x,y=I.axes();if math.abs(x)+math.abs(y)>.3 then I.active=true end
    if App.state=='achievements' and I.pad and I.pad:isConnected() then
        local scroll=I.pad:getGamepadAxis('righty');if math.abs(scroll)>.2 then require('achievements_screen').move(scroll*280*dt);I.active=true end
    end
    if App.state=='bestiary' and I.pad and I.pad:isConnected() then
        local scroll=I.pad:getGamepadAxis('righty');if math.abs(scroll)>.2 then UI.scrollBestiary(scroll*240*dt);I.active=true end
    end
    if App.state=='playing' or App.state=='bossWorld' then return end
    I.repeatAt=math.max(0,I.repeatAt-dt)
    if math.max(math.abs(x),math.abs(y))>.5 then
        if App.state=='worlds' then
            if I.repeatAt==0 then if math.abs(y)>math.abs(x) then WorldMap.step(y>0 and 1 or -1) else WorldMap.branch(x>0) end;I.repeatAt=.28 end
            return
        end
        if I.repeatAt==0 then I.navigate(math.abs(x)>math.abs(y) and (x>0 and 1 or -1) or 0,math.abs(y)>=math.abs(x) and (y>0 and 1 or -1) or 0);I.repeatAt=.18 end
    else I.repeatAt=0 end
end
function I.press(j,b)
    I.use(j);if I.pad~=j then return end
    if UI.binding then
        if UI.bindingDevice=='pad' then I.bind(b) elseif b=='b' then I.cancelBinding() end
        return
    end
    if Replay and Replay.playing then if not I.padAction(b) and b=='b' then Replay.stop() end;return end
    if App.state=='playing' then I.padAction(b);return end
    if App.state=='pause' and b==Profile.padBindings.pause then I.padAction(b);return end
    if b=='start' or b=='b' then love.keypressed('escape');I.active=true;return end
    if App.state=='worlds' and b=='a' then Audio.play('selection');App.openEntry(App.selectedWorld,WorldMap.hardcore);return end
    if App.state=='bossWorld' then
        if Secret.pending then if b=='a' then Secret.confirm() end;return end
        if b=='y' then Secret.switchCategory()
        elseif b=='rightshoulder' then Secret.turnPage(1) elseif b=='leftshoulder' then Secret.turnPage(-1) end
        return
    end
    if b=='a' and App.state=='pause' then require('run_start').armed=false end
    if b=='a' then local v=UI.buttons[I.index];if v and not v.disabled then UI.click(v.x+v.w/2,v.y+v.h/2) end
    elseif b=='leftshoulder' and App.state=='menu' then Characters.cycle(-1)
    elseif b=='rightshoulder' and App.state=='menu' then Characters.cycle(1)
    elseif b=='x' and App.state=='entry' then love.keypressed('backspace');I.active=true end
end
function I.draw()
    if not I.active then return end
    local b=UI.buttons[I.index]
    if b and not b.disabled and App.state~='playing' and App.state~='bossWorld' and App.state~='worlds' then
        local g=love.graphics;g.setColor(1,.85,.3);g.setLineWidth(3)
        if b.radius then g.circle('line',b.x+b.w/2,b.y+b.h/2,b.radius+4)
        else g.rectangle('line',b.x-4,b.y-4,b.w+8,b.h+8,6) end
        g.setLineWidth(1)
    end
end
return I
