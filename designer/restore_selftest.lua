local T={}
local function equal(a,b)
 if type(a)~=type(b) then return false end
 if type(a)=='number' then return math.abs(a-b)<1e-8 end
 if type(a)~='table' then return a==b end
 for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
function T.run(M,state,select)
 io.stdout:setvbuf('no');M.draftFilename='restore-test-drafts.json';M.drafts={};M.applied={version=1,levels={}}
 local rawDefaults=M.clone(M.defaults)
 for _,world in ipairs({1,4,6}) do
  for level=1,10 do
   M.select(world,level);local original=M.clone(M.layout)
   M.add({kind='wall',w=30,h=40},400,300);local edited=M.clone(M.layout)
   assert(M.restore(),'Restauration réussie')
   assert(equal(M.layout,original),'La restauration doit retrouver le même original que le chargement : '..world..':'..level)
   assert(equal(M.drafts[M.key()],original),'Le brouillon restauré contient le niveau complet')
   M.undo(false);assert(equal(M.layout,edited),'Annuler restaure les modifications précédentes')
   M.undo(true);assert(equal(M.layout,original),'Rétablir retrouve le niveau original complet')
   if world==6 then
    assert(#M.layout.entities>1,'Le Ciel ne doit pas devenir vide')
    if level==10 then
     local boss=false;for _,e in ipairs(M.layout.entities) do if e.kind=='boss' and e.type=='storm' then boss=true end end
     assert(boss,'Le boss du Ciel est restauré')
    end
   end
  end
 end
 assert(equal(M.defaults,rawDefaults),'Les modèles d’origine ne sont jamais modifiés')
 -- The real project editor delegates the developer restore to this same path.
 require('project_model').install(M);M.devMode=true;M.workshop=false
 M.select(6,10);M.add({kind='wall',w=30,h=40},400,300)
 assert(M.restore() and #M.layout.entities==2,'Restauration correcte depuis le mode développeur')
 M.select(6,1);local previous=M.clone(M.layout);local saved=M.defaults.levels['6:1']
 M.defaults.levels['6:1']=nil
 local ok=M.restore();assert(ok==false and equal(M.layout,previous),'Un original absent ne vide pas la carte')
 M.defaults.levels['6:1']=saved
 love.draw()
 print('PASS editor restore: 30 campaign originals, ten nonempty sky maps, sky boss, undo/redo, developer mode and missing-original protection')
 love.event.quit()
end
return T
