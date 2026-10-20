-- Descend through a submerged volcanic fissure into a dry geothermal cavern.
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
 local land=ease((t-7.8)/2)
 local walk=ease((t-5.8)/2.4)
 local turn=ease((t-5.6)/.7)
 return {x=.5+.34*walk,y=.23+.43*ease(t/6.2),progress=land,
  camera=.40*ease((t-6.1)/2.4),turn=turn,
  size=1.65-.65*land,depth=ease(t/6.2),heat=ease((t-2.2)/4.2),
  mapAlpha=land,actorsAlpha=land,
  bubble=1-ease((t-5.1)/1),release=ease((t-5.1)/1),
  dir=t<5.95 and 'down' or t<9.3 and 'right' or 'up'}
end
function S.position(t,w,h,sx,sy)
 local p=S.pose(t)
 local x=w*(p.x-p.camera);local y=h*p.y
 return x+(sx-x)*p.progress,y+(sy-y)*p.progress
end
function S.advance(age)
 local old=S.age;local dt=math.max(0,age-old);S.age=age
 local x,y=S.position(age,Arena.width,Arena.height,player.x+15,player.y+8)
 local ox,oy=S.position(old,Arena.width,Arena.height,player.x+15,player.y+8)
 local distance=age>5.8 and math.sqrt((x-ox)^2+(y-oy)^2) or 0
 require('brown_walk').advance(S.actor,distance,dt)
end
function S.draw(canvas,w,h)
 local g=love.graphics;local shader=g.getShader();local t=S.age;local p=S.pose(t)
 local decor=require('transition_scenery');local scale,x,y=App.viewport(w,h)
 local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
 local ax,ay=S.position(t,w,h,sx,sy)
 local size=Characters.playerWidth*scale*p.size
 g.push('all');g.origin();g.setShader()
 S.scenery=S.scenery or g.newShader('assets/shaders/abyss_hell_passage.glsl')
 S.scenery:send('dimensions',{w,h});S.scenery:send('clock',t)
 S.scenery:send('camera',p.camera);S.scenery:send('depth',p.depth);S.scenery:send('heat',p.heat)
 S.scenery:send('lamp',{ax/w,ay/h});S.scenery:send('water',p.bubble)
 g.setShader(S.scenery);g.setColor(1,1,1);g.rectangle('fill',0,0,w,h);g.setShader()
 local a=1-p.mapAlpha
 -- Marine snow and rising vent bubbles establish the water before the steam veil.
 for i=1,65 do
  local px=w*((i*.6180339+math.sin(t*.22+i)*.008)%1)
  local py=h*((i*.137+t*(.014+i%4*.004)+p.depth*.28)%1)
  g.setColor(.23,.63,.78,a*p.bubble*(.12+i%3*.06))
  g.circle('fill',px,py,(.7+i%3*.45)*scale)
 end
 for i=1,24 do
  local phase=(i*.173+t*.11)%1
  local px=w*(.5+math.sin(i*2.7)*(.025+phase*.11))
  local py=h*(1-phase)
  g.setColor(.36,.66,.74,a*p.bubble*.28);g.setLineWidth(scale)
  g.circle('line',px,py,(1.5+i%4*.6)*scale)
 end
 -- Warm vapor thickens at the submerged throat, covering the change of medium.
 local steam=ease((t-3.8)/1.2)*(1-ease((t-6.1)/1.2))*a
 decor.mist(w,h,t,steam*.35,.5)
 for i=1,35 do
  local px=w*((i*.618+t*.012)%1);local py=h*((i*.173-t*.045)%1)
  g.setColor(1,.38,.10,a*(1-p.bubble)*.55)
  g.ellipse('fill',px,py,scale,(1.5+i%3)*scale,12)
 end
 decor.reveal(canvas,S.environment,w,h,p.mapAlpha,p.actorsAlpha,shader)
 Characters.shadow(ax,ay+size*.18*(1-p.progress),size,p.dir,S.actor,ease((t-6)/2))
 g.push();g.translate(ax,ay);g.scale(1-.18*math.sin(p.turn*math.pi),1)
 g.setColor(1,1,1);Characters.draw(0,0,size,p.dir,S.actor,2);g.pop()
 if p.bubble>0 then
  local bubble=require('breathing_bubble');local hx,hy,r=bubble.headPosition(ax,ay,size,p.dir)
  -- Equipment stays on the swimmer until the hot vapor consumes it, without teleporting away.
  if not require('integrated_skins').bubble(Characters.selected()) then
   bubble.drawAt(hx,hy,r*(1+p.release*.08),t,false,nil,nil,p.bubble,p.dir)
  end
  bubble.drawLantern(hx,hy,r,t,nil,p.bubble,p.dir)
 end
 -- Foreground wisps pass in front of the character as well as behind it.
 decor.mist(w,h,t+.7,steam*.23,.25)
 g.pop()
end
return require('arrival_timing').fit(S)
