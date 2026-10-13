local T={}
function T.run()
 local F=require('art_filter');local g=love.graphics;local count=0
 for path,entry in pairs(F.pixelArt) do
  assert(not path:match('^assets/skins/'),'Player skins must remain untouched')
  local image=F.image(path);local w,h=image:getDimensions()
  assert(w==entry.size[1] and h==entry.size[2],path)
  local min,mag=image:getFilter();assert(min=='nearest' and mag=='nearest',path)
  assert(F.image(path)==image,'Texture uploads must be cached')
  local sx,sy=F.sourceScale(image,.17,.23)
  assert(math.abs(w*sx-entry.sourceSize[1]*.17)<1e-7,path)
  assert(math.abs(h*sy-entry.sourceSize[2]*.23)<1e-7,path)
  -- Test the actual legacy draw call, including its noncentral pivot.
  local draw=g.draw;local called=false
  g.draw=function(img,x,y,angle,ax,ay,ox,oy)
   assert(img==image and x==50 and y==60 and angle==.4)
   assert(math.abs(ox*ax-11*.17)<1e-7 and math.abs(oy*ay-23*.23)<1e-7,path)
   called=true
  end
  F.drawSource(image,50,60,.4,.17,.23,11,23);g.draw=draw;assert(called)
  count=count+1
 end
 assert(count==163,'Retained pixel-art illustrations must be registered')
 for _,path in ipairs({'assets/environments/paradis/encre-atlas.json','assets/environments/paradis/characters-ink.json','assets/monstres/serviteurs/frames.json'}) do
  for name,frame in pairs(require('json').decode(love.filesystem.read(path))) do
   local image=F.image(frame.path);local w,h=image:getDimensions()
   assert(frame.x>=0 and frame.y>=0 and frame.w>0 and frame.h>0,name)
   assert(frame.x+frame.w<=w and frame.y+frame.h<=h,name)
   local quad=g.newQuad(frame.x,frame.y,frame.w,frame.h,w,h);quad:release()
  end
 end
 for _,name in ipairs({'skeleton_spine','skeleton_rib','skeleton_tail'}) do
  Art.drawBoneProjectile(name,100,100,24,0,32)
  local image=Art.images['projectile_'..name].image
  assert(image:getFilter()=='linear','Bone projectiles retain smooth filtering')
  assert(Art.images[name].image~=image,'Boss art stays independent of projectile art')
 end
 print('PASS pixel art: 163 cached nearest textures, original display sizes and pivots, all animation atlas bounds')
 io.stdout:flush();love.event.quit()
end
return T
