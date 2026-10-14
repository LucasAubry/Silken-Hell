local L={}
function L.draw(x,y,charges,brightness,clock)
 local g=love.graphics
 if not L.mesh then
  L.mesh=g.newMesh({{-1,-1,0,0},{1,-1,1,0},{1,1,1,1},{-1,1,0,1}},'fan','static')
  L.shader=g.newShader('assets/shaders/abyss_charge_glow.glsl')
 end
 local radius=50+90*charges
 local pulse=1+math.sin(clock*2.4)*.025
 g.push('all');g.setBlendMode('add');g.setShader(L.shader)
 g.setColor(1,1,1,(.08+.32*brightness)*pulse)
 g.draw(L.mesh,x,y,0,radius,radius)
 g.pop()
end
return L
