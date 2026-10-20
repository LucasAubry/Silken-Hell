-- Recover a lantern from a ledge, ride its underwater slide, then swim into the Abyss.
local B={duration=7.95,impact=7.8}
local motion=require('cinematic_motion')
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
local route={{0,-.10,0},{1.8,.43,0},{7.95,.43,0}}
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
function B.pose(t)
 local land=ease((t-6.4)/1.4)
 local worldX=motion.sample(route,t)
 local slide=math.max(0,t-3.6)
 local camera=slide*slide*.10
 local leave=ease((t-5.1)/1.3)
 local rockX=.43-.65*ease((t-5.1)/2.7)
 local drop=.18*ease(slide/1.65)
 local rockY=.60+drop+.15*slide*slide
 local crack=ease((t-3.25)/.35)
 local jolt=ease(slide/.045)*(1-ease((slide-.10)/.55))*crack
 return {worldX=worldX,camera=camera,x=worldX,y=.538+drop-.203*leave,
  crack=crack,jolt=jolt,tilt=.24*ease(slide/.7)*(1-leave),
  rockX=rockX,rockY=rockY,leave=leave,slide=slide,progress=land,
  depth=ease((t-3.6)/3.5),mapAlpha=land,actorsAlpha=land,
  equip=ease((t-2.1)/1.3),size=1.5-.5*land,dir=t>=3.6 and 'up' or 'right'}
end
function B.position(t,w,h,sx,sy)
 local p=B.pose(t);local x,y=w*p.x,h*p.y
 return x+(sx-x)*p.progress,y+(sy-y)*p.progress
end
function B.advance(age)
 local old=B.age;local dt=math.max(0,age-old);B.age=age
 local distance=math.abs(B.pose(age).worldX-B.pose(old).worldX)*Arena.width
 require('brown_walk').advance(B.actor,distance,dt)
end
function B.draw(canvas,w,h)
 local g=love.graphics;local shader=g.getShader();local t=B.age;local p=B.pose(t)
 local decor=require('transition_scenery');local rocks=require('rockslide_scenery');local bubble=require('breathing_bubble')
 local scale,x,y=App.viewport(w,h);local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
 local ax,ay=B.position(t,w,h,sx,sy);local size=Characters.playerWidth*scale*p.size
 g.push('all');g.origin();g.setShader()
 g.translate(math.sin(t*63)*p.jolt*11*scale,math.sin(t*47)*p.jolt*15*scale)
 decor.backdrop(4,w,h,t,1,p.camera*.6)
 g.setColor(.002,.009,.025,p.depth*.85);g.rectangle('fill',0,0,w,h)
 for i=1,45 do
  local px=w*((i*.618-p.camera*.3-t*.018)%1);local py=h*((.12+i*.137-p.camera*.6)%1)
  g.setColor(.25,.65,.80,(1-p.mapAlpha)*.20);g.circle('fill',px,py,(.6+i%3*.4)*scale)
 end
 -- The water rushes upward relative to the sinking rider, at several depths.
 local rush=ease(p.slide/.65)*(1-ease((t-5.4)/1.3))
 for i=1,26 do
  local px=w*((i*.618)%1);local py=h*((i*.173-p.camera*(.8+i%3*.35))%1)
  g.setColor(.42,.72,.80,rush*(.06+i%3*.025));g.setLineWidth((.7+i%2*.6)*scale)
  g.line(px,py,px,py+h*(.015+p.slide*.012)*rush)
 end
 decor.reveal(canvas,B.environment,w,h,p.mapAlpha,p.actorsAlpha,shader)
 -- Both layers stay solid and leave the screen with the following camera.
 rocks.draw(w,h,p,t)
 local hx,hy,r=bubble.headPosition(ax,ay,size,p.dir)
 local fromX,fromY=w*.52,h*.595+r*1.20-5*scale
 local lampX=fromX+(hx-fromX)*p.equip
 local lampY=fromY+(hy-fromY)*p.equip-math.sin(p.equip*math.pi)*18*scale
 local lx,ly=bubble.lanternPosition(lampX,lampY,r,t*(1-p.progress),p.dir)
 if p.equip<1 then
  for i=5,1,-1 do g.setColor(1,.72,.28,.025);g.circle('fill',lx,ly,(12+i*13)*scale) end
 end
 g.push();g.translate(ax,ay);g.rotate(p.tilt);g.scale(1-.65*math.exp(-((t-3.6)/.16)^2),1);g.translate(-ax,-ay)
 g.setColor(1,1,1);Characters.draw(ax,ay,size,p.dir,B.actor,7)
 if not require('integrated_skins').bubble(Characters.selected()) then bubble.drawAt(hx,hy,r,t*(1-p.progress),false,nil,nil,1,p.dir) end
 if p.equip>0 and p.equip<1 then
  require('silk_art').thread(ax+size*.22,ay+size*.08,lx,ly,3*scale,math.sin(p.equip*math.pi))
 end
 bubble.drawLantern(lampX,lampY,r,t*(1-p.progress),nil,1,p.dir)
 g.pop()
 g.pop()
end
return require('arrival_timing').fit(B)
