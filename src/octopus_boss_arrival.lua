local B={liveBackdrop=true,duration=12}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function B.reset(options)
 B.active=false;B.age=0;require('boss_arrival_backdrop').clear(B)
 for _,cache in pairs(B.meshes or {}) do if cache.mesh then cache.mesh:release() end end
 B.meshes={};B.curves={};B.curveTick=nil
 if Campaign.world~=4 or player.level~=10 or options and options.retry or App.sessionLayout or App.workshopMap or Secret.duel then return end
 if not App.historyPreview and (App.preview or App.practice or App.singleLevel or App.hardcore) then return end
 local boss=Octopus.active and Octopus or nil
 for _,item in ipairs(Bosses.items) do if item.kind=='octopus' then boss=item.boss;break end end
 if not boss then return end
 B.boss=boss;B.active=true
end
function B.current()return B.active and B or nil end
function B.update(dt)
 if not B.active then return false end
 require('ambient_motion').update(dt)
 B.age=B.age+dt
 if B.age>=B.duration then
  B.active=false
  if not (App.historyPreview or Replay.playing or Replay.ghost or App.preview or App.practice or App.singleLevel or App.hardcore or App.sessionLayout) then
   Profile.transitionsSeen=Profile.transitionsSeen or {}
   if not Profile.transitionsSeen.boss_octopus then Profile.transitionsSeen.boss_octopus=true;Profile.save() end
  end
 end
 return true
end
function B.pose(t)
 local o=B.boss
 if t<6.55 then
  local u=math.max(0,math.min(1,(t-.35)/6.2))
  return {near=true,visible=t>=.35,x=Arena.width+820-(Arena.width+1640)*u,y=280+25*math.sin(u*math.pi*2),scale=2.8,angle=math.pi/2,swim=1}
 end
 local u=ease((t-6.9)/4.4)
 local settle=ease((t-9.7)/1.6)
 local travel=u+.025*math.sin(u*math.pi*4)
 return {near=false,visible=t>=6.9,x=-300+(o.x+300)*travel,y=o.y+25*math.sin(u*math.pi*2)*(1-settle),scale=1,angle=-math.pi/2*(1-settle)+o.angle*settle,swim=1-settle}
end
-- Alternating suckers keep a fixed world-space contact while the mantle advances.
function B.contact(t,arm,p)
 local source=B.boss.armCurve(arm);local tip=source[#source]
 local period=p.near and 1.15 or 1.3
 local offset=((arm-1)%4)*.25;local phase=(t/period+offset)%1
 local start=t-phase*period
 local function anchor(at)
  local pose=B.pose(math.max(p.near and .35 or 6.9,at))
  local c,s=math.cos(pose.angle),math.sin(pose.angle)
  return pose.x+(c*tip.x-s*tip.y)*pose.scale,pose.y+(s*tip.x+c*tip.y)*pose.scale
 end
 local ax,ay=anchor(start);local bx,by=anchor(start+period)
 local recovery=ease((phase-.6)/.4)
 local x,y=ax+(bx-ax)*recovery,ay+(by-ay)*recovery
 local dx,dy=(x-p.x)/p.scale,(y-p.y)/p.scale
 local c,s=math.cos(p.angle),math.sin(p.angle)
 return {x=x,y=y,tx=c*dx+s*dy,ty=-s*dx+c*dy,planted=phase<.6,phase=phase,lift=math.sin(recovery*math.pi)}
end
function B.armCurve(t,arm,p)
 local source=B.boss.armCurve(arm);local points={};local length=0
 local foot=B.contact(t,arm,p);local tip=source[#source]
 -- Waves travel from the joined arm roots towards their curled tips.
 for i,v in ipairs(source)do
  local u=(i-1)/(#source-1);local wave=math.sin(t*4.3-arm*.62-u*6.5)
  local follow=u*u*(3-2*u)
  local waveWeight=math.sin(u*math.pi)*u
  local x=v.x+((foot.tx-tip.x)*follow+wave*30*waveWeight-foot.lift*v.x*.18*follow)*p.swim
  local y=v.y+((foot.ty-tip.y)*follow+math.cos(t*4.3-arm*.62-u*6.5)*24*waveWeight-foot.lift*35*follow)*p.swim
  local previous=points[i-1]
  if previous then length=length+math.sqrt((x-previous.x)^2+(y-previous.y)^2)end
  points[i]={x=x,y=y,width=v.width,distance=length}
 end
 for i,v in ipairs(points)do
  local a,b=points[math.max(1,i-1)],points[math.min(#points,i+1)]
  local dx,dy=b.x-a.x,b.y-a.y;local d=math.max(.001,math.sqrt(dx*dx+dy*dy))
  local original=source[i];local sign=(-dy/d*original.nx+dx/d*original.ny)<0 and -1 or 1
  v.nx,v.ny=-dy/d*sign,dx/d*sign
 end
 return points
end
local function body(t,p)
 if not p.visible then return end
 local g=love.graphics;local o=B.boss;local vector=require('mobs.bosses.octopus.tentacle')
 g.push('all')
 for i=1,8 do
  local foot=B.contact(t,i,p)
  if foot.phase>=.6 and p.swim>.1 then
   local age=(foot.phase-.6)/.4
   for j=1,3 do
    g.setColor(.42,.63,.76,(1-age)*.3*p.swim);g.setLineWidth(1)
    g.circle('line',foot.x+math.sin(i*2.4+j)*age*18,foot.y-age*(12+j*7),1+age*(2+j))
   end
  end
 end
 g.translate(p.x,p.y);g.scale(p.scale);g.rotate(p.angle)
 local tick=math.floor(t*30)
 if B.curveTick~=tick then
  for i=1,8 do B.curves[i]=B.armCurve(t,i,p)end
  B.curveTick=tick
 end
 for i=1,8 do B.meshes[i]=vector.draw(B.curves[i],1,0,B.meshes[i])end
 local key,_,size=o.sprite();local a=Art.images[key]
 -- Mantle and all eight arms always use one transform and cross the screen together.
 if p.near then require('mobs.bosses.octopus.head').underside(a,0,0,0,size/math.max(a.w,a.h))
 else require('mobs.bosses.octopus.head').draw(a,0,0,0,size/math.max(a.w,a.h),0) end
 g.pop()
end
function B.drawWorld()
 local p=B.pose(B.age)
 if not p.near then body(B.age,p)end
end
function B.draw(canvas,w,h)
 local g=love.graphics;local p=B.pose(B.age)
 g.push('all');g.origin();local weight=p.near and p.visible and math.sin(math.pi*math.max(0,math.min(1,(B.age-.35)/6.2))) or 0
 require('boss_arrival_backdrop').draw(canvas,w,h,math.sin(B.age*19)*weight*.6,math.cos(B.age*23)*weight*.8)
 if p.near then body(B.age,p)end
 g.pop()
end
return B
