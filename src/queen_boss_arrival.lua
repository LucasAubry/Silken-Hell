local B={duration=7.2,impact=4.3}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function B.reset(options)
 B.active=false;B.age=0;require('boss_arrival_backdrop').clear(B)
 local f=require('final_spider');B.boss=f
 if Campaign.world~=3 or player.level~=1 or not f.active or options and options.retry or App.sessionLayout or App.workshopMap then return end
 if not App.historyPreview and (App.preview or App.practice or App.singleLevel or App.hardcore or Secret.duel) then return end
 B.active=true;B.hit=false
end
function B.current()
 local r=require('run_start')
 return B.active and (App.historyPreview or not (r.active or r.arrival)) and B or nil
end
function B.update(dt)
 if not B.current() then return false end
 B.age=B.age+dt
 if B.age>=5.25 and not B.hit then
  B.hit=true;local f=B.boss;f.snare=2.1;f.introSnare=true;f.introContact=true;f.escapeTaps={};f.escapeHeld={};f.snareSource='cocoon'
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
 return {y=-150+(B.boss.y+150)*ease(t/2.5),shake=ease((t-2.6)/1.7),broken=t>=B.impact,shot=ease((t-B.impact)/.95)}
end
function B.draw(canvas,w,h)
 local g=love.graphics;local t=B.age;local p=B.pose(t);local f=B.boss
 g.push('all');g.origin();require('boss_arrival_backdrop').draw(canvas,w,h)
 local x=f.x+math.sin(t*85)*p.shake*5;local y=p.y
 if not p.broken then
  g.setColor(.92,.89,.79);g.setLineWidth(2);g.line(f.x,-20,x,y-83)
  if not Art.images.queen_cocoon then Art.add('queen_cocoon','assets/monstres/renaissance/reine/cocoon.png') end
  g.setColor(1,1,1);Art.draw('queen_cocoon',x,y,110,math.sin(t*65)*p.shake*.045,180)
 else
  require('final_art').spider('queen',f.x,f.y,62,0,f)
  local age=t-B.impact
  for i=1,26 do
   local a=i*2.399;local speed=130+i%7*27;local radius=age*speed
   local px,py=f.x+math.cos(a)*radius,f.y+math.sin(a)*radius
   g.setColor(.92,.91,.83,math.max(0,1-age/2.7));g.setLineWidth(2)
   g.line(px-7*math.cos(a+age),py-7*math.sin(a+age),px+7*math.cos(a+age),py+7*math.sin(a+age))
   if age<1.7 then require('final_art').draw('web_shot',px,py,16,a) end
  end
  if not B.hit then
   local px=f.x+(player.x+15-f.x)*p.shot;local py=f.y+(player.y+12-f.y)*p.shot
   g.setColor(1,1,1);require('final_art').draw('web_shot',px,py,30,t*3)
  else require('queen_escape').draw(f) end
 end
 g.pop()
end
return B
