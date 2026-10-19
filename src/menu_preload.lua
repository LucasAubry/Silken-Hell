-- Compile menu shaders and upload lazy portraits before accepting menu clicks.
local P={}
function P.load()
 if App.preview then return end
 local g=love.graphics;local canvas=g.newCanvas(1200,750,{dpiscale=1})
 local state,selected,name=App.state,App.selectedWorld,App.draftName
 local buttons,clock=UI.buttons,UI.clock
 local online=Online.enabled
 g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.clear()
 local ok,err=xpcall(function()
  Online.enabled=false;App.state='menu';UI.menu();Online.enabled=online
  App.state='skins';UI.skins()
  App.state='entry';App.draftName=Profile.name or '';UI.background();UI.entry()
  for _,world in ipairs(Worlds.selection) do
   require('world_preview').draw(world,0,0,680,300,false)
  end
  App.selectedWorld=selected;WorldMap.open();WorldMap.drawBackground(1200,750);WorldMap.draw()
  g.flushBatch()
 end,debug.traceback)
 g.pop();canvas:release()
 Online.enabled=online;App.state=state;App.selectedWorld=selected;App.draftName=name;UI.buttons=buttons;UI.clock=clock
 if not ok then error(err) end
 P.ready=true
end
return P
