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
 pixels=canvas:newImageData();pixels:encode('png','designer-larvae-size.png');pixels:release()
 -- Compare the whole editor at different animation times, including palette sprites.
 M.layout.entities[#M.layout.entities+1]={kind='mob',type='dragonfly',x=500,y=300}
 M.layout.entities[#M.layout.entities+1]={kind='vent',x=600,y=300,rx=30,ry=23}
 M.selected=nil;state.tool=nil;state.category='Mobs';state.scroll=0
 local getTime=love.timer.getTime
 local function frozenFrame(time)
  state.clock=time;love.timer.getTime=function() return time end
  g.push('all');g.setCanvas(canvas);love.draw();g.pop()
  local data=canvas:newImageData();local bytes=data:getString();data:release();return bytes
 end
 local first=frozenFrame(0);local second=frozenFrame(1.73)
 love.timer.getTime=getTime
 assert(first==second,'Editor monsters and palette must stay still as both clocks advance')
 canvas:release()
 local G=require('graphics_settings');local focus=love.window.hasFocus
 love.window.hasFocus=function() return true end;assert(G.targetRate(true)==30)
 love.window.hasFocus=function() return false end;assert(G.targetRate(true)==10)
 love.window.hasFocus=focus
 -- Exercise the production limiter with a fake clock (tests normally bypass sleeps).
 local getenv,sleep,setSync=os.getenv,love.timer.sleep,love.window.setVSync
 local lastFrame,appliedSync=G.lastFrame,G.appliedSync
 local now,slept=100,0
 os.getenv=function(key) if key=='SILKEN_TEST' or key=='SILKEN_DESIGNER_TEST' then return nil end;return getenv(key) end
 love.timer.getTime=function() return now end
 love.timer.sleep=function(seconds) slept=slept+seconds;now=now+seconds end
 love.window.setVSync=function() end
 for _,active in ipairs({true,false}) do
  love.window.hasFocus=function() return active end;G.lastFrame=now;slept=0
  G.pace(true);assert(math.abs(slept-1/(active and 30 or 10))<.00001,'Production editor pacing must sleep')
 end
 os.getenv=getenv;love.timer.sleep=sleep;love.timer.getTime=getTime;love.window.setVSync=setSync;love.window.hasFocus=focus
 G.lastFrame=lastFrame;G.appliedSync=appliedSync
 print('PASS editor thermal: static monster pixels and production frame pacing at 30/10 FPS')
 print('PASS editor: movable level-nine gate, placement palette, exact game larva sizes and visible carrier markers')
 print('VISUALS '..love.filesystem.getSaveDirectory());love.event.quit()
end
return T
