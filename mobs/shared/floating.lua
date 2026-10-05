-- Shared pose keeps the artwork, contact box and halo on the same bob.
local F={}
function F.offset(m)
 return m.float and math.sin((m.floatTime or 0)*4)*8 or 0
end
function F.hitbox(m)
 -- Approved tuner values: 100% width, 140% height, X +0, Y +5.
 m.hitBox_width=28;m.hitBox_height=42*1.4
 m.hitBox_offset_x=-14;m.hitBox_offset_y=-m.hitBox_height/2+5
end
return F
