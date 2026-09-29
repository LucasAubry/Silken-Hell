local V={}
local palettes={
 [1]={.98,.79,.40},[2]={1,.28,.12},[3]={.60,.94,.48},[4]={.22,.86,.90},
 [5]={.83,.62,.35},[6]={.66,.77,1},[7]={.32,.65,1}
}
function V.enter(continuation)
 V.run={world=Campaign.world,biome=Campaign.biome,time=timer,deaths=player.death,hardcore=App.hardcore,
  rows=RunDetails.snapshot(),started=UI.clock,online=Online.current,continuation=continuation,page=1,name=Profile.name}
 V.run.replayData=Replay.recording and Replay.data or nil
 App.state='victory';UI.boardWorld=Campaign.world
end
function V.rank(r)
 if r.hardcore then return 'HARDCORE','Hors classement normal' end
 local run=r.online
 if not Online.enabled or not run or run.failed then
  for i,s in ipairs(Profile.ranking(r.world)) do
   if s.name==r.name and math.abs((s.rawTime or 0)-r.time)<.001 and s.deaths==r.deaths then return '#'..i,'Classement sur cet appareil' end
  end
  return '—','Partie non classée'
 end
 if not run.id or #run.pending>0 then return 'ENVOI…','Score en attente de publication' end
 if r.rank then return '#'..r.rank,'Classement mondial · cette partie' end
 if r.notFound then return '—','Score absent du classement actuel' end
 local data,status=Online.page(r.world,false,r.page)
 if status=='loading' then return '…','Recherche du rang mondial' end
 if status~='online' then return 'HORS LIGNE','Rang mondial indisponible' end
 for i,s in ipairs(data.scores) do if s.runId==run.id then r.rank=(r.page-1)*10+i;return '#'..r.rank,'Classement mondial · cette partie' end end
 if data.hasMore then r.page=r.page+1 else r.notFound=true end
 return '…','Recherche du rang mondial'
end
function V.backdrop(r)
 local g=love.graphics;local c=palettes[r.biome] or palettes[1];local t=UI.clock-r.started
 g.setColor(.008,.015,.027,1);g.rectangle('fill',0,0,1200,750)
 -- A rising halo and animated silhouettes give each biome its own celebration.
 for i=28,1,-1 do g.setColor(c[1],c[2],c[3],.006);g.circle('fill',600,110,80+i*13) end
 g.setColor(c[1],c[2],c[3],.30);g.setLineWidth(1)
 for i=1,3 do g.ellipse('line',600,110,155+i*17+math.sin(t*.8+i)*5,49+i*9) end
 for i=1,64 do
  local x=(i*137.3+math.sin(t*.3+i)*20)%1200
  local y=(i*81.7-t*(12+i%17))%750
  g.setColor(c[1],c[2],c[3],.12+.2*(.5+.5*math.sin(t+i)))
  if r.biome==4 or r.biome==7 then g.circle('line',x,y,2+i%5)
  elseif r.biome==6 then g.line(x,y,x+4,y+8,x+1,y+14)
  elseif r.biome==5 then g.polygon('fill',x,y-4,x+3,y,x,y+4,x-3,y)
  else g.circle('fill',x,y,1+i%3) end
 end
 g.setColor(c[1]*.12,c[2]*.12,c[3]*.12,1)
 for i=0,12 do
  local x=i*110
  if r.biome==4 or r.biome==7 then
   g.ellipse('fill',x,760+math.sin(t+i)*8,150,65+i%3*18)
  elseif r.biome==6 or r.biome==1 then g.ellipse('fill',x,755,160,55+i%3*20)
  else g.polygon('fill',x-80,750,x+25,640-i%3*30,x+120,750) end
 end
 return c
end
function V.draw()
 if not V.run then V.enter() end
 local r=V.run;local g=love.graphics;local c=V.backdrop(r);local white={.94,.96,1};local muted={.57,.65,.74}
 UI.text(Worlds.names[r.biome]:upper(),80,76,'heading',white,1040,'center')
 UI.rawText(r.name,100,119,'body',muted,1000,'center')
 UI.panel(70,166,400,430,true);UI.panel(490,166,640,430,true)
 UI.text('TEMPS CLASSÉ',95,189,'small',c)
 g.push();g.translate(92,217);g.scale(1.8);UI.rawText(UI.time(Scoring.total(r.time,r.deaths)),0,0,'heading',white);g.pop()
 UI.text(r.deaths..' morts · pénalité '..Scoring.label(r.deaths),95,281,'small',muted)
 g.setColor(c[1],c[2],c[3],.3);g.line(95,318,445,318)
 UI.text('TEMPS ACTIF',95,339,'small',muted);UI.rawText(UI.time(r.time),95,365,'heading',c)
 local rank,label=V.rank(r)
 UI.rawText(rank,95,467,'heading',white);UI.text(label,95,513,'small',muted,350)
 UI.text('VOTRE PARCOURS',516,189,'small',c)
 UI.text('NIVEAU',516,222,'small',muted);UI.text('TEMPS',873,222,'small',muted);UI.text('MORTS',1030,222,'small',muted)
 local rows={};for _,row in ipairs(r.rows) do rows[row.level]=row end
 for n=1,Worlds.levelCount(r.world) do
  local y=249+(n-1)*31;local row=rows[n]
  if n%2==1 then g.setColor(c[1],c[2],c[3],.045);g.rectangle('fill',506,y-3,608,29,3) end
  local boss=Worlds.isSecret(r.world) or n==10 or (r.world==3 and n==1)
  local name=boss and ((Campaign.titles[r.biome] or {})[Worlds.isSecret(r.world) and 10 or n] or 'Le gardien') or 'Niveau '..n
  UI.rawText(string.format('%02d',n),518,y,'small',c);UI.text(name,553,y,'body',white,300)
  UI.rawText(row and UI.time(row.time) or '—',873,y,'body',white)
  UI.rawText(row and tostring(row.deaths) or '—',1045,y,'body',muted)
 end
 local replay=r.replayData
 UI.button('Voir ma traversée',70,617,250,47,function() Replay.play(replay) end,not (replay and replay.completed))
 UI.button('Classement',334,617,210,47,function() UI.boardReturn='victory';UI.boardWorld=r.world;UI.boardCountry=false;UI.boardLocal=false;UI.boardPage=1;App.state='rankings' end,r.hardcore)
 UI.button(r.continuation and 'Continuer' or r.hardcore and 'Rejouer en hardcore' or Worlds.next(r.world) and 'Monde suivant' or 'Rejouer ce monde',560,617,570,47,function()
  if r.continuation then r.continuation() else App.openEntry(r.hardcore and r.world or Worlds.next(r.world) or r.world,r.hardcore) end
 end,false,true,nil,nil,palettes[Worlds.biome((not r.hardcore and Worlds.next(r.world)) or r.world)] or c)
 UI.button('Retour au menu',450,685,300,33,function() if Worlds.isSecret(r.world) then Secret.open() else App.state='menu' end end)
end
return V
