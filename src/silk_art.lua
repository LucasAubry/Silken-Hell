-- Authored silk texture; attachment positions are measured on the real skin alpha.
local S={anchors={}}
function S.load()
 Art.add('silk_strand','assets/effects/silk/strand.png')
 for i,key in ipairs(Characters.keys) do
  if not Characters.crowned[i] then
   local a=Art.images.spider_down
   local path='assets/skins/perle/down.png'
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
function S.menuThread(x,top,y,size)
 local index=Characters.selected();index=Characters.crowned[index] or index
 local bottom=y+(S.anchors[index] or -.32)*size+3
 local g=love.graphics;g.push('all');g.setColor(.95,.91,.82,.92)
 Art.draw('silk_strand',x,(top+bottom)/2,5.5,0,bottom-top);g.pop()
end
return S
