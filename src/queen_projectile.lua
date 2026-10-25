-- One material and ballistic step for combat webs and the cocoon volley.
local P={size=26}
function P.step(w,dt)
 w.age=(w.age or 0)+dt
 local x,y=w.x+w.vx*dt,w.y+w.vy*dt
 local wx,wy,wt=require('queen_brood').impact(w.x,w.y,x,y)
 return x,y,wx,wy,wt
end
function P.draw(w)
 local g=love.graphics;local a=math.atan2(w.vy,w.vx);local dx,dy=math.cos(a),math.sin(a)
 g.push('all');g.setShader();g.setColor(.18,.24,.12,.3);g.setLineWidth(4)
 g.line(w.x-dx*17+2,w.y-dy*17+5,w.x+2,w.y+5)
 g.setColor(.88,.94,.73,.7);g.setLineWidth(1.2);g.line(w.x-dx*17,w.y-dy*17,w.x,w.y)
 local c=require('queen_heirs').color(w.owner or 0);g.setColor(c[1],c[2],c[3])
 require('final_art').draw('web_shot',w.x,w.y,P.size,a);g.pop()
end
return P
