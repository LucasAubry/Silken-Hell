-- Cross the sealed waterline of a dry abyssal shaft, leaving the lamp underwater.
local S={duration=9.95,impact=9.8}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function S.begin()
 S.age=0;S.actor={walkMoving=false}
 if S.environment then S.environment:release();S.environment=nil end
 return S.duration
end
function S.captureEnvironment(canvas)
 if S.environment then return end
 local g=love.graphics;local previous=g.getCanvas()
 S.environment=g.newCanvas(canvas:getWidth(),canvas:getHeight(),{dpiscale=canvas:getDPIScale()})
 g.push('all');g.setCanvas(S.environment);g.origin();g.setShader();g.clear()
 g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(canvas);g.setCanvas(previous);g.pop()
end
function S.pose(t)
 local land=ease((t-5.8)/4)
 local camera=.055*math.max(0,t-2)^2
 local jump=ease((t-.3)/1.1)
 return {x=.34+.16*jump,y=.43-.065*math.sin(jump*math.pi)+.055*math.max(0,t-1.4)^2-camera,
  camera=camera,progress=land,size=1.65-.65*land,depth=camera/1.35,heat=ease((t-3.3)/3.5),
  mapAlpha=land,actorsAlpha=land,bubble=1-ease((t-2.65)/.45),release=ease((t-2.65)/.45),
  blur=14*(1-ease((t-2.65)/7.15)),
  detached=t>=2.65,broken=t>=2.95,dir=t<1.4 and 'right' or t<5.8 and 'down' or 'up'}
end
function S.position(t,w,h,sx,sy)
 local p=S.pose(t);local x,y=w*p.x,h*p.y
 return x+(sx-x)*p.progress,y+(sy-y)*p.progress
end
function S.advance(age)
 local old=S.age;S.age=age
 require('brown_walk').advance(S.actor,age<1.4 and math.abs(S.pose(age).x-S.pose(old).x)*Arena.width or 0,math.max(0,age-old))
end
-- Filter the complete live scene together, including lava, lighting and creatures.
function S.drawDepth(canvas,w,h,radius,shader)
 local g=love.graphics
 if radius<.01 then
  require('transition_scenery').reveal(canvas,nil,w,h,1,1,shader);return
 end
 local cw,ch=canvas:getDimensions()
 if not S.blurA or S.blurA:getWidth()~=cw or S.blurA:getHeight()~=ch then
  if S.blurA then S.blurA:release();S.blurB:release() end
  S.blurA=g.newCanvas(cw,ch);S.blurB=g.newCanvas(cw,ch)
 end
 S.blurShader=S.blurShader or g.newShader('assets/shaders/arrival_depth_blur.glsl')
 local previous=g.getCanvas()
 g.push('all');g.origin();g.setColor(1,1,1);g.setBlendMode('replace')
 g.setShader(S.blurShader)
 S.blurShader:send('stepUV',{radius/cw,0})
 g.setCanvas(S.blurA);g.clear();g.draw(canvas)
 S.blurShader:send('stepUV',{0,radius/ch})
 g.setCanvas(S.blurB);g.clear();g.draw(S.blurA)
 g.setCanvas(previous);g.pop()
 require('transition_scenery').reveal(S.blurB,nil,w,h,1,1,shader)
end
function S.draw(canvas,w,h)
 local g=love.graphics;local shader=g.getShader();local t=S.age;local p=S.pose(t)
 local decor=require('transition_scenery');local bubble=require('breathing_bubble');local silk=require('silk_art')
 local scale,x,y=App.viewport(w,h);local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
 local ax,ay=S.position(t,w,h,sx,sy);local size=Characters.playerWidth*scale*p.size
 g.push('all');g.origin();g.setShader()
 S.drawDepth(canvas,w,h,p.blur,shader)
 S.scenery=S.scenery or g.newShader('assets/shaders/abyss_hell_passage.glsl')
 S.scenery:send('dimensions',{w,h});S.scenery:send('clock',t);S.scenery:send('depth',p.depth)
 S.scenery:send('camera',p.camera);S.scenery:send('heat',p.heat)
 S.scenery:send('landing',p.progress)
 g.setShader(S.scenery);g.setColor(1,1,1);g.rectangle('fill',0,0,w,h);g.setShader()
 local waterline=h*(.58-p.camera)
 -- Suspended particles remain above the sealed surface; there is no waterfall.
 for i=1,50 do
  local px=w*((i*.618+math.sin(t*.3+i)*.008)%1);local py=h*((i*.137)% .58-p.camera)
  if py<waterline then g.setColor(.22,.65,.85,.25);g.circle('fill',px,py,(.7+i%3*.4)*scale) end
 end
 -- Only a few drops follow the spider through the meniscus.
 for i=1,7 do
  local age=t-2.65-i*.035
  if age>0 and age<1.5 then
   g.setColor(.45,.8,.95,(1-age/1.5)*.65)
   g.ellipse('fill',w*.5+math.sin(i*2.4)*16*scale,h*(.58+.13*age+.22*age*age-p.camera),scale,2.5*scale)
  end
 end
 Characters.shadow(sx,sy,Characters.playerWidth*scale,p.dir,S.actor,p.mapAlpha)
 g.setColor(1,1,1);Characters.draw(ax,ay,size,p.dir,S.actor,2)
 local hx,hy,r=bubble.headPosition(ax,ay,size,p.dir)
 if p.bubble>0 and not require('integrated_skins').bubble(Characters.selected()) then
  bubble.drawAt(hx,hy,r,t,false,nil,nil,p.bubble,p.dir)
 end
 if not p.detached then bubble.drawLantern(hx,hy,r,t,nil,1,p.dir)
 else
  -- The buoyant lamp remains at a fixed depth in the water as the camera falls.
  local lampX=w*.5+math.sin((t-2.65)*2)*3*scale
  local lampY=h*(.55-p.camera);local lampR=Characters.playerWidth*scale*1.65*.19
  bubble.drawLantern(lampX,lampY,lampR,t,nil,1,'down')
  local lx,ly=bubble.lanternPosition(lampX,lampY,lampR,t,'down')
  if not p.broken then silk.thread(hx,hy,lx,ly,2*scale,1)
  else
   local recoil=ease((t-2.95)/.6);local alpha=1-ease((t-3.2)/.5)
   silk.thread(lx,ly,lx+math.sin(t*12)*5*scale,ly+(1-recoil)*20*scale,2*scale,1)
   silk.thread(hx,hy,hx-5*scale,hy-(1-recoil)*20*scale,2*scale,alpha)
  end
 end
 g.pop()
end
return require('arrival_timing').fit(S)
