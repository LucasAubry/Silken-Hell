-- Layout-only rendering never resets the live run or advances its simulation.
local P={}
function P.level(world)
 local current=(App.previewLevels or {})[world..':'..tostring(WorldMap.hardcore==true)]
 return math.max(1,math.min(Worlds.levelCount(world),current or (Profile.levels or {})[world] or 1))
end
function P.layout(world)
 local n=P.level(world);local custom=LevelLayouts.read()[world..':'..n]
 if world==6 then return custom and require('sky').prepare(custom) or require('sky').layout(n,960) end
 if custom then return custom end
 if not P.defaults then
  P.defaults=require('campaign_order').migrate(require('abyss_sequence').migrate(require('json').decode(love.filesystem.read('designer/default_levels.json')))).levels
 end
 return P.defaults[world..':'..n]
end
function P.draw(world,time)
 local layout=P.layout(world);if not layout then return end
 local g=love.graphics;local old={world=Campaign.world,biome=Campaign.biome,width=Arena.width,level=player.level,secret=Secret.inArena}
 Campaign.world=world;Campaign.biome=layout.biome or world;Arena.width=layout.width;player.level=layout.level;Secret.inArena=function()return false end
 g.push('all');g.clear(.01,.02,.03)
 local scale=math.min(680/layout.width,.5);g.translate((680-layout.width*scale)/2,(300-600*scale)/2);g.scale(scale)
 local ok,err=xpcall(function()
  require('biome_floor').draw(Campaign.biome,layout.width,600,time)
  require('ocean_scenery').draw()
  local holes,lava={},{}
  for _,e in ipairs(layout.entities)do if e.kind=='hole' then holes[#holes+1]=e elseif e.kind=='lava' then lava[#lava+1]=e end end
  require('terrain_surface').draw(holes,'hole',time,1,Campaign.biome);require('lava_zones').drawAll(lava,time,1,Campaign.biome)
  P.catalog=P.catalog or require('designer.catalog')
  for _,e in ipairs(layout.entities)do
   g.setColor(1,1,1)
   if e.kind=='wall' then Arena.drawWall({x=e.x-e.w/2,y=e.y-e.h/2,w=e.w,h=e.h,rotation=e.rotation},world==2)
   elseif e.kind=='spawn' then Characters.draw(e.x,e.y,45,'down')
   elseif e.kind=='tear' or e.kind=='light' then Art.draw('tear_ring',e.x,e.y,38)
   elseif e.kind=='electric_ground' then require('electric_ground').draw({e},time,1)
   elseif e.kind=='rain' then g.setColor(.25,.6,1,.8);for i=-1,1 do g.line(e.x+i*8,e.y-18,e.x+i*8-5,e.y+7) end
   elseif e.kind=='current' then require('ocean_current').draw(e,time)
   elseif e.kind=='hole' or e.kind=='lava' then
   else
    local entry
    for _,c in ipairs(P.catalog)do if c.kind==e.kind and c.type==e.type then entry=c;break end end
    if entry and entry.art and not Art.images[entry.art] then
     local paths={catalog_ange='assets/monstres/paradis/ange/ange_down.png',catalog_snake='assets/monstres/paradis/serpent/snake_down.png',catalog_trap='assets/monstres/paradis/pieges/piege.png',tear_ring='assets/textures/aureole.png'}
     local path=paths[entry.art] or 'assets/sprites/'..entry.art..'.png'
     if not love.filesystem.getInfo(require('asset_paths').resolve(path)) then path='assets/sprites/directional/'..entry.art..'.png' end
     if love.filesystem.getInfo(require('asset_paths').resolve(path)) then Art.add(entry.art,path) end
    end
    if e.kind=='mob' then
     local best
     for _,v in ipairs(Bestiary.entries)do if v.id==e.type then best=v;break end end
     if best then require('bestiary_animation').draw(best,e.x,e.y,48,time,'down')
     elseif entry and entry.art and Art.images[entry.art] then Art.draw(entry.art,e.x,e.y,48) end
    elseif entry and entry.art and Art.images[entry.art] then
     if e.kind=='abyss_part' or e.kind=='abyss_gate' then Art.draw(entry.art,e.x,e.y,e.w or 540,(e.rotation or 0)*math.pi/180,e.h)
     else Art.draw(entry.art,e.x,e.y,e.kind=='boss' and 100 or 50) end
    end
   end
  end
  if world==3 then
   require('final_art').spider(layout.level==1 and 'queen' or 'partner',layout.width*.5,165,62,0)
  end
  require('biome_borders').draw();require('renaissance_frame').draw();require('earth_frame').draw();require('paradise_frame').draw();require('hell_frame').draw();require('biome_edge_life').draw()
 end,debug.traceback)
 g.pop();Campaign.world=old.world;Campaign.biome=old.biome;Arena.width=old.width;player.level=old.level;Secret.inArena=old.secret
 if not ok then error(err) end
 P.shownLevel=layout.level
end
function P.border(world)
 local cw,cb,aw,pl,si=Campaign.world,Campaign.biome,Arena.width,player.level,Secret.inArena
 Campaign.world=world;Campaign.biome=world;Arena.width=1360;player.level=P.level(world);Secret.inArena=function()return false end
 love.graphics.push('all');love.graphics.scale(.5)
 local ok,err=xpcall(function()
  require('biome_borders').draw();require('ocean_scenery').draw();require('renaissance_frame').draw();require('earth_frame').draw();require('paradise_frame').draw();require('hell_frame').draw();require('biome_edge_life').draw()
 end,debug.traceback)
 love.graphics.pop();Campaign.world=cw;Campaign.biome=cb;Arena.width=aw;player.level=pl;Secret.inArena=si
 if not ok then error(err) end
end
return P
