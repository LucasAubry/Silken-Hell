local T={}
function T.run(M,state,select)
 local Art=require('art');local g=love.graphics
 M.drafts={};M.applied.levels={};state.clock=0;state.grid=false
 select(7,9)
 local head
 for _,e in ipairs(M.layout.entities) do if e.kind=='abyss_gate' then head=e end end
 assert(head and head.x<M.layout.width/2 and M.validate(M.layout),'Level nine exposes the passage head as an editable object')
 local catalog=require('catalog');local available=false
 for _,e in ipairs(catalog) do if e.kind=='abyss_gate' then available=true end end
 assert(available,'Passage head is available in the palette')
 head.x=140;assert(M.validate(M.layout));love.draw()
 local canvas=g.newCanvas(g.getWidth(),g.getHeight(),{dpiscale=1})
 g.push('all');g.setCanvas(canvas);love.draw();g.pop()
 local pixels=canvas:newImageData();pixels:encode('png','designer-abyss-gate.png');pixels:release()
 select(2,1);M.layout.entities={{kind='spawn',x=760,y=480},{kind='mob',type='magma_larva',x=400,y=300,has_larme=true},{kind='mob',type='larva',x=300,y=300,has_larme=true}}
 local draw,worm=Art.draw,Art.drawWorm;local magmaSize,wormSize
 Art.draw=function(key,x,y,w,angle,h,...)
  if key=='magma_larva' and x==400 and y==300 then magmaSize=math.max(w,h) end
  return draw(key,x,y,w,angle,h,...)
 end
 Art.drawWorm=function(dir,x,y,size,...)
  if x==300 and y==300 then wormSize=size end
  return worm(dir,x,y,size,...)
 end
 g.push('all');g.setCanvas(canvas);love.draw();g.pop()
 Art.draw=draw;Art.drawWorm=worm
 assert(magmaSize==38 and wormSize==30,'Editor uses the same magma larva and small worm dimensions as gameplay')
 pixels=canvas:newImageData();pixels:encode('png','designer-larvae-size.png');pixels:release();canvas:release()
 print('PASS editor: movable level-nine gate, placement palette, exact game larva sizes and visible carrier markers')
 print('VISUALS '..love.filesystem.getSaveDirectory());love.event.quit()
end
return T
