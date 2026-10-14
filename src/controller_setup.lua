-- SDL_GameControllerDB, zlib license (assets/controllers/LICENSE.txt).
-- https://github.com/mdqinc/SDL_GameControllerDB/tree/c1d5289a1f713b30a2c121e9fe6529d39360be0f
local C={file='controller-mappings.json',custom={},steps={
    {'dpup','Haut'},{'dpdown','Bas'},{'dpleft','Gauche'},{'dpright','Droite'},
    {'a','Valider / touche vitesse'},{'b','Retour'},{'start','Pause'},
    {'x','Rejouer le niveau',true},{'y','Bestiaire',true},{'back','Recommencer le monde',true},
    {'leftshoulder','Bouton supérieur gauche',true},{'rightshoulder','Bouton supérieur droit',true},
}}
local json=require('json')
local hats={u=1,r=2,d=4,l=8}
local function platform() local os=love.system.getOS();return os=='OS X' and 'Mac OS X' or os end
local function validGuid(guid) return type(guid)=='string' and #guid==32 and guid:match('^%x+$') end
function C.load()
    C.custom={};C.wizard=nil;C.error=nil
    local ok,saved=pcall(json.decode,love.filesystem.read(C.file) or '{}')
    if ok and type(saved)=='table' then
        for guid,line in pairs(saved) do
            if validGuid(guid) and type(line)=='string' and line:sub(1,33)==guid..',' and not line:find('[\r\n]') then
                if pcall(love.joystick.loadGamepadMappings,line) then C.custom[guid]=line end
            end
        end
    end
end
function C.recognize(j)
    if j:isGamepad() then return true end -- Preserve SDL / Steam Input's working mappings.
    local guid=j:getGUID()
    if not C.database then
        C.database={}
        for line in (love.filesystem.read('assets/controllers/gamecontrollerdb.txt') or ''):gmatch('[^\r\n]+') do
            local key=line:match('^(%x+),')
            if key and line:find('platform:'..platform()..',',1,true) then C.database[key]=line end
        end
    end
    local line=C.custom[guid] or C.database[guid]
    if line then pcall(love.joystick.loadGamepadMappings,line) end
    return j:isGamepad()
end
local function snapshot(j)
    local values={}
    for n=1,j:getButtonCount() do values['b'..(n-1)]=j:isDown(n) and 1 or 0 end
    for n=1,j:getHatCount() do
        local dir=j:getHat(n)
        for name,mask in pairs(hats) do values['h'..(n-1)..'.'..mask]=dir:find(name,1,true) and 1 or 0 end
    end
    for n=1,j:getAxisCount() do values['a'..(n-1)]=j:getAxis(n) end
    return values
end
function C.begin(j)
    if not j or not j:isConnected() then return end
    Input.cancelBinding();C.error=nil;Input.active=false
    C.wizard={pad=j,index=1,bindings={},rest=snapshot(j),previous=snapshot(j),used={}}
end
function C.cancel() C.wizard=nil;C.block=.25 end
function C.finish()
    local w=C.wizard;local guid=w.pad:getGUID()
    if not validGuid(guid) then C.error='Manette non identifiable';return end
    local parts={guid,w.pad:getName():gsub('[,\r\n]',' ')}
    for _,step in ipairs(C.steps) do if w.bindings[step[1]] then parts[#parts+1]=step[1]..':'..w.bindings[step[1]] end end
    parts[#parts+1]='platform:'..platform()
    local line=table.concat(parts,',')..','
    local old=C.custom[guid];C.custom[guid]=line
    local ok=love.filesystem.write(C.file,json.encode(C.custom))
    if not ok then C.custom[guid]=old;C.error='Impossible de sauvegarder la manette';return end
    local loaded=pcall(love.joystick.loadGamepadMappings,line)
    if not loaded or not w.pad:isGamepad() then
        C.custom[guid]=old;love.filesystem.write(C.file,json.encode(C.custom))
        C.error='Configuration non reconnue';return
    end
    local j=w.pad;C.cancel();Input.pad=j;Input.axisHeld={};Input.scan()
end
function C.advance(token)
    local w=C.wizard;if not w then return end
    if token and w.used[token] then return end
    if token then w.bindings[C.steps[w.index][1]]=token;w.used[token]=true;w.release=token end
    if w.index==#C.steps then C.finish() else w.index=w.index+1 end
end
function C.skip()
    local w=C.wizard
    if w and C.steps[w.index][3] then C.advance() end
end
function C.update(dt)
    C.block=math.max(0,(C.block or 0)-dt)
    local w=C.wizard;if not w then return end
    if App.state~='settings' or UI.settingsPage~='shortcuts' or UI.bindingTab~='pad' then C.cancel();return end
    if not w.pad:isConnected() then C.cancel();C.error='Manette déconnectée';return end
    if C.error then return end
    local now=snapshot(w.pad)
    if w.release then
        local axis=w.release:match('^[+-](a%d+)$')
        local released=axis and math.abs(now[axis]-w.rest[axis])<.25 or not axis and now[w.release]==0
        w.previous=now
        if released then w.release=nil end
        return
    end
    -- Only fresh presses count; held buttons, stick noise and resting triggers do not.
    local tokens={};for token in pairs(now) do tokens[#tokens+1]=token end;table.sort(tokens)
    for _,token in ipairs(tokens) do
        local value=now[token];local previous=w.previous[token] or 0
        local captured
        if token:sub(1,1)=='a' then
            if math.abs(value)>.65 and math.abs(value-w.rest[token])>.65 and (math.abs(previous)<=.65 or previous*value<=0) then captured=(value>0 and '+' or '-')..token end
        elseif value==1 and previous==0 then captured=token end
        if captured and not w.used[captured] then w.previous=now;C.advance(captured);return end
    end
    w.previous=now
end
function C.busy() return C.wizard~=nil or (C.block or 0)>0 end
return C
