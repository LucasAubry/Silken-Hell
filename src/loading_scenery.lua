-- A small bootstrap scene: only the real spider and silk are needed before preload.
local S={}
local g=love.graphics
local anchors={{55,105},{195,-30},{450,-20},{640,65},{700,290},{600,455},{190,420},{100,285}}
local function glow(x,y,r,c,alpha)
 g.setBlendMode('add')
 g.setColor(c[1],c[2],c[3],alpha*.55);g.draw(S.halo,x,y,0,r,r)
 g.setBlendMode('alpha')
end
local function thread(x,y,xx,yy,alpha)
 local a=S.strand;local dx,dy=xx-x,yy-y;local length=math.sqrt(dx*dx+dy*dy)
 local t=math.max(0,math.min(1,((x+xx)/2-500)/600))
 local r,gg,b=1-.3*t,.83-.02*t,.47+.48*t
 g.setBlendMode('add');g.setColor(r,gg,b,(alpha or .8)*.08);g.setLineWidth(4);g.line(x,y,xx,yy);g.setBlendMode('alpha')
 g.setColor(r,gg,b,alpha or .8);g.setLineWidth(1);g.line(x,y,xx,yy)
 g.setColor(1,.94,.75,alpha or .8)
 g.draw(a.image,a.quad,(x+xx)/2,(y+yy)/2,math.atan2(-dx,dy),4/a.w,length/a.h,a.w/2,a.h/2)
end
local function curve(x,y,xx,yy,sag,alpha)
 local px,py=x,y
 for i=1,12 do local t=i/12;local nx,ny=x+(xx-x)*t,y+(yy-y)*t+math.sin(t*math.pi)*sag
  thread(px,py,nx,ny,alpha);px,py=nx,ny
 end
end
function S.load()
 Art.add('original','assets/skins/base_marron/down.png')
 Art.add('silk_strand','assets/effects/silk/strand.png')
 S.spider=Art.images.original;S.strand=Art.images.silk_strand
 S.shader=g.newShader('assets/shaders/loading_crevasse.glsl')
 local vertices={{0,0,0,0,1,1,1,1}}
 for i=0,48 do local a=i*math.pi/24;vertices[#vertices+1]={math.cos(a),math.sin(a),0,0,1,1,1,0} end
 S.halo=g.newMesh(vertices,'fan','static')
 S.spiderShader=g.newShader('assets/shaders/loading_spider.glsl')
 S.spiderShader:send('texel',{1/S.spider.image:getWidth(),1/S.spider.image:getHeight()})
 S.pixel=g.newImage(love.image.newImageData(1,1))
end
function S.draw(w,h,time)
 g.setShader(S.shader);S.shader:send('time',time);S.shader:send('foregroundOnly',0)
 g.setColor(1,1,1);g.draw(S.pixel,0,0,0,w,h);g.setShader()
 local scale=math.min(w/1200,h/750)
 g.translate(w/2,h/2);g.scale(scale);g.translate(-600,-375)
 local sway=math.sin(time*.6)*2
 g.push();g.translate(0,sway)
 local cx,cy=355,255
 for _,p in ipairs(anchors) do curve(cx,cy,p[1],p[2],5,.85) end
 for ring=1,5 do
  local t=ring/6
  for i,p in ipairs(anchors) do
   local q=anchors[i%#anchors+1]
   curve(cx+(p[1]-cx)*t,cy+(p[2]-cy)*t+math.sin(t*math.pi)*5,cx+(q[1]-cx)*t,cy+(q[2]-cy)*t+math.sin(t*math.pi)*5,12*t,.85)
  end
 end
 -- Single support strands continue out of the web into the rock face.
 curve(640,65,1280,10,85,.6)
 curve(700,290,1280,210,80,.75)
 curve(600,455,1280,560,38,.75)
 -- Only the two lower spokes are extended, beneath the foreground rocks.
 curve(190,420,-250,860,5,.85)
 -- Silk contacts sit under the actual feet, with the same sway as the web.
 local sx,sy=265,167
 for _,v in ipairs({{-48,-20},{-52,5},{-45,30},{46,-20},{51,5},{44,30}}) do
  curve(sx+v[1],sy+v[2],cx,cy,8,.65)
 end
 glow(sx,sy,100,{.12,.75,.63},.18)
 local a=S.spider;local size=122/math.max(a.w,a.h)
 g.setShader(S.spiderShader);S.spiderShader:send('breath',.98+.02*math.sin(time*1.5))
 g.setColor(1,1,1);g.draw(a.image,a.quad,sx,sy,.12+math.sin(time*.6)*.008,size,size*(1+math.sin(time*1.5)*.007),a.w/2,a.h/2)
 g.setShader();g.pop()
 for i=1,25 do
  local x=160+(i*137+math.sin(time*.23+i)*13)%900
  local y=65+(i*89-time*(2+i%3))%470
  local c=i%3==0 and {.12,.95,.88} or {1,.69,.22}
  local alpha=.65+.25*math.sin(time*.8+i)
  local r=i%5==0 and 3 or 1.6
  glow(x,y,r*7,c,alpha)
  g.setColor(c[1],c[2],c[3],alpha);g.polygon('fill',x,y-r,x+r*.7,y,x,y+r,x-r*.7,y)
 end
 g.setColor(.94,.91,.82);g.printf('Chargement des assets…',300,580,600,'center')
 curve(-100,630,1300,630,26,1)
 local x=600+math.sin(time*.85)*330;local y=630+math.sin((x+100)/1400*math.pi)*26
 glow(x,y,35,{1,.65,.18},1)
 g.setColor(1,.87,.57);g.polygon('fill',x,y-5,x+5,y,x,y+5,x-5,y)
 -- Repaint only the foreground rocks, so every silk attachment is occluded
 -- by the exact same silhouette at any window aspect ratio.
 g.push();g.origin();g.setShader(S.shader);S.shader:send('foregroundOnly',1)
 g.setColor(1,1,1);g.draw(S.pixel,0,0,0,w,h);g.setShader();g.pop()
end
function S.release()
 S.halo:release();S.halo=nil
 S.spiderShader:release();S.spiderShader=nil
 S.shader:release();S.pixel:release();S.shader=nil;S.pixel=nil
 -- Sprite textures stay in the shared art cache for the menu and game.
 S.spider=nil;S.strand=nil
end
return S
