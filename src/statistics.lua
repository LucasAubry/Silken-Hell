local S={}
local bosses={[1]='merle',[6]='storm',[5]='hedgehog',[4]='octopus',[7]='skeleton_fish',[2]='wasp',[3]='final_spider'}
function S.draw()
 local U,g=UI,love.graphics;local white={.94,.94,.9};local muted={.66,.73,.76};local gold={1,.83,.43}
 U.panel(70,45,1060,660)
 U.text('STATISTIQUES',100,67,'heading',white,1000,'center')
 local kills=0;for _,n in pairs(Profile.bossKills or {}) do kills=kills+n end
 for i,v in ipairs({{'Larmes',Profile.stats.tears},{'Morts',Profile.stats.deaths},{'Essais',Profile.stats.attempts},{'Boss vaincus',kills}}) do
  local x=100+(i-1)*255;g.setColor(.035,.10,.13,.96);g.rectangle('fill',x,116,235,70,5)
  U.text(v[1],x,125,'body',muted,235,'center');U.text(tostring(v[2]),x,146,'heading',gold,235,'center')
 end
 U.text('Biome / boss',105,209,'body',muted)
 for i,label in ipairs({'Larmes','Morts','Essais','Victoires'}) do U.text(label,620+(i-1)*117,209,'body',muted,112,'center') end
 for i,world in ipairs(Worlds.order) do
  local y=240+(i-1)*51;local row=Profile.biomeCounters(world);local id=bosses[world];local entry
  for _,e in ipairs(Bestiary.entries) do if e.id==id then entry=e;break end end
  local count=(Profile.bossKills or {})[id] or 0
  local beaten=count>0 or Profile.hasCompleted(world) or (Profile.achievements or {})['bossflawless'..world]
  local tint=Worlds.color(world).tear
  g.setColor(.035,.075,.10,.94);g.rectangle('fill',100,y,1000,46,4)
  g.setColor(tint);g.rectangle('fill',100,y+4,3,38)
  U.text(Worlds.names[world],114,y+3,'body',white)
  U.fitText(entry and entry.name or '',114,y+25,'small',muted,350)
  U.text(beaten and 'VAINCU' or 'À VAINCRE',468,y+15,'small',beaten and {.5,.9,.65} or muted,140,'center')
  for j,n in ipairs({row.tears or 0,row.deaths or 0,row.attempts or 0,count}) do U.text(tostring(n),620+(j-1)*117,y+11,'medium',white,112,'center') end
 end
 U.text('Détails par biome et victoires comptés depuis cette mise à jour.',100,611,'small',muted,1000,'center')
 U.button('Retour',440,652,320,36,function()App.state='menu' end)
end
return S
