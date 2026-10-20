local H={}
H.scenes={
 {id='intro',label='Le début'},
 {id='paradise_sky',label='Paradis → Ciel'},
 {id='sky_earth',label='Ciel → Terre'},
 {id='earth_ocean',label='Terre → Océan'},
}
local fields={'selectedWorld','hardcore','preview','practice','singleLevel','sessionLayout','workshopMap','entryFromWorld','custom','runSkin','runEffects'}
function H.open()
 App.state='history';UI.buttons={};UI.pressed=nil;Input.index=1;love.keyboard.setTextInput(false)
end
function H.close()
 if H.saved then
  require('prologue_audio').stop()
  for _,key in ipairs(fields) do App[key]=H.saved[key] end
  love.math.setRandomState(H.saved.rng)
  H.saved=nil
 end
 App.historyPreview=nil
 local C=require('run_start');C.active=false;C.arrival=nil;C.arrivalKind=nil;C.goAge=nil
 require('prologue').paused=false
 Replay.recording=false;Replay.input=nil
 H.open()
end
function H.startWorld(world)
 App.preview=true;App.hardcore=false;App.practice=nil;App.singleLevel=true;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
 App.start(world)
end
function H.play(id)
 if H.saved then H.close() end
 H.saved={rng=love.math.getRandomState()};for _,key in ipairs(fields) do H.saved[key]=App[key] end
 App.historyPreview=true;App.preview=true;Replay.recording=false;Replay.input=nil;UI.buttons={};UI.pressed=nil
 if id=='story' then require('prologue').open(true)
 elseif id=='intro' then require('prologue_mystery').open()
 elseif id=='earth_ocean' then H.startWorld(4);require('run_start').beginOceanArrival()
 elseif id=='sky_earth' then H.startWorld(5);require('run_start').beginEarthArrival()
 elseif id=='paradise' then H.startWorld(1);require('run_start').beginArrival(true,true)
 else H.startWorld(6);require('run_start').beginSkyArrival(id=='paradise_sky') end
end
function H.draw()
 UI.text('Histoire',340,90,'heading',{.96,.94,.86},520,'center')
 for i,scene in ipairs(H.scenes) do
  UI.button(scene.label,340,220+(i-1)*90,520,60,function()H.play(scene.id)end)
 end
 UI.button('Retour',450,620,300,48,function()App.state='menu';Input.index=1 end)
end
function H.drawBack()
 UI.button('Retour',28,24,180,48,H.close)
end
function H.key(key)
 if key=='up' or key=='down' then Input.active=true;Input.navigate(0,key=='up' and -1 or 1);return true end
 if key=='tab' then Input.active=true;Input.index=Input.index%math.max(1,#UI.buttons)+1;return true end
 if key=='return' or key=='kpenter' or key=='space' then
  local b=UI.buttons[Input.index];if b then UI.click(b.x+b.w/2,b.y+b.h/2) end;return true
 end
 return false
end
return H
