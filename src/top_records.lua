local T={page=1};local json=require('json')
local function valid(r)
 return type(r)=='table' and type(r.runId)=='string' and #r.runId==36 and r.runId:match('^[a-f0-9%-]+$')
  and type(r.world)=='number' and r.world%1==0 and r.world>=1 and r.world<=7
  and type(r.achievedAt)=='number' and r.achievedAt>0 and r.achievedAt<1e13
  and type(r.rawTime)=='number' and r.rawTime>=0 and r.rawTime<=86400
  and type(r.deaths)=='number' and r.deaths>=0 and r.deaths<=100000
end
function T.load()
 local ok,rows=pcall(json.decode,love.filesystem.read('top-records.json') or '[]')
 Profile.topRecords={}
 if ok and type(rows)=='table' then for _,r in ipairs(rows) do if valid(r) then Profile.topRecords[#Profile.topRecords+1]=r end end end
end
function T.has(world)
 for _,r in ipairs(Profile.topRecords or {}) do if r.world==world then return true end end
 return false
end
function T.merge(rows)
 if Replay.playing then return end
 local all=Profile.topRecords or {};local known={};local changed=false
 for _,r in ipairs(all) do known[r.runId]=r end
 for _,r in ipairs(rows or {}) do if valid(r) then
  local old=known[r.runId]
  if not old then
   old={runId=r.runId,world=r.world,hardcore=r.hardcore==true,achievedAt=r.achievedAt,
    rawTime=r.rawTime,deaths=r.deaths,skin=r.skin or 1,name=r.name or Profile.name,hasReplay=r.hasReplay==true}
   all[#all+1]=old;known[r.runId]=old;changed=true
  elseif r.hasReplay and not old.hasReplay then old.hasReplay=true;changed=true end
  -- The local replay is available even while its upload is still pending.
  for _,run in ipairs(Online.runs or {}) do
   if run.id==r.runId and run.replay and old.replay~=run.replay then old.replay=run.replay;changed=true end
  end
 end end
 if changed then
  table.sort(all,function(a,b)return a.achievedAt==b.achievedAt and a.runId<b.runId or a.achievedAt>b.achievedAt end)
  Profile.topRecords=all
  local old=love.filesystem.read('top-records.json');if old then love.filesystem.write('top-records.backup.json',old) end
  love.filesystem.write('top-records.json',json.encode(all))
 end
end
function T.open(world)
 T.world=world;T.page=1;App.state='topRecords';Input.index=1;Replay.status=''
 if Online.syncTopRecords then Online.syncTopRecords() end
end
function T.draw()
 local U=UI;local white={.94,.95,.98};local gold={1,.82,.4}
 U.panel(85,55,1030,665)
 U.text(T.world and ('TOP 1 · '..Worlds.names[T.world]) or 'MES PREMIÈRES PLACES',120,79,'heading',white,960,'center')
 local rows={};for _,r in ipairs(Profile.topRecords or {}) do if not T.world or r.world==T.world then rows[#rows+1]=r end end
 local pages=math.max(1,math.ceil(#rows/5));T.page=math.min(T.page,pages)
 for i=(T.page-1)*5+1,math.min(T.page*5,#rows) do
  local r=rows[i];local y=151+((i-1)%5)*91
  U.panel(115,y,970,80)
  U.text(Worlds.names[r.world]..(r.hardcore and ' · Hardcore' or ''),135,y+10,'body',gold,315)
  U.rawText(os.date('%d/%m/%Y · %H:%M',math.floor(r.achievedAt/1000)),135,y+43,'body',white)
  U.text('Chrono '..U.time(Scoring.total(r.rawTime,r.deaths)),470,y+10,'body',white)
  U.text(U.time(r.rawTime)..' · '..r.deaths..' morts',470,y+43,'body',white)
  U.button('Revoir la run',825,y+20,235,42,function()Replay.watch(r)end,not (r.replay or r.hasReplay))
 end
 if #rows==0 then U.text('Aucune première place enregistrée.',150,350,'body',white,900,'center') end
 if Replay.status and Replay.status~='' then U.rawText(U.ellipsize(Replay.status,'body',920),140,609,'body',gold,920,'center') end
 U.button('Précédent',120,657,180,40,function()T.page=T.page-1 end,T.page<=1)
 U.rawText(T.page..' / '..pages,310,667,'body',white,100,'center')
 U.button('Retour',450,657,300,40,function()App.state='achievements';Input.index=1 end)
 U.button('Suivant',900,657,180,40,function()T.page=T.page+1 end,T.page>=pages)
end
return T
