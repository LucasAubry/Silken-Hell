-- Capsule masks share the cloud material used by biome snails.
local G={}
local function bounds(p)
 local m=p.radius+18
 return math.min(p.x,p.tx)-m,math.min(p.y,p.ty)-m,math.max(p.x,p.tx)+m,math.max(p.y,p.ty)+m
end
function G.draw(s)
 if #s.holes==0 then
  if s.groundCache then s.groundCache.empty=true end
  return
 end
 local g=love.graphics;local width=math.ceil(Arena.width)
 if not s.groundCache or s.groundCache.width~=width then
  if s.groundCache then for _,k in ipairs({'canvas','distanceA','distanceB','distanceResult'})do local v=s.groundCache[k];if v then v:release()end end end
  s.groundCache={width=width,canvas=g.newCanvas(width,600,{dpiscale=1}),snapshots={}}
 end
 local cache=s.groundCache;local dirty={math.huge,math.huge,-math.huge,-math.huge};local active=false
 local function include(p)
  if not p or p.radius<=0 then return end
  local x,y,xx,yy=bounds(p)
  dirty[1]=math.min(dirty[1],x);dirty[2]=math.min(dirty[2],y);dirty[3]=math.max(dirty[3],xx);dirty[4]=math.max(dirty[4],yy)
 end
 local full=cache.list~=s.holes or cache.empty
 for i=1,math.max(#s.holes,#cache.snapshots)do
  local p,old=s.holes[i],cache.snapshots[i]
  if p and p.radius>0 then active=true end
  if full or not p or not old or p.radius~=old.radius or p.x~=old.x or p.y~=old.y or p.tx~=old.tx or p.ty~=old.ty then
   include(old);include(p)
   cache.snapshots[i]=p and {x=p.x,y=p.y,tx=p.tx,ty=p.ty,radius=p.radius} or nil
  end
 end
 cache.list=s.holes;cache.empty=not active
 if not active then return end
 if full or dirty[1]<dirty[3] then
  G.shader=G.shader or g.newShader('assets/shaders/snail_hole_mask.glsl')
  g.push('all');g.setCanvas(cache.canvas);g.origin();g.setScissor()
  if not full then
   local x,y=math.max(0,math.floor(dirty[1])),math.max(0,math.floor(dirty[2]))
   local xx,yy=math.min(width,math.ceil(dirty[3])),math.min(600,math.ceil(dirty[4]))
   g.setScissor(x,y,math.max(0,xx-x),math.max(0,yy-y))
  end
  g.clear(0,0,0,1);g.setShader(G.shader);g.setBlendMode('lighten','premultiplied');g.setColor(1,1,1)
  for _,p in ipairs(s.holes)do if p.radius>0 then
   local x,y,xx,yy=bounds(p)
   if full or (xx>=dirty[1] and yy>=dirty[2] and x<=dirty[3] and y<=dirty[4]) then
    G.shader:send('ends',{p.x,p.y,p.tx,p.ty});G.shader:send('radius',p.radius)
    g.rectangle('fill',x,y,xx-x,yy-y)
   end
  end end
  g.pop()
  if active then
   local region;if not full then region=dirty end
   require('hole_union_distance').build(cache.canvas,cache,region)
  end
 end
 -- A cached distance field must never resurrect the last erased scar.
 if active then require('terrain_surface').drawSkyField({image=cache.distanceResult,x=0,y=0,w=width,h=600,step=1},1)end
end
return G
