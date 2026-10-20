-- A volcanic updraft launches the swimmer into a silk swing over the Hell arena.
local motion=require('cinematic_motion')
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
 local land=ease((t-6.8)/3)
 local angle=motion.sample({{4.2,-.68,0},{5.6,.58,0},{6.8,0,0}},t)
 local startX,startY=.53+.42*math.sin(-.68),-.08+.57*math.cos(-.68)
 local x=motion.sample({{0,.28,0},{1.3,.32,0},{2.8,.32,0},{3.5,.28,-.05},{4.2,startX,0}},t)
 local y=motion.sample({{0,.70,0},{1.3,.64,-.12},{2.8,.40,-.24},{3.5,.18,0},{4.2,startY,0}},t)
 if t>=4.2 then x=.53+.42*math.sin(angle);y=-.08+.57*math.cos(angle) end
 local release=ease((t-3.1)/.45)
 return {x=x,y=y,progress=land,size=1.65-.65*land,
  waterline=.25+.95*ease((t-2.8)/3),opening=ease((t-3.3)/3.5),
  silk=ease((t-3.65)/.55)*(1-ease((t-6.8)/.4)),angle=angle,
  mapAlpha=land,actorsAlpha=land,bubble=1-release,release=release,
  blur=14*(1-ease((t-2.65)/7.15)),
  detached=t>=3.1,broken=t>=3.35,dir=t<3.1 and 'up' or t<5.6 and 'right' or t<6.8 and 'left' or 'up'}
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
 S.scenery:send('dimensions',{w,h});S.scenery:send('clock',t)
 S.scenery:send('waterline',p.waterline);S.scenery:send('opening',p.opening)
 g.setShader(S.scenery);g.setColor(1,1,1);g.rectangle('fill',0,0,w,h);g.setShader()
 -- Bubbles accelerate up the vent and break at the receding surface.
 for i=1,70 do
  local speed=.12+i%5*.035
  local py=h*(p.waterline+((i*.137-t*speed)%1)*1.2)
  local px=w*(.32+math.sin(i*2.4+t*.7)*(.035+i%4*.018))
  if py<h+20 then
   g.setColor(.36,.72,.83,.22);g.setLineWidth(scale)
   g.circle('line',px,py,(2+i%5)*scale)
   g.setColor(.72,.91,.94,.32);g.circle('fill',px-scale,py-scale,scale)
  end
 end
 -- The launch throws only spray into the dry chamber; the lamp stays afloat below.
 for i=1,18 do
  local age=t-3.1-i*.008
  if age>0 and age<1.7 then
   g.setColor(.55,.85,.95,(1-age/1.7)*.65)
   g.ellipse('fill',w*(.32+math.sin(i*2.4)*age*.11),h*(.30-.24*age+.48*age*age),scale,2.5*scale)
  end
 end
 if p.silk>0 then
  local attachX,attachY=w*.53,-h*.08
  local thread=ease((t-3.65)/.55)
  silk.thread(ax,ay+size*.12,ax+(attachX-ax)*thread,ay+(attachY-ay)*thread,3.5*scale,p.silk)
 end
 Characters.shadow(sx,sy,Characters.playerWidth*scale,p.dir,S.actor,p.mapAlpha)
 g.setColor(1,1,1);Characters.draw(ax,ay,size,p.dir,S.actor,2)
 local hx,hy,r=bubble.headPosition(ax,ay,size,p.dir)
 if p.bubble>0 and not require('integrated_skins').bubble(Characters.selected()) then
  bubble.drawAt(hx,hy,r,t,false,nil,nil,p.bubble,p.dir)
 end
 if not p.detached then bubble.drawLantern(hx,hy,r,t,nil,1,p.dir)
 else
  -- The buoyant lamp stays on the water as the camera rises into the cavern.
  local lampX=w*.32+math.sin((t-3.1)*2)*3*scale
  local lampY=h*(p.waterline+.065);local lampR=Characters.playerWidth*scale*1.65*.19
  bubble.drawLantern(lampX,lampY,lampR,t,nil,1,'down')
  local lx,ly=bubble.lanternPosition(lampX,lampY,lampR,t,'down')
  if not p.broken then silk.thread(hx,hy,lx,ly,2*scale,1)
  else
   local recoil=ease((t-3.35)/.6);local alpha=1-ease((t-3.5)/.5)
   silk.thread(lx,ly,lx+math.sin(t*12)*5*scale,ly+(1-recoil)*20*scale,2*scale,1)
   silk.thread(hx,hy,hx-5*scale,hy-(1-recoil)*20*scale,2*scale,alpha)
  end
 end
 g.pop()
end
return require('arrival_timing').fit(S)
