-- Observe newly earned achievements without changing progress or replay state.
local N={queue={}}
local empty={}
local tracked={'achievements','completed','storyTexts','skinGrants'}
local function mapChanged(snapshot,current)
 current=current or empty
 if not snapshot or snapshot.source~=current then return true end
 for key,value in pairs(current) do if snapshot.values[key]~=value then return true end end
 for key in pairs(snapshot.values) do if current[key]==nil then return true end end
 return false
end
local function rememberMap(snapshot,current)
 current=current or empty;snapshot=snapshot or {values={}}
 snapshot.source=current
 for key in pairs(snapshot.values) do if current[key]==nil then snapshot.values[key]=nil end end
 for key,value in pairs(current) do snapshot.values[key]=value end
 return snapshot
end
local function dependenciesChanged()
 local d=N.dependencies
 if not d or d.profile~=Profile or d.list~=Achievements.list or d.listCount~=#Achievements.list
  or d.scores~=Profile.scores or d.scoreCount~=#(Profile.scores or empty)
  or d.records~=Profile.topRecords or d.recordCount~=#(Profile.topRecords or empty) then return true end
 for _,key in ipairs(tracked) do if mapChanged(d[key],Profile[key]) then return true end end
 return mapChanged(d.hardcore,Hardcore and Hardcore.completed)
end
local function rememberDependencies()
 local d=N.dependencies or {};N.dependencies=d
 d.profile=Profile;d.list=Achievements.list;d.listCount=#Achievements.list
 d.scores=Profile.scores;d.scoreCount=#(Profile.scores or empty)
 d.records=Profile.topRecords;d.recordCount=#(Profile.topRecords or empty)
 for _,key in ipairs(tracked) do d[key]=rememberMap(d[key],Profile[key]) end
 d.hardcore=rememberMap(d.hardcore,Hardcore and Hardcore.completed)
 N.scanTime=.2
end
function N.invalidate() N.scanTime=0 end
function N.init()
 N.seen={};N.queue={};N.active=nil;N.dependencies=nil
 for _,entry in ipairs(Achievements.list) do N.seen[entry.id]=Achievements.unlocked(entry)==true end
 rememberDependencies()
end
function N.test()
 N.active={entry=Achievements.list[#Achievements.list],age=0,preview=true}
end
function N.storyProgress(found,total)
 -- Only a newly read inscription emits progress; loading a save stays silent.
 if found>=total then N.invalidate();return end
 for _,entry in ipairs(Achievements.list) do
  if entry.id=='story_all' then
   N.queue[#N.queue+1]={id=entry.id,name=entry.name,progress=found,total=total}
   return
  end
 end
end
function N.visible()
 if not N.active or Replay.playing then return false end
 if App.state=='playing' and require('run_start').active then return false end
 return App.state=='playing' or App.state=='menu' or App.state=='victory' or App.state=='customVictory' or App.state=='skinUnlock' or App.state=='credits'
end
function N.update(dt)
 if not N.seen then N.init() end
 N.scanTime=math.max(0,(N.scanTime or 0)-dt)
 -- Small progress tables are checked immediately. The bounded fallback also
 -- observes edits inside existing score rows without rescanning history at FPS.
 if not Replay.playing and not App.preview and not App.sessionLayout
  and (N.scanTime<=0 or dependenciesChanged()) then
  for _,entry in ipairs(Achievements.list) do
   local done=Achievements.unlocked(entry)==true
   if done and not N.seen[entry.id] then N.queue[#N.queue+1]=entry end
   N.seen[entry.id]=done
  end
  rememberDependencies()
 end
 if N.visible() then
  N.active.age=N.active.age+dt
  if N.active.age>=3.6 then N.active=nil end
 end
 if not N.active and #N.queue>0 and not Replay.playing and not require('discovery_notice').visible() then
  N.active={entry=table.remove(N.queue,1),age=0}
 end
end
function N.draw()
 if not N.visible() then return end
 local n=N.active;local entry=n.entry
 if n.age>0 and not n.sounded then n.sounded=true;Audio.play('notice') end
 local L=require('localization')
 local heading=n.preview and 'APERÇU · SUCCÈS DÉBLOQUÉ' or 'SUCCÈS DÉBLOQUÉ'
 local name=entry.localizedName and entry.localizedName() or entry.name
 if entry.progress then heading=L.text('SUCCÈS')..' · '..entry.progress..'/'..entry.total
 elseif entry.id=='story_all' and not n.preview then
  local found,total=require('story').progress();name=L.render(name)..' · '..found..'/'..total
 end
 require('notice_card').draw(n.age,heading,name,
  n.preview and 'Aperçu sans déblocage' or 'Ajouté à vos succès',function(x,y,a)
   local g=love.graphics;g.setColor(1,.8,.42,a);g.setLineWidth(2);g.setLineStyle('smooth')
   g.polygon('line',x-11,y-15,x+11,y-15,x+9,y+1,x+4,y+7,x-4,y+7,x-9,y+1)
   g.line(x-11,y-11,x-18,y-11,x-17,y-2,x-9,y+2)
   g.line(x+11,y-11,x+18,y-11,x+17,y-2,x+9,y+2)
   g.line(x,y+7,x,y+16);g.line(x-9,y+17,x+9,y+17)
  end)
end
return N
