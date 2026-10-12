local T={}
function T.run()
 local g=love.graphics;local walk=require('brown_walk')
 local art=Art.images[Characters.model('down',1)]
 local p={walkMoving=true,walkPhase=.7}
 local canvas=g.newCanvas(240,240,{dpiscale=1})
 g.push('all');g.setCanvas(canvas);g.origin();g.clear();g.setColor(1,1,1)
 walk.draw(art.image,'down',120,120,180,p,art.quad)
 local cache=walk.meshes[art.image].down;local mesh=cache.mesh
 local uploads=0
 local proxy={setVertices=function(_,vertices)uploads=uploads+1;return mesh:setVertices(vertices)end}
 local draw=g.draw
 g.draw=function(item,...)return draw(item==proxy and mesh or item,...)end
 cache.mesh=proxy
 for _=1,10 do walk.draw(art.image,'down',120,120,180,p,art.quad) end
 assert(uploads==0,'Repeated display frames must not upload the same walking pose')
 p.walkPhase=1.3;walk.draw(art.image,'down',120,120,180,p,art.quad)
 assert(uploads==1,'One new walking pose needs one batched upload')
 cache.mesh=mesh;g.draw=draw
 for i,r in ipairs(cache.rig) do
  local stride=math.sin(p.walkPhase+r.offset);local lift=math.max(0,math.cos(p.walkPhase+r.offset))
  local x=r.x+(stride*r.side*.043)*cache.w*r.weight
  local y=r.y+(stride*.031-lift*.024)*cache.h*r.weight
  local actualX,actualY=mesh:getVertex(i)
  assert(math.abs(actualX-x)<.001 and math.abs(actualY-y)<.001,'The optimized pose must match the original rig')
 end
 g.pop();canvas:release()
 -- Demonstrate why render FPS does not measure simulation refresh.
 Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 App.singleLevel=true;App.practice=9;App.start(6);App.practice=nil
 Replay.disabled=false;Replay.playing=false;Replay.ghost=false;Replay.recording=true
 local moved=0;local repeated=0
 local input,slow=Input.move,Input.slow
 Input.move=function()return 1,0 end;Input.slow=function()return true end
 for _=1,400 do
  local before=moved
  Replay.update(1/400,function(dt)moved=moved+1;assert(dt==1/60)end)
  if moved==before then repeated=repeated+1 end
 end
 Input.move,Input.slow=input,slow
 assert(moved>=59 and moved<=60 and repeated>=340,'400 render frames still contain about 60 simulation steps')
 print(string.format('PASS walk render cache: unchanged pose uploads=0, changed pose uploads=1, all 441 vertices match; 400 display frames / %d simulation steps / %d repeated positions',moved,repeated))
 love.event.quit()
end
return T
