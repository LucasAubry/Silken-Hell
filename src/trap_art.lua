-- Shared metal render in gameplay and the editor.
local T={}
function T.draw(kind,x,y,size,biome,active,angle)
 local key=kind=='scie' and 'wheel' or active and 'trap_closed' or 'trap_open'
 local g=love.graphics;g.push('all');g.setColor(1,1,1)
 local frame=require('paradise_ink').frame(key)
 local height,pose
 local depth=math.max(1,math.min(3,size*.035))
 if kind=='scie' then
  angle=angle or 0
  -- Rotate in the floor plane before projecting it, so the ellipse stays flat.
  pose=function(xx,yy)
   g.push();g.translate(xx,yy);g.scale(1,.62)
   g.draw(frame.image,frame.quad,0,0,angle,size/frame.w,size/frame.w,frame.w/2,frame.h/2)
   g.pop()
  end
 else
  -- Project the original PNG onto the floor, with a shallow front rim.
  -- Traps stay planted even when the editor supplies its animation clock.
  height=size*frame.h/frame.w*.62
  angle=0
 end
 require('sprite_relief').draw(frame,x,y,size,angle,height,depth,biome==5,pose)
 g.pop()
end
return T
