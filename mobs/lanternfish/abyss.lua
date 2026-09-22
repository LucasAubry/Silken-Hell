-- Lanternfish share the abyss fish's light-seeking movement, with their own sprite.
return function(A)
 local behavior=require('mobs.abyss_fish')(A)
 behavior.draw=function(m)
  if m.abyssHeld then return end
  love.graphics.setColor(1,1,1);Art.drawFacing('lanternfish',m.dir,m.x,m.y,68)
 end
 return behavior
end
