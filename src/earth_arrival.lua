-- A living treetop above the clouds, then a swinging rappel into the cave.
local E={duration=8.6,impact=7.4}
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
function E.begin()E.age=0;E.actor={walkMoving=false};return E.duration end
function E.advance(age)E.age=age end
function E.pose(age)
 local jump=ease((age-.7)/.9)
 local descent=ease((age-1.6)/4.7)
 local land=ease((age-6)/1.4)
 local swingTime=math.max(0,age-1.6)
 local angle=.50*math.cos(swingTime*2.6)*math.exp(-swingTime*.32)*(1-land)
 return {jump=jump,rappel=descent,progress=land,mapAlpha=land,
  silk=age>=1.3 and age<7.4,cast=ease((age-1.3)/.3),angle=angle,
  length=.24+.85*descent,camera=.75*descent,size=1.6-.6*land,
  dir=land>.9 and 'up' or age<1.6 and 'right' or 'down',
  lift=age>7.4 and age<7.7 and math.sin((age-7.4)/.3*math.pi)*3 or 0}
end
local function cloud(w,h,camera,t)
 local g=love.graphics
 E.cloud=E.cloud or g.newShader(love.filesystem.read('assets/shaders/sky_clouds.glsl')..[[
  extern vec2 dimensions;extern float camera;extern float clock;
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
   vec2 q=(pixel/ dimensions-vec2(.29,.31-camera))*vec2(1.,1.65);
   float mass=0.;
   for(int i=0;i<7;i++){
    float k=float(i);vec2 c=vec2((k-3.)*.045,sin(k*2.4)*.018);
    vec2 d=(q-c)/vec2(.065,.045+sin(k*1.7)*.009);mass+=exp(-dot(d,d)*1.8);
   }
   float n=skyNoise(q*45.+vec2(clock*.04,0.));
   float a=smoothstep(.15,.55,mass+n*.10);
   vec3 c=mix(vec3(.34,.48,.63),vec3(.91,.96,1.),(1.-smoothstep(-.05,.045,q.y)));
   c+=vec3(.035)*n;
   return vec4(c,a);
  }
 ]])
 E.cloud:send('dimensions',{w,h});E.cloud:send('camera',camera);E.cloud:send('clock',t)
 g.setColor(1,1,1);g.setShader(E.cloud);g.rectangle('fill',0,0,w,h);g.setShader()
end
function E.draw(canvas,w,h)
 local g=love.graphics;local shader=g.getShader();local t=E.age;local p=E.pose(t)
 local scale,x,y=App.viewport(w,h);local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
 local decor=require('transition_scenery')
 g.push('all');g.origin();g.setShader()
 decor.backdrop(6,w,h,t)
 local underground=ease((t-4.3)/1.7)
 decor.backdrop(5,w,h,t,underground,p.rappel)
 if t<4.5 then cloud(w,h,p.camera,t) end
 -- Roots and stone edges pass the lens while the camera follows the silk underground.
 if underground>0 and p.mapAlpha<1 then
  local alpha=underground*(1-p.mapAlpha)
  for side=-1,1,2 do
   for i=1,12 do
    local rx=(side<0 and .035 or .965)*w+math.sin(i*1.7)*w*.025
    local ry=(i*.13-.6*p.rappel)*h
    decor.rock(rx,ry,w*(.055+i%3*.014),i,alpha)
    g.setColor(.19,.13,.06,alpha);g.setLineWidth(2*scale)
    g.line(rx,ry,rx-side*w*.06,ry+h*.05,rx-side*w*.065,ry+h*.12)
   end
  end
 end
 if p.mapAlpha>0 then
  g.setShader(shader);g.setBlendMode('alpha','premultiplied');g.setColor(p.mapAlpha,p.mapAlpha,p.mapAlpha,p.mapAlpha)
  g.draw(canvas,x,y,0,scale,scale);g.setBlendMode('alpha');g.setShader()
 end
 local anchorX,anchorY=w*.36,h*(.27-p.camera)
 local ax=anchorX+math.sin(p.angle)*p.length*h
 local ay=anchorY+math.cos(p.angle)*p.length*h
 if t<1.6 then
  local catchX=w*.36+math.sin(.5)*.24*h;local catchY=h*(.27+math.cos(.5)*.24)
  ax=w*.30+(catchX-w*.30)*p.jump
  ay=h*.235+(catchY-h*.235)*p.jump-math.sin(p.jump*math.pi)*h*.13
 end
 ax=ax+(sx-ax)*p.progress;ay=ay+(sy-ay)*p.progress-p.lift*scale
 local size=Characters.playerWidth*scale*p.size
 if t<.8 then Characters.shadow(ax,h*.27,size,p.dir,nil,1-p.jump) end
 if p.mapAlpha>0 then Characters.shadow(sx,sy,Characters.playerWidth*scale,'up',nil,p.mapAlpha) end
 if p.silk then
  local tipX=ax+(anchorX-ax)*p.cast;local tipY=ay+(anchorY-ay)*p.cast
  g.setColor(.91,.96,1,1-ease((t-6.7)/.7));g.setLineWidth(1.4*scale);g.line(ax,ay-size*.15,tipX,tipY)
 end
 g.push();g.translate(ax,ay);g.rotate(t<1.6 and math.sin(p.jump*math.pi)*.25 or -p.angle*.65)
 g.setColor(1,1,1);Characters.draw(0,0,size,p.dir,E.actor,p.mapAlpha>0 and 5 or 6);g.pop()
 g.pop()
end
return E
