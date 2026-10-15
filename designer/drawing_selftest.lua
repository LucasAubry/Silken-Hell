local T={}
function T.run(M,state,select)
 local g=love.graphics;local H=require('ground_holes');local S=require('terrain_surface')
 M.draftFilename='drawing-test-drafts.json';M.drafts={}
 local target=g.newCanvas(g.getWidth(),g.getHeight(),{dpiscale=1})
 local function render()
  g.push('all');g.setCanvas(target);g.origin();love.draw();g.pop()
  return target:newImageData()
 end
 for _,world in ipairs({2,6}) do
  select(world,1);state.grid=false;M.layout.entities={};M.selected=nil
  local baseline=render();local v=state.canvas;local width=M.layout.width
  local kind=world==2 and 'lava' or 'hole'
  M.layout.entities={
   H.stroke({0,120,0,480},100,kind),H.stroke({width,120,width,480},100,kind),
   H.stroke({200,0,600,0},100,kind),H.stroke({200,600,600,600},100,kind),
   {kind='wall',x=-30,y=300,w=140,h=200},
  }
  for pass=1,3 do
   if pass==3 then state.stroke=H.stroke({0,0,width,0,width,600,0,600,0,0},36,kind) end
   local pixels=render()
   local function same(x,y)
    x,y=math.floor(x),math.floor(y)
    local r,b,c=baseline:getPixel(x,y);local rr,bb,cc=pixels:getPixel(x,y)
    assert(math.abs(r-rr)+math.abs(b-bb)+math.abs(c-cc)<.01,'Terrain leaks outside the map at '..x..','..y)
   end
   for offset=4,16,4 do
    for y=140,460,40 do same(v.x-offset,v.y+y*v.s);same(v.x+width*v.s+offset,v.y+y*v.s) end
    for x=220,580,40 do same(v.x+x*v.s,v.y-offset);same(v.x+x*v.s,v.y+600*v.s+offset) end
   end
   local ix,iy=math.floor(v.x+50*v.s),math.floor(v.y+180*v.s)
   local r,b,c=baseline:getPixel(ix,iy);local rr,bb,cc=pixels:getPixel(ix,iy)
   assert(math.abs(r-rr)+math.abs(b-bb)+math.abs(c-cc)>.05,'Terrain is still visible inside the map')
   if pass==3 then pixels:encode('png','editor-clipping-'..kind..'.png') end
   pixels:release()
  end
  state.stroke=nil
  baseline:release()
  print('PASS editor clipping: '..kind..', cold/warm caches and all four edges')
  state.tool={kind=kind,points={0,0}};state.brush=28
  local function point(x,y)return v.x+x*v.s,v.y+y*v.s end
  local x,y=point(100,180);love.mousepressed(x,y,1)
  assert(state.stroke,'Brush stroke starts')
  local builds=S.builds;local started=love.timer.getTime()
  for frame=1,80 do
   x,y=point(100+frame*6,280+100*math.sin(frame*.12));love.mousemoved(x,y)
   g.push('all');g.setCanvas(target);g.origin();love.draw();g.pop()
  end
  print(string.format('EDITOR_DRAW_%s_MS=%.2f',kind,(love.timer.getTime()-started)*1000/80))
  assert(S.builds==builds,'Drawing must not rebuild the terrain distance field on every movement')
  local count=#M.layout.entities
  love.mousereleased(x,y,1);assert(not state.stroke and #M.layout.entities==count+1)
  local pixels=render();pixels:release()
  assert(S.builds==builds+1,'The final union is built once after releasing the brush')
  state.tool=nil;x,y=point(100,180);love.mousepressed(x,y,1)
  assert(state.drag and M.selected==M.layout.entities[#M.layout.entities],'Completed stroke can be dragged')
  pixels=render();pixels:release();builds=S.builds
  for frame=1,40 do
   x,y=point(100+frame*2,180+frame);love.mousemoved(x,y)
   g.push('all');g.setCanvas(target);g.origin();love.draw();g.pop()
  end
  assert(S.builds==builds,'Moving painted terrain must not rebuild its material each frame')
  love.mousereleased(x,y,1)
  pixels=render();pixels:release()
  assert(S.builds==builds+1,'Moved terrain is baked at its final position')
  M.undo(false) -- Undo the movement before undoing the new stroke.
  M.undo(false);assert(#M.layout.entities==count);M.undo(true);assert(#M.layout.entities==count+1)
  state.tool=nil
 end
 target:release()
 print('PASS editor drawing: smooth live strokes, final terrain, clipping and undo/redo')
 love.event.quit()
end
return T
