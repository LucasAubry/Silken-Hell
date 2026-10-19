local A={}
local ambienceFiles={
    [2]='assets/audio/ambience/hell-fire.mp3',
    [3]='assets/audio/ambience/renaissance-birds.mp3',
}
local ambienceVolumes={}
local eventFiles={
    notice='assets/audio/effects/progression/notice.mp3',
    inkStep='assets/audio/effects/ocean/ink-step.mp3',
    inkSpit='assets/audio/effects/ocean/ink-spit.mp3',
    abyssSwallow='assets/audio/effects/abyss/swallow.mp3',
}
function A.load()
    love.audio.setVolume(1)
    local ok,source=pcall(love.audio.newSource,'assets/audio/music/menu paradi.mp3','stream')
    if ok then A.paradise=source;source:setLooping(true) end
    local files={selection='assets/audio/effects/menu/selection niveau.mp3',go='assets/audio/effects/menu/go.mp3',back='assets/audio/effects/menu/back.mp3',editor='assets/audio/effects/editeur start.mp3'}
    for name,path in pairs(eventFiles) do files[name]=path end
    for name,path in pairs(files) do
        local ok,source=pcall(love.audio.newSource,path,'static')
        A[name]=ok and source or nil
    end
    A.click=A.selection
    A.ambiences={}
    for biome,path in pairs(ambienceFiles) do
        local ok,source=pcall(love.audio.newSource,path,'stream')
        if ok then source:setLooping(true);A.ambiences[biome]=source end
    end
end
function A.focus(focused)
    A.focused=focused
    if not focused and A.paradise then A.paradise:pause() end
    if not focused then
        for _,source in pairs(A.ambiences or {}) do source:pause() end
        for name in pairs(eventFiles) do if A[name] then A[name]:stop() end end
    end
end
function A.update(p,hell)
    if A.focused==false then return end
    local pauseSettings=(App.state=='settings' or App.state=='graphics') and UI.returnTo=='pause'
    local victoryRanking=App.state=='rankings' and UI.boardReturn=='victory'
    local menu=not victoryRanking and App.state~='playing' and App.state~='prologue' and App.state~='pause' and App.state~='credits' and App.state~='victory' and App.state~='customVictory' and not pauseSettings
    if A.paradise then
        A.paradise:setVolume(p.music)
        if menu then
            if not A.paradise:isPlaying() then A.paradise:play() end
        else A.paradise:stop() end
    end
    for _,k in ipairs({'pick','death','click','selection','go','back','editor'}) do if A[k] then A[k]:setVolume(p.sound) end end
    for name in pairs(eventFiles) do if A[name] then A[name]:setVolume(p.sound) end end
    local biome=Campaign and Campaign.biome or nil
    -- Birds accompany the reunion after the Renaissance boss, only in level 2.
    if biome==3 and not (Campaign.world==3 and player and player.level==2) then biome=nil end
    for id,source in pairs(A.ambiences or {}) do
        local opening=App.state=='prologue' and id==3 and not require('prologue').paused
        source:setVolume(p.sound*(ambienceVolumes[id] or 1)*(opening and (1-require('prologue').darkness) or 1))
        if App.state=='playing' and id==biome or opening then
            if not source:isPlaying() then source:play() end
        elseif App.state=='pause' and biome==id then source:pause()
        else source:stop() end
    end
    if App.state~='playing' then
        for _,name in ipairs({'inkStep','inkSpit','abyssSwallow'}) do if A[name] then A[name]:stop() end end
    end
end
function A.inkContact(state,inside,x,y)
    if not inside then state.audioInInk=false;return end
    if not state.audioInInk or (x-(state.audioInkX or x))^2+(y-(state.audioInkY or y))^2>=22^2 then
        A.play('inkStep');state.audioInkX=x;state.audioInkY=y
    end
    state.audioInInk=true
end
function A.play(name)
    if A.focused==false then return end
    -- A crowd crossing ink should sound like footsteps, not a stack of clips.
    if name=='inkStep' then
        local now=love.timer.getTime()
        if now<(A.nextInkStep or 0) then return end
        A.nextInkStep=now+.16
    end
    local source=A[name];if source then source:setVolume(Profile and Profile.sound or .65);source:stop();source:play() end
end
return A
