-- Leave the volcanic ledge, swing into open air, and weave a landing net.
local S=require('elemental_arrival').new(true)
local motion=require('cinematic_motion')
S.duration=11.4;S.impact=11.2
local function ease(v)v=math.max(0,math.min(1,v));return v*v*(3-2*v)end
local xs={{0,.18,0},{1,.24,.10},{2.4,.48,.04},{3,.5,0},{11.4,.5,0}}
local ys={{0,.22,0},{1,.22,0},{1.3,.18,0},{2.4,.54,.5},{3.4,.60,.015},{7.5,.62,.04},{9.2,.78,0},{9.8,.71,0},{11.4,.76,0}}
function S.pose(t)
 local land=ease((t-7.2)/4.2)
 return {x=motion.sample(xs,t),y=motion.sample(ys,t),progress=land,size=1.9-.9*land,
  mapAlpha=ease((t-4.2)/5.1),actorsAlpha=ease((t-9.5)/1.7),
  silk=ease((t-8.1)/.5)*(1-ease((t-10.6)/.8)),dir=t<1.3 and 'right' or 'up'}
end
function S.position(t,w,h,sx,sy)
 local p=S.pose(t)
 if p.progress==1 then return sx,sy end
 return w*p.x+(sx-w*p.x)*p.progress,h*p.y+(sy-h*p.y)*p.progress
end
function S.advance(age)
 local old=S.age;S.age=age
 require('brown_walk').advance(S.actor,math.abs(S.pose(age).x-S.pose(old).x)*Arena.width,math.max(0,age-old))
end
function S.draw(canvas,w,h)
 local g=love.graphics;local shader=g.getShader();local t=S.age;local p=S.pose(t)
 local decor=require('transition_scenery');local silk=require('silk_art')
 local scale,x,y=App.viewport(w,h);local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
 local ax,ay=S.position(t,w,h,sx,sy);local size=Characters.playerWidth*scale*p.size
 g.push('all');g.origin();g.setShader()
 decor.floor(2,w,h,1)
 decor.reveal(canvas,S.environment,w,h,p.mapAlpha,p.actorsAlpha,shader)
 local cliff=1-ease((t-3.4)/1.2)
 if cliff>0 then
  g.push();g.translate(0,-h*1.8*ease((t-1.2)/3.4))
  decor.material(false);g.setColor(.20,.065,.035,cliff)
  g.polygon('fill',0,h*.18,w*.28,h*.18,w*.27,h*.33,w*.23,h*1.6,w*.15,h*2.1,0,h*2.3)
  for i=1,14 do
   g.setColor(.3,.09,.035,cliff*.7);g.line(0,h*(.28+i*.12),w*(.24-i*.003),h*(.24+i*.12))
  end
  g.setShader();g.setColor(.9,.22,.035,cliff*.65);g.setLineWidth(2*scale)
  g.line(0,h*.18,w*.28,h*.18);g.pop()
 end
 -- Foreground streaks and drifting rock fragments make the long free fall readable.
 local speed=ease((t-1.4)/.8)*(1-ease((t-8.2)/1.2))
 for i=1,45 do
  local px=w*((i*.618)%1);local py=h*((i*.173-t*.8)%1)
  g.setColor(.96,.84,.63,speed*.25);g.setLineWidth((1+i%2)*scale)
  g.line(px,py,px,py+(35+i%5*12)*scale)
 end
 Characters.shadow(sx,sy,Characters.playerWidth*scale,p.dir,S.actor,ease((t-8.6)/2.6))
 -- Two ground anchors spread a flexible web under the falling spider.
 if p.silk>0 then
  local deploy=ease((t-8.1)/.5)
  for _,side in ipairs({-1,1}) do
   local gx=sx+side*135*scale;local gy=sy+38*scale
   silk.thread(ax,ay,gx+(ax-gx)*(1-deploy),gy+(ay-gy)*(1-deploy),3*scale,p.silk)
   g.setColor(.85,.96,.75,p.silk*.6);g.circle('line',gx,gy,5*scale)
  end
  for i=1,4 do
   local u=i/5;local lx=ax+(sx-135*scale-ax)*u;local rx=ax+(sx+135*scale-ax)*u
   local py=ay+(sy+38*scale-ay)*u
   silk.thread(lx,py,rx,py,1.5*scale,p.silk*.65)
  end
 end
 g.setColor(1,1,1);Characters.draw(ax,ay,size,p.dir,S.actor,3)
 g.pop()
end
return S
