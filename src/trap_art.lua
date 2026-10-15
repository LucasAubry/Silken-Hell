-- Shared raised metal render in gameplay and the editor.
local T={}
function T.draw(kind,x,y,size,biome,active,angle)
 local key=kind=='scie' and 'wheel' or active and 'trap_closed' or 'trap_open'
 local g=love.graphics;g.push('all');g.setColor(1,1,1)
 require('sprite_relief').draw(require('paradise_ink').frame(key),x,y,size,angle,nil,nil,biome==5)
 g.pop()
end
return T
