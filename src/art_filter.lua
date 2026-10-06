-- Preserve the original pixel skins; illustrated world textures use mipmaps.
-- Mipmaps stabilize high-resolution art at gameplay size without a screen blur.
local F={images={}}
function F.mode(path) return path and path:match('^assets/skins/') and 'nearest' or 'linear' end
function F.image(path,data)
 if path then
  path=require('asset_paths').resolve(path)
  if F.images[path] then return F.images[path] end
 end
 local mode=F.mode(path)
 local cleaned
 if path and path:match('^assets/skins/commun/') then
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
return F
