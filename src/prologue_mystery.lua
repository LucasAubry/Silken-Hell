-- Optional cinematic study; the regular first launch and History remain intact.
local M={}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
local function move(a,x,y,speed,dt)
 local dx,dy=x-a.x,y-a.y;local d=math.sqrt(dx*dx+dy*dy);local step=math.min(d,speed*dt)
 if d>.01 then a.x=a.x+dx/d*step;a.y=a.y+dy/d*step;a.angle=math.atan2(dy,dx)-math.pi/2 end
 require('brown_walk').advance(a,step,dt)
end
function M.open()
 local p=require('prologue');p.open(true);p.mystery=true;p.phase='dusk'
 p.hero.x=p.nest.x-18;p.hero.y=p.nest.y-9
 p.victim={x=p.nest.x+18,y=p.nest.y-9}
 p.partner.x=p.victim.x;p.partner.y=p.victim.y;p.partner.angle=math.pi
 p.camera={x=p.nest.x,y=p.nest.y};p.glow=0;p.eyeOpen=0;p.kneel=0
end
function M.update(p,dt)
 p.time=p.time+dt;local t=p.time
 p.hero.walkMoving=false;p.partner.walkMoving=false;p.queen.walkMoving=false
 if p.phase=='dusk' then
  p.glow=ease(t/2);p.darkness=.38*ease(t/2)
  if t>=2 then p.transition('portal_open') end
 elseif p.phase=='portal_open' then
  p.portalAmount=ease(t);if t>=1 then p.transition('arrival') end
 elseif p.phase=='arrival' then
  move(p.queen,p.victim.x+15,p.victim.y+8,240,dt)
  if t>=2 then p.queen.x=p.victim.x+15;p.queen.y=p.victim.y+8;p.transition('lift') end
 elseif p.phase=='lift' then
  p.queen.angle=0;p.kneel=math.sin(ease(t/1.5)*math.pi)
  p.glow=1-.5*ease(t/1.5)
  if t>=1.5 then p.kneel=0;p.carrying=true;p.transition('confront') end
 elseif p.phase=='confront' then
  -- The waking hero approaches; the queen hesitates instead of fleeing.
  move(p.hero,p.queen.x-58,p.queen.y+43,65,dt);p.hero.dir='up'
  p.queen.angle=0
  if t>=3 then p.transition('departure') end
 elseif p.phase=='departure' then
  move(p.queen,p.portal.x,p.portal.y,p.departureDistance/2.5,dt)
  move(p.hero,p.queen.x-65,p.queen.y+50,155,dt);p.hero.dir='up'
  if t>=2.5 then p.queen.x=p.portal.x;p.queen.y=p.portal.y;p.queen.angle=0;p.transition('look') end
 elseif p.phase=='look' then
  p.eyeOpen=ease(t/.65);p.glow=.5+.2*math.sin(t*2)
  move(p.hero,p.queen.x-65,p.queen.y+50,100,dt);p.hero.dir='up'
  if t>=.8 and #p.tears==0 then
   local x,y=p.partnerEye();p.tears[1]={x=x,y=y+32,eyeX=x,eyeY=y,age=0}
  end
  if t>=2.3 then p.transition('queen_enter') end
 elseif p.phase=='queen_enter' then
  p.eyeOpen=1-ease(t/1.8);p.glow=.5*(1-ease(t/1.8))
  if t>=1.8 then p.queenGone=true;p.transition('wake') end
 elseif p.phase=='wake' then
  move(p.hero,p.portal.x,p.portal.y,110,dt);p.hero.dir='up'
  if t>=1 then p.transition('enter') end
 elseif p.phase=='enter' then
  p.darkness=.38+.62*ease(t/.85)
  if t>=.85 then p.close();return end
 end
 p.updateTears(dt)
 local target=p.carrying and not p.queenGone and p.queen or p.hero
 if p.phase=='dusk' or p.phase=='portal_open' or p.phase=='arrival' or p.phase=='lift' then target=p.partner end
 local f=1-math.exp(-dt*2.5);p.camera.x=p.camera.x+(target.x-p.camera.x)*f;p.camera.y=p.camera.y+(target.y-p.camera.y)*f
end
function M.camera(p)
 local zoom=2.7;local x=math.max(p.width/(2*zoom),math.min(p.width-p.width/(2*zoom),p.camera.x))
 local y=math.max(p.height/(2*zoom),math.min(p.height-p.height/(2*zoom),p.camera.y))
 love.graphics.translate(p.width/2,p.height/2);love.graphics.scale(zoom);love.graphics.translate(-x,-y)
end
function M.halo(p,x,y)
 if p.glow<=0 then return end
 local g=love.graphics;g.push('all');g.setBlendMode('add')
 for i=8,1,-1 do g.setColor(.67,.81,1,.035*p.glow);g.ellipse('fill',x,y,24+i*5,18+i*3) end
 for i=1,7 do local a=i*2.399+p.clock*.5;local r=18+i%3*4
  g.setColor(.8,.9,1,p.glow*.5);g.circle('fill',x+math.cos(a)*r,y+math.sin(a)*r*.6, .7)
 end
 g.pop()
end
function M.eyes(p,q,width)
 if p.eyeOpen<=0 then return end
 local a=Art.images.prologue_carrier_down;local qx,qy=a.quad:getViewport();local s=width/a.w
 local g=love.graphics;g.push('all');g.translate(q.x,q.y)
 -- Reveal the eyes over the closed eyelids of the existing passenger sprite.
 for _,eye in ipairs({{735,416},{820,425}}) do
  local x,y=(eye[1]-qx-a.w/2)*s,(eye[2]-qy-a.h/2)*s
  g.setColor(.91,.89,.81,p.eyeOpen);g.ellipse('fill',x,y,29*s,15*s*p.eyeOpen)
  g.setColor(.10,.08,.10,p.eyeOpen);g.ellipse('fill',x-5*s,y,20*s,13*s*p.eyeOpen)
  g.setColor(.9,.96,1,p.eyeOpen);g.circle('fill',x-10*s,y-4*s,4*s)
 end
 g.pop()
end
function M.ui(p)
 if p.phase~='confront' then return end
 local g=love.graphics;local alpha=ease(p.time/.35)
 g.setColor(.018,.008,.023,alpha*.88);g.rectangle('fill',200,620,800,74,12)
 UI.text('Pardonne-moi. Son heure est venue.',220,642,'medium',{1,.89,.73,alpha},760,'center')
end
return M
