local S={scroll=0,maxScroll=0}
function S.move(amount) S.scroll=math.max(0,math.min(S.maxScroll,S.scroll+amount)) end
function S.draw()
 local U,g=UI,love.graphics;local white={.93,.93,.87}
 U.panel(170,55,860,665);U.text('SUCCÈS',200,76,'heading',white,800,'center')
 local filter=U.achievementFilter or 'all'
 U.button('Filtre : '..({all='Tous',todo='À faire',done='Obtenus'})[filter],205,124,225,34,function()
  U.achievementFilter=({all='todo',todo='done',done='all'})[filter];S.scroll=0
 end)
 U.button('Statistiques',800,124,195,34,function()App.state='statistics' end)
 local rows={}
 for _,a in ipairs(Achievements.list) do
  local done=Achievements.unlocked(a)
  if (not a.visible or a.visible()) and (filter=='all' or filter=='done' and done or filter=='todo' and not done) then rows[#rows+1]={a=a,done=done} end
 end
 S.maxScroll=math.max(0,#rows*82-6-456);S.move(0)
 g.push('all');local x,y=g.transformPoint(205,178);local right,bottom=g.transformPoint(995,634)
 g.intersectScissor(x,y,right-x,bottom-y)
 for i,row in ipairs(rows) do
  local yy=178+(i-1)*82-S.scroll
  if yy+76>=178 and yy<=634 then
   local a,done=row.a,row.done;local accent=done and {.48,.82,.61} or {.68,.67,.57}
   g.setColor(done and {.035,.10,.075,.96} or {.045,.065,.075,.96});g.rectangle('fill',205,yy,780,76,5)
   g.setColor(accent);g.setLineWidth(1.5)
   if done then g.line(222,yy+25,227,yy+30,237,yy+18) else g.rectangle('line',223,yy+19,12,12,2) end
   U.rawText(U.ellipsize(require('localization').render(a.localizedName and a.localizedName() or a.name),'body',710),253,yy+9,'body',white)
   U.text(a.description(),253,yy+34,'body',done and {.58,.71,.63} or {.72,.76,.78},715)
  end
 end
 if #rows==0 then U.text(filter=='todo' and 'Tout est accompli !' or 'Aucun succès obtenu.',230,377,'body',white,730,'center') end
 g.pop()
 if S.maxScroll>0 then
  local thumb=math.max(35,456*456/(S.maxScroll+456))
  g.setColor(.19,.23,.24);g.rectangle('fill',999,178,3,456,1)
  g.setColor(.64,.59,.43);g.rectangle('fill',999,178+(456-thumb)*S.scroll/S.maxScroll,3,thumb,1)
 end
 U.button('Retour',440,667,320,36,function()App.state='menu' end)
end
return S
