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
 p.camera={x=p.nest.x,y=p.nest.y};p.chaseZoom=0;p.glow=0;p.eyeOpen=0;p.kneel=0
end
local function chase(p,dt,speed)
 local h,q=p.hero,p.queen;local tear=p.tears[1]
 local target=tear and tear.released and not tear.collected and tear or q
 local dx,dy=target.x-h.x,target.y-h.y;local d=math.sqrt(dx*dx+dy*dy)
 local stop=target==q and not p.queenGone and 48 or 0
 if d>stop then move(h,target.x,target.y,math.min(speed,(d-stop)/dt),dt) end
 if math.abs(dx)>math.abs(dy) then h.dir=dx<0 and 'left' or 'right' else h.dir=dy<0 and 'up' or 'down' end
 if tear and not tear.collected and tear.age>=1.05 and (h.x-tear.x)^2+(h.y-tear.y)^2<27^2 then
  tear.collected=true;tear.pickupAge=0;p.tearsCollected=p.tearsCollected+1
 end
end
function M.update(p,dt)
 p.time=p.time+dt;local t=p.time
 p.hero.walkMoving=false;p.partner.walkMoving=false;p.queen.walkMoving=false
 if p.phase=='dusk' then
  -- Three quiet seconds together before several slow pulses of light.
  local age=math.max(0,t-3)
  p.glow=ease(age/.7)*(.15+1.05*(.5+.5*math.cos(age*2.1)))
  p.darkness=.38*ease(age/3)
  if t>=10 then p.transition('portal_open') end
 elseif p.phase=='portal_open' then
  p.glow=.2+.9*(.5+.5*math.cos((p.clock-3)*2.1))
  p.portalAmount=ease(t);if t>=1 then p.transition('arrival') end
 elseif p.phase=='arrival' then
  p.glow=.2+.9*(.5+.5*math.cos((p.clock-3)*2.1))
  move(p.queen,p.victim.x+15,p.victim.y+8,240,dt)
  if t>=2 then p.queen.x=p.victim.x+15;p.queen.y=p.victim.y+8;p.transition('lift') end
 elseif p.phase=='lift' then
  p.queen.angle=0;p.kneel=math.sin(ease(t/1.5)*math.pi)
  p.glow=1-.5*ease(t/1.5)
  if t>=1.5 then p.kneel=0;p.carrying=true;p.transition('confront') end
 elseif p.phase=='confront' then
  move(p.hero,p.queen.x-55,p.queen.y-15,80,dt);p.hero.dir='right'
  p.queen.angle=0
  if t>=1.4 then p.transition('departure') end
 elseif p.phase=='departure' then
  p.chaseZoom=ease(t/.45)
  local speed=p.departureDistance/1.4
  move(p.queen,p.portal.x,p.portal.y,speed,dt)
  p.eyeOpen=ease(t/.2)
  if t>=.15 and #p.tears==0 then
   local x,y=p.partnerEye();p.tears[1]={x=x,y=y+32,eyeX=x,eyeY=y,age=0}
  end
  chase(p,dt,135)
  if t>=1.4 then p.queen.x=p.portal.x;p.queen.y=p.portal.y;p.queen.angle=0;p.transition('queen_enter') end
 elseif p.phase=='queen_enter' then
  p.eyeOpen=1-ease(t/.65);p.glow=.5*(1-ease(t/.65));chase(p,dt,165)
  if t>=.65 then p.queenGone=true;p.transition('wake') end
 elseif p.phase=='wake' then
  chase(p,dt,170)
  if (p.hero.x-p.portal.x)^2+(p.hero.y-p.portal.y)^2<6^2 and p.tearsCollected==1 then p.transition('enter') end
 elseif p.phase=='enter' then
  p.darkness=.38+.62*ease(t/.85)
  if t>=.85 then p.enterWorld();return end
 end
 p.updateTears(dt)
 local target=p.carrying and not p.queenGone and {x=(p.queen.x+p.hero.x)/2,y=(p.queen.y+p.hero.y)/2} or p.hero
 if p.phase=='dusk' or p.phase=='portal_open' or p.phase=='arrival' or p.phase=='lift' then target=p.partner end
 local f=1-math.exp(-dt*(p.chaseZoom>0 and 6 or 2.5));p.camera.x=p.camera.x+(target.x-p.camera.x)*f;p.camera.y=p.camera.y+(target.y-p.camera.y)*f
end
function M.camera(p)
 local zoom=2.7-p.chaseZoom;local x=math.max(p.width/(2*zoom),math.min(p.width-p.width/(2*zoom),p.camera.x))
 local y=math.max(p.height/(2*zoom),math.min(p.height-p.height/(2*zoom),p.camera.y))
 love.graphics.translate(p.width/2,p.height/2);love.graphics.scale(zoom);love.graphics.translate(-x,-y)
end
function M.halo(p,x,y)
 if p.glow<=0 then return end
 local g=love.graphics;g.push('all');g.setBlendMode('add')
 for i=32,1,-1 do g.setColor(.67,.81,1,.00875*p.glow);g.ellipse('fill',x,y,24+i*1.25,18+i*.75) end
 for i=1,7 do local a=i*2.399+p.clock*.5;local r=18+i%3*4
  g.setColor(.8,.9,1,p.glow*.5);g.circle('fill',x+math.cos(a)*r,y+math.sin(a)*r*.6, .7)
 end
 g.pop()
end
function M.eyes(p,q,width)
 if p.eyeOpen<=0 then return end
 local dir=require('final_art').facing(q.angle)
 local g=love.graphics;local _,_,_,alpha=g.getColor();g.push('all')
 -- Each eye follows its source pixels, including mesh deformation and body sway.
 local function ellipse(eye,dx,dy,rx,ry)
  local vertices={}
  for i=0,19 do
   local angle=i*math.pi/10
   local x,y=p.carrierPoint(q,width,eye[1]+dx+math.cos(angle)*rx,eye[2]+dy+math.sin(angle)*ry)
   vertices[#vertices+1]=x;vertices[#vertices+1]=y
  end
  g.polygon('fill',vertices)
 end
 for _,eye in ipairs(p.passengerEyes[dir]) do
  g.setColor(.91,.89,.81,p.eyeOpen*alpha);ellipse(eye,0,0,24,12*p.eyeOpen)
  g.setColor(.10,.08,.10,p.eyeOpen*alpha);ellipse(eye,-4,0,16,10*p.eyeOpen)
  g.setColor(.9,.96,1,p.eyeOpen*alpha);ellipse(eye,-8,-3,3,3)
 end
 g.pop()
end
function M.ui(p)
 if p.phase~='confront' then return end
 local g=love.graphics;local alpha=ease(p.time/.35)
 g.setColor(.018,.008,.023,alpha*.88);g.rectangle('fill',200,620,800,74,12)
 UI.text('Pardonne-moi.',220,642,'medium',{1,.89,.73,alpha},760,'center')
end
return M
