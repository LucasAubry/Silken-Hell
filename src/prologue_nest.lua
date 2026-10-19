-- The retreat is a dedicated transparent sprite; its entrance anchors the bed.
local N={width=150}
function N.load()
 Art.add('prologue_cocoon','assets/prologue/silk_cocoon.png')
end
function N.blocked(x,y,nx,ny)
 local dx,dy=x-nx,y-ny
 -- Solid silk at the back and sides; the front entrance stays open.
 return (dx/65)^2+((dy+18)/43)^2<1 and (dy < -8 or math.abs(dx)>39)
end
function N.draw(x,y)
 N.load();local g=love.graphics;local a=Art.images.prologue_cocoon
 local scale=N.width/a.w
 g.push('all');g.setShader()
 g.setColor(.91,.94,.83);g.draw(a.image,a.quad,x,y,0,scale,scale,a.w*.55,a.h*.73)
 g.pop()
end
return N
