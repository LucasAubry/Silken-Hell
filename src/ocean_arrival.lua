-- Discover an air pearl in a cave spring, wear it, then ride its underwater current.
local O={duration=8.15,impact=8}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function O.begin()
 O.age=0;O.actor={walkMoving=false}
 if O.environment then O.environment:release();O.environment=nil end
 return O.duration
end
function O.captureEnvironment(canvas)
 if O.environment then return end
 local g=love.graphics;local previous=g.getCanvas()
 O.environment=g.newCanvas(canvas:getWidth(),canvas:getHeight(),{dpiscale=canvas:getDPIScale()})
 g.push('all');g.setCanvas(O.environment);g.origin();g.setShader();g.clear()
 g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(canvas);g.setCanvas(previous);g.pop()
end
function O.advance(age)
 local previous=O.age;local dt=math.max(0,age-previous);O.age=age
 local distance=age<1.8 and math.abs(O.pose(age).x-O.pose(previous).x)*Arena.width or age>4.8 and age<8 and dt*45 or 0
 require('brown_walk').advance(O.actor,distance,dt)
end
local motion=require('cinematic_motion')
local swimX={{0,.20,0},{1.8,.43,0},{3.3,.43,0},{4.3,.57,.06},{5.2,.61,0},{6.2,.5,0}}
local swimY={{0,0,0},{3,0,0},{3.3,.012,0},{3.75,-.075,0},{4.3,.075,.40},{4.8,.26,.22},{5.4,.32,0},{6.2,.26,0}}
function O.pose(t)
 return {approach=ease(t/1.8),equip=ease((t-1.8)/1.2),equipped=t>=3,
  x=motion.sample(swimX,t),y=motion.sample(swimY,t),
  swim=ease((t-4.8)/1.4),dive=ease((t-3.3)/2.1),underwater=ease((t-4.4)/1.6),camera=1.35*ease((t-4.8)/1.6),
  progress=ease((t-6.2)/1.8),mapAlpha=ease((t-6)/2),actorsAlpha=ease((t-7.45)/.55),
  dir=t>=5.2 and 'up' or t>=3.8 and 'down' or 'right',grounded=t<=3.3}
end
function O.draw(canvas,w,h)
 local g=love.graphics;local shader=g.getShader();local t=O.age;local p=O.pose(t)
 local scale,x,y=App.viewport(w,h);local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
 local bubble=require('breathing_bubble');local decor=require('transition_scenery')
 local surface=h*(.62-p.camera);local cave=1-p.underwater
 g.push('all');g.origin();g.setShader()
 -- The camera crosses the surface: the same ocean floor is visible beneath the spring.
 decor.backdrop(5,w,h,t,1,p.camera)
 decor.backdrop(4,w,h,t,ease((t-3.1)/3.2),p.camera)
 -- Water is present below the ledge from the opening shot.
 if surface<h then
  g.setScissor(0,math.max(0,surface),w,h-math.max(0,surface))
  decor.backdrop(4,w,h,t,1,p.camera);g.setScissor()
 end
 do
  local offset=p.camera*h
  decor.grotto(w,h,t,p.camera,1,false)
  for i=1,8 do
   local rx=w*(.04+i*.043);local ry=h*(.56+math.sin(i)*.01)-offset
   decor.mushroom(rx,ry,(13+i%3*6)*scale,1)
  end
  for i=1,7 do
   local dx=w*(.50+i*.065);local dy=h*(.18+((t*.16+i*.163)%.37))-offset
   g.setColor(.72,.85,.57,cave*.4);g.ellipse('fill',dx,dy,1.2*scale,3*scale)
  end
 end
 decor.reveal(canvas,O.environment,w,h,p.mapAlpha,p.actorsAlpha,shader)
 decor.mist(w,h,t,.08*(1-p.mapAlpha),p.underwater)
 local size=Characters.playerWidth*scale*((1.65-.35*p.dive)*(1-p.progress)+p.progress)
 local groundY=h*(.55+math.sin(p.x/.47*9)*.004)
 local restY=groundY-Characters.playerWidth*scale*1.65*.21
 local ax=w*p.x
 local ay=restY+h*(p.y-p.camera*(.85*.35/1.35))
 ax=ax+(sx-ax)*p.progress;ay=ay+(sy-ay)*p.progress
 local rotation=math.pi*2*ease((t-4.6)/1.6)+math.sin(t*4)*.045*p.swim*(1-p.progress)
 if p.mapAlpha>0 then Characters.shadow(ax,sy,Characters.playerWidth*scale,p.dir,nil,p.mapAlpha) end
 if cave>0 then Characters.shadow(ax,groundY-p.camera*h,size,p.dir,O.actor,cave*(1-ease((t-3.3)/.8))) end
 g.push();g.translate(ax,ay);g.rotate(rotation)
 g.setColor(1,1,1);Characters.draw(0,0,size,p.dir,O.actor,p.equipped and 4 or 5)
 local hx,hy,r=bubble.headPosition(0,0,size,p.dir)
 if not p.equipped then
  local bx=(w*.53-ax)*(1-p.equip)+hx*p.equip
  local by=(h*.44-ay+math.sin(t*2)*4*scale)*(1-p.equip)+hy*p.equip-math.sin(p.equip*math.pi)*25*scale
  -- The air pearl has the exact gameplay outline, highlighted by the spring.
  for i=4,1,-1 do g.setColor(.35,.80,1,(1-p.equip)*.025);g.circle('fill',bx,by,r+i*5*scale) end
  bubble.drawAt(bx,by,r,t,false,nil,nil,1,p.dir)
 elseif not require('integrated_skins').bubble(Characters.selected()) then
  bubble.drawAt(hx,hy,r,t*(1-p.progress),false,nil,nil,1,p.dir)
 end
 g.pop()
 -- Transparent moving water crosses the body, with a soft reflective meniscus.
 if surface<h and p.mapAlpha<1 then
  O.water=O.water or g.newShader([[
   extern vec2 dimensions;extern float surface;extern float clock;extern float opacity;
   vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
    float wave=sin(pixel.x/dimensions.x*19.+clock*2.)*2.+sin(pixel.x/dimensions.x*43.-clock)*1.2;
    float d=pixel.y-surface-wave;
    float water=smoothstep(-2.,5.,d);
    float edge=exp(-abs(d)/3.);
    float shimmer=pow(max(0.,sin(pixel.x*.023+clock*.7+pixel.y*.008)),18.);
    vec3 c=mix(vec3(.035,.30,.39),vec3(.60,.91,.93),edge*.85);
    return vec4(c,(water*.16+edge*.38+shimmer*.025*water)*opacity);
   }
  ]])
  O.water:send('dimensions',{w,h});O.water:send('surface',surface);O.water:send('clock',t);O.water:send('opacity',(1-p.mapAlpha)*.85)
  g.setColor(1,1,1);g.setShader(O.water);g.rectangle('fill',0,0,w,h);g.setShader()
 end
 if surface>0 and surface<h then
  local splash=ease((t-4.3)/.12)*(1-ease((t-4.5)/.6))
  if splash>0 then
   for i=1,16 do
    local a=i*2.399;local radius=(t-4.3)*(55+i%4*22)*scale
    g.setColor(.71,.97,1,splash*.8);g.ellipse('fill',w*.57+math.cos(a)*radius,surface-math.abs(math.sin(a))*radius*.8+(t-4.3)^2*70*scale,1.5*scale,3*scale)
   end
  end
 end
 local current=p.dive*(1-p.mapAlpha)
 for i=1,30 do
  local u=(i/30+t*.27)%1;local bx=w*(.65+.18*math.sin(u*5+i*.1));local by=h*(.9-u*.85)
  if by>surface then
   g.setColor(.65,.94,1,current*.45);g.setLineWidth(scale);g.circle('line',bx,by,(2+i%4)*scale)
  end
 end
 g.pop()
end
return require('arrival_timing').fit(O)
