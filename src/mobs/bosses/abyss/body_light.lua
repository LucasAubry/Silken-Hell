local L={}
function L.apply(a,b)
 local g=love.graphics
 L.shader=L.shader or g.newShader([[
 extern vec4 spriteRect;
 extern vec4 pose;
 extern float angle;
 extern float clock;
 extern float baseLight;
 extern vec2 playerLight;
 extern vec4 boltLight;
 vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen) {
  vec4 pixel=Texel(tex,uv);
  vec2 local=(uv-spriteRect.xy)/spriteRect.zw-vec2(.5);
  local*=pose.zw;
  vec2 world=pose.xy+mat2(cos(angle),sin(angle),-sin(angle),cos(angle))*local;
  float ripple=sin(world.x*.014+clock*.7)*sin(world.y*.021-clock*.45);
  float glint=pow(max(0.,ripple),4.)*.19;
  float nearby=exp(-dot(world-playerLight,world-playerLight)/6500.)*.32;
  float bolt=exp(-dot(world-boltLight.xy,world-boltLight.xy)/1700.)*boltLight.z;
  float light=min(.8,baseLight+glint+nearby+bolt);
  return vec4(pixel.rgb*vec3(.62,.82,1.)*light,pixel.a)*color;
 }
 ]])
 local sprite=Art.images[b.key];local x,y,w,h=sprite.quad:getViewport();local iw,ih=sprite.image:getDimensions()
 L.shader:send('spriteRect',{x/iw,y/ih,w/iw,h/ih})
 L.shader:send('pose',{b.x,b.y,b.w,b.h});L.shader:send('angle',b.angle or 0)
 L.shader:send('clock',a.clock);L.shader:send('baseLight',b.part=='head' and .41 or b.part=='tail' and .34 or b.part==a.webPartIds[#a.webPartIds] and .24 or .14)
 L.shader:send('playerLight',{player.x+15,player.y+12})
 local best,dist
 for _,p in ipairs(a.returnShots)do if p.lightning then local d=(p.x-b.x)^2+(p.y-b.y)^2;if not dist or d<dist then best,dist=p,d end end end
 L.shader:send('boltLight',best and {best.x,best.y,.65,0} or {0,0,0,0})
 g.setShader(L.shader);g.setColor(1,1,1)
end
function L.lights(a,lights)
 for _,b in ipairs(a.bones)do if #lights<24 and (b.part=='head' or b.part=='tail')then
  lights[#lights+1]={b.x,b.y,b.part=='head' and 100 or 75,.15}
 end end
 for _,p in ipairs(a.returnShots)do if p.lightning and #lights<24 then lights[#lights+1]={p.x,p.y,65,.35} end end
end
return L
