-- Hand-inked Paradise art is selected at render time; collision geometry is unchanged.
local P={images={},frames={}}
local g=love.graphics
local function metadata()
 if P.metadata then return P.metadata end
 P.metadata=require('json').decode(love.filesystem.read('assets/environments/paradis/encre-atlas.json'))
 for key,value in pairs(require('json').decode(love.filesystem.read('assets/environments/paradis/characters-ink.json'))) do P.metadata[key]=value end
 return P.metadata
end
function P.load()
 require('paradise_style').load()
 for key in pairs(metadata()) do P.frame(key);if Art.onLoad then Art.onLoad() end end
end
function P.active()
 return Campaign and Campaign.biome==1 and not (Secret and Secret.inArena())
end
function P.frame(key)
 if P.frames[key] then return P.frames[key] end
 local m=assert(metadata()[key],key)
 local image=P.images[m.path]
 if not image then image=require('art_filter').image(m.path);P.images[m.path]=image end
 local iw,ih=image:getDimensions()
 local a={image=image,quad=g.newQuad(m.x,m.y,m.w,m.h,iw,ih),w=m.w,h=m.h,source=m.source}
 P.frames[key]=a;return a
end
function P.draw(key,x,y,width,angle,height,flip)
 local a=P.frame(key);local sx=width/a.w;local sy=height and height/a.h or sx
 if key=='wheel' or key=='trap_open' or key=='trap_closed' or key=='nest' then
  require('sprite_relief').draw(a,x,y,width,angle,height);return
 end
 if flip then sx=-sx end
 if key=='egg' then
  Art.contactShadow(x,y+(height or a.h*sy)*.43,width*.50,(height or a.h*sy)*.10,.18)
 elseif key~='tear' then
  g.push()
  if key=='wheel' or key=='trap_open' or key=='trap_closed' or key=='nest' then g.translate(-4,-8) end
  Art.shadow(a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2)
  g.pop()
 end
 local previous=require('paradise_style').bind(a,key:match('^merle_') and 'bird' or key)
 g.draw(a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2)
 g.setShader(previous)
 require('servant_art').web(a,a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2)
end
local aliases={merle_egg='egg',nest='nest',wheel='wheel',catalog_ange='ange_down',catalog_snake='snake_down'}
function P.sprite(key)
 if not P.active() or key:match('^original_') or key:match('^spider_') then return end
 local name=aliases[key] or key
 if metadata()[name] then return P.frame(name) end
end
function P.art(key,x,y,width,angle,height)
 local a=P.sprite(key);if not a then return false end
 local original=Art.images[key]
 height=height or (original and width*original.h/original.w)
 P.draw(aliases[key] or key,x,y,width,angle,height);return true
end
function P.facing(name,dir,x,y,size)
 local key=name..'_'..(dir or 'down')
 local a=P.sprite(key);if not a then return false end
 local original=assert(Art.images[key]);local scale=size/math.max(original.w,original.h)
 P.draw(key,x,y,original.w*scale,0,original.h*scale);return true
end
function P.player(key,pose,width,p)
 local a=P.sprite(key);if not a then return end
 local original=assert(Art.images[key])
 -- Retain the original aspect ratio and walking rig after the style transfer.
 g.push();g.scale(1,(original.h/original.w)/(a.h/a.w))
 local walking=require('brown_walk').draw(a.image,pose,0,0,width,p,a.quad)
 if not walking then g.draw(a.image,a.quad,0,0,0,width/a.w,width/a.w,a.w/2,a.h/2) end
 g.pop();return true,walking
end
function P.tear(x,y,size)
 if not P.active() then return false end
 local a=P.frame('tear');local s=a.source
 P.draw('tear',x+(s.x+s.w/2)*size,y+(s.y+s.h/2)*size,s.w*size,0,s.h*size)
 return true
end
function P.mob(m)
 if not P.active() then return false end
 if m.type=='ange' or m.type=='snake' then
  if not m.img then return true end
  local key=m.type..'_'..(m.dir or 'down');local a=P.frame(key);local s=a.source
  local float=require('mobs.shared.floating').offset(m)
  -- The source canvas/pivot and visible size stay aligned with existing hitboxes.
  g.push();g.translate(m.x,m.y+float);g.rotate(m.rotation or 0)
  P.draw(key,(s.x+s.w/2-s.iw/2)*m.size,(s.y+s.h/2-s.ih/2)*m.size,s.w*m.size,0,s.h*m.size)
  g.pop();return true
 end
 if m.type=='scie' then
  local x,y=m.tipX or m.x,m.tipY or m.y
  g.push('all');g.setShader()
  g.setColor(.24,.18,.105,.24);g.setLineWidth(9);g.line(m.x+4,m.y+6,x+4,y+6)
  g.setColor(.15,.17,.18);g.setLineWidth(11);g.line(m.x,m.y,x,y)
  g.setColor(.60,.61,.55);g.setLineWidth(8);g.line(m.x,m.y-1,x,y-1)
  local length=math.sqrt((x-m.x)^2+(y-m.y)^2)
  for i=0,math.floor(length/7) do
   local t=length>0 and i*7/length or 0
   local px,py=m.x+(x-m.x)*t,m.y+(y-m.y)*t
   g.setColor(.12,.15,.16);g.circle('fill',px,py,2.3)
   g.setColor(.9,.88,.75,.65);g.arc('line','open',px,py,2.7,0,math.pi,8)
  end
  g.setColor(.16,.19,.20);g.circle('fill',m.x,m.y,5)
  g.setColor(.85,.81,.65);g.setLineWidth(1);g.circle('line',m.x,m.y,4)
  g.setColor(1,1,1);P.draw('wheel',x,y,60,m.rotation or 0);g.pop()
  return true
 elseif m.type=='piege' then
  P.draw(m.active and 'trap_closed' or 'trap_open',m.x,m.y,52)
  return true
 end
 return false
end
function P.edge(length)
 local a=P.frame('border');local tile=176
 g.push('all');g.setColor(1,1,1)
 require('paradise_style').bind(a,'border')
 for x=0,length-1,tile do
  local w=math.min(tile,length-x)
  if w==tile then g.draw(a.image,a.quad,x,0,0,tile/a.w,22/a.h)
  else
   local qx,qy=a.quad:getViewport()
   P.edgeQuad=P.edgeQuad or g.newQuad(0,0,1,1,a.image:getDimensions())
   P.edgeQuad:setViewport(qx,qy,a.w*w/tile,a.h,a.image:getDimensions())
   g.draw(a.image,P.edgeQuad,x,0,0,tile/a.w,22/a.h)
  end
 end
 g.setShader();g.setColor(.25,.22,.16,.28);g.setLineWidth(1);g.line(0,22,length,22)
 g.pop()
end
function P.wall(r)
 g.push('all');g.setShader()
 g.setColor(.27,.205,.12,.16);g.rectangle('fill',r.x+3,r.y+5,r.w,r.h)
 if r.w>=r.h then g.translate(r.x,r.y)
 else g.translate(r.x+r.w,r.y);g.rotate(math.pi/2) end
 local length,depth=math.max(r.w,r.h),math.min(r.w,r.h)
 local rows=math.max(1,math.ceil(depth/22));local height=depth/rows
 for row=0,rows-1 do
  g.push();g.translate(0,row*height);g.scale(1,height/22);P.edge(length);g.pop()
 end
 g.pop()
end
return P
