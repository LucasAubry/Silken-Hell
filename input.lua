-- SDL gamepad mappings also accept the virtual gamepad exposed by Steam Input.
local I={active=false,index=1,repeatAt=0,deadzone=.2}
function I.add(j)
    if j:isGamepad() and not I.pad then I.pad=j end
end
function I.load() for _,j in ipairs(love.joystick.getJoysticks()) do I.add(j) end end
function I.remove(j)
    if j~=I.pad then return end
    I.pad=nil;I.active=false;I.load()
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
function I.bind(key)
    local old=Profile.keys[UI.binding]
    for action,value in pairs(Profile.keys) do if value==key then Profile.keys[action]=old end end
    Profile.keys[UI.binding]=key;UI.binding=nil;Profile.save()
end
function I.label(key)
    local b=key:match('^mouse:(%d+)$');return b and ('Souris '..b) or key:upper()
end
function I.move()
    if Replay and Replay.input then return Replay.input[1],Replay.input[2] end
    local k=Profile.keys
    local x=(I.down(k.right) and 1 or 0)-(I.down(k.left) and 1 or 0)
    local y=(I.down(k.down) and 1 or 0)-(I.down(k.up) and 1 or 0)
    if x==0 and y==0 then x,y=I.axes() end
    local d=math.sqrt(x*x+y*y);if d>1 then x,y=x/d,y/d end
    return x,y
end
function I.slow()
    if Replay and Replay.input then return Replay.input[3] end
    local j=I.pad
    return I.down(Profile.keys.dash) or j and j:isConnected() and (j:isGamepadDown('a','leftshoulder','rightshoulder') or j:getGamepadAxis('triggerleft')>.3 or j:getGamepadAxis('triggerright')>.3) or false
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
    local x,y=I.axes();if math.abs(x)+math.abs(y)>.3 then I.active=true end
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
    if Replay and Replay.playing then if b=='b' then Replay.stop() elseif b=='a' or b=='start' then Replay.paused=not Replay.paused end;return end
    if b=='start' or b=='b' then love.keypressed('escape');I.active=true;return end
    if App.state=='worlds' and b=='a' then App.openEntry(App.selectedWorld,WorldMap.hardcore);return end
    if App.state=='bossWorld' then
        if b=='y' then Secret.category=Secret.category=='mobs' and 'boss' or 'mobs';Secret.page=1;Secret.refresh()
        elseif b=='rightshoulder' then Secret.turnPage(1) elseif b=='leftshoulder' then Secret.turnPage(-1) end
        return
    end
    if App.state=='playing' then if b=='y' then Bestiary.openBoss() end;return end
    if UI.binding then UI.binding=nil;return end
    if b=='a' then local v=UI.buttons[I.index];if v and not v.disabled then Audio.play(v.sound or 'go');v.run() end
    elseif b=='leftshoulder' and App.state=='menu' then Characters.cycle(-1)
    elseif b=='rightshoulder' and App.state=='menu' then Characters.cycle(1)
    elseif b=='x' and App.state=='entry' then love.keypressed('backspace');I.active=true end
end
function I.draw()
    if not I.active then return end
    local b=UI.buttons[I.index]
    if b and not b.disabled and App.state~='playing' and App.state~='bossWorld' and App.state~='worlds' then
        local g=love.graphics;g.setColor(1,.85,.3);g.setLineWidth(3);g.rectangle('line',b.x-4,b.y-4,b.w+8,b.h+8,6);g.setLineWidth(1)
    end
    UI.text('Stick / croix : déplacement   ·   A : valider / ralentir   ·   B / Start : retour / pause',160,725,'small',{.8,.85,.9},880,'center')
end
return I
