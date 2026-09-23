local R={rows={}}
function R.reset() R.rows={};R.lastDeaths=0;R.view=nil end
function R.row()
 local n=player.level;R.rows[n]=R.rows[n] or {level=n,time=0,deaths=0};return R.rows[n]
end
function R.tick(dt) local r=R.row();r.time=r.time+dt end
function R.death() local n=player.death or 0;local delta=math.max(0,n-(R.lastDeaths or 0));local r=R.row();r.deaths=r.deaths+delta;R.lastDeaths=n end
function R.key(s) return table.concat({s.world or 0,s.name or '',string.format('%.3f',s.time or 0),s.deaths or 0,s.skin or 1},'|') end
function R.snapshot() local out={};local levels={};for n in pairs(R.rows) do levels[#levels+1]=n end;table.sort(levels);for _,n in ipairs(levels) do local r=R.rows[n];out[#out+1]={level=n,time=r.time,deaths=r.deaths} end;return out end
function R.openScore(score,world)
 local view={world=world,rows={},status='Détail indisponible pour cette ancienne partie.'};R.view=view
 local function receive(rows)
  if R.view~=view or type(rows)~='table' then return end
  for _,r in pairs(rows) do if type(r)=='table' and type(r.level)=='number' and r.level%1==0 and r.level>=1 and r.level<=Worlds.levelCount(world) and type(r.time)=='number' and r.time>=0 and r.time<1e9 and type(r.deaths)=='number' and r.deaths>=0 and r.deaths<1e9 then view.rows[r.level]=r;view.status=nil end end
 end
 receive(score.splits)
 if next(view.rows) then return end
 local json=require 'json'
 if type(score.replay)=='string' and #score.replay==64 and score.replay:match('^[a-f0-9]+$') then
  local ok,data=pcall(json.decode,love.filesystem.read('replays/'..score.replay..'.json') or '')
  if ok and type(data)=='table' then receive(data.splits) end
 elseif type(score.runId)=='string' and #score.runId==36 and score.runId:match('^[a-f0-9%-]+$') and score.hasReplay then
  view.status='Chargement…'
  Online.request('/v1/replays/'..score.runId,nil,function(data,code)
   if R.view~=view then return end
   view.status='Détail indisponible pour cette ancienne partie.'
   if code==200 and type(data)=='table' and type(data.replay)=='table' then receive(data.replay.splits) end
  end)
 end
end
function R.draw()
 UI.panel(300,145,600,510);UI.text('Détail de la traversée',330,170,'heading')
 UI.text('Niveau',330,216,'body');UI.text('Temps passé',500,216,'body');UI.text('Morts',750,216,'body')
 for n=1,Worlds.levelCount(R.view and R.view.world or Campaign.world) do local r=(R.view and R.view.rows or R.rows)[n]
  UI.text(tostring(n),350,248+(n-1)*30,'body')
  UI.text(r and UI.time(r.time) or '—',500,248+(n-1)*30,'body')
  UI.text(r and tostring(r.deaths) or '—',770,248+(n-1)*30,'body')
 end
 UI.text(R.view and R.view.status or 'Temps actif, tentatives ratées incluses. Pénalités de mort à part.',330,568,'small',{.65,.77,.79})
 UI.button('Retour',330,600,540,35,function() UI.showRunDetails=false;R.view=nil end)
end
return R
