-- A luminous guide leads the spider through a lateral current into the deep sea.
local B={duration=9.6,impact=7.8}
local motion=require('cinematic_motion')
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
local path={{0,-.10,0},{1.5,.17,.13},{3.6,.29,.035},{5.6,.38,.06},{7.8,.5,0}}
function B.begin()
 B.age=0;B.actor={walkMoving=false}
 if B.environment then B.environment:release();B.environment=nil end
 return B.duration
end
function B.captureEnvironment(canvas)
 if B.environment then return end
 local g=love.graphics;local previous=g.getCanvas()
 B.environment=g.newCanvas(canvas:getWidth(),canvas:getHeight(),{dpiscale=canvas:getDPIScale()})
 g.push('all');g.setCanvas(B.environment);g.origin();g.setShader();g.clear()
 g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(canvas);g.setCanvas(previous);g.pop()
end
function B.advance(age)
 local dt=math.max(0,age-B.age);B.age=age
 require('brown_walk').advance(B.actor,dt*40*(1-ease((age-6)/1.8)),dt)
end
function B.pose(t)
 local land=ease((t-5.6)/2.2)
 return {x=motion.sample(path,t),y=.5+math.sin(t*1.4)*.018*(1-land),progress=land,
  depth=ease((t-1.5)/4),mapAlpha=ease((t-4.8)/3),actorsAlpha=ease((t-7.8)/1.6),
  size=1.5-.5*land,dir=land>.9 and 'up' or 'right'}
end
function B.draw(canvas,w,h)
 local g=love.graphics;local shader=g.getShader();local t=B.age;local p=B.pose(t)
 local decor=require('transition_scenery');local scale,x,y=App.viewport(w,h)
 local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
 g.push('all');g.origin();g.setShader()
 decor.backdrop(4,w,h,t,1,t*.12)
 B.deep=B.deep or g.newShader([[
 extern vec2 dimensions;extern float clock;extern float depth;
 vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
  vec2 p=pixel/dimensions;
  float channel=exp(-pow((p.y-.5)*4.,2.));
  float current=pow(max(0.,sin(p.y*55.+sin(p.x*5.-clock*.6)*2.)),20.);
  vec3 c=mix(vec3(.006,.012,.035),vec3(.018,.095,.15),channel);
  c+=vec3(.02,.08,.14)*current*channel;
  return vec4(c,depth);
 }
 ]])
 B.deep:send('dimensions',{w,h});B.deep:send('clock',t);B.deep:send('depth',p.depth)
 g.setShader(B.deep);g.setColor(1,1,1);g.rectangle('fill',0,0,w,h);g.setShader()
 -- Passing rock lips frame an open horizontal fissure, never a black cut.
 local drift=t*.12
 for side=-1,1,2 do
  for i=0,8 do
   local rx=w*((i*.19-drift)%1.5-.25)
   local ry=side<0 and -h*.05 or h*1.08
   decor.rock(rx,ry,h*(.22+.04*math.sin(i*2)),i+11,p.depth*(1-p.mapAlpha)*.65)
  end
 end
 -- Plankton streams to the left while the swimmer enters from the left.
 for i=1,55 do
  local px=w*((i*.618-t*(.08+i%3*.025))%1)
  local py=h*(.15+(i*.137)% .70)+math.sin(t+i)*3
  g.setColor(.25,.65,.88,(1-p.mapAlpha)*(.12+.18*(i%3)/2));g.setLineWidth(scale)
  g.line(px,py,px+(4+i%4*3)*scale,py)
 end
 -- A small translucent jellyfish guides the passage and fades into the deep.
 local jx=w*(p.x+.20);local jy=h*(.39+math.sin(t*1.7)*.025);local ja=1-p.mapAlpha
 for i=4,1,-1 do g.setColor(.12,.61,.95,ja*.035);g.circle('fill',jx,jy,(16+i*8)*scale) end
 g.setColor(.36,.84,1,ja*.65);g.ellipse('fill',jx,jy,16*scale,(10+math.sin(t*3))*scale,32)
 for i=-2,2 do
  local points={}
  for j=0,12 do points[#points+1]=jx+i*5*scale+math.sin(t*3-j*.35+i)*j*.3*scale;points[#points+1]=jy+j*2.5*scale end
  g.setColor(.42,.81,1,ja*.45);g.setLineWidth(scale);g.line(points)
 end
 decor.reveal(canvas,B.environment,w,h,p.mapAlpha,p.actorsAlpha,shader)
 local ax=w*p.x;local ay=h*p.y
 ax=ax+(sx-ax)*p.progress;ay=ay+(sy-ay)*p.progress
 local size=Characters.playerWidth*scale*p.size
 g.setColor(1,1,1);Characters.draw(ax,ay,size,p.dir,B.actor,7)
 if not require('integrated_skins').bubble(Characters.selected()) then
  local bubble=require('breathing_bubble');local hx,hy,r=bubble.headPosition(ax,ay,size,p.dir)
  bubble.drawAt(hx,hy,r,t*(1-p.progress),false,nil,nil,1,p.dir)
 end
 local bubble=require('breathing_bubble');local hx,hy,r=bubble.headPosition(ax,ay,size,p.dir)
 bubble.drawLantern(hx,hy,r,t*(1-p.progress),nil,p.depth,p.dir)
 g.pop()
end
return B
