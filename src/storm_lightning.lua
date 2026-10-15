-- Shared encounter light follows persistent branching discharges.
local L={origin={0,0},size={0,600},events={},life=2.4}
function L.load()
 L.shader=L.shader or love.graphics.newShader('assets/shaders/storm_ground_light.glsl')
end
function L.reset() L.events={} end
function L.trigger(x,y,seed)
 if #L.events>=4 then table.remove(L.events,1) end
 L.events[#L.events+1]={x=x,y=y,age=0,seed=seed or x+y}
end
function L.update(dt)
 if Aftermath and Aftermath.cleared then L.reset();return end
 for i=#L.events,1,-1 do
  local p=L.events[i];p.age=p.age+dt
  if p.age>=L.life then table.remove(L.events,i) end
 end
end
function L.reach(age) return math.max(0,age*2400) end
function L.draw(x,y,age,life,seed)
 if age<0 or age>=life then return end
 L.load();local g=love.graphics
 L.origin[1],L.origin[2]=x,y;L.shader:send('origin',L.origin)
 L.size[1]=Arena.width;L.shader:send('floorSize',L.size)
 L.shader:send('reach',L.reach(age))
 L.shader:send('fade',math.min(1,(life-age)/math.min(.75,life*.45)))
 L.shader:send('seed',(seed or x+y)%31)
 L.shader:send('age',age)
 g.push('all');g.setShader(L.shader);g.setColor(1,1,1);g.setBlendMode('add')
 -- The shader uses logical world coordinates, including scaled render canvases.
 g.draw(UI.pixel,0,0,0,Arena.width,600)
 g.pop()
end
function L.drawAll()
 for _,p in ipairs(L.events) do L.draw(p.x,p.y,p.age,L.life,p.seed) end
end
function L.warning(x,y,charge,rx,ry)
 local g=love.graphics;g.push('all');g.setShader();g.setBlendMode('alpha')
 g.setColor(1,.88,.49,.28+charge*.35);g.setLineWidth(1.2)
 g.ellipse('line',x,y,rx,ry)
 g.setColor(1,.94,.72,.45+charge*.4)
 g.line(x-5,y,x+5,y);g.line(x,y-3,x,y+3);g.pop()
end
return L
