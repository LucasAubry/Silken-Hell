-- An isolated pose of the gameplay rig: never resets or updates the live boss.
local P={}
function P.draw(x,y,size,time)
 if not P.rig then
  P.rig=assert(love.filesystem.load('src/mobs/bosses/octopus/init.lua'))()
  local r=P.rig;r.x=0;r.y=0;r.angle=0;r.arms={3,3,3,3,3,3,3,3}
 end
 local g=love.graphics;local r=P.rig
 g.push('all');g.translate(x,y+math.sin((time or 0)*1.2)*size*.015)
 g.scale(size/400);g.rotate(math.sin((time or 0)*.6)*.10);g.setColor(1,1,1)
 r.drawArms()
 local key,_,width=r.sprite();local a=Art.images[key]
 require('mobs.bosses.octopus.head').draw(a,0,0,0,width/math.max(a.w,a.h),0)
 g.pop()
end
return P
