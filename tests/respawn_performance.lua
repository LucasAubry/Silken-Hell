local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 Replay.disabled=true;Replay.playing=false;App.practice=nil;App.sessionLayout=nil;App.hardcore=false
 Profile.completed={};for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 App.start(2,{skipArrival=true});local H=require('ground_holes');local surface=require('terrain_surface')
 local original=H.geometry;local geometryTime=0
 H.geometry=function(...)local start=love.timer.getTime();local result=original(...);geometryTime=geometryTime+love.timer.getTime()-start;return result end
 local g=love.graphics;local target=g.newCanvas(Arena.width,600)
 local function render()
  g.push('all');g.setCanvas(target);g.clear();Hazards.drawFloor();g.pop()
  local pixels=target:newImageData();pixels:release()
 end
 for _,n in ipairs({4,5,8}) do
  player.level=n;reset_level();render()
  local builds=H.builds;local fields=surface.builds;geometryTime=0
  local start=love.timer.getTime()
  for retry=1,3 do reset_level({retry=true});render() end
  print(string.format('Hell %d: three reset+lava frames %.1f ms; geometry %.1f ms; terrain rebuilds %d',n,(love.timer.getTime()-start)*1000,geometryTime*1000,surface.builds-fields))
  if builds then assert(H.builds==builds,'Retry reuses authored collision geometry') end
  assert(surface.builds==fields,'Retry reuses the lava distance field')
 end
 local a={x=0,y=0,radius=10,points={0,0,30,0,30,30}}
 local b={x=90,y=0,radius=10,points={0,0,30,0,30,30}}
 local first=H.geometry(a);assert(H.geometry(b)==first,'Identical translated shapes share geometry')
 b.points[3]=45;assert(H.geometry(b)~=first and H.geometry(a)==first,'Editor changes invalidate only the edited shape')
 H.geometry=original;target:release()
 print('PASS lava respawn performance: same terrain survives retries')
 love.event.quit()
end
return T
