local A={}
function A.load()
    love.audio.setVolume(1)
    local ok,source=pcall(love.audio.newSource,'assets/audio/music/menu paradi.mp3','stream')
    if ok then A.paradise=source;source:setLooping(true) end
    local files={selection='assets/audio/effects/menu/selection niveau.mp3',go='assets/audio/effects/menu/go.mp3',back='assets/audio/effects/menu/back.mp3',editor='assets/audio/effects/editeur start.mp3'}
    for name,path in pairs(files) do
        local ok,source=pcall(love.audio.newSource,path,'static')
        A[name]=ok and source or nil
    end
    A.click=A.selection
end
function A.focus(focused)
    A.focused=focused
    if not focused and A.paradise then A.paradise:pause() end
end
function A.update(p,hell)
    if A.focused==false then return end
    local pauseSettings=(App.state=='settings' or App.state=='graphics') and UI.returnTo=='pause'
    local victoryRanking=App.state=='rankings' and UI.boardReturn=='victory'
    local menu=not victoryRanking and App.state~='playing' and App.state~='pause' and App.state~='credits' and App.state~='victory' and App.state~='customVictory' and not pauseSettings
    if A.paradise then
        A.paradise:setVolume(p.music)
        if menu then
            if not A.paradise:isPlaying() then A.paradise:play() end
        else A.paradise:stop() end
    end
    for _,k in ipairs({'pick','death','click','selection','go','back','editor'}) do if A[k] then A[k]:setVolume(p.sound) end end
end
function A.play(name) local source=A[name];if source then source:setVolume(Profile and Profile.sound or .65);source:stop();source:play() end end
return A
