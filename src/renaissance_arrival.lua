-- Leave the volcanic ledge, swing into open air, and weave a landing net.
local S=require('elemental_arrival').new(true)
local motion=require('cinematic_motion')
S.duration=8.2;S.impact=8
local function ease(v)v=math.max(0,math.min(1,v));return v*v*(3-2*v)end
local xs={{0,.18,0},{1,.23,.08},{2.4,.40,.10},{3.7,.5,0},{8.2,.5,0}}
local ys={{0,.28,0},{1,.28,0},{1.6,.19,0},{2.7,.38,.18},{4,.28,0},{5.1,.48,.28},{6.3,.83,0},{6.9,.73,0},{8.2,.78,0}}
function S.pose(t)
 local land=ease((t-4.2)/4)
 return {x=motion.sample(xs,t),y=motion.sample(ys,t),progress=land,size=1.6-.6*land,
  mapAlpha=ease((t-2.6)/2.8),actorsAlpha=ease((t-7.1)/.9),
  silk=ease((t-4.6)/.6)*(1-ease((t-7.4)/.8)),dir=t<3.7 and 'right' or 'up'}
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
 local cliff=1-ease((t-2.8)/1.4)
 if cliff>0 then
  decor.material(false);g.setColor(.20,.065,.035,cliff)
  g.polygon('fill',0,0,w*.30,0,w*.29,h*.22,w*.26,h*.31,w*.17,h*.34,0,h*.40)
  g.setShader();g.setColor(.9,.22,.035,cliff*.65);g.setLineWidth(2*scale)
  g.line(0,h*.36,w*.16,h*.30,w*.24,h*.29,w*.27,h*.23)
 end
 -- A first line catches on the cliff lip; releasing it carries the jump forward.
 if t>1.7 and t<4 then
  local alpha=ease((t-1.7)/.25)*(1-ease((t-3.5)/.5))
  silk.thread(w*.25,h*.1,ax,ay-size*.12,3*scale,alpha)
 end
 Characters.shadow(sx,sy,Characters.playerWidth*scale,p.dir,S.actor,ease((t-5.7)/2.3))
 -- Two ground anchors spread a flexible web under the falling spider.
 if p.silk>0 then
  local deploy=ease((t-4.6)/.6)
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
