local T={}
function T.run()
 assert(require('texture_preload').ready)
 Online.enabled=false;Replay.disabled=true;LevelLayouts.disabled=true
 local g=love.graphics;local original=g.newImage;local uploads=0
 g.newImage=function(...) uploads=uploads+1;return original(...) end
 -- First spawns and first renders must be warm, including locked skins.
 for _,spawn in ipairs({spawn_snake,spawn_scie,spawn_piege,spawn_ange}) do spawn(100,100,1) end
 for skin=1,22 do for _,dir in ipairs({'up','down','left','right'}) do Characters.portrait(skin,50,50,40,dir,false) end end
 for path in pairs(require('asset_paths').paths) do
  local name=path:match('^assets/sprites/final/(.+)%.png$')
  if name then require('final_art').draw(name,50,50,40,0) end
 end
 local filter=require('art_filter')
 assert(filter.image('texture/spider_down.png')==player.img_down,'Resolved aliases must share one texture')
 local tasks={}
 for _,w in ipairs(Worlds.order) do for n=1,Worlds.levelCount(w) do tasks[#tasks+1]={w,n} end end
 for w in pairs(Worlds.secretBiomes) do tasks[#tasks+1]={w,1} end
 local index=0
 love.update=function()
  index=index+1
  if index<=#tasks then
   local task=tasks[index];Campaign.select(task[1]);player.level=task[2];reset_level();App.state='playing'
  else
   g.newImage=original
   assert(uploads==0,'First level renders created '..uploads..' textures after startup')
   print('PASS texture preload: first spawns, all skins and '..#tasks..' level renders without texture uploads')
   love.event.quit()
  end
 end
end
return T
