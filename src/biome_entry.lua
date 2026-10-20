-- Repeat visits keep the last movement of the story, over the actual frozen level.
local B={duration=2.5}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function B.begin(world)
 B.world=world;B.age=0;B.actor={walkMoving=false}
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
function B.pose(age,w,h,sx,sy,scale)
 local u=ease(age/2.15);local side=B.world==7 or B.world==3
 local x=side and -Characters.playerWidth*scale or sx
 local y=side and sy or -Characters.playerWidth*scale
 return {x=u==1 and sx or x+(sx-x)*u,y=u==1 and sy or y+(sy-y)*u,progress=u,size=1+(B.world==6 and .65 or .12)*(1-u),
  dir=u==1 and 'up' or side and 'right' or B.world==6 and 'up' or 'down'}
end
function B.advance(age)
 local previous=B.age;local dt=math.max(0,age-previous);B.age=age
 local distance=math.abs(ease(age/2.15)-ease(previous/2.15))*Arena.width
 require('brown_walk').advance(B.actor,distance,dt)
end
function B.draw(canvas,w,h)
 local g=love.graphics;local shader=g.getShader();local scale,x,y=App.viewport(w,h)
 local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
 local p=B.pose(B.age,w,h,sx,sy,scale);local size=Characters.playerWidth*scale*p.size
 g.push('all');g.origin();g.setShader()
 require('transition_scenery').floor(B.world,w,h,1)
 require('transition_scenery').reveal(canvas,B.environment,w,h,1,ease((B.age-1.5)/.9),shader)
 if B.world==5 and p.progress<1 then
  require('silk_art').thread(sx,-20*scale,p.x,p.y-size*.16,3*scale,0)
 end
 if B.world==3 or B.world==5 or B.world==2 or B.world==6 then
  Characters.shadow(B.world==3 and p.x or sx,sy,Characters.playerWidth*scale,p.dir,B.actor,B.world==3 and 1 or ease((B.age-1.5)/.65))
 end
 g.setColor(1,1,1);Characters.draw(p.x,p.y,size,p.dir,B.actor,B.world)
 if B.world==4 or B.world==7 then
  local bubble=require('breathing_bubble');local hx,hy,r=bubble.headPosition(p.x,p.y,size,p.dir)
  if not require('integrated_skins').bubble(Characters.selected()) then bubble.drawAt(hx,hy,r,B.age,false,nil,nil,1,p.dir) end
  if B.world==7 then bubble.drawLantern(hx,hy,r,B.age,nil,1,p.dir) end
 elseif B.world==6 then
  require('sky_arrival').drawClouds(w,h,B.age,(1-p.progress)*.35)
 end
 g.pop()
end
return B
