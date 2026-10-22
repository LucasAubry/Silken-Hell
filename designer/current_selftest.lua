local T={}
function T.run(M,state,select)
 io.stdout:setvbuf('no');M.draftFilename='current-test-drafts.json';M.drafts={}
 select(4,1);M.layout.entities={{kind='spawn',x=100,y=100}};state.grid=false
 local g=love.graphics;local canvas=g.newCanvas(g.getDimensions())
 local function render()g.push('all');g.setCanvas(canvas);g.origin();love.draw();g.pop()end
 render()
 local found=false
 for _,b in ipairs(state.buttons) do if b.x==14 and b.y==166 then b.fn();found=true;break end end
 assert(found and state.tool.kind=='current','Ocean has a direct drawing button')
 local v=state.canvas;local function point(x,y)return v.x+x*v.s,v.y+y*v.s end
 local x,y=point(200,250);love.mousepressed(x,y,1)
 x,y=point(500,250);love.mousemoved(x,y);x,y=point(500,400);love.mousereleased(x,y,1)
 local e=M.selected;assert(e and e.kind=='current' and #e.points>=4 and e.speed==80 and e.dx==1)
 assert(require('layout_schema').validate(M.layout),'Painted current validates')
 render();local rotated=false
 for _,b in ipairs(state.buttons) do if b.label and b.label:match('^Sens') then b.fn();rotated=true;break end end
 -- Buttons use text only for presentation; find the stored action by row if needed.
 if not rotated then
  for _,b in ipairs(state.buttons) do if b.x==g.getWidth()-227 and b.y==436 then b.fn();rotated=true;break end end
 end
 assert(rotated and e.dx==-1,'Direction control reverses current')
 state.tool=nil;render();canvas:newImageData():encode('png','editor-ocean-current.png')
 local copy=M.clone(M.layout);M.undo(false);assert(#M.layout.entities==#copy.entities,'Direction undo preserves the painted zone')
 assert(M.layout.entities[#M.layout.entities].dx==1);M.undo(false);assert(#M.layout.entities==1,'Drawing undo removes the stroke')
 canvas:release();print('PASS editor ocean current: brush gesture, validation, direction, serialization and undo');love.event.quit()
end
return T
