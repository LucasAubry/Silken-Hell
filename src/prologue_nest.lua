-- The retreat is a dedicated transparent sprite; its entrance anchors the bed.
local N={width=174}
function N.load()
 Art.add('prologue_cocoon','assets/prologue/silk_cocoon.png')
end
function N.draw(x,y)
 N.load();local g=love.graphics;local a=Art.images.prologue_cocoon
 local scale=N.width/a.w
 g.push('all');g.setShader()
 g.setColor(.035,.045,.02,.16);g.ellipse('fill',x-5,y+16,65,24)
 g.setColor(.91,.94,.83);g.draw(a.image,a.quad,x,y,0,scale,scale,a.w*.55,a.h*.73)
 g.pop()
end
return N
