local A={sprites={}}
function A.facing(angle)
 local x,y=math.cos(angle or 0),math.sin(angle or 0)
 if math.abs(x)>math.abs(y) then return x<0 and 'left' or 'right' end
 return y<0 and 'up' or 'down'
end
function A.sprite(direction)
 local key=direction=='left' and 'right' or direction
 if A.sprites[key] then return A.sprites[key] end
 local data=love.image.newImageData('assets/monstres/ciel/escargot/'..key..'.png')
 local w,h=data:getDimensions();local x0,y0,x1,y1=w,h,0,0
 for y=0,h-1 do for x=0,w-1 do local _,_,_,alpha=data:getPixel(x,y)
  if alpha>.12 then x0=math.min(x0,x);y0=math.min(y0,y);x1=math.max(x1,x);y1=math.max(y1,y) end
 end end
 local g=love.graphics;local image=g.newImage(data);data:release();image:setFilter('nearest','nearest')
 local s={image=image,w=x1-x0+1,h=y1-y0+1};s.quad=g.newQuad(x0,y0,s.w,s.h,w,h);A.sprites[key]=s;return s
end
function A.draw(x,y,size,time,angle,alpha)
 local direction=A.facing(angle);local s=A.sprite(direction);local g=love.graphics
 local scale=size/math.max(s.w,s.h);local breath=math.sin((time or 0)*4)*.018
 g.push('all');g.setShader();g.setColor(1,1,1,alpha or 1)
 g.draw(s.image,s.quad,x,y,0,scale*(direction=='left' and -1 or 1)*(1+breath),scale*(1-breath),s.w/2,s.h*.62)
 g.pop()
end
return A
