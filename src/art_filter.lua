-- Preserve crisp pixel edges and the original game-space dimensions.
local F={images={}}
F.pixelArt=require('json').decode(love.filesystem.read('assets/pixel-art.json') or '{}')
function F.binaryAlpha(path)
 return path and ((F.pixelArt[path] and F.pixelArt[path].binaryAlpha) or path:match('^assets/skins/commun/') or path:match('^assets/skins/integrated/') or path:match('^assets/skins/accessoires/') or path:match('^assets/skins/maxance/') or path:match('^assets/skins/cocon/'))~=nil
end
function F.mode(path)
 if path and path:match('^assets/skins/base_marron/') then return 'linear' end
 if F.pixelArt[path] or F.binaryAlpha(path) then return 'nearest' end
 return path and (path:match('^assets/skins/') or path:match('^assets/ui/achievements/')) and 'nearest' or 'linear'
end
function F.image(path,data)
 if path then
  path=require('asset_paths').resolve(path)
  if F.images[path] then return F.images[path] end
 end
 local mode=F.mode(path)
 local cleaned
 if F.binaryAlpha(path) then
  -- Generated PNGs contain near-transparent residue along their pixel outlines.
  -- Normalize once at upload, keeping the original RGB and empty leg gaps.
  cleaned=data and data:clone() or love.image.newImageData(path)
  cleaned:mapPixel(function(x,y,r,g,b,a)
   if a<.5 then return 0,0,0,0 end
   return r,g,b,1
  end)
 end
 local image=love.graphics.newImage(cleaned or data or path,{mipmaps=mode=='linear'})
 if cleaned then cleaned:release() end
 image:setFilter(mode,mode)
 if mode=='linear' then image:setMipmapFilter('linear',0) end
 if path then F.images[path]=image end
 require('prism_material').register(image,path)
 return image
end
-- Legacy renderers express scale and pivots in the original PNG coordinates.
function F.sourceSize(image)
 local entry=F.pixelArt[require('prism_material').paths[image]]
 if entry then return entry.sourceSize[1],entry.sourceSize[2] end
 return image:getDimensions()
end
function F.sourceScale(image,sx,sy)
 local w,h=F.sourceSize(image)
 return (sx or 1)*w/image:getWidth(),(sy or sx or 1)*h/image:getHeight()
end
function F.drawSource(image,x,y,angle,sx,sy,ox,oy)
 local w,h=F.sourceSize(image)
 local ax,ay=F.sourceScale(image,sx,sy)
 love.graphics.draw(image,x,y,angle or 0,ax,ay,
  (ox or 0)*image:getWidth()/w,(oy or 0)*image:getHeight()/h)
end
return F
