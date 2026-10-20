local A={}
function A.load()
 if A.river then return end
 local function sound(seconds,crack)
  local rate=22050;local data=love.sound.newSoundData(math.floor(seconds*rate),rate,16,1)
  local seed,low=731,0
  for i=0,data:getSampleCount()-1 do
   seed=seed*48271%2147483647;local noise=seed/1073741823.5-1
   low=low*.92+noise*.08;local t=i/rate
   local envelope=crack and math.exp(-t*6)*math.min(1,t*90) or .3+.04*math.sin(t*math.pi*2/seconds)
   data:setSample(i,math.max(-1,math.min(1,(crack and (noise*.22+low*.7+math.sin(t*110)*.25) or low)*envelope)))
  end
  local source=love.audio.newSource(data,'static');data:release();return source
 end
 A.river=sound(3,false);A.river:setLooping(true);A.crack=sound(1.1,true)
end
function A.update(paused,darkness)
 if not A.river then return end
 local audible=not paused and Audio.focused~=false
 A.river:setVolume(Profile.sound*(1-darkness*.7)*.7)
 if audible then if not A.river:isPlaying() then A.river:play() end else A.river:pause() end
end
function A.impact()
 if A.crack and Audio.focused~=false then A.crack:setVolume(Profile.sound*.65);A.crack:stop();A.crack:play() end
end
function A.stop() if A.river then A.river:stop();A.crack:stop() end end
return A
