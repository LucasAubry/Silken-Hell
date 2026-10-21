-- Incremental capsule mask; same cloud material and union distance as biome snails.
local G={}
function G.draw(s)
 if #s.holes==0 then return end
 local g=love.graphics;local width=math.ceil(Arena.width)
 if not s.groundCache or s.groundCache.width~=width then
  if s.groundCache then for _,k in ipairs({'canvas','distanceA','distanceB','distanceResult'})do local v=s.groundCache[k];if v then v:release()end end end
  s.groundCache={width=width,canvas=g.newCanvas(width,600,{dpiscale=1})}
 end
 local cache=s.groundCache
 local rebuild=cache.list~=s.holes or cache.revision~=s.groundRevision or (cache.count or 0)>#s.holes
 if rebuild or cache.count~=#s.holes then
  G.shader=G.shader or g.newShader('assets/shaders/snail_hole_mask.glsl')
  g.push('all');g.setCanvas(cache.canvas);g.origin();g.setScissor();g.setShader(G.shader)
  if rebuild then g.clear(0,0,0,1);cache.count=0 end
  g.setBlendMode('lighten','premultiplied');g.setColor(1,1,1)
  local dirty={math.huge,math.huge,-math.huge,-math.huge}
  for i=(cache.count or 0)+1,#s.holes do local p=s.holes[i]
   if p.radius>0 then
    local margin=p.radius+18
    local x,y=math.min(p.x,p.tx)-margin,math.min(p.y,p.ty)-margin
    local xx,yy=math.max(p.x,p.tx)+margin,math.max(p.y,p.ty)+margin
    G.shader:send('ends',{p.x,p.y,p.tx,p.ty});G.shader:send('radius',p.radius)
    g.rectangle('fill',x,y,xx-x,yy-y)
    dirty[1]=math.min(dirty[1],x);dirty[2]=math.min(dirty[2],y);dirty[3]=math.max(dirty[3],xx);dirty[4]=math.max(dirty[4],yy)
   end
  end
  g.pop()
  require('hole_union_distance').build(cache.canvas,cache,rebuild and nil or dirty)
  cache.count=#s.holes;cache.list=s.holes;cache.revision=s.groundRevision
 end
 require('terrain_surface').drawSkyField({image=cache.distanceResult,x=0,y=0,w=width,h=600,step=1},1)
end
return G
