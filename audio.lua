local A={}
local function tone(seconds, frequencies, volume)
    local rate=22050
    local data=love.sound.newSoundData(math.floor(seconds*rate),rate,16,1)
    for i=0,data:getSampleCount()-1 do
        local t=i/rate
        local envelope=math.min(1,t/.008)*math.min(1,(seconds-t)/.045)
        local v=0
        for _,f in ipairs(frequencies) do v=v+math.sin(t*f*math.pi*2)+0.2*math.sin(t*f*math.pi*4) end
        data:setSample(i,v/#frequencies*volume*envelope)
    end
    return love.audio.newSource(data,'static')
end
function A.load()
    love.audio.setVolume(1)
    A.music=tone(8,{130.81,196,261.63,329.63},0.12); A.music:setLooping(true)
    A.hell=tone(8,{65.41,98,155.56},0.16); A.hell:setLooping(true)
    A.pick=tone(0.35,{659.25,987.77},0.3)
    A.death=tone(0.18,{82.41,87.31},0.35)
    A.click=tone(0.09,{440,660},0.45)
    local files={selection='music et song/song/menu/selection niveau.mp3',go='music et song/song/menu/go.mp3',back='music et song/song/menu/back.mp3',editor='music et song/song/editeur start.mp3'}
    for name,path in pairs(files) do
        local ok,source=pcall(love.audio.newSource,path,'static')
        A[name]=ok and source or A.click:clone()
    end
end
function A.update(p,hell)
    A.music:setVolume(p.music); A.hell:setVolume(p.music)
    local active=hell and A.hell or A.music
    local other=hell and A.music or A.hell
    other:stop(); if not active:isPlaying() then active:play() end
    for _,k in ipairs({'pick','death','click','selection','go','back','editor'}) do A[k]:setVolume(p.sound) end
end
function A.play(name) local source=A[name] or A.click;if source then source:setVolume(Profile and Profile.sound or .65);source:stop();source:play() end end
return A
