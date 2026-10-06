-- Boss servants have authored skins; accumulated silk leaves the body palette intact.
local S={frames={},current=nil}
function S.load()
 local frames=require('json').decode(love.filesystem.read('assets/monstres/serviteurs/frames.json'))
 for key,f in pairs(frames) do
  local image=require('art_filter').image(f.path);local w,h=image:getDimensions()
  S.frames[key]={image=image,quad=love.graphics.newQuad(f.x,f.y,f.w,f.h,w,h),w=f.w,h=f.h}
 end
 S.webImage=require('art_filter').image('assets/effects/silk/web.png')
 S.shader=love.graphics.newShader([[
 extern Image silk;extern vec4 bounds;extern float amount;
 vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px){
  vec4 body=Texel(tex,uv);vec2 localUV=(uv-bounds.xy)/bounds.zw;
  vec4 web=Texel(silk,clamp(localUV,0.,1.));
  return vec4(vec3(.93,.91,.83),web.a*body.a*amount*color.a);
 }]])
 S.shader:send('silk',S.webImage)
end
function S.variant(key)
 if key:match('^mole_') then return nil end -- All moles use their normal directional art.
 return S.current and S.current.bossServant and S.frames[key]
end
function S.image(key) return S.variant(key) or require('art').images[key] end
function S.amount(world,level)
 local rank=Worlds.rank(world or (Campaign and Campaign.world) or 1)
 if Worlds.isSecret(world or Campaign.world) then rank=Worlds.rank(Worlds.biome(world or Campaign.world)) end
 return .07+(math.min(7,math.max(1,rank))-1)*.055+math.min(9,math.max(0,(level or player.level or 1)-1))*.004
end
function S.web(a,...)
 if not S.current or not S.shader then return end
 if S.current.type=='piege' or S.current.type=='scie' or S.current.ground then return end
 local x,y,w,h=a.quad:getViewport();local iw,ih=a.image:getDimensions()
 local g=love.graphics;g.push('all');g.setShader(S.shader)
 S.shader:send('bounds',{x/iw,y/ih,w/iw,h/ih});S.shader:send('amount',S.amount())
 g.draw(...);g.pop()
end
return S
