-- Offsets in rendered sprite-size units, measured on the authored Auréole PNGs.
local A={}
function A.winged(index) return (Characters.crowned[index] or index)==6 end
function A.menuOffset(index,size) return A.winged(index) and -size*.13 or 0 end
function A.halo(dir)
 if dir=='up' then return 0,-.35,.17,.075 end
 if dir=='left' or dir=='right' then return (dir=='right' and 1 or -1)*.25,.14,.16,.075 end
 return 0,.075,.18,.075
end
function A.eye(dir,eye)
 if dir=='left' or dir=='right' then return (dir=='right' and 1 or -1)*.29,.26 end
 return eye==2 and .09 or -.09,.24
end
return A
