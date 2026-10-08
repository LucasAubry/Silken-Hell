local T={}
function T.run(M,state,select,apply,preview)
 local P=require('creator_projects');local V=require('project_ui')
 assert(M.projects and not M.currentProject,'Editor opens the project library')
 -- Tests stay inside the editor test identity.
 love.filesystem.createDirectory('creator-qa');M.save=love.filesystem.getSaveDirectory()..'/creator-qa'
 local a=assert(P.new(M.save,4,nil,1));V.open(a)
 M.add({kind='mob',type='crab',speed=120},450,300);assert(M.apply())
 local id=a.id;V.home();assert(not M.currentProject)
 V.open(assert(P.load(M.save,id)));assert(#M.layout.entities==3,'Resume restores the saved content')
 local original=M.clone(M.layout);local b=assert(P.new(M.save,4,M.layout,1));V.open(b)
 M.add({kind='wall',w=40,h=80},650,400);M.rotate();assert(M.selected.rotation==90);M.rotate();assert(M.selected.rotation==0);M.undo(false);M.selected=M.layout.entities[#M.layout.entities];M.undo(false);assert(M.layout.entities[#M.layout.entities].rotation==nil);M.undo(true);assert(M.apply());assert(P.load(M.save,b.id).entries[1].layout.entities[#M.layout.entities].rotation==90,'Wall angle survives undo and saving')
 assert(#P.load(M.save,id).entries[1].layout.entities==3,'Copy never changes the source')
 local world=assert(P.new(M.save,7,nil,10));V.open(world)
 for i=1,10 do assert(M.selectSlot(i));assert(#M.layout.entities==2);M.add({kind='mob',type='lanternfish',speed=50+i},400,250);assert(M.apply())end
 assert(#P.load(M.save,world.id).entries==10 and P.load(M.save,world.id).entries[1].layout.entities[3].speed==51)
 M.layout.entities={};assert(M.apply(),'Incomplete draft can be saved')
 V.home();V.open(assert(P.load(M.save,world.id)));assert(#M.layout.entities==0,'Even incomplete work survives leaving')
 M.restore();M.undo(false);assert(#M.layout.entities==0,'Clear is undoable');M.undo(true)
 V.openPublish();local e=M.currentProject.entries[M.currentProject.current]
 V.field(e,'name');V.text('La cité bleue');V.key('return');V.field(e,'author',24);V.text('Lucas');V.key('return');e.difficulty=4;M.persist()
 local old=os.execute;local launches=0;os.execute=function()launches=launches+1;return 0 end
 V.request('validate');os.execute=old
 local request=P.read(M.save,'creator-request.json');assert(request.projectId==world.id and request.slot==10 and request.action=='validate' and launches==1)
 assert(P.load(M.save,world.id).entries[10].name=='La cité bleue','Publication fields persist')
 assert(not P.proof(M.save,world,10),'Unfinished levels cannot be published')
 -- Developer mode edits the campaign file, never the Workshop library.
 V.publication=false;V.home();local oldProject=M.project;M.project=M.save
 local live=M.clone(M.defaults.levels['1:1']);live.entities[1].x=123
 assert(P.write(M.save,'custom_levels.json',{version=1,levels={['1:1']=live}}))
 assert(M.openDev());assert(M.devMode and M.layout.entities[1].x==123)
 M.add({kind='wall',x=600,y=400,w=30,h=60},600,400);assert(M.apply())
 assert(P.read(M.save,'custom_levels.json').levels['1:1'].entities[#M.layout.entities].kind=='wall')
 assert(P.load(M.save,id).entries[1].layout.entities[3].type=='crab','Dev edits leave Workshop projects alone')
 V.home();assert(not M.devMode);M.project=oldProject
 local legacy={version=1,id='legacy-1-1',name='Campaign',entries={{layout=live}},current=1};P.save(M.save,legacy)
 for _,p in ipairs(P.list(M.save))do assert(p.id~=legacy.id,'Old campaign imports are hidden from projects')end
 local tick=0
 state.testUpdate=function()
  tick=tick+1
  if tick==1 then V.publication=false;V.home()
  elseif tick==2 then love.graphics.captureScreenshot('creator-library.png')
  elseif tick==3 then V.view='new';V.kind='copy';V.biome=4
  elseif tick==4 then love.graphics.captureScreenshot('creator-copy.png')
  elseif tick==5 then V.open(assert(P.load(M.save,world.id)))
  elseif tick==6 then love.graphics.captureScreenshot('creator-ten-levels.png')
  elseif tick==7 then V.openPublish()
  elseif tick==8 then love.graphics.captureScreenshot('creator-publication.png')
  elseif tick==9 then V.publication=false;V.home();M.openDev();select(1,1)
  elseif tick==10 then love.graphics.captureScreenshot('oct8-dev-levels.png')
  elseif tick==11 then M.add({kind='wall',w=180,h=24,rotation=90},500,300)
  elseif tick==12 then love.graphics.captureScreenshot('rotated-wall-editor.png')
  elseif tick==13 then print('PASS project editor: library, new/copy/10 slots, autosave, resume, incomplete drafts, undo and publication menu');love.event.quit()end
 end
end
return T
