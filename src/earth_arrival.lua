-- A cloud departure and silk descent dissolve softly into the cave.
local E={duration=10.8,impact=8.8}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function E.clearSource()if E.source then E.source:release();E.source=nil end end
function E.captureSource(canvas,drawFrame)
 if E.source or App.historyPreview or App.preview or App.practice or App.singleLevel or App.hardcore or Replay.playing
  or Campaign.world~=6 or player.level~=Worlds.levelCount(6) then return end
 local g=love.graphics;local previous=g.getCanvas()
 E.source=g.newCanvas(canvas:getWidth(),canvas:getHeight(),{dpiscale=canvas:getDPIScale()})
 g.push('all');g.setCanvas(E.source);g.origin();g.setShader();g.clear();g.setColor(1,1,1)
 g.setBlendMode('alpha','premultiplied');g.draw(canvas);g.setBlendMode('alpha')
 if drawFrame then drawFrame() end
 g.setCanvas(previous);g.pop()
end
function E.begin()
 E.age=0;E.actor={walkMoving=false}
 if E.environment then E.environment:release();E.environment=nil end
 return E.duration
end
function E.captureEnvironment(canvas)
 if E.environment then return end
 local g=love.graphics;local previous=g.getCanvas()
 E.environment=g.newCanvas(canvas:getWidth(),canvas:getHeight(),{dpiscale=canvas:getDPIScale()})
 g.push('all');g.setCanvas(E.environment);g.origin();g.setShader();g.clear()
 g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(canvas);g.setCanvas(previous);g.pop()
end
function E.advance(age)E.age=age end
function E.pose(age)
 local jump=ease((age-.7)/.9)
 local descent=ease((age-1.6)/4.7)
 local land=ease((age-6)/2.8)
 local swingTime=math.max(0,age-1.6)
 local angle=.10*math.cos(swingTime*2.6)*math.exp(-swingTime*.32)*(1-land)
 return {jump=jump,rappel=descent,progress=land,mapAlpha=land,actorsAlpha=ease((age-8.8)/1.6),
  silk=age>=1.3 and age<8.8,cast=ease((age-1.3)/.3),angle=angle,
  length=.24+.85*descent,camera=.75*descent,size=1.6-.6*land,
  dir=land>.9 and 'up' or age<1.6 and 'right' or 'down',
  lift=age>8.8 and age<9.1 and math.sin((age-8.8)/.3*math.pi)*3 or 0}
end
local function cloud(w,h,camera,t,opacity)
 local g=love.graphics
 E.cloud=E.cloud or g.newShader(love.filesystem.read('assets/shaders/sky_clouds.glsl')..[[
  extern vec2 dimensions;extern float camera;extern float clock;extern float opacity;
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
   vec2 q=(pixel/dimensions-vec2(.21,.31-camera))*vec2(1.,1.);
   float mass=0.;
   for(int i=0;i<5;i++){
    float k=float(i);float crown=1.-abs(k-2.)*.5;
    vec2 c=vec2((k-2.)*.045,-.035*crown+sin(k*2.)*.008);
    vec2 d=(q-c)/vec2(.057,.044+.028*crown);mass+=exp(-dot(d,d)*1.7);
   }
   float n=skyNoise(q*60.+vec2(clock*.035,0.));
   float a=smoothstep(.08,.42,mass+n*.045);
   float light=1.-smoothstep(-.06,.055,q.y);
   vec3 c=mix(vec3(.48,.66,.84),vec3(.97,.98,1.),light);
   c+=vec3(.025)*(n-.5);
   return vec4(c,a*opacity);
  }
 ]])
 E.cloud:send('opacity',opacity or 1)
 E.cloud:send('dimensions',{w,h});E.cloud:send('camera',camera);E.cloud:send('clock',t)
 g.setColor(1,1,1);g.setShader(E.cloud);g.rectangle('fill',0,0,w,h);g.setShader()
end
function E.draw(canvas,w,h)
 local g=love.graphics;local shader=g.getShader();local t=E.age;local p=E.pose(t)
 local scale,x,y=App.viewport(w,h);local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
 local decor=require('transition_scenery')
 g.push('all');g.origin();g.setShader()
 decor.backdrop(6,w,h,t)
 -- Match Paradise-to-Sky: broad atmospheric layers, then a long destination dissolve.
 cloud(w,h,p.camera,t)
 local underground=ease((t-2.9)/3.1)
 decor.backdrop(5,w,h,t,underground,p.rappel)
 require('sky_arrival').drawClouds(w,h,t*.35,(1-underground)*(.16+.42*math.exp(-((t-3.8)/1.2)^2)))
 decor.caveEdges(w,h,t,p.rappel,underground*(1-p.mapAlpha))
 decor.reveal(canvas,E.environment,w,h,p.mapAlpha,p.actorsAlpha,shader)
 local veil=ease((t-2.5)/1.5)*(1-ease((t-7.1)/2))
 decor.mist(w,h,t,veil*.22,0)
 local anchorX,anchorY=w*.25,h*(.31-p.camera)
 local ax=w*(.5+math.sin(p.angle)*.035)
 local ay=h*(.31-p.camera+math.cos(p.angle)*p.length)
 if t<1.6 then
  local catchX=w*(.5+math.sin(.10)*.035);local catchY=h*(.31+math.cos(.10)*.24)
  ax=w*.21+(catchX-w*.21)*p.jump
  ay=h*.235+(catchY-h*.235)*p.jump-math.sin(p.jump*math.pi)*h*.13
 end
 ax=ax+(sx-ax)*p.progress;ay=ay+(sy-ay)*p.progress-p.lift*scale
 local size=Characters.playerWidth*scale*p.size

 if p.mapAlpha>0 then Characters.shadow(sx,sy,Characters.playerWidth*scale,'up',nil,p.mapAlpha) end
 if p.silk then
  local tipX=ax+(anchorX-ax)*p.cast;local tipY=ay+(anchorY-ay)*p.cast
  require('silk_art').thread(tipX,tipY,ax,ay-size*.15,5.5*scale,.92*(1-ease((t-7.6)/1.2)))
 end
 -- The cloud occludes the anchor, so the silk emerges from behind its underside.
 cloud(w,h,p.camera,t,1-underground)
 g.push();g.translate(ax,ay);g.rotate(t<1.6 and math.sin(p.jump*math.pi)*.25 or -p.angle*.65)
 g.setColor(1,1,1);Characters.draw(0,0,size,p.dir,E.actor,p.mapAlpha>0 and 5 or 6);g.pop()
 g.pop()
end
return E
