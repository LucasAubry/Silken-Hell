-- Only the animated Abyss lantern remains separate; other accessories are in the PNGs.
local A={}
function A.draw(index,x,y,size,dir,locked,front,alpha,marineOverlay)
 if index~=10 or not front or marineOverlay==7 then return end
 local g=love.graphics;local side=dir=='left' or dir=='right'
 g.push('all');g.setShader();g.setBlendMode('alpha');g.translate(x,y);g.scale(size/59)
 if dir=='right' then g.scale(-1,1) end
 local bubble=require('breathing_bubble')
 local hx,hy,r=bubble.headPosition(0,0,59,side and 'left' or dir,index)
 bubble.drawLantern(hx,hy,r,0,locked,alpha,side and 'left' or dir)
 g.pop()
end
return A
