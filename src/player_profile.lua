-- Public progress is a snapshot of the player's own save; identity stays server-side.
local P={page=1}
function P.snapshot()
 local achievements,worlds={},{}
 for _,a in ipairs(Achievements.list) do if Achievements.unlocked(a) then achievements[#achievements+1]=a.id end end
 for _,world in ipairs(Worlds.order) do
  local counters=Profile.biomeCounters(world)
  worlds[#worlds+1]={world=world,completed=Profile.hasCompleted(world),hardcore=Worlds.canViewScores(world,true),flawless=Profile.flawless(world),
   tears=counters.tears or 0,deaths=counters.deaths or 0,attempts=counters.attempts or 0,bosses=Profile.bossVictories(world)}
 end
 local stats={};for k,v in pairs(Profile.stats) do stats[k]=v end
 stats.bosses=0;for _,row in ipairs(worlds) do stats.bosses=stats.bosses+row.bosses end
 return {name=Profile.name,skin=Characters.selected(),stats=stats,worlds=worlds,achievements=achievements}
end
function P.open(score)
 P.returnState=App.state;P.page=1;P.tab='stats';P.data=nil;P.status='Chargement…';P.name=score.name
 local ticket={};P.ticket=ticket;App.state='playerProfile'
 if not score.runId then P.data=P.snapshot();P.status=nil;return end
 Online.request('/v1/players/by-run/'..score.runId,nil,function(data,code)
  if P.ticket~=ticket then return end
  if code==200 and type(data)=='table' and type(data.stats)=='table' and type(data.worlds)=='table' and type(data.achievements)=='table' then
   P.data=data;P.status=nil
  else P.status=code==404 and 'Profil indisponible' or 'Connexion indisponible' end
 end)
end
function P.close() P.ticket=nil;App.state=P.returnState or 'rankings';P.data=nil end
function P.draw()
 local U,g=UI,love.graphics;local white={.94,.94,.9};local gold={1,.83,.43};local muted={.66,.73,.76}
 U.panel(90,55,1020,640)
 U.rawText(U.ellipsize(P.data and P.data.name or P.name or '', 'heading',720),240,78,'heading',gold,720,'center')
 if P.data then g.setColor(1,1,1);Characters.portrait(P.data.skin or 1,170,110,64) end
 U.button('Statistiques',280,140,300,40,function()P.tab='stats';P.page=1 end,false,P.tab=='stats','go')
 U.button('Succès',620,140,300,40,function()P.tab='achievements';P.page=1 end,false,P.tab=='achievements','go')
 if P.status then U.text(P.status,180,350,'body',muted,840,'center')
 elseif P.tab=='stats' then
  local stats=P.data.stats
  local labels=P.data.source=='scores' and {{'Parcours',stats.runs},{'Morts',stats.deaths},{'Temps',U.time(stats.time or 0)}} or
   {{'Larmes',stats.tears},{'Morts',stats.deaths},{'Essais',stats.attempts},{'Boss vaincus',stats.bosses}}
  local width=920/#labels
  for i,v in ipairs(labels) do local x=140+(i-1)*width;U.text(v[1],x,209,'body',muted,width,'center');U.text(tostring(v[2] or 0),x,240,'heading',gold,width,'center') end
  U.text('Monde',140,300,'body',muted)
  for i,label in ipairs({'Terminé','Hardcore','Sans mourir'}) do U.text(label,490+(i-1)*180,300,'body',muted,175,'center') end
  local rows={};for _,r in ipairs(P.data.worlds) do rows[r.world]=r end
  for i,world in ipairs(Worlds.order) do local row=rows[world] or {};local y=334+(i-1)*38
   U.text(Worlds.canEnter(world) and Worlds.names[world] or '???',140,y,'body',white)
   for j,key in ipairs({'completed','hardcore','flawless'}) do U.text(row[key] and 'Oui' or '—',490+(j-1)*180,y,'body',row[key] and gold or muted,175,'center') end
  end
  if P.data.source=='scores' then U.text('Statistiques des parcours classés',140,610,'body',muted,920,'center') end
 else
  local earned={};for _,id in ipairs(P.data.achievements) do earned[id]=true end
  local list={};for _,a in ipairs(Achievements.list) do if earned[a.id] then list[#list+1]=a end end
  local pages=math.max(1,math.ceil(#list/8));P.page=math.min(P.page,pages)
  for i=(P.page-1)*8+1,math.min(P.page*8,#list) do
   local a=list[i];local y=216+(i-1)%8*43
   require('flawless_badge').draw(175,y+12,10)
   U.rawText(U.ellipsize((a.world and not Worlds.canEnter(a.world)) and '???' or require('localization').render(a.name),'body',780),210,y,'body',white)
  end
  if #list==0 then U.text('Aucun succès obtenu',180,350,'body',muted,840,'center') end
  U.button('←',140,594,64,36,function()P.page=P.page-1 end,P.page<=1,false,'go')
  U.text(P.page..' / '..pages,430,600,'body',gold,340,'center')
  U.button('→',996,594,64,36,function()P.page=P.page+1 end,P.page>=pages,false,'go')
 end
 U.button('Retour',440,647,320,36,P.close,false,false,'back')
end
return P
