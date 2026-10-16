-- Shared transparent monster PNGs in the same pixel-art style as the spider.
local A={images={}}
local paths={wind_bat='assets/monstres/ciel/chauve_souris/wind_bat.png',lava_scorpion='assets/monstres/enfer/scorpion/lava_scorpion.png',dragonfly='assets/monstres/ciel/libellule/electric_dragonfly.png',mist_moth='assets/monstres/ciel/papillon/mist_moth.png'}
local directional={wind_bat=true,lava_scorpion=true}
function A.facing(angle)
 local x,y=-math.sin(angle or 0),math.cos(angle or 0)
 if math.abs(x)>math.abs(y) then return x<0 and 'left' or 'right' end
 return y<0 and 'up' or 'down'
end
function A.sprite(kind,dir)
 dir=directional[kind] and (dir or 'down') or 'down'
 if dir=='left' then dir='right' end
 local key=kind..'_'..dir
 if A.images[key] then return A.images[key] end
 local path=assert(paths[kind])
 if dir~='down' then path=path:gsub('%.png$','_'..dir..'.png') end
 local g=love.graphics;local data=love.image.newImageData(path)
 local w,h=data:getDimensions();local x0,y0,x1,y1=w,h,0,0
 for y=0,h-1 do for x=0,w-1 do
  local _,_,_,a=data:getPixel(x,y)
  if a>.12 then x0=math.min(x0,x);x1=math.max(x1,x);y0=math.min(y0,y);y1=math.max(y1,y) end
 end end
 local image=g.newImage(data);data:release();image:setFilter('nearest','nearest')
 local sprite={image=image,w=x1-x0+1,h=y1-y0+1}
 sprite.quad=g.newQuad(x0,y0,sprite.w,sprite.h,w,h);A.images[key]=sprite
 return sprite
end
-- Wing tips flex while the bat's head and torso remain stable.
local function batWings(sprite,time,side)
 local g=love.graphics;local qx,qy,qw,qh=sprite.quad:getViewport()
 local iw,ih=sprite.image:getDimensions();local vertices={};local columns,rows=12,6
 local function vertex(u,v)
  local weight=side and math.max(0,(.7-u)/.7) or math.max(0,(math.abs(u-.5)-.19)/.31)
  weight=weight*weight
  local flap=math.sin(time*13)
  local x=(u-.5)*qw*(1-weight*(.13-.1*flap))
  local y=(v-.5)*qh+weight*flap*qh*.13
  return {x,y,(qx+u*qw)/iw,(qy+v*qh)/ih}
 end
 for row=0,rows-1 do for col=0,columns-1 do
  local u,v=col/columns,row/rows;local uu,vv=(col+1)/columns,(row+1)/rows
  for _,uv in ipairs({{u,v},{uu,v},{uu,vv},{u,v},{uu,vv},{u,vv}}) do vertices[#vertices+1]=vertex(uv[1],uv[2]) end
 end end
 if not sprite.mesh then sprite.mesh=g.newMesh(vertices,'triangles','stream');sprite.mesh:setTexture(sprite.image)
 else sprite.mesh:setVertices(vertices) end
 return sprite.mesh
end
function A.draw(kind,x,y,size,time,angle)
 local g=love.graphics;local moth=kind=='mist_moth';local t=time or 0
 local dir=directional[kind] and A.facing(angle) or 'down'
 local sprite=A.sprite(kind,dir)
 -- Keep every pose inside the same footprint, without rotating its anatomy.
 local extent=directional[kind] and math.max(sprite.w,sprite.h) or sprite.w
 local scale=(size or 72)/extent
 local mirror=dir=='left' and -1 or 1
 local flap=(kind=='wind_bat' or kind=='lava_scorpion') and 1 or moth and (.9+.1*math.cos(t*11)) or (.94+.06*math.cos(t*39))
 g.push('all');g.translate(x,y)
 if not directional[kind] then g.rotate(angle or 0) end
 if require('art').shadowAllowed() then
  g.setColor(.015,.035,.08,.20);g.ellipse('fill',2,9,(size or 72)*.33,10)
 end
 g.setColor(1,1,1)
 if kind=='wind_bat' then
  g.draw(batWings(sprite,t,dir=='left' or dir=='right'),0,math.sin(t*5)*1.4,0,scale*mirror,scale)
 else
  g.draw(sprite.image,sprite.quad,0,math.sin(t*5)*1.4,0,scale*flap*mirror,scale,sprite.w/2,sprite.h/2)
 end
 if kind=='dragonfly' then
  g.setColor(.7,.92,1,.7);g.setLineWidth(1)
  local a=math.floor(t*12);local r=(size or 72)*.33
  for side=-1,1,2 do
   g.line(side*r,-5,side*(r+4),-10+math.sin(a)*3,side*(r+7),-4)
  end
 end
 g.pop()
end
return A
