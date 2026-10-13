-- The catalogue and gameplay share the same PNG frames and biome material.
local T={}
function T.draw(kind,x,y,size,biome,active,angle)
 local g=love.graphics;local art=require('paradise_ink')
 local key=kind=='scie' and 'wheel' or active and 'trap_closed' or 'trap_open'
 g.push('all');g.setColor(1,1,1)
 if biome==5 then
  local a=art.frame(key)
  T.shader=T.shader or g.newShader([[
   vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px) {
    vec4 p=Texel(tex,uv);float l=dot(p.rgb,vec3(.299,.587,.114));
    vec3 earth=mix(vec3(.075,.029,.009),vec3(.76,.47,.22),l);
    return vec4(earth,p.a)*color;
   }
  ]])
  g.setShader(T.shader);g.draw(a.image,a.quad,x,y,angle or 0,size/a.w,size/a.w,a.w/2,a.h/2)
 else art.draw(key,x,y,size,angle) end
 g.pop()
end
return T
