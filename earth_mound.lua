-- Generated packed-earth burrow, sharing the existing tunnel footprint.
local M={}
function M.draw(x,y)
 if not Art.images.earth_mound then Art.add('earth_mound','assets/sprites/earth_mound.png') end
 love.graphics.setColor(1,1,1);Art.draw('earth_mound',x,y,104,0,68)
end
return M
