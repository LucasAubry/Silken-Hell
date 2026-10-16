local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 local function compile(dir)
  for _,name in ipairs(love.filesystem.getDirectoryItems(dir)) do
   local path=dir..'/'..name;local info=love.filesystem.getInfo(path)
   if info.type=='directory' then compile(path)
   elseif name:match('%.lua$') then assert(loadstring(love.filesystem.read(path),'@'..path)) end
  end
 end
 compile('src');compile('designer')
 for _,path in pairs(require('asset_paths').paths) do assert(love.filesystem.getInfo(path),'Missing aliased asset: '..path) end
 local json=require('json')
 for _,file in ipairs({'custom_levels.json','designer/default_levels.json'}) do
  local content=json.decode(love.filesystem.read(file))
  for key,layout in pairs(content.levels) do
   require('layout_schema').migrate(layout)
   local ok,err=require('layout_schema').validate(layout);assert(ok,key..': '..tostring(err))
   for _,e in ipairs(layout.entities) do assert(e.type~='gull' and e.type~='imp','Removed creature in map '..key) end
  end
 end
 for _,name in ipairs({'gull','imp'}) do assert(not MobBehaviors[name]);assert(not Art.images[name..'_down']) end
 for _,kind in ipairs({'dragonfly','mist_moth','wind_bat','lava_scorpion'}) do
  local a=require('sky_insect_art').sprite(kind);assert(a.w>0 and a.h>0)
  UI.bestiaryIcon({id=kind},100,100,64);require('sanctuary_scene').boss({type=kind},200,100)
 end
 App.sessionLayout={world=2,level=1,width=960,height=600,entities={{kind='spawn',x=100,y=300},{kind='mob',type='imp',x=500,y=300,speed=85}}}
 App.singleLevel=true;App.practice=1;App.start(2);App.practice=nil;require('run_start').active=false
 assert(mobs[1].type=='lava_scorpion','Old campaign goblin is migrated during play')
 local m=mobs[1];local x=m.x;MobBehaviors.lava_scorpion.update(m,.1);assert(m.x<x)
 MobBehaviors.lava_scorpion.draw(m)
 App.sessionLayout=nil
 -- Capture the replacements at their real game scale in their own biomes.
 local frame=0
 love.update=function()
  frame=frame+1
  if frame==1 then App.capture='scorpion-lava.png'
  elseif frame==3 then App.practice=1;App.start(4);App.practice=nil;require('run_start').active=false;App.capture='coral-piranhas.png'
  elseif frame==6 then print('PASS content cleanup: all live Lua modules compile, aliases resolve, campaign/editor maps validate, retired enemies absent, scorpion save migration and movement, new PNGs in bestiary/sanctuary');love.event.quit() end
 end
end
return T
