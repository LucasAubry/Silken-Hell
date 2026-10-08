Walls = walls_1
function update_walls_level()
	Walls = _G["walls_" .. tostring(player.level)] or {}
--_G cest la variable global en lua qui contien tout les variable global
end

function addWall(x, y, w, h)
    table.insert(Walls, {x = x, y = y, w = w, h = h})
end

function willCollide(newX, newY)
    if Abyss and Abyss.blockedPlayer and Abyss.blockedPlayer(newX,newY) then return true end
    if Abyss and Abyss.playerMinX and newX<Abyss.playerMinX(newY) then return true end
	local offsetX = player.hitBox_offset_x or 0
	local offsetY = player.hitBox_offset_y or 0

    local px,py,pw,ph=require('collision_shapes').bounds(player,newX,newY)
    return Arena.blocked(px,py,pw,ph,Walls)
end



function checkCollision(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and
           bx < ax + aw and
           ay < by + bh and
           by < ay + ah
end


function isTouching(a, b)
    if (a==player and b~=objet.larme and b.tunnelTravel) or (b==player and a~=objet.larme and a.tunnelTravel) then return false end
    if Abyss and Abyss.isPulling() and ((a==player and b~=objet.larme) or (b==player and a~=objet.larme)) then return false end
    if a.abyssHeld or b.abyssHeld or (player.abyssSpit and (a==player or b==player)) then return false end
    if (player.abyssGrace or 0)>0 and ((a==player and b~=objet.larme) or (b==player and a~=objet.larme)) then return false end
    local T=require('collision_shapes')
    local ax,ay,aw,ah=T.bounds(a);local bx,by,bw,bh=T.bounds(b)
    return checkCollision(ax,ay,aw,ah,bx,by,bw,bh)
end
