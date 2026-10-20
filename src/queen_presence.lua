local Q={}
function Q.land(f)
 f.landed={x=f.x,y=f.y,at=f.clock}
end
function Q.ground(f)
 local g=love.graphics;g.push('all');g.setShader()
 local height=f.jumpHeight or 0
 -- A planted shadow expands and softens as she rises.
 if height<=0 then Art.contactShadow(f.x,f.y+13,28,11,.32) end
 g.pop()
end
return Q
