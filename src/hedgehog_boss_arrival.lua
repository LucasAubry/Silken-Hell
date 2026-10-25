local B={liveBackdrop=true,duration=8.2}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function B.reset(options)
 B.active=false;B.age=0;require('boss_arrival_backdrop').clear(B)
 if Campaign.world~=5 or player.level~=10 or options and options.retry or App.sessionLayout or App.workshopMap or Secret.duel then return end
 if not App.historyPreview and (App.preview or App.practice or App.singleLevel or App.hardcore) then return end
 local boss=Hedgehog.active and Hedgehog or nil
 for _,item in ipairs(Bosses.items) do if item.kind=='hedgehog' then boss=item.boss;break end end
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
   if not Profile.transitionsSeen.boss_hedgehog then Profile.transitionsSeen.boss_hedgehog=true;Profile.save() end
  end
 end
 return true
end
function B.pose(t)
 local o=B.boss;local x,y=-100,o.y+170;local angle=0
 if t>=1.6 and t<3.15 then
  local u=(t-1.6)/1.55;x=-100+(Arena.width+35)*u;y=o.y+170-80*math.sin(u*math.pi);angle=u*18
 elseif t>=3.15 and t<4.65 then
  local u=(t-3.15)/1.5;x=Arena.width-65-(Arena.width-160)*u;y=o.y+170-180*math.sin(u*math.pi/2);angle=18-u*17
 elseif t>=4.65 then
  local u=ease((t-4.65)/1.5);x=95+(o.x-95)*u;y=o.y-10+10*u;angle=1+u*10
 end
 return {x=x,y=y,angle=angle,visible=t>=1.6,unroll=ease((t-6.15)/.85)}
end
function B.shake(t)
 local amplitude=t<1.6 and ease(t/1.6)*1.8 or 0
 for _,impact in ipairs({1.6,3.15,4.65})do
  local age=t-impact
  if age>=0 and age<.65 then amplitude=amplitude+8*(1-age/.65)^2 end
 end
 return math.sin(t*83)*amplitude,math.sin(t*107+.8)*amplitude*.65
end
function B.molePose(m,t)
 if m.type~='mole' or m.dead then return m end
 local p={};for k,v in pairs(m)do p[k]=v end
 if t<1.6 then p.age=m.age
 elseif t<2.15 then p.age=4.3+.7*ease((t-1.6)/.55)
 elseif t<6.15 then p.age=.5
 elseif t<6.85 then p.age=2.15+.55*ease((t-6.15)/.7)
 else p.age=2.7 end
 p.vx=0;p.vy=0
 return p
end
local function debris(x,y,age,side)
 if age<0 or age>1.25 then return end
 local g=love.graphics;local fade=1-age/1.25
 for i=1,24 do
  local vx=side*(35+i%6*37);local vy=-70-i%5*32
  local px=x+vx*age;local py=y+vy*age+130*age*age
  local size=2+i%4
  g.setColor(.36,.26,.15,fade*.65);g.circle('fill',px,py,8+i%5*3)
  g.setColor(.64,.5,.32,fade);g.polygon('fill',px-size,py,px,py-size,px+size,py+size,px-size*.6,py+size)
 end
end
function B.draw(canvas,w,h)
 local g=love.graphics;local t=B.age;local p=B.pose(t);local o=B.boss
 g.push('all');g.origin();local sx,sy=B.shake(t);require('boss_arrival_backdrop').draw(canvas,w,h,sx,sy)
 -- A low rumble dislodges dust before the rolling silhouette enters.
 if t<1.6 then
  for i=1,14 do
   local amount=ease(t/1.6);local x=22+i%3*13;local y=o.y+85+i*7
   g.setColor(.58,.44,.28,amount*.55);g.circle('fill',x+math.sin(t*30+i)*amount*5,y,2+i%3)
  end
 end
 for _,m in ipairs(mobs)do if m.type=='mole' then
  require('mole_dust').draw(B.molePose(m,t))
 end end
 debris(25,o.y+170,t-1.6,1)
 debris(Arena.width-45,o.y+170,t-3.15,-1)
 debris(85,o.y-10,t-4.65,1)
 if p.visible then
  g.setColor(0,0,0,.23);g.ellipse('fill',p.x,p.y+31,44,15)
  if p.unroll<1 then
   g.push();g.translate(p.x,p.y);g.rotate(p.angle);g.setColor(1,1,1,1-p.unroll)
   Art.drawFacing('hedgehog_ball','down',0,0,92+12*p.unroll);g.pop()
  end
  if p.unroll>0 then
   g.setColor(1,1,1,p.unroll);Art.drawFacing('hedgehog','down',p.x,p.y,104)
  end
 end
 g.pop()
end
return B
