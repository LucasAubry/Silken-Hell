-- Shared metal render in gameplay and the editor.
local T={}
function T.draw(kind,x,y,size,biome,active,angle)
 local key=kind=='scie' and 'wheel' or active and 'trap_closed' or 'trap_open'
 local g=love.graphics;g.push('all');g.setColor(1,1,1)
 local frame=require('paradise_ink').frame(key)
 if kind=='scie' then
  -- A rotating blade is seen straight from above, without projection or relief.
  if biome==5 then require('sprite_relief').bind(frame,true) end
  g.draw(frame.image,frame.quad,x,y,angle or 0,size/frame.w,size/frame.w,frame.w/2,frame.h/2)
  g.pop();return
 end
 -- Jaw traps stay planted even when the editor supplies its animation clock.
 local height=size*frame.h/frame.w*.62
 local depth=math.max(1,math.min(3,size*.035))
 require('sprite_relief').draw(frame,x,y,size,0,height,depth,biome==5)
 g.pop()
end
return T
