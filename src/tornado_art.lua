local T={}
function T.draw(art,x,y,time,size,alpha)
 local g=love.graphics;size=size or 94;time=time or 0
 g.push('all');g.setShader()
 g.setColor(1,1,1,alpha or 1)
 art.draw('cloud_snare',x,y,size*(1+.025*math.sin(time*3)),time*2.2)
 g.setColor(.82,.91,.96,.45*(alpha or 1))
 art.draw('cloud_snare',x,y,size*.35,-time*3.4)
 g.pop()
end
return T
