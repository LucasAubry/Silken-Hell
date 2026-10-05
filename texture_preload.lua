-- Keep the textures used by lazy renderers resident before opening the menu.
local P={}
function P.screen()
 local g=love.graphics
 love.event.pump()
 g.push('all');g.origin();g.setCanvas();g.setShader();g.setScissor()
 if P.font then g.setFont(P.font) end
 g.clear(.013,.025,.035);g.setColor(.9,.94,1)
 local w,h=g.getDimensions()
 g.printf('Chargement des textures…',0,h*.47,w,'center')
 g.setColor(.5,.65,.75)
 g.printf('Préparation du jeu',0,h*.47+32,w,'center')
 g.pop();g.present()
end
function P.begin()
 P.font=love.graphics.newFont(24)
 P.screen()
 local last=love.timer.getTime()
 Art.onLoad=function()
  if love.timer.getTime()-last>=.05 then P.screen();last=love.timer.getTime() end
 end
end
function P.load()
 local extra={
  earth_mound='assets/monstres/terre/taupe/earth_mound.png',
  octopus_mantle='assets/monstres/ocean/poulpe/mantle.png',
  ink_ground='assets/monstres/ocean/poulpe/ink_ground.png',
  merle_egg='assets/monstres/paradis/merle/merle_egg.png',
  reward_crown='assets/skins/accessoires/couronne.png',
  queen_crown='assets/monstres/renaissance/reine/crown.png',
  hardcore_skull='assets/sprites/hardcore_skull.png',
 }
 for _,pose in ipairs({'up','down','left'}) do extra['original_'..pose]='texture/spider_'..pose..'.png' end
 for path in pairs(require('asset_paths').paths) do
  local name=path:match('^assets/sprites/final/(.+)%.png$')
  if name then extra['final_'..name]=path end
 end
 for key,path in pairs(extra) do if not Art.images[key] then Art.add(key,path) end end
 local image=require('art_filter').image
 for _,kind in ipairs({'ange','serpent'}) do
  for _,dir in ipairs({'up','down','left','right'}) do
   image('assets/monstres/paradis/'..kind..'/'..(kind=='serpent' and 'snake' or kind)..'_'..dir..'.png')
  end
 end
 for _,name in ipairs({'scie','scie_pique','scie_blanc','piege','piege_active'}) do image('assets/monstres/paradis/pieges/'..name..'.png') end
 require('paradise_ink').load()
 require('boss_arrival').load()
 local borders=require('biome_borders');borders.images=borders.images or {}
 for _,biome in ipairs({3,4,7}) do borders.images[biome]=image('assets/environments/ink/wall-'..biome..'.png') end
 image('assets/icons/biome-backgrounds.png')
 Art.onLoad=nil
 P.font:release();P.font=nil
 P.ready=true
end
return P
