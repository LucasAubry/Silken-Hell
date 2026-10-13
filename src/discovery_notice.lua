-- Non-blocking first-encounter notices; previews never change discoveries.
local N={queue={}}
function N.enqueue(entry)
 if not App or App.state~='playing' or Replay.playing or App.preview then return end
 N.queue[#N.queue+1]=entry
end
function N.test()
 local entries=Bestiary.list('creatures');N.previewIndex=(N.previewIndex or 0)%#entries+1
 N.active={entry=entries[N.previewIndex].entry,age=0,preview=true}
end
function N.visible()
 local n=N.active
 if not n or require('achievement_notice').active or Replay.playing or (App.state=='playing' and require('run_start').active) then return false end
 return n.preview and App.state=='menu' or not n.preview and App.state=='playing'
end
function N.update(dt)
 if require('run_start').active and App.state=='playing' then return end
 if N.visible() then N.active.age=N.active.age+dt;if N.active.age>=3.6 then N.active=nil end end
 if not N.active and #N.queue>0 and App.state=='playing' and not Replay.playing and not require('achievement_notice').active then
  N.active={entry=table.remove(N.queue,1),age=0}
 end
end
function N.draw()
 if not N.visible() then return end
 local notice=N.active
 if notice.age>0 and not notice.sounded then notice.sounded=true;Audio.play('notice') end
 local label=notice.preview and 'APERÇU · NOUVELLE DÉCOUVERTE' or 'NOUVELLE DÉCOUVERTE'
 require('notice_card').draw(notice.age,label,notice.entry.name,
  notice.preview and 'Aperçu sans déblocage' or 'Ajoutée au bestiaire',
  function(x,y) UI.bestiaryIcon(notice.entry,x,y,45) end)
end
return N
