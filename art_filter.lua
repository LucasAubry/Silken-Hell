-- One sampling policy for every skin, creature and scenery texture.
-- Mipmaps stabilize high-resolution art at gameplay size without a screen blur.
local F={images={}}
function F.mode(path) return 'linear' end
function F.image(path,data)
 if path then
  path=require('asset_paths').resolve(path)
  if F.images[path] then return F.images[path] end
 end
 local image=love.graphics.newImage(data or path,{mipmaps=true})
 image:setFilter('linear','linear')
 image:setMipmapFilter('linear',0)
 if path then F.images[path]=image end
 require('prism_material').register(image,path)
 return image
end
return F
