-- Hardcore progression and scores are separate from normal runs.
local H={completed={}}
function H.unlocked() return Profile.hasCompleted(Worlds.order[3]) end
function H.available(world)
 if world==8 then return Worlds.sanctuaryUnlocked() end
 return Worlds.rank(world)<=#Worlds.order and H.unlocked() and Profile.hasCompleted(world)
end
function H.load()
 local ok,data=pcall(require('json').decode,love.filesystem.read('hardcore.json') or '')
 H.completed=ok and type(data)=='table' and data or {}
end
function H.complete(world)
 if Replay.playing then return end
 require('app_icon').complete(world)
 H.completed[tostring(world)]=true
 love.filesystem.write('hardcore.json',require('json').encode(H.completed))
 Profile.complete(world,timer,player.death,true)
end
function H.notify(text,down)
 H.notice={text=text,down=down,untilTime=UI.clock+2.4}
 Audio.play(down and 'levelDown' or 'levelUp')
 local pad=Input and Input.pad
 if pad and pad:isConnected() and pad:isVibrationSupported() then
  pad:setVibration(down and .45 or .12,down and .15 or .3,.16)
 end
end
function H.death()
 if not App.hardcore then return end
 local old=player.level;player.level=math.max(1,old-1)
 local unit=Campaign.world==8 and 'Boss' or 'Niveau'
 H.notify(old>1 and (unit..' '..old..' : retour au précédent ('..player.level..')') or (unit..' 1 · Nouvelle tentative'),true)
end
function H.draw()
 if not App.hardcore then return end
 if not Art.images.hardcore_skull then Art.add('hardcore_skull','assets/sprites/hardcore_skull.png') end
 local g=love.graphics;local icon=Art.images.hardcore_skull
 g.push('all');g.setColor(1,1,1)
 Art.draw('hardcore_skull',646,28,28*icon.w/math.max(icon.w,icon.h))
 g.pop()
end
function H.visible()
 local state=App.state
 if state=='rankings' or state=='boards' then return UI.boardHardcore==true end
 if state=='menu' or state=='worlds' or state=='quitConfirm' then return WorldMap.hardcore==true end
 if state=='bossWorld' or state=='skinUnlock' or state=='credits' then return false end
 return App.hardcore==true
end
function H.borderAmount(now)
 local target=H.visible() and 1 or 0
 local s=H.borderState or {value=0,at=now,target=target}
 -- Finish the elapsed portion in the previous direction before reversing.
 local dt=math.max(0,now-s.at)
 s.value=math.max(0,math.min(1,s.value+(s.target==1 and 1 or -1)*dt/.65))
 s.at=now;s.target=target;H.borderState=s
 return s.value
end
function H.drawBorder(w,h)
 local amount=H.borderAmount(UI.clock)
 if amount<=0 then return end
 local g=love.graphics
 H.border=H.border or g.newShader('assets/shaders/hardcore_border.glsl')
 g.push('all');g.origin();g.setScissor();g.setBlendMode('alpha');g.setShader(H.border)
 H.border:send('viewport',{w,h});H.border:send('clock',UI.clock)
 H.border:send('ignition',amount)
 g.setColor(1,1,1);g.draw(UI.pixel,0,0,0,w,h);g.pop()
end
return H
