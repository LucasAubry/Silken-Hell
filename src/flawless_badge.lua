local B={}
function B.draw(x,y,r)
 local g=love.graphics;g.push('all');g.setShader();g.setColor(.025,.12,.08,.98)
 g.circle('fill',x,y,r);g.setColor(.65,1,.73);g.setLineWidth(2)
 g.circle('line',x,y,r);g.line(x-r*.5,y,x-r*.12,y+r*.4,x+r*.55,y-r*.4);g.pop()
end
return B
