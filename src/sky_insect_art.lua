-- Shared transparent monster PNGs in the same pixel-art style as the spider.
local A={images={}}
local paths={dragonfly='assets/monstres/ciel/libellule/electric_dragonfly.png',mist_moth='assets/monstres/ciel/papillon/mist_moth.png'}
function A.sprite(kind)
 if A.images[kind] then return A.images[kind] end
 local g=love.graphics;local data=love.image.newImageData(assert(paths[kind]))
 local w,h=data:getDimensions();local x0,y0,x1,y1=w,h,0,0
 for y=0,h-1 do for x=0,w-1 do
  local _,_,_,a=data:getPixel(x,y)
  if a>.12 then x0=math.min(x0,x);x1=math.max(x1,x);y0=math.min(y0,y);y1=math.max(y1,y) end
 end end
 local image=g.newImage(data);data:release();image:setFilter('nearest','nearest')
 local sprite={image=image,w=x1-x0+1,h=y1-y0+1}
 sprite.quad=g.newQuad(x0,y0,sprite.w,sprite.h,w,h);A.images[kind]=sprite
 return sprite
end
function A.draw(kind,x,y,size,time,angle)
 local g=love.graphics;local moth=kind=='mist_moth';local t=time or 0
 local sprite=A.sprite(kind);local scale=(size or 72)/sprite.w
 local flap=moth and (.9+.1*math.cos(t*11)) or (.94+.06*math.cos(t*39))
 g.push('all');g.translate(x,y);g.rotate(angle or 0)
 g.setColor(.015,.035,.08,.20);g.ellipse('fill',2,9,(size or 72)*.33,10)
 g.setColor(1,1,1)
 g.draw(sprite.image,sprite.quad,0,math.sin(t*5)*1.4,0,scale*flap,scale,sprite.w/2,sprite.h/2)
 if not moth then
  g.setColor(.7,.92,1,.7);g.setLineWidth(1)
  local a=math.floor(t*12);local r=(size or 72)*.33
  for side=-1,1,2 do
   g.line(side*r,-5,side*(r+4),-10+math.sin(a)*3,side*(r+7),-4)
  end
 end
 g.pop()
end
return A
