-- Hand-inked Paradise art is selected at render time; collision geometry is unchanged.
local P={images={},frames={}}
local g=love.graphics
function P.active()
 return Campaign and Campaign.biome==1 and not (Secret and Secret.inArena())
end
function P.frame(key)
 if P.frames[key] then return P.frames[key] end
 P.metadata=P.metadata or require('json').decode(love.filesystem.read('assets/environments/paradis/encre-atlas.json'))
 local m=assert(P.metadata[key],key)
 local image=P.images[m.path]
 if not image then image=g.newImage(m.path,{mipmaps=true});image:setFilter('linear','linear');P.images[m.path]=image end
 local iw,ih=image:getDimensions()
 local a={image=image,quad=g.newQuad(m.x,m.y,m.w,m.h,iw,ih),w=m.w,h=m.h}
 P.frames[key]=a;return a
end
function P.draw(key,x,y,width,angle,height,flip)
 local a=P.frame(key);local sx=width/a.w;local sy=height and height/a.h or sx
 if flip then sx=-sx end
 Art.shadow(a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2)
 g.draw(a.image,a.quad,x,y,angle or 0,sx,sy,a.w/2,a.h/2)
end
local aliases={merle_egg='egg',nest='nest',wheel='wheel'}
function P.art(key,x,y,width,angle,height)
 if not P.active() then return false end
 local name=aliases[key];if not name then return false end
 P.draw(name,x,y,width,angle,height);return true
end
function P.mob(m)
 if not P.active() then return false end
 if m.type=='scie' then
  local x,y=m.tipX or m.x,m.tipY or m.y
  g.push('all');g.setColor(.13,.16,.20);g.setLineWidth(4);g.line(m.x,m.y,x,y)
  g.setColor(.62,.65,.66);g.setLineWidth(1)
  for i=0,7 do local t=i/8;g.circle('line',m.x+(x-m.x)*t,m.y+(y-m.y)*t,2.3) end
  g.setColor(.16,.19,.23);g.circle('fill',m.x,m.y,6)
  g.setColor(.77,.78,.73);g.circle('line',m.x,m.y,4)
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
 g.setColor(.18,.20,.24,.28);g.setLineWidth(1);g.line(0,22,length,22)
 g.pop()
end
return P
