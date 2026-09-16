local A={}
local function tone(seconds, frequencies, volume)
    local rate=22050
    local data=love.sound.newSoundData(math.floor(seconds*rate),rate,16,1)
    for i=0,data:getSampleCount()-1 do
        local t=i/rate
        local envelope=math.min(1,t*4)*math.min(1,(seconds-t)*4)
        local v=0
        for _,f in ipairs(frequencies) do v=v+math.sin(t*f*math.pi*2)+0.2*math.sin(t*f*math.pi*4) end
        data:setSample(i,v/#frequencies*volume*envelope)
    end
    return love.audio.newSource(data,'static')
end
function A.load()
    A.music=tone(8,{130.81,196,261.63,329.63},0.12); A.music:setLooping(true)
    A.hell=tone(8,{65.41,98,155.56},0.16); A.hell:setLooping(true)
    A.pick=tone(0.35,{659.25,987.77},0.3)
    A.death=tone(0.18,{82.41,87.31},0.35)
    A.click=tone(0.09,{440,660},0.18)
end
function A.update(p,hell)
    A.music:setVolume(p.music); A.hell:setVolume(p.music)
    local active=hell and A.hell or A.music
    local other=hell and A.music or A.hell
    other:stop(); if not active:isPlaying() then active:play() end
    for _,k in ipairs({'pick','death','click'}) do A[k]:setVolume(p.sound) end
end
function A.play(name) if A[name] then A[name]:stop(); A[name]:play() end end
return A
