local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 App.start(6)
 local data=Realms.floor:newImageData()
 for _,p in ipairs({{5,300},{Arena.width-6,300},{math.floor(Arena.width/2),5},{math.floor(Arena.width/2),595}})do
  local r,g,b=data:getPixel(p[1],p[2]);assert(r<.07 and g<.12 and b<.22,'Sky edge must remain empty dark void')
 end
 local B=require('biome_borders');B.key=nil;B.draw();assert(B.key==nil,'No decorative sky walls')
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then App.capture='sky-void-border.png' end
  if tick==5 then print('PASS sky void on all four edges, no decorative walls');love.event.quit()end
 end
end
return T
