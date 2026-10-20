-- Presentation only: the destination level and its replay clock stay frozen.
local S={duration=4.9,exitDuration=1.8}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function S.clearSource()
 if S.source then S.source:release();S.source=nil end
end
function S.captureSource(canvas,drawFrame)
 if App.historyPreview or S.source or Campaign.world~=1 or player.level~=10 or not Aftermath.cleared or not Aftermath.canEnter()
  or App.practice or App.singleLevel or App.hardcore or Replay.playing then return end
 local g=love.graphics;local previous=g.getCanvas()
 S.source=g.newCanvas(canvas:getWidth(),canvas:getHeight(),{dpiscale=canvas:getDPIScale()})
 g.push('all');g.setCanvas(S.source);g.origin();g.setShader();g.clear();g.setColor(1,1,1)
 g.setBlendMode('alpha','premultiplied');g.draw(canvas);g.setBlendMode('alpha');if drawFrame then drawFrame() end;g.setCanvas(previous);g.pop()
end
function S.begin(fromParadise)
 S.fromParadise=fromParadise==true;S.actor={walkMoving=false};S.age=0
 return S.duration+(S.fromParadise and S.exitDuration or 0)
end
function S.advance(age)
 local dt=math.max(0,age-S.age);S.age=age
 if S.fromParadise and age<S.exitDuration then
  require('brown_walk').advance(S.actor,age<=1.05 and 90/1.05*dt or 0,dt)
 else S.actor.walkMoving=false end
end
function S.pose(age)
 local t=math.max(0,age-(S.fromParadise and S.exitDuration or 0))
 local fall=t
 local descent=ease(fall/4.2)
 local bounce=fall>4.2 and fall<4.55 and math.sin((fall-4.2)/.35*math.pi)*4 or 0
 return {time=t,fallTime=fall,
  progress=descent,zoom=1+.25*(1-descent),tilt=1,angle=0,
  height=115*(1-descent)+bounce,bounce=bounce,size=1+1.3*(1-descent),dir='up',
  mapAlpha=ease((fall-2.8)/1.4)}
end

local function white(alpha,w,h)
 local g=love.graphics;g.setColor(.91,.96,1,alpha);g.rectangle('fill',0,0,w,h)
end
function S.drawDeparture(w,h)
 local source=not App.historyPreview and S.source or nil
 local g=love.graphics;local t=S.age
 local sw,sh=source and source:getWidth() or Arena.width,source and source:getHeight() or Arena.height
 local scale=math.min(w/sw,h/sh);local x,y=(w-sw*scale)/2,(h-sh*scale)/2
 require('biome_floor').draw(1,w,h,UI.clock)
 g.push('all');g.translate(x,y);g.scale(scale)
 if source then g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied');g.draw(source);g.setBlendMode('alpha') end
 local px,py=sw/2,sh/2
 if not source then require('prologue').drawPortal({x=px,y=py},1,t) end
 local entering=ease((t-1.05)/.5);local size=Characters.playerWidth*(1-.8*entering)
 local ay=py+90*(1-ease(t/1.05))
 Characters.shadow(px,ay,size,'up',S.actor,1-entering)
 g.setColor(1,1,1,1-entering);Characters.draw(px,ay,size,'up',S.actor,1)
 g.pop();white(ease((t-1.35)/.45),w,h)
end
local function atmosphere(w,h,time,progress,opacity)
 local g=love.graphics
 S.atmosphere=S.atmosphere or g.newShader(love.filesystem.read('assets/shaders/sky_clouds.glsl')..[[
  extern float clock;extern vec2 dimensions;extern float approach;extern float opacity;
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){return vec4(skyCloudColor(pixel,dimensions,clock,approach),opacity);}
 ]])
 S.atmosphere:send('clock',time);S.atmosphere:send('dimensions',{w,h});S.atmosphere:send('approach',progress);S.atmosphere:send('opacity',opacity or 1)
 g.setColor(1,1,1);g.setShader(S.atmosphere);g.rectangle('fill',0,0,w,h);g.setShader()
end
local function cloudVeil(w,h,time,strength)
 local g=love.graphics
 S.cloudShader=S.cloudShader or g.newShader([[
  extern vec2 dimensions;
  extern float clock;
  extern float strength;
  float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
  float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
   return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
   vec2 p=(pixel-dimensions*.5)/dimensions.y;
   float depth=fract(clock*.55);
   p=p*(3.6-depth*2.5)+vec2(clock*.31,-clock*.6);
   float n=noise(p)*.65+noise(p*2.7)*.25+noise(p*6.1)*.1;
   float cloud=smoothstep(.23,.72,n);
   return vec4(.87,.95,1.,cloud*strength);
  }
 ]])
 S.cloudShader:send('dimensions',{w,h});S.cloudShader:send('clock',time);S.cloudShader:send('strength',strength)
 g.setShader(S.cloudShader);g.setColor(1,1,1);g.rectangle('fill',0,0,w,h);g.setShader()
end
function S.draw(canvas,w,h)
 local g=love.graphics;local sceneShader=g.getShader();g.push('all');g.origin();g.setShader()
 if S.fromParadise and S.age<S.exitDuration then S.drawDeparture(w,h);g.pop();return end
 local p=S.pose(S.age);local scale,x,y=App.viewport(w,h)
 local px,py=player.x+15,player.y+8
 local sx,sy=x+px*scale,y+py*scale
 atmosphere(w,h,p.fallTime*.25*(1-p.progress),0)
 -- Reveal the real map at full-screen scale through the last cloud bank.
 -- Never shrink its rectangular bounds into a floating platform.
 if p.mapAlpha>0 then
  g.push();g.translate(w/2,h/2);g.scale(p.zoom);g.translate(-w/2,-h/2)
  g.setShader(sceneShader);g.setBlendMode('alpha','premultiplied')
  g.setColor(p.mapAlpha,p.mapAlpha,p.mapAlpha,p.mapAlpha);g.draw(canvas,x,y,0,scale,scale)
  g.setBlendMode('alpha');g.setShader();g.pop()
 end
 local ax=sx+(w*.5-sx)*(1-p.progress)
 local ay=sy+(h*.45-sy)*(1-p.progress)-p.bounce*scale
 local size=Characters.playerWidth*scale*p.size;local opacity=1
 local shadowAlpha=ease((p.fallTime-3.7)/.5)
 if shadowAlpha>0 then
  Characters.shadow(sx,sy,Characters.playerWidth*scale*(.45+.55*p.progress),'up',nil,shadowAlpha*opacity)
 end
 local air=ease(p.fallTime/.45)*(1-ease((p.fallTime-3.4)/.8))
 for i=1,48 do
  local angle=i*2.399;local travel=(p.fallTime*(.45+p.progress*.45)+i*.173)%1
  local radius=(.14+travel*.78)*math.max(w,h)
  local cx,cy=ax+math.cos(angle)*radius,ay+math.sin(angle)*radius*.8
  local length=(35+travel*135)*scale
  g.setColor(.86,.96,1,air*(.16+.35*travel));g.setLineWidth((.7+travel*1.4)*scale)
  g.line(cx,cy,cx+math.cos(angle)*length,cy+math.sin(angle)*length*.8)
 end
 g.push();g.translate(ax,ay);g.rotate(math.sin(p.fallTime*5)*.1*air)
 g.setColor(1,1,1,opacity);Characters.draw(0,0,size,p.dir,S.actor,6);g.pop()
 -- Clouds cross in front of the body and briefly obscure it as it falls through.
 local pass1=math.exp(-((p.fallTime-1.05)/.36)^2)
 local pass2=math.exp(-((p.fallTime-2.65)/.42)^2)
 cloudVeil(w,h,p.fallTime,air*(.13+.72*pass1+.8*pass2))
 if S.fromParadise then white(1-ease(p.time/.25),w,h) end
 g.pop()
end
S.drawAtmosphere=atmosphere
S.drawClouds=cloudVeil
return S
