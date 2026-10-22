local T={}
function T.run(M,state,select)
 select(4,1);state.category='Mobs';state.all=false;state.scroll=0
 local entry
 for _,e in ipairs(require('catalog')) do if e.type=='plankton' then entry=e end end
 assert(entry and entry.world==4,'Plancton au catalogue Océan')
 local m=M.add(entry,400,220);m.has_larme=true
 assert(M.validate(M.layout),'Plancton porteur sauvegardable')
 love.draw()
 print('PASS plankton editor: ocean catalog, placement, carrier and rendering')
 love.event.quit()
end
return T
