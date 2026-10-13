local T={}
function T.run(M,state,select)
 M.draftFilename='hole-test-drafts.json'
 M.drafts={};M.applied={version=1,levels={}}
 select(6,1);state.category='Terrain';state.all=false;love.draw()
 for _,e in ipairs(M.layout.entities) do assert(e.kind~='hole','No default sky holes') end
 local before=#M.layout.entities;local catalog=require('catalog')
 for _,entry in ipairs(catalog) do if entry.kind=='hole' then state.tool=entry end end
 assert(state.tool,'Brush appears in catalog')
 local view=state.canvas
 local function point(x,y) return view.x+x*view.s,view.y+y*view.s end
 local x,y=point(260,180);love.mousepressed(x,y,1)
 x,y=point(420,180);love.mousemoved(x,y)
 x,y=point(420,360);love.mousemoved(x,y);love.draw();love.mousereleased(x,y,1)
 assert(#M.layout.entities==before+1,'One drag adds one editable hole')
 local e=M.layout.entities[#M.layout.entities]
 assert(e.points and #e.points==6 and M.validate(M.layout),'Brush shape is valid and saved')
 M.undo(false);assert(#M.layout.entities==before)
 M.undo(true);e=M.layout.entities[#M.layout.entities];assert(#e.points==6,'Redo restores the full stroke')
 state.tool=nil;x,y=point(330,180);love.mousepressed(x,y,1)
 assert(M.selected==e,'Clicking any part of a long stroke selects it')
 x,y=point(350,200);love.mousemoved(x,y);love.mousereleased(x,y,1)
 assert(require('ground_holes').contains(e,350,200),'Whole stroke follows dragging')
 assert(require('json').decode(love.filesystem.read(M.draftFilename))['6:1'].entities[#M.layout.entities].points,'Draft retains brush points')
 local oldProject,oldSave=M.project,M.save
 M.project=love.filesystem.getSaveDirectory();M.save=M.project;M.filename='hole-test-levels.json'
 local ok,msg=M.apply();assert(ok,msg)
 local saved=require('json').decode(love.filesystem.read(M.filename));assert(M.validate(saved.levels['6:1']))
 M.project,M.save=oldProject,oldSave
 local tick=0
 state.testUpdate=function()
  tick=tick+1
  if tick==2 then love.graphics.captureScreenshot('drawn-holes-editor.png') end
  if tick==4 then print('PASS editor holes: drawing, selection, moving, undo/redo, draft and level saving');love.event.quit() end
 end
end
return T
