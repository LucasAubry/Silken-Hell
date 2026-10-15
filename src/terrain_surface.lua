-- A cached distance field of the union removes brush seams. Collision and saved
-- points remain authored geometry; only the material follows its outer contour.
local S={cache={},serial=0,builds=0,transient=setmetatable({},{__mode='k'})}
local H=require('ground_holes')
local function extent(e)
 if e.points then local a,b,c,d=H.bounds(e);return e.x+a,e.y+b,e.x+c,e.y+d end
 return e.x-e.rx*1.4,e.y-e.ry*1.4,e.x+e.rx*1.4,e.y+e.ry*1.4
end
local function footprint(e,kind)
 if e.points then H.draw(e);return end
 local g=love.graphics
 if kind=='lava' then g.ellipse('fill',e.x,e.y,e.rx,e.ry);return end
 for j=0,63 do
  local a,b=j*math.pi/32,(j+1)*math.pi/32
  local function radius(t)return 1+.22*math.sin(t*3+(e.seed or 0))+.13*math.sin(t*7-(e.seed or 0))end
  g.polygon('fill',e.x,e.y,e.x+math.cos(a)*e.rx*radius(a),e.y+math.sin(a)*e.ry*radius(a),e.x+math.cos(b)*e.rx*radius(b),e.y+math.sin(b)*e.ry*radius(b))
 end
end
local function distance(cells,w,h)
 local d={};local diagonal=math.sqrt(2)
 for i=1,w*h do d[i]=cells[i] and 0 or 10000 end
 for y=0,h-1 do for x=0,w-1 do
  local i=y*w+x+1;local v=d[i]
  if x>0 then v=math.min(v,d[i-1]+1) end
  if y>0 then
   v=math.min(v,d[i-w]+1)
   if x>0 then v=math.min(v,d[i-w-1]+diagonal) end
   if x<w-1 then v=math.min(v,d[i-w+1]+diagonal) end
  end
  d[i]=v
 end end
 for y=h-1,0,-1 do for x=w-1,0,-1 do
  local i=y*w+x+1;local v=d[i]
  if x<w-1 then v=math.min(v,d[i+1]+1) end
  if y<h-1 then
   v=math.min(v,d[i+w]+1)
   if x>0 then v=math.min(v,d[i+w-1]+diagonal) end
   if x<w-1 then v=math.min(v,d[i+w+1]+diagonal) end
  end
  d[i]=v
 end end
 return d
end
function S.field(zones,kind)
 if #zones==0 then return end
 local key={kind};local x0,y0,x1,y1=math.huge,math.huge,-math.huge,-math.huge
 for _,e in ipairs(zones) do
  key[#key+1]=table.concat({e.x,e.y,e.rx or e.radius,e.ry or e.radius,e.seed or 0},',')
  if e.points then key[#key+1]=H.geometry(e).signature end
  local a,b,c,d=extent(e);x0=math.min(x0,a);y0=math.min(y0,b);x1=math.max(x1,c);y1=math.max(y1,d)
 end
 key=table.concat(key,';');S.serial=S.serial+1
 for _,entry in ipairs(S.cache) do if entry.key==key then entry.used=S.serial;return entry end end
 S.builds=S.builds+1
 local margin=kind=='hole' and 30 or 20
 x0=math.floor(x0-margin);y0=math.floor(y0-margin);x1=math.ceil(x1+margin);y1=math.ceil(y1+margin)
 local step=math.max(1.5,math.sqrt((x1-x0)*(y1-y0)/220000))
 local w,h=math.ceil((x1-x0)/step),math.ceil((y1-y0)/step)
 local g=love.graphics;local canvas=g.newCanvas(w,h,{dpiscale=1})
 g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.setShader();g.clear(0,0,0,0)
 g.setBlendMode('replace','premultiplied');g.setColor(1,1,1);g.scale(1/step);g.translate(-x0,-y0)
 for _,e in ipairs(zones) do footprint(e,kind) end
 g.pop()
 local mask=canvas:newImageData();canvas:release();local inside,outside={},{}
 for y=0,h-1 do for x=0,w-1 do
  local _,_,_,a=mask:getPixel(x,y);local i=y*w+x+1
  inside[i]=a>.5;outside[i]=not inside[i]
 end end
 mask:release()
 local toInside,toOutside=distance(inside,w,h),distance(outside,w,h)
 local data=love.image.newImageData(w,h)
 for y=0,h-1 do for x=0,w-1 do
  local i=y*w+x+1
  local d=(inside[i] and toOutside[i]-.5 or .5-toInside[i])*step
  data:setPixel(x,y,math.max(0,math.min(1,.5+d/128)),0,0,1)
 end end
 local texture=g.newImage(data);data:release();texture:setFilter('linear','linear')
 local entry={key=key,used=S.serial,image=texture,x=x0,y=y0,w=w*step,h=h*step,step=step}
 S.cache[#S.cache+1]=entry
 if #S.cache>6 then
  table.sort(S.cache,function(a,b)return a.used>b.used end)
  local expired=table.remove(S.cache)
  expired.image:release();if expired.surface then expired.surface:release() end
 end
 return entry
end
local function shader(field,kind,time,biome)
 local g=love.graphics
 S.shader=S.shader or g.newShader('assets/shaders/terrain_surface.glsl')
 S.shader:send('material',kind=='lava' and 1 or 0)
 S.shader:send('biome',biome)
 S.shader:send('clock',time or 0);S.shader:send('worldOrigin',{field.x,field.y})
 S.shader:send('worldSize',{field.w,field.h});S.shader:send('sampleStep',{1/field.image:getWidth(),1/field.image:getHeight()})
 return S.shader
end
local function bake(field,biome)
 if field.surface and field.surfaceBiome==biome then return field.surface end
 if field.surface then field.surface:release() end
 field.surfaceBiome=biome
 local g=love.graphics
 field.surface=g.newCanvas(math.ceil(field.w),math.ceil(field.h),{dpiscale=1})
 field.surface:setFilter('linear','linear')
 g.push('all');g.setCanvas(field.surface);g.origin();g.setScissor();g.clear(0,0,0,0)
 g.setBlendMode('alpha');g.setShader(shader(field,'hole',0,biome));g.setColor(1,1,1)
 g.draw(field.image,0,0,0,field.step,field.step);g.pop()
 return field.surface
end
local function drawSurface(zones,kind,time,alpha,biome)
 local field=S.field(zones,kind);if not field then return end
 local g=love.graphics;g.push('all')
 -- Stone lips never animate: shade once, then composite a single texture.
 if kind~='lava' then
  local image=bake(field,biome)
  g.setShader();g.setBlendMode('alpha','premultiplied')
  local a=alpha or 1;g.setColor(a,a,a,a);g.draw(image,field.x,field.y)
 else
  g.setShader(shader(field,kind,time,biome));g.setColor(1,1,1,alpha or 1)
  g.draw(field.image,field.x,field.y,0,field.step,field.step)
 end
 g.pop()
end
-- Small analytic masks share the stone material without joining the expensive
-- authored terrain cache. Both are shaded once, never during their animation.
local function analytic(x,y,w,h,step,signedDistance)
 local iw,ih=math.ceil(w/step),math.ceil(h/step)
 local data=love.image.newImageData(iw,ih)
 for row=0,ih-1 do for col=0,iw-1 do
  local d=signedDistance((col+.5)*step,(row+.5)*step)
  data:setPixel(col,row,math.max(0,math.min(1,.5+d/128)),0,0,1)
 end end
 local image=love.graphics.newImage(data);data:release();image:setFilter('linear','linear')
 return {x=x,y=y,w=iw*step,h=ih*step,step=step,image=image}
end
local function transientHole(p,alpha,biome)
 local g=love.graphics;local cached=S.transient[p]
 if cached and cached.biome~=biome then cached.image:release();cached=nil end
 local image=cached and cached.image
 if not image then
  local field=analytic(p.x-64,p.y-56,128,112,1,function(x,y)
   x,y=(x-64)/22,(y-56)/17.16
   local angle=math.atan2(y,x);local seed=p.seed or 0
   local radius=1+.22*math.sin(angle*3+seed)+.13*math.sin(angle*7-seed)
   return (radius-math.sqrt(x*x+y*y))*17.16
  end)
  image=bake(field,biome);field.image:release();S.transient[p]={image=image,biome=biome}
 end
 g.push('all');g.setShader();g.setBlendMode('alpha','premultiplied')
 local a=alpha or 1;g.setColor(a,a,a,a)
 g.draw(image,p.x,p.y,0,p.rx/22,p.ry/17.16,64,56);g.pop()
end
function S.draw(zones,kind,time,alpha,biome)
 biome=biome or (Campaign and Campaign.biome) or 2
 if kind~='hole' then return drawSurface(zones,kind,time,alpha,biome) end
 local fixed={}
 for _,p in ipairs(zones) do
  -- Lightning craters shrink every simulation tick. Never include their radius
  -- in the expensive distance field of the hand-painted, stationary terrain.
  if p.temporary and not p.points then transientHole(p,alpha,biome)
  else fixed[#fixed+1]=p end
 end
 drawSurface(fixed,kind,time,alpha,biome)
end
return S
