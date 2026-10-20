-- A cloud departure and silk descent dissolve softly into the cave.
local E={duration=8.95,impact=8.8}
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
local motion=require('cinematic_motion')
local flightX={{0,.21,0},{.5,.21,0},{1.8,.5,0},{2.1,.5,0},{6,.5,0}}
local flightY={{0,.235,0},{.5,.235,0},{1.12,.105,0},{1.8,.235,0},{1.95,.245,0},{2.1,.235,0},
 {2.5,.18,0},{3.3,.48,.18},{4.5,.60,.045},{6,.64,0}}
local clouds={
 {x=.21,y=.31,sx=1.05,sy=.90,seed=1,alpha=1},
 {x=.5,y=.31,sx=.85,sy=1.08,seed=4,alpha=1},
 {x=.79,y=.17,sx=.62,sy=.55,seed=7,alpha=.65},
 {x=.92,y=.43,sx=.78,sy=.42,seed=11,alpha=.48},
 {x=.08,y=.62,sx=.46,sy=.52,seed=15,alpha=.40},
}
function E.cloudState(index,t)
 local c=clouds[index];local phase=c.seed*1.73
 local dx=.006*math.sin(t*.43+phase);local dy=.005*math.sin(t*.65+phase*.7)
 return {x=c.x+dx,y=c.y+dy,dx=dx,dy=dy,sx=c.sx,sy=c.sy,seed=c.seed,alpha=c.alpha}
end
function E.pose(age)
 local descent=ease((age-2.5)/3.8)
 local left,middle=E.cloudState(1,age),E.cloudState(2,age)
 local hop=ease((age-.5)/1.3);local follow=1-ease((age-2.5)/1.5)
 local dx=(left.dx+(middle.dx-left.dx)*hop)*follow
 local dy=(left.dy+(middle.dy-left.dy)*hop)*follow
 local land=ease((age-6)/2.8)
 local swingTime=math.max(0,age-3.3)
 local angle=.045*math.sin(swingTime*2.1)*ease(swingTime/.7)*math.exp(-swingTime*.45)*(1-land)
 return {jump=ease((age-.5)/1.3),rappel=descent,progress=land,mapAlpha=land,actorsAlpha=ease((age-8.25)/.55),
  silk=age>=2.1 and age<8.8,angle=angle,camera=.75*descent,size=1.6-.6*land,
  x=motion.sample(flightX,age)+math.sin(angle)*.035+dx,y=motion.sample(flightY,age)+dy,
  dir=age<2.1 and 'right' or 'up',lift=0}
end
local function cloud(w,h,camera,t,opacity,index)
 local g=love.graphics;local c=E.cloudState(index,t)
 E.cloud=E.cloud or g.newShader(love.filesystem.read('assets/shaders/sky_clouds.glsl')..[[
  extern vec2 dimensions;extern float camera;extern float clock;extern float opacity;extern vec2 center;extern vec2 shape;extern float seed;
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
   vec2 q=(pixel/dimensions-center+vec2(0.,camera))/shape;
   float mass=0.;
   for(int i=0;i<5;i++){
    float k=float(i);float crown=1.-abs(k-2.)*.5;
    vec2 c=vec2((k-2.)*.045,-.030*crown+sin(k*2.+seed)*.015);
    vec2 d=(q-c)/vec2(.050+.008*sin(k+seed),.040+.030*crown+.008*cos(k*2.+seed));mass+=exp(-dot(d,d)*1.7);
   }
   float n=skyNoise(q*60.+vec2(clock*.035,0.));
   float a=smoothstep(.08,.42,mass+n*.045);
   float light=1.-smoothstep(-.06,.055,q.y);
   vec3 c=mix(vec3(.48,.66,.84),vec3(.97,.98,1.),light);
   c+=vec3(.025)*(n-.5);
   return vec4(c,a*opacity);
  }
 ]])
 E.cloud:send('center',{c.x,c.y});E.cloud:send('shape',{c.sx,c.sy});E.cloud:send('seed',c.seed)
 E.cloud:send('opacity',(opacity or 1)*c.alpha)
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
 for i=3,#clouds do cloud(w,h,p.camera*.65,t,1,i) end
 cloud(w,h,p.camera,t,1,1)
 cloud(w,h,p.camera,t,1,2)
 local underground=ease((t-3.7)/2.3)
 decor.backdrop(5,w,h,t,underground,p.rappel)
 require('sky_arrival').drawClouds(w,h,t*.35,(1-underground)*(.16+.42*math.exp(-((t-3.8)/1.2)^2)))
 decor.caveEdges(w,h,t,p.rappel,underground*(1-p.mapAlpha))
 decor.reveal(canvas,E.environment,w,h,p.mapAlpha,p.actorsAlpha,shader)
 local veil=ease((t-3.3)/1.5)*(1-ease((t-7.1)/2))
 decor.mist(w,h,t,veil*.22,0)
 local tether=E.cloudState(2,t)
 local anchorX,anchorY=w*tether.x,h*(tether.y-p.camera)
 local ax,ay=w*p.x,h*p.y
 ax=ax+(sx-ax)*p.progress;ay=ay+(sy-ay)*p.progress-p.lift*scale
 local size=Characters.playerWidth*scale*p.size

 if p.mapAlpha>0 then Characters.shadow(sx,sy,Characters.playerWidth*scale,'up',nil,p.mapAlpha) end
 if p.silk then
  local tipX,tipY=anchorX,anchorY
  require('silk_art').thread(tipX,tipY,ax,ay-size*.15,5.5*scale,.92*(1-ease((t-7.6)/1.2)))
 end
 -- The cloud occludes the anchor, so the silk emerges from behind its underside.
 cloud(w,h,p.camera,t,1-underground,1)
 cloud(w,h,p.camera,t,1-underground,2)
 g.push();g.translate(ax,ay);g.rotate(t<2.1 and math.sin(p.jump*math.pi)*.12 or -p.angle*.65)
 g.setColor(1,1,1);Characters.draw(0,0,size,p.dir,E.actor,p.mapAlpha>0 and 5 or 6);g.pop()
 g.pop()
end
return E
