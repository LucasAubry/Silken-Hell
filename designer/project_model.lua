local P=require('creator_projects')
local X={}
function X.install(M)
 M.projects=true;M.workshop=true;M.currentProject=nil
 local oldKey,oldPersist=M.key,M.persist
 local oldSelect,oldApply,oldRestore=M.select,M.apply,M.restore
 function M.key() return M.currentProject and ('project:'..M.currentProject.id..':'..M.currentProject.current) or oldKey() end
 function M.persist()
  if not M.currentProject then return oldPersist() end
  local p=M.currentProject;p.entries[p.current].layout=M.clone(M.layout)
  local ok,err=P.save(M.save,p);M.saveError=not ok and err or nil;return ok,err
 end
 function M.openProject(project,slot)
  M.currentProject=project;M.currentProject.current=slot or project.current or 1
  local e=project.entries[M.currentProject.current];M.layout=M.clone(e.layout);M.world=M.layout.biome or M.layout.world;M.level=1
  M.history={};M.future={};M.selected=nil;M.dirty={};return true
 end
 function M.select(world,level)
  if M.devMode then return oldSelect(world,level) end
  if not M.currentProject then return end
  M.checkpoint();M.world=world;M.layout.world=world;M.layout.biome=world;M.layout.level=1;M.selected=nil;return M.persist()
 end
 function M.selectSlot(slot)
  local ok,err=M.persist();if not ok then return nil,err end
  return M.openProject(M.currentProject,slot)
 end
 function M.apply()
  if M.devMode then return oldApply() end
  local ok,err=M.persist();return ok,ok and 'Projet enregistré.' or err
 end
 function M.restore()
  if M.devMode then return oldRestore() end
  M.checkpoint();M.layout=require('workshop_maps').blank(M.world);M.selected=nil;return M.persist()
 end
 function M.openDev()
  if M.currentProject then local ok,err=M.persist();if not ok then return nil,err end end
  M.currentProject=nil;M.devMode=true;M.workshop=false;M.filename='custom_levels.json';M.draftFilename='dev-drafts.json'
  M.applied=require('abyss_sequence').migrate(P.read(M.save,'custom_levels.json') or {version=1,levels={}})
  local raw=love.filesystem.read(M.draftFilename);local ok,data=pcall(require('json').decode,raw or '{}');M.drafts=ok and data or {}
  if M.drafts._abyssSequence~=2 then
   if raw then love.filesystem.write('dev-drafts.before-abyss-sequence.json',raw) end
   require('abyss_sequence').migrate({levels=M.drafts})
   M.drafts['7:9']=nil;M.drafts._abyssSequence=2
   love.filesystem.write(M.draftFilename,require('json').encode(M.drafts))
  end
  oldSelect(1,1);return true
 end
 function M.home()
  if M.devMode then oldPersist();M.devMode=false;M.workshop=true end
  if M.currentProject then local ok,err=M.persist();if not ok then return nil,err end end
  M.currentProject=nil;M.selected=nil;return true
 end
end
return X
