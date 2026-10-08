-- Non-blocking first-encounter notices; previews never change discoveries.
local N={queue={}}
function N.enqueue(entry)
 if not App or App.state~='playing' or Replay.playing or App.preview then return end
 N.queue[#N.queue+1]=entry
end
function N.test()
 local entries=Bestiary.list('creatures');N.previewIndex=(N.previewIndex or 0)%#entries+1
 N.active={entry=entries[N.previewIndex].entry,age=0,preview=true};Audio.play('pick')
end
function N.update(dt)
 if require('run_start').active and App.state=='playing' then return end
 if N.active then N.active.age=N.active.age+dt;if N.active.age>=3.6 then N.active=nil end end
 if not N.active and #N.queue>0 and App.state=='playing' and not Replay.playing then
  N.active={entry=table.remove(N.queue,1),age=0};Audio.play('pick')
 end
end
function N.draw()
 if require('run_start').active and App.state=='playing' then return end
 local notice=N.active;if not notice then return end
 if notice.preview and App.state~='menu' or not notice.preview and App.state~='playing' then return end
 local label=notice.preview and 'APERÇU · NOUVELLE DÉCOUVERTE' or 'NOUVELLE DÉCOUVERTE'
 require('notice_card').draw(notice.age,label,notice.entry.name,
  notice.preview and 'Aperçu sans déblocage' or 'Ajoutée au bestiaire',
  function(x,y) UI.bestiaryIcon(notice.entry,x,y,45) end,
  require('achievement_notice').visible() and 1 or 0)
end
return N
