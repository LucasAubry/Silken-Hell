local B={liveBackdrop=true,duration=4.6,impact=2.8}
function B.reset(options)
 B.active=false;B.age=0;require('boss_arrival_backdrop').clear(B)
 if Campaign.world~=6 or player.level~=10 or options and options.retry or App.sessionLayout or App.workshopMap or Secret.duel then return end
 if not App.historyPreview and (App.preview or App.practice or App.singleLevel or App.hardcore)then return end
 local boss=Storm.active and Storm or nil
 for _,item in ipairs(Bosses.items)do if item.kind=='storm' then boss=item.boss;break end end
 if boss then B.boss=boss;B.active=true end
end
function B.current()return B.active and B or nil end
function B.update(dt)
 if not B.active then return false end
 require('ambient_motion').update(dt);B.age=B.age+dt
 if B.age>=B.duration then
  B.active=false
  if not (App.historyPreview or Replay.playing or Replay.ghost or App.preview or App.practice or App.singleLevel or App.hardcore)then
   Profile.transitionsSeen=Profile.transitionsSeen or {};Profile.transitionsSeen.boss_sky=true;Profile.save()
  end
 end
 return true
end
function B.pose(t)
 local u=math.max(0,math.min(1,(t-.4)/2.4));u=u*u*(3-2*u)
 return {x=B.boss.x,y=-140+(B.boss.y+140)*u,visible=t>=.4}
end
function B.draw(canvas,w,h)
 local g=love.graphics;local p=B.pose(B.age);local sx,sy=require('cinematic_accents').shake(B.age,B.impact,5,.5)
 g.push('all');g.origin();require('boss_arrival_backdrop').draw(canvas,w,h,sx,sy)
 if p.visible then
  Art.contactShadow(p.x,B.boss.y+27,57,19,.2)
  require('cloud_snail_art').draw(p.x,p.y,155,B.age,math.pi/2)
 end
 if B.age>=B.impact then
  for _,s in ipairs(B.boss.snails)do require('mobs.bosses.storm.snail_art').draw(s,B.age)end
 end
 g.pop()
end
return B
