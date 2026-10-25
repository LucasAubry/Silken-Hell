local B={liveBackdrop=true,duration=7.2,impact=4.3,projectileSize=26}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function B.reset(options)
 B.active=false;B.age=0;require('boss_arrival_backdrop').clear(B)
 local f=require('final_spider');B.boss=f
 if Campaign.world~=3 or player.level~=1 or not f.active or options and options.retry or App.sessionLayout or App.workshopMap then return end
 if not App.historyPreview and (App.preview or App.practice or App.singleLevel or App.hardcore or Secret.duel) then return end
 B.active=true;B.hit=false;B.fired=false;B.hitCount=0;B.splats={}
end
function B.current()
 local r=require('run_start')
 return B.active and not r.arrival and (App.historyPreview or not r.active) and B or nil
end
function B.fire()
 B.fired=true
 local f=B.boss;local x,y=f.x,f.y-24
 local angle=math.atan2(player.y+12-y,player.x+15-x)
 local distance=math.sqrt((player.x+15-x)^2+(player.y+12-y)^2)
 -- All shots use the same speed and collision rules; only this one ray intersects the player.
 local count=math.max(8,math.min(24,math.floor(distance/30)))
 for i=0,count-1 do
  local a=angle+i*math.pi*2/count
  f.webs[#f.webs+1]={x=x,y=y,vx=math.cos(a)*420,vy=math.sin(a)*420,age=0,owner=0}
 end
end
function B.updateShots(dt)
 local f=B.boss;local projectile=require('queen_projectile')
 for i=#f.webs,1,-1 do
  local w=f.webs[i];local xx,yy,wx,wy,wallT=projectile.step(w,dt)
  local hit=require('collision_shapes').sweptCircle('queen_web',w.x,w.y,xx,yy,21)
  -- Wall collision wins if it occurs before the player's contact point.
  if hit and not wx then
   B.hit=true;B.hitCount=B.hitCount+1;f.snare=2.1;f.introSnare=true;f.introContact=true
   f.escapeTaps={};f.escapeHeld={};f.snareSource='cocoon';table.remove(f.webs,i)
  elseif wx then
   B.splats[#B.splats+1]={x=wx,y=wy,age=0};table.remove(f.webs,i)
  else w.x=xx;w.y=yy end
 end
 for _,s in ipairs(B.splats)do s.age=s.age+dt end
end
function B.update(dt)
 if not B.current() then return false end
 require('ambient_motion').update(dt)
 local previous=B.age;B.age=B.age+dt
 if B.age>=B.impact then
  if not B.fired then B.fire() end
  B.updateShots(B.age-math.max(previous,B.impact))
 end
 if B.age>=B.duration then
  B.active=false
  if not (App.historyPreview or Replay.playing or Replay.ghost or App.preview or App.practice or App.singleLevel or App.hardcore) then
   Profile.transitionsSeen=Profile.transitionsSeen or {}
   if not Profile.transitionsSeen.boss_queen then Profile.transitionsSeen.boss_queen=true;Profile.save() end
  end
 end
 return true
end
function B.pose(t)
 return {y=-150+(B.boss.y+126)*ease(t/2.5),shake=ease((t-2.6)/1.7),broken=t>=B.impact,shot=ease((t-B.impact)/.95)}
end
function B.drawWorld()
 local g=love.graphics;local t=B.age;local p=B.pose(t);local f=B.boss
 g.push('all');g.setShader()
 local x=f.x+math.sin(t*85)*p.shake*5;local y=p.y
 if not p.broken then
  g.setColor(.92,.89,.79);g.setLineWidth(2);g.line(f.x,-20,x,y-57)
  if not Art.images.queen_cocoon then Art.add('queen_cocoon','assets/monstres/renaissance/reine/cocoon.png') end
  g.setColor(1,1,1);Art.draw('queen_cocoon',x,y,76,math.sin(t*65)*p.shake*.045,124)
 else
  require('final_art').spider('queen',f.x,f.y,62,0,f)
  require('cinematic_accents').silk(f.x,f.y-24,t-B.impact)
  for _,w in ipairs(f.webs)do require('queen_projectile').draw(w)end
  for _,s in ipairs(B.splats)do
   g.setColor(.75,.73,.54,math.max(0,1-s.age/3));require('final_art').draw('web_wall',s.x,s.y,28)
   require('cinematic_accents').silk(s.x,s.y,s.age)
  end

 end
 g.pop()
end
function B.draw(canvas,w,h)
 local g=love.graphics;local sx,sy=require('cinematic_accents').shake(B.age,B.impact,7,.6)
 g.push('all');g.origin();require('boss_arrival_backdrop').draw(canvas,w,h,sx,sy);g.pop()
end
return B
