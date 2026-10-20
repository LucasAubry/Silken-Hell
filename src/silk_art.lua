-- Authored silk texture; attachment positions are measured on the real skin alpha.
local S={anchors={}}
function S.load()
 Art.add('silk_strand','assets/effects/silk/strand.png')
 for i,key in ipairs(Characters.keys) do
  if not Characters.crowned[i] then
   local a=Art.images[Characters.model('down')]
   local path='assets/skins/commun/down.png'
   if a then
    local data=Art.imageData(path);local qx,qy,qw,qh=a.quad:getViewport()
    local top=qh*.2
    for y=0,qh-1 do
     local _,_,_,alpha=data:getPixel(math.floor(qx+qw/2),math.floor(qy+y))
     if alpha>.3 then top=y;break end
    end
    local divisor=math.max(a.w,a.h)
    S.anchors[i]=(top-qh/2)/divisor
    data:release()
   end
  end
 end
end
function S.thread(x,y,xx,yy,width,alpha)
 local dx,dy=xx-x,yy-y;local length=math.sqrt(dx*dx+dy*dy)
 if length<1 then return end
 local g=love.graphics;g.push('all');g.setColor(.95,.91,.82,alpha or .92)
 Art.draw('silk_strand',(x+xx)/2,(y+yy)/2,width or 5.5,math.atan2(dy,dx)-math.pi/2,length)
 g.pop()
end
function S.menuThread(x,top,y,size)
 local index=Characters.menuIndex();index=Characters.crowned[index] or index
 local anchor=require('winged_anchors').winged(index) and -.19 or (S.anchors[index] or -.32)
 local bottom=y+anchor*size+3
 if bottom<=top then return end
 S.thread(x,top,x,bottom,5.5,.92)
end
return S
