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
 local image=love.graphics.newImage(data or path,{mipmaps=mode=='linear'})
 image:setFilter(mode,mode)
 if mode=='linear' then image:setMipmapFilter('linear',0) end
 if path then F.images[path]=image end
 require('prism_material').register(image,path)
 return image
end
return F
