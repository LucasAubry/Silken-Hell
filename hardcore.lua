-- Separate progress: hardcore runs never submit checkpoints to normal rankings.
local H={completed={}}
function H.unlocked() return Profile.hasCompleted(Worlds.order[3]) end
function H.available(world)
 return Worlds.rank(world)<=#Worlds.order and H.unlocked() and Profile.hasCompleted(world)
end
function H.load()
 local ok,data=pcall(require('json').decode,love.filesystem.read('hardcore.json') or '')
 H.completed=ok and type(data)=='table' and data or {}
end
function H.complete(world)
 if Replay.playing then return end
 H.completed[tostring(world)]=true
 love.filesystem.write('hardcore.json',require('json').encode(H.completed))
 Replay.finish()
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
 H.notify(old>1 and ('Niveau '..old..' : retour au niveau '..player.level) or 'Niveau 1 · Nouvelle tentative',true)
end
function H.draw()
 if App.hardcore then UI.text('HARDCORE · mort = niveau précédent',635,22,'small',{.96,.72,.44}) end
end
return H
