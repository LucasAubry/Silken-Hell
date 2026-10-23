local T={}
function T.run(M)
 io.stdout:setvbuf('no');M.draftFilename='restore-test-drafts.json';M.drafts={};M.applied={version=1,levels={}}
 for _,world in ipairs({1,4,6}) do for level=1,10 do
  M.select(world,level);M.add({kind='wall',w=30,h=40},400,300)
  local count=#M.layout.entities;local width=M.layout.width
  assert(M.restore());assert(#M.layout.entities==0 and next(M.layout.environment)==nil)
  assert(M.layout.width==width and #M.drafts[M.key()].entities==0)
  M.undo(false);assert(#M.layout.entities==count)
  M.undo(true);assert(#M.layout.entities==0)
  M.select(world,level);assert(#M.layout.entities==0,'Empty map survives reopening')
 end end
 require('project_model').install(M);M.devMode=true;M.workshop=false
 M.select(6,10);M.add({kind='wall',w=30,h=40},400,300)
 assert(M.restore() and #M.layout.entities==0)
 print('PASS editor clear: 30 maps, persisted empty sky, undo/redo and developer mode')
 love.event.quit()
end
return T
