-- Two continuous journeys share the frozen-level handoff, each with its own motion and scenery.
local motion=require('cinematic_motion')
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
local M={}
function M.new(garden)
 local S={duration=10.4,impact=8.4}
 local ascent={{0,.78,0},{2,.64,-.12},{3.8,.36,0},{5.8,.53,.05},{6.2,.55,0}}
 local crossing={{0,.15,0},{2,.26,.065},{4,.39,.06},{6.2,.5,0}}
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
  local land=ease((t-6.2)/2.2)
  return {x=garden and motion.sample(crossing,t) or .5+math.sin(t*1.3)*.012*(1-land),
   y=garden and .57 or motion.sample(ascent,t),progress=land,size=1.6-.6*land,
   scroll=1.25*ease(t/8.4),change=ease((t-1.7)/4.5),mapAlpha=ease((t-5.8)/2.6),actorsAlpha=ease((t-8.4)/1.6),
   bubble=1-ease((t-4)/1),release=ease((t-3.2)/1.8),dir=land>.9 and 'up' or garden and 'right' or 'down'}
 end
 function S.position(t,w,h,sx,sy)
  local p=S.pose(t)
  if p.progress==1 then return sx,sy end
  return w*p.x+(sx-w*p.x)*p.progress,h*p.y+(sy-h*p.y)*p.progress
 end
 function S.advance(age)
  local old=S.age;local dt=math.max(0,age-old);S.age=age
  local distance=garden and (math.abs(S.pose(age).x-S.pose(old).x)+math.abs(S.pose(age).scroll-S.pose(old).scroll))*Arena.width or dt*30*(1-S.pose(age).progress)
  require('brown_walk').advance(S.actor,distance,dt)
 end
 function S.draw(canvas,w,h)
  local g=love.graphics;local shader=g.getShader();local t=S.age;local p=S.pose(t)
  local decor=require('transition_scenery');local scale,x,y=App.viewport(w,h)
  local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
  g.push('all');g.origin();g.setShader()
  S.scenery=S.scenery or g.newShader([[
   extern vec2 dimensions;extern float clock;extern float change;extern float garden;extern float scroll;
   float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
   float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
   vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
    vec2 q=pixel/dimensions;vec2 p=(pixel-dimensions*.5)/dimensions.y;
    if(garden>.5) p.x+=scroll*.75;
    float growth=smoothstep(.15,.8,change+(q.x-.5)*.65);
    float n=noise(p*8.+vec2(0.,clock*.025))*.7+noise(p*23.)*.3;
    float seam=pow(1.-abs(sin(p.x*19.+sin(p.y*13.)*2.+n*7.)),16.);
    vec3 fire=mix(vec3(.085,.012,.025),vec3(.31,.045,.035),n);
    fire+=vec3(.65,.12,.025)*seam*(.6+.15*sin(clock*1.5+p.y*4.));
    float shaft=exp(-p.x*p.x*12.);
    vec3 deep=mix(vec3(.006,.014,.035),vec3(.02,.10,.17),n);
    deep+=vec3(.25,.075,.015)*shaft*q.y*q.y*change;
    vec3 green=mix(vec3(.045,.10,.065),vec3(.19,.31,.14),n);
    float ray=pow(max(0.,sin(q.x*15.+q.y*3.-clock*.10)),12.)*(1.-q.y*.7);
    green+=vec3(.30,.31,.14)*ray*.4+vec3(.12,.14,.04)*exp(-dot(p-vec2(.15,-.2),p-vec2(.15,-.2))*3.);
    vec3 c=garden>.5?mix(fire,green,growth):mix(deep,fire,change);
    if(garden<.5){
     float wall=smoothstep(.27,.39+noise(vec2(p.y*9.,3.))*.08,abs(p.x));
     c*=1.-wall*.55;
     c+=vec3(.42,.13,.025)*shaft*change*(1.-change)*3.*smoothstep(.2,1.,q.y);
    }
    c*=1.-smoothstep(.3,1.2,length(p))*.25;
    return vec4(c,1.);
   }
  ]])
  S.scenery:send('dimensions',{w,h});S.scenery:send('clock',t);S.scenery:send('change',p.change);S.scenery:send('garden',garden and 1 or 0);S.scenery:send('scroll',p.scroll)
  g.setShader(S.scenery);g.setColor(1,1,1);g.rectangle('fill',0,0,w,h);g.setShader()
  local a=1-p.mapAlpha
  if garden then
   -- A continuous stone causeway becomes a living root bridge beneath the feet.
   local path={0,h*.61}
   for i=0,50 do path[#path+1]=w*i/50;path[#path+1]=h*(.61+math.sin(i*.31+p.scroll*15)*.006) end
   for i=50,0,-1 do path[#path+1]=w*i/50;path[#path+1]=h*(.70+math.sin(i*.23+p.scroll*12)*.018+math.sin(i*.71+p.scroll*36)*.005) end
   decor.material(false);g.setColor(.23-.08*p.change,.09+.13*p.change,.055+.035*p.change,a);g.polygon('fill',path);g.setShader()
   for strand=1,7 do
    local points={}
    for i=0,60 do points[#points+1]=i*w/60;points[#points+1]=h*(.618+strand*.009+math.sin(i*.16+strand*.8+p.scroll*8)*.005) end
    g.setColor(.34,.20+.11*p.change,.085,a*.7);g.setLineWidth(scale*(strand%2+1));g.line(points)
   end
   for i=0,155 do
    local px=(i+math.sin(i*2.7)*.35)*w/65-p.scroll*w;local grow=ease((t-2-i*.035)/1.6)*a
    local height=(15+i%5*5)*scale*grow;local py=h*.61
    local bend=math.sin(t*1.1+i)*height*.18
    g.setColor(.22,.43,.13,a);g.setLineWidth(1.5*scale);g.line(px,py,px+bend,py-height)
    if grow>0 then
     g.setColor(.42,.57,.20,grow);g.ellipse('fill',px+bend-4*scale,py-height*.65,6*scale*grow,2.2*scale*grow,16)
     if i%5==0 then g.setColor(.94,.81,.48,grow);g.circle('fill',px+bend,py-height,2.5*scale) end
    end
   end
  else
   -- Convection lifts the swimmer through a glowing volcanic chimney.
   decor.grotto(w,h,t*.3,0,(1-p.change)*.55*a,true)
   for i=1,32 do
    local u=(i*.137+t*.19)%1;local px=w*(.5+math.sin(i*2.4)*(.10+.15*u));local py=h*(1-u)
    g.setColor(.40+.55*p.change,.70-.38*p.change,.88-.78*p.change,a*.35)
    if p.change<.55 then g.setLineWidth(scale);g.circle('line',px,py,(2+i%4)*scale)
    else g.ellipse('fill',px,py,scale,(2+i%3)*scale,12) end
   end
   decor.mist(w,h,t,math.sin(p.change*math.pi)*.25*a,1-p.change)
  end
  -- Ash warms into golden pollen; every particle keeps its continuous trajectory.
  for i=1,48 do
   local px=w*((i*.618+t*.018)%1);local py=h*((i*.173-t*.035)%1)
   local green=garden and p.change or 0
   g.setColor(.95-.25*green,.28+.52*green,.09+.32*green,a*.5)
   g.ellipse('fill',px,py,(1.2+green)*scale,(2.5-green)*scale,12)
  end
  decor.reveal(canvas,S.environment,w,h,p.mapAlpha,p.actorsAlpha,shader,garden and w*.35*(1-p.progress) or 0)
  local ax,ay=S.position(t,w,h,sx,sy)
  local size=Characters.playerWidth*scale*p.size
  if garden or p.change>.7 then Characters.shadow(ax,garden and (h*.61+(sy-h*.61)*p.progress) or ay+size*.23*(1-p.progress),size,p.dir,S.actor,garden and 1 or ease((p.change-.7)/.3)) end
  g.setColor(1,1,1);Characters.draw(ax,ay,size,p.dir,S.actor,garden and 3 or 2)
  if not garden and p.bubble>0 then
   local bubble=require('breathing_bubble');local hx,hy,r=bubble.headPosition(ax,ay,size,p.dir)
   -- Bubble and lamp lift away together in the steam after leaving the water.
   hy=hy-p.release*h*.32;hx=hx+math.sin(t*2)*p.release*12*scale
   if not require('integrated_skins').bubble(Characters.selected()) then bubble.drawAt(hx,hy,r*(1+p.release*.22),t,false,nil,nil,p.bubble,p.dir) end
   bubble.drawLantern(hx,hy,r,t,nil,p.bubble,p.dir)
  end
  g.pop()
 end
 return S
end
return M
