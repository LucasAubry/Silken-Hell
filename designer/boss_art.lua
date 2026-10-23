-- Use isolated visual state: editor previews never reset the live encounter.
local P={}
local Art=require('art')
function P.draw(kind,x,y,size)
 if kind~='merle' and kind~='storm' and kind~='octopus' then return false end
 local g=love.graphics;g.push('all');g.setColor(1,1,1)
 if kind=='merle' then
  require('mobs.bosses.raven.egg').draw(x,y,size/2,0)
 elseif kind=='storm' then
  local a=Art.images.merle_flight;local scale=size/math.max(a.w,a.h)
  Art.draw('merle_flight',x,y,a.w*scale,0,a.h*scale)
 else
  if not P.octopus then
   local chunk=assert(love.filesystem.load('src/mobs/bosses/octopus/init.lua'))
   setfenv(chunk,setmetatable({MobBehaviors={}},{__index=_G}))
   P.octopus=chunk()
   local o=P.octopus;o.x=0;o.y=0;o.angle=0;o.arms={3,3,3,3,3,3,3,3};o.wrapArms={}
  end
  g.translate(x,y);g.scale(size/360)
  P.octopus.drawArms()
  local a=Art.images.octopus_extended_down
  require('mobs.bosses.octopus.head').draw(a,0,0,0,360/math.max(a.w,a.h),0)
 end
 g.pop();return true
end
return P
