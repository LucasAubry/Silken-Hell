-- Called by the game with SILKEN_EXPORT_ICONS pointing to an output directory.
local E={}
function E.run(folder)
 local composer=require('icon_composer')
 -- Check against the real player's renderer, including its material and crop.
 local g=love.graphics;local canvas=g.newCanvas(512,512);local previous=g.getCanvas()
 g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.clear();g.setColor(1,1,1)
 composer.drawSpider(256,260,composer.spiderSize);g.setCanvas(previous);local actual=canvas:newImageData()
 g.setCanvas(canvas);g.clear();g.setColor(1,1,1);Characters.portrait(1,256,260,composer.spiderSize,'down');g.setCanvas(previous);local expected=canvas:newImageData()
 assert(actual:getString()==expected:getString(),'App icon must use the current brown player skin')
 g.setCanvas(previous);g.pop();actual:release();expected:release();canvas:release()
 local function save(data,path)
  local bytes=data:encode('png');local file=assert(io.open(folder..'/'..path,'wb'))
  file:write(bytes:getString());file:close();bytes:release();data:release()
 end
 for _,kind in ipairs({'game','editor'}) do
  for _,size in ipairs({16,32,64,128,256,512,1024}) do save(composer.make(3,kind=='editor',size),kind..'-'..size..'.png') end
 end
 for world=1,7 do save(composer.make(world,false,512),'biome-'..world..'.png') end
 print('Exported matching game/editor icons at 7 resolutions and all 7 game biomes')
 love.event.quit()
end
return E
