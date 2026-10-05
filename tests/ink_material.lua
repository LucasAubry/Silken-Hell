local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true;love.focus=function()end
 Graphics.showFPS=false;App.singleLevel=true;App.practice=7;App.start(1)
 local g=love.graphics;local M=require('prism_material');local ink=M.inkShader
 local function sample(key,mode,biome,shader)
  Campaign.biome=biome or 1;M.enabled=mode~='raw';M.inkShader=mode=='legacy' and M.shader or ink
  local c=g.newCanvas(160,160);g.push('all');g.setCanvas(c);g.origin();g.clear(0,0,0,0);g.setColor(1,1,1,.7)
  M.beginScene(c);if shader then g.setShader(shader) end
  local a=Art.images[key];local scale=140/math.max(a.w,a.h)
  g.draw(a.image,a.quad,80,80,0,scale,scale,a.w/2,a.h/2)
  if shader then assert(g.getShader()==shader)end
  M.endScene();g.pop();M.inkShader=ink;M.enabled=true
  local data=c:newImageData();c:release();return data
 end
 for _,key in ipairs({'crab_open','hedgehog_down','mole_down','octopus_mantle','skeleton_head','magma_larva'}) do
  local before,after,other=sample(key,'raw'),sample(key,'ink'),sample(key,'ink',7);local changes=0
  for y=0,159 do for x=0,159 do
   local r,green,b,a=before:getPixel(x,y);local nr,ng,nb,na=after:getPixel(x,y)
   assert(math.abs(a-na)<1/255+.0001,'Alpha and silhouette stay exact: '..key)
   local br,bg,bb,ba=other:getPixel(x,y)
   assert(nr==br and ng==bg and nb==bb and na==ba,'Biomes cannot recolor assets')
   if a>.2 and r+green+b>.1 then
    local gain=(nr+ng+nb)/(r+green+b)
    assert(math.abs(nr-r*gain)<3/255 and math.abs(ng-green*gain)<3/255 and math.abs(nb-b*gain)<3/255,'Original hue/saturation preserved')
   end
   if math.abs(nr-r)+math.abs(ng-green)+math.abs(nb-b)>.025 then changes=changes+1 end
  end end
  assert(changes>200,'Ink treatment must be visible: '..key);before:release();after:release();other:release()
 end
 -- Compare to the previous material, including queen poses and pixel skins.
 local keys={'original_down','rebirth_white_spider','final_queen','final_partner','final_baby_red','final_baby_white','final_baby_black','final_side_red','final_up_white','final_left_black','queen_crown','wheel'}
 for _,name in ipairs(Characters.keys) do if Art.images[name..'_down'] then keys[#keys+1]=name..'_down' end end
 for _,key in ipairs(keys) do
  local before,after=sample(key,'legacy'),sample(key,'ink')
  assert(before:getString()==after:getString(),'Protected spider/reference art changed: '..key);before:release();after:release()
 end
 local src='vec4 effect(vec4 c, Image tex, vec2 uv, vec2 px) { vec4 p=Texel(tex,uv); return vec4(p.rgb*vec3(.7,1.,.8),p.a)*c; }'
 local base=g.newShader(src);local styled=M.surfaceShader(src)
 local a,b=sample('crab_open','raw',1,base),sample('crab_open','raw',1,styled)
 assert(a:getString()==b:getString(),'Existing material stays exact outside the new style');a:release();b:release()
 local data=sample('crab_open','ink',1,styled);data:release();base:release();styled:release()
 print('PASS ink rendering: visible contours/shading, unchanged alpha and RGB proportions, biome independence, exact protected spiders/reference art, preserved custom shaders')
 local tasks={};for _,w in ipairs(Worlds.order) do for _,level in ipairs({w==3 and 1 or 7,Worlds.levelCount(w)}) do
  tasks[#tasks+1]={world=w,level=level}
 end end
 local draw=love.draw;local tick=0;local task
 local newImage=g.newImage;local uploads=0;g.newImage=function(...)uploads=uploads+1;return newImage(...)end
 love.update=function()
  tick=tick+1
  if tick%2==1 then
   task=tasks[math.ceil(tick/2)]
   if not task then g.newImage=newImage;assert(uploads==0,'No runtime texture uploads');M.enabled=true;print('PASS seven biomes, boss renders, unchanged RNG/collisions, no texture uploads');love.event.quit();return end
   App.practice=task.level;App.start(task.world);UI.clock=2
   for _,m in ipairs(mobs) do if m.type=='mole' then m.age=3 end end
  end
  M.enabled=tick%2==0
 end
 love.draw=function()
  if not task then return end
  local state=love.math.getRandomState();local walls=require('json').encode(Arena.walls);draw()
  assert(love.math.getRandomState()==state and walls==require('json').encode(Arena.walls),'Rendering cannot alter gameplay')
  local path='/tmp/silken-ink-'..task.world..'-'..task.level..(M.enabled and '-after' or '-before')..'.png'
  g.captureScreenshot(function(data)local file=assert(io.open(path,'wb'));file:write(data:encode('png'):getString());file:close()end)
 end
end
return T
