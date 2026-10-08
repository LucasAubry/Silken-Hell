-- Observe newly earned achievements without changing progress or replay state.
local N={queue={}}
function N.init()
 N.seen={};N.queue={};N.active=nil
 for _,entry in ipairs(Achievements.list) do N.seen[entry.id]=Achievements.unlocked(entry)==true end
end
function N.test()
 N.active={entry=Achievements.list[#Achievements.list],age=0,preview=true}
 Audio.play('pick')
end
function N.visible()
 if not N.active or Replay.playing then return false end
 if App.state=='playing' and require('run_start').active then return false end
 return App.state=='playing' or App.state=='menu' or App.state=='victory' or App.state=='customVictory' or App.state=='skinUnlock'
end
function N.update(dt)
 if not N.seen then N.init() end
 if not Replay.playing and not App.preview and not App.sessionLayout then
  for _,entry in ipairs(Achievements.list) do
   local done=Achievements.unlocked(entry)==true
   if done and not N.seen[entry.id] then N.queue[#N.queue+1]=entry end
   N.seen[entry.id]=done
  end
 end
 if N.visible() then
  N.active.age=N.active.age+dt
  if N.active.age>=3.6 then N.active=nil end
 end
 if not N.active and #N.queue>0 and not Replay.playing then
  N.active={entry=table.remove(N.queue,1),age=0};Audio.play('pick')
 end
end
function N.draw()
 if not N.visible() then return end
 local n=N.active;local entry=n.entry
 require('notice_card').draw(n.age,n.preview and 'APERÇU · SUCCÈS DÉBLOQUÉ' or 'SUCCÈS DÉBLOQUÉ',
  entry.localizedName and entry.localizedName() or entry.name,
  n.preview and 'Aperçu sans déblocage' or 'Ajouté à vos succès',function(x,y,a)
   local g=love.graphics;g.setColor(1,.8,.42,a);g.setLineWidth(2);g.setLineStyle('smooth')
   g.polygon('line',x-11,y-15,x+11,y-15,x+9,y+1,x+4,y+7,x-4,y+7,x-9,y+1)
   g.line(x-11,y-11,x-18,y-11,x-17,y-2,x-9,y+2)
   g.line(x+11,y-11,x+18,y-11,x+17,y-2,x+9,y+2)
   g.line(x,y+7,x,y+16);g.line(x-9,y+17,x+9,y+17)
  end)
end
return N
