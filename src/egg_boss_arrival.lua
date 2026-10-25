local B={liveBackdrop=true,duration=5.5,release=2.1,impact=3.25}
function B.reset(options)
 B.active=false;B.age=0;require('boss_arrival_backdrop').clear(B)
 if Campaign.world~=1 or player.level~=10 or options and options.retry or App.sessionLayout or App.workshopMap or Secret.duel then return end
 if not App.historyPreview and (App.preview or App.practice or App.singleLevel or App.hardcore)then return end
 local boss=Raven.active and Raven or nil
 for _,item in ipairs(Bosses.items)do if item.kind=='merle' then boss=item.boss;break end end
 if boss then B.boss=boss;B.active=true end
end
function B.current()return B.active and B or nil end
function B.update(dt)
 if not B.active then return false end
 require('ambient_motion').update(dt);B.age=B.age+dt
 if B.age>=B.duration then
  B.active=false
  if not (App.historyPreview or Replay.playing or Replay.ghost or App.preview or App.practice or App.singleLevel or App.hardcore)then
   Profile.transitionsSeen=Profile.transitionsSeen or {};Profile.transitionsSeen.boss_egg=true;Profile.save()
  end
 end
 return true
end
function B.pose(t)
 local x=B.boss.x;local ground=B.boss.y-5
 local u=math.min(1,t/B.release);u=u*u*(3-2*u)
 local bx=-170+(x+170)*u;local by=85+math.sin(t*3)*8
 if t>=B.release then local leave=t-B.release;bx=x+leave*300;by=85-leave*85 end
 local ey=ground
 if t<B.release then ey=by+60
 elseif t<B.impact then local fall=(t-B.release)/(B.impact-B.release);ey=145+(ground-145)*fall*fall
 else local bounce=t-B.impact;ey=ground-math.abs(math.sin(bounce*9))*18*math.max(0,1-bounce/1.1)end
 return {birdX=bx,birdY=by,eggX=t<B.release and bx or x,eggY=ey}
end
function B.drawWorld()
 -- Nest occupants remain part of the living arena during the delivery.
 local b=B.boss;local broken=b.broken;local methods=B.hiddenMethods
 if methods then
  if methods.drawGround then methods.drawGround()end
  b.broken=true;if methods.draw then methods.draw()end
 end
 b.broken=broken
end
function B.draw(canvas,w,h)
 local g=love.graphics;local p=B.pose(B.age);local sx,sy=require('cinematic_accents').shake(B.age,B.impact,4,.4)
 g.push('all');g.origin();require('boss_arrival_backdrop').draw(canvas,w,h,sx,sy)
 Art.contactShadow(B.boss.x,B.boss.y+43,38,10,.13)
 require('mobs.bosses.raven.egg').draw(p.eggX,p.eggY,60,0,0)
 g.setColor(1,1,1);Art.draw('merle_flight',p.birdX,p.birdY,180,0)
 g.pop()
end
return B
