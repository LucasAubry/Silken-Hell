local B={duration=8.5,impact=2.65}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function B.reset(options)
 B.active=false;B.age=0;require('boss_arrival_backdrop').clear(B)
 if Campaign.world~=6 or player.level~=10 or options and options.retry or App.sessionLayout or App.workshopMap or Secret.duel then return end
 if not App.historyPreview and (App.preview or App.practice or App.singleLevel or App.hardcore) then return end
 local boss=Storm.active and Storm or nil
 for _,item in ipairs(Bosses.items)do if item.kind=='storm' then boss=item.boss;break end end
 if not boss then return end
 B.boss=boss;B.target={x=boss.x,y=boss.y};B.active=true
end
function B.current()return B.active and B or nil end
function B.update(dt)
 if not B.active then return false end
 B.age=B.age+dt
 if B.age>=B.duration then
  B.active=false
  if not (App.historyPreview or Replay.playing or Replay.ghost or App.preview or App.practice or App.singleLevel or App.hardcore or App.sessionLayout) then
   Profile.transitionsSeen=Profile.transitionsSeen or {}
   if not Profile.transitionsSeen.boss_sky then Profile.transitionsSeen.boss_sky=true;Profile.save() end
  end
 end
 return true
end
function B.pose(t)
 local x=Arena.width*.55;local y=330
 local p={x=x,y=y,visible=false,angle=math.pi/2,hole=0}
 if t>=1.6 and t<B.impact then
  local u=(t-1.6)/(B.impact-1.6);p.y=-240+570*u*u;p.visible=true
 elseif t>=B.impact then
  p.hole=1-ease((t-5.3)/2.2)
  if t<B.impact+.35 then p.visible=true;p.y=330+(t-B.impact)/.35*230;p.burrowing=true
  elseif t>=4.05 and t<5.2 then
   p.visible=true;p.angle=-math.pi/2;p.y=550-430*ease((t-4.05)/1.05);p.burrowing=true
  elseif t>=5.2 and t<5.75 then
   local u=ease((t-5.2)/.55);p.visible=true;p.angle=-math.pi/2
   p.x=x-Arena.width*.35*u;p.y=120-500*u
  end
 end
 return p
end
local function bird(x,y,angle,t)
 local g=love.graphics;local a=Art.images.merle_flight;local scale=150/math.max(a.w,a.h)
 g.push();g.translate(x,y);g.rotate(angle)
 -- Tail attachment matches the boss's normal sprite; one captive follows it.
 local sx,sy=-155,58+math.sin(t*5)*5
 g.setColor(.78,.83,.84);g.setLineWidth(2);g.line(-60,58,-105,65,sx,sy)
 require('mobs.bosses.storm.snail_art').draw({x=sx,y=sy,phase='tethered',angle=0,age=t},t)
 g.setColor(1,1,1);local flap=1+math.sin(t*14)*.025
 Art.draw('merle_flight',0,0,a.w*scale*flap,0,a.h*scale/flap)
 g.pop()
end
function B.draw(canvas,w,h)
 local g=love.graphics;local t=B.age;local p=B.pose(t)
 g.push('all');g.origin();require('boss_arrival_backdrop').draw(canvas,w,h)
 local cx,cy=Arena.width*.55,330
 if p.hole>0 then
  local surface=require('terrain_surface')
  if not B.holeField or B.holeWidth~=Arena.width then
   B.holeField=surface.field({{x=cx,y=cy,rx=95,ry=70,seed=2}},'hole');B.holeWidth=Arena.width
  end
  g.push();g.translate(cx,cy);g.scale(p.hole);g.translate(-cx,-cy)
  surface.drawSkyField(B.holeField,1);g.pop()
 end
 local impactAge=t-B.impact
 if impactAge>=0 and impactAge<1.1 then
  local u=impactAge/1.1
  for i=1,26 do
   local a=i*2.399;local radius=u*(85+i%4*19)
   g.setColor(.88,.94,1,(1-u)*.75)
   g.circle('fill',cx+math.cos(a)*radius,cy+math.sin(a)*radius*.55,2+i%4)
  end
 end
 if p.visible then
  if t<B.impact then
   g.setColor(.82,.93,1,.5);g.setLineWidth(2)
   for i=-1,1 do g.line(p.x+i*28,p.y-90,p.x+i*28,p.y-180) end
  end
  if p.burrowing then
   local scale,x,y=App.viewport(w,h);g.intersectScissor(x,y,Arena.width*scale,cy*scale)
  end
  bird(p.x,p.y,p.angle,t)
 end
 g.pop()
end
return B
