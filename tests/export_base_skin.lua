-- Export the actual Soie material, without animation, shadows or equipped FX.
local T={}
function T.run()
 local g=love.graphics
 local shader=g.newShader('assets/shaders/player_skin.glsl')
 shader:send('bodyColor',Characters.drawColors[1])
 shader:send('paletteSkin',false)
 shader:send('brownSkin',true)
 shader:send('locked',false)
 love.filesystem.createDirectory('base-skin-export')
 for _,pose in ipairs({'down','up','profil'}) do
  local source=require('art_filter').image('assets/skins/commun/'..pose..'.png')
  local w,h=source:getDimensions()
  local canvas=g.newCanvas(w,h,{dpiscale=1})
  shader:send('sideView',pose=='profil')
  shader:send('frontView',pose=='down')
  g.push('all');g.setCanvas(canvas);g.origin();g.setScissor()
  g.clear(0,0,0,0);g.setShader(shader);g.setColor(1,1,1)
  g.setBlendMode('replace','premultiplied');g.draw(source,0,0)
  g.pop()
  local data=canvas:newImageData()
  assert(data:getWidth()==w and data:getHeight()==h)
  local _,_,_,alpha=data:getPixel(0,0);assert(alpha==0,'Export must stay transparent')
  data:encode('png','base-skin-export/'..pose..'.png')
  data:release();canvas:release()
 end
 shader:release()
 print('PASS base skin export: three native-resolution brown poses, transparent and without equipped FX')
 print('EXPORT '..love.filesystem.getSaveDirectory()..'/base-skin-export')
 love.event.quit()
end
return T
